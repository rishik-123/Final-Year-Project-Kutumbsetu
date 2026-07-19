import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpVerificationForm extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback onChangeMobile;
  final Function(String) onVerify;
  final VoidCallback onResend;

  const OtpVerificationForm({
    Key? key,
    required this.phoneNumber,
    required this.onChangeMobile,
    required this.onVerify,
    required this.onResend,
  }) : super(key: key);

  @override
  State<OtpVerificationForm> createState() => _OtpVerificationFormState();
}

class _OtpVerificationFormState extends State<OtpVerificationForm> {
  static const int _otpLength = 6;
  final List<TextEditingController> _controllers = List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(_otpLength, (_) => FocusNode());

  int _resendCountdown = 30;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto focus the first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _resendCountdown = 30;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        setState(() {
          _canResend = true;
          _timer?.cancel();
        });
      } else {
        setState(() {
          _resendCountdown--;
        });
      }
    });
  }

  void _resend() {
    if (_canResend) {
      _startTimer();
      widget.onResend();
      // Clear OTP fields
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  void _submit() {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length == _otpLength) {
      widget.onVerify(otp);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the full 6-digit OTP code'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      // If we typed a digit, focus the next box
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // We reached the end, close keyboard or verify
        _focusNodes[index].unfocus();
        _submit();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Enter OTP Sent to:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            TextButton(
              onPressed: widget.onChangeMobile,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Change Mobile Number'),
            ),
          ],
        ),
        Text(
          widget.phoneNumber,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        // 6 Custom Input Boxes for OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_otpLength, (index) {
            return SizedBox(
              width: 48,
              height: 58,
              child: CallbackShortcuts(
                bindings: <ShortcutActivator, VoidCallback>{
                  const SingleActivator(LogicalKeyboardKey.backspace): () {
                    // Custom backspace detection to shift focus backwards
                    if (_controllers[index].text.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                      _controllers[index - 1].clear();
                    }
                  },
                },
                child: Focus(
                  onKeyEvent: (FocusNode node, KeyEvent event) {
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                      if (_controllers[index].text.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                        _controllers[index - 1].clear();
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextFormField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2.0,
                        ),
                      ),
                    ),
                    onChanged: (value) => _onChanged(value, index),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        // Verification button
        ElevatedButton(
          onPressed: _submit,
          style: theme.elevatedButtonTheme.style,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Verify & Continue',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.verified_user_rounded, size: 20, color: Colors.white),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Countdown timer & Resend Action
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _canResend ? "Didn't receive code? " : "Resend OTP in ",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              if (_canResend)
                GestureDetector(
                  onTap: _resend,
                  child: Text(
                    'Resend OTP',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              else
                Text(
                  '$_resendCountdown seconds',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
