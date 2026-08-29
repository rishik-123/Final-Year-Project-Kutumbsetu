import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../api_config.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  bool get isDarkMode => ref.watch(themeModeProvider) == ThemeMode.dark;

  // State Variables
  String _currentStep = 'email'; // 'email' or 'otp'
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _adminUsernameController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();

  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  String? _developmentOtp;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  void _showOtpDevelopmentDialog(String otp) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.developer_mode_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Development Mode',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Use the following OTP to log in:',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: Text(
                    otp,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Development OTP: $otp',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      _showErrorSnackBar('Please enter a valid email address.');
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/send-email-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _currentStep = 'otp';
          _isSendingOtp = false;
          _developmentOtp = null;
        });

        _showSuccessSnackBar('OTP code sent successfully! Please check your Gmail.');
      } else {
        setState(() {
          _isSendingOtp = false;
        });
        _showErrorSnackBar(data['message'] ?? 'Failed to send OTP.');
      }
    } catch (e) {
      setState(() {
        _isSendingOtp = false;
      });
      _showErrorSnackBar('Failed to connect to local server. Please check backend connection.');
    }
  }

  Future<void> _handleVerifyOtp() async {
    final enteredOtp = _otpController.text.trim();
    if (enteredOtp.length != 6) {
      _showErrorSnackBar('Please enter the 6-digit OTP code.');
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    final email = _emailController.text.trim();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/verify-email-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': enteredOtp,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (data['userExists'] == true) {
          // Registered user profile
          final userModel = await AuthService.fetchUserProfile(email);
          setState(() {
            _isVerifyingOtp = false;
          });
          if (userModel != null) {
            ref.read(currentUserProvider.notifier).state = userModel;
            _showSuccessSnackBar('Welcome to KutumbSetu!');
            context.go('/home');
          } else {
            _showErrorSnackBar('Failed to fetch user profile details.');
          }
        } else {
          // Email verified but not registered
          setState(() {
            _isVerifyingOtp = false;
          });
          _showSuccessSnackBar('Email verified. Please register your account.');
          context.push('/register');
        }
      } else {
        setState(() {
          _isVerifyingOtp = false;
        });
        _showErrorSnackBar(data['message'] ?? 'Invalid OTP code.');
      }
    } catch (e) {
      setState(() {
        _isVerifyingOtp = false;
      });
      _showErrorSnackBar('Verification failed: $e');
    }
  }

  Future<void> _handleAdminLogin() async {
    final username = _adminUsernameController.text.trim();
    final password = _adminPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Please enter both username and password.');
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/admin-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final userModel = UserModel.fromJson(data['user']);
        setState(() {
          _isVerifyingOtp = false;
        });
        ref.read(currentUserProvider.notifier).state = userModel;
        _showSuccessSnackBar('Welcome, Admin!');
        context.go('/admin');
      } else {
        setState(() {
          _isVerifyingOtp = false;
        });
        _showErrorSnackBar(data['message'] ?? 'Invalid admin credentials.');
      }
    } catch (e) {
      setState(() {
        _isVerifyingOtp = false;
      });
      _showErrorSnackBar('Connection failed. Please check backend.');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = isDarkMode;

    final bgGradient = LinearGradient(
      colors: isDark
          ? [
              const Color(0xFF5D2800),
              const Color(0xFF121212),
            ]
          : [
              const Color(0xFFFFF3E0),
              const Color(0xFFFAFAFA),
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
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  // Theme switch
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () {
                        ref.read(themeModeProvider.notifier).toggleTheme();
                      },
                      icon: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: isDark ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),

                  // Header branding
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.diversity_3_rounded,
                          size: 64,
                          color: Color(0xFFE67E22),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'KutumbSetu',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF333333),
                        ),
                      ),
                      Text(
                        'कुटुम्बसेतु',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFE67E22),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Login Form Card
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Sign In',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Authenticate using Email OTP code verification.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_currentStep == 'email') ...[
                              // Email Address Input
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email address is required';
                                  }
                                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _isSendingOtp ? null : _handleSendOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE67E22),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isSendingOtp
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text('Send OTP Code', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _currentStep = 'admin';
                                  });
                                },
                                icon: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFE67E22)),
                                label: const Text('Login as Admin', style: TextStyle(color: Color(0xFFE67E22), fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: const BorderSide(color: Color(0xFFE67E22)),
                                ),
                              ),
                            ] else if (_currentStep == 'otp') ...[
                              // OTP Input
                              TextFormField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                decoration: InputDecoration(
                                  labelText: 'Enter 6-Digit Email OTP',
                                  prefixIcon: const Icon(Icons.lock_clock_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: _isSendingOtp ? null : _handleSendOtp,
                                    child: const Text('Resend OTP', style: TextStyle(color: Color(0xFFE67E22))),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _currentStep = 'email';
                                      });
                                    },
                                    child: const Text('Change Email', style: TextStyle(color: Colors.grey)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _isVerifyingOtp ? null : _handleVerifyOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B4F72),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isVerifyingOtp
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text('Verify & Log In', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                              ),
                            ] else if (_currentStep == 'admin') ...[
                              // Admin input
                              TextFormField(
                                controller: _adminUsernameController,
                                decoration: InputDecoration(
                                  labelText: 'Admin Username',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _adminPasswordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Admin Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _currentStep = 'email';
                                      });
                                    },
                                    child: const Text('Back to Email Login', style: TextStyle(color: Colors.grey)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _isVerifyingOtp ? null : _handleAdminLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B4F72),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isVerifyingOtp
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text('Verify Admin & Log In', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Register prompt
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: RichText(
                      text: TextSpan(
                        text: "New to KutumbSetu? ",
                        style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black87),
                        children: const [
                          TextSpan(
                            text: 'Register Here',
                            style: TextStyle(color: Color(0xFFE67E22), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
