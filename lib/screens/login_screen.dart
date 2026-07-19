import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/mobile_input_form.dart';
import '../widgets/otp_verification_form.dart';

class LoginScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const LoginScreen({
    Key? key,
    required this.isDarkMode,
    required this.onToggleTheme,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Navigation/Auth State: 'phone' or 'otp'
  String _currentStep = 'phone';
  String _enteredPhone = '';
  
  // Mock constant OTP for validation demo
  static const String _mockOtp = '123456';

  void _handleSendOtp(String fullPhoneNumber) {
    setState(() {
      _enteredPhone = fullPhoneNumber;
      _currentStep = 'otp';
    });
    
    // Premium Snackbar notification indicating successful OTP dispatch
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'OTP sent successfully! Use mock code: $_mockOtp',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2E7D32), // Forest Green
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  void _handleVerifyOtp(String otpCode) {
    if (otpCode == _mockOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.verified_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Login Successful! Welcome to KutumbSetu.',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2E7D32), // Forest Green
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Invalid OTP code. Please try again.',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _handleResendOtp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP resent. Use mock code: $_mockOtp'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFE67E22), // Saffron
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleChangeMobile() {
    setState(() {
      _currentStep = 'phone';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = widget.isDarkMode;

    // Soft saffon-to-white / saffron-to-dark gradient background
    final bgGradient = LinearGradient(
      colors: isDark
          ? [
              const Color(0xFF5D2800), // Deep muted saffron brown
              const Color(0xFF121212), // Obsidian background
            ]
          : [
              const Color(0xFFFFF3E0), // Soft cream saffron
              const Color(0xFFFAFAFA), // Off-white
            ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - 32,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Theme Switcher & Utility Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: widget.onToggleTheme,
                          icon: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            color: isDark ? Colors.white : Colors.grey.shade700,
                          ),
                          tooltip: 'Toggle Theme',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Top Section - Logo & Tagline
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Icon(
                            Icons.diversity_3_rounded,
                            size: 64,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'KutumbSetu',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF333333),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'कुटुम्बसेतु',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.secondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Connecting Families, Traditions, and Communities.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Welcome Section & Card Container
                    Card(
                      elevation: isDark ? 0 : 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: isDark ? Colors.grey.shade800 : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Welcome to KutumbSetu',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Stay connected with your family, community updates, matrimonial profiles, and events.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Authentication Switcher (Phone Input vs OTP)
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _currentStep == 'phone'
                                  ? MobileInputForm(
                                      key: const ValueKey('phoneForm'),
                                      onSendOtp: _handleSendOtp,
                                    )
                                  : OtpVerificationForm(
                                      key: const ValueKey('otpForm'),
                                      phoneNumber: _enteredPhone,
                                      onChangeMobile: _handleChangeMobile,
                                      onVerify: _handleVerifyOtp,
                                      onResend: _handleResendOtp,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Verification Notice
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Only verified community members can access KutumbSetu.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Bottom Privacy Links & Version Number
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Privacy Policy page link')),
                                  );
                                },
                                child: Text(
                                  'Privacy Policy',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.tertiary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '|',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Terms & Conditions page link')),
                                  );
                                },
                                child: Text(
                                  'Terms & Conditions',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.tertiary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Version 1.0',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
