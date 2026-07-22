import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const RegisterScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Form Field Controllers & Scroll Controller
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _nativePlaceController = TextEditingController();
  final TextEditingController _currentCityController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // Selected State variables
  String _selectedGender = 'Male';
  DateTime? _selectedDob;
  String _selectedMaritalStatus = 'Single';
  String _selectedState = 'Maharashtra';
  String _selectedAvatar = 'avatar_male_1';
  bool _acceptedTerms = false;

  // OTP & Firebase Auth State
  bool _isOtpSent = false;
  bool _isSendingOtp = false;
  bool _isOtpVerified = false;
  bool _isSubmitting = false;
  String? _verificationId;
  int? _resendToken;
  String? _developmentOtp;


  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _maritalStatuses = ['Single', 'Married', 'Widowed', 'Divorced'];
  final List<String> _indianStates = [
    'Andhra Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Delhi',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Tamil Nadu',
    'Telangana',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    _fullNameController.dispose();
    _surnameController.dispose();
    _fatherNameController.dispose();
    _mobileController.dispose();
    _nativePlaceController.dispose();
    _currentCityController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // Date Picker Handler
  Future<void> _selectDateOfBirth() async {
    final DateTime initialDate = _selectedDob ?? DateTime(2000, 1, 1);
    final DateTime firstDate = DateTime(1920);
    final DateTime lastDate = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: widget.isDarkMode
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFFE67E22),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFFE67E22),
                    onPrimary: Colors.white,
                  ),
                ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  // Avatar Picker Dialog
  void _openAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Profile Photo / Avatar',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _avatarChoice('avatar_male_1', Icons.face_rounded, Colors.blue),
                  _avatarChoice('avatar_female_1', Icons.face_3_rounded, Colors.pink),
                  _avatarChoice('avatar_male_2', Icons.face_4_rounded, Colors.teal),
                  _avatarChoice('avatar_generic', Icons.account_circle_rounded, Colors.orange),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Custom gallery photo selected for profile.')),
                  );
                },
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Upload from Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _avatarChoice(String id, IconData icon, Color color) {
    final isSelected = _selectedAvatar == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAvatar = id;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade400,
            width: isSelected ? 3 : 1.5,
          ),
        ),
        child: Icon(icon, size: 40, color: color),
      ),
    );
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
                'Use the following OTP to register:',
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

  // OTP Sending Handler
  void _sendOtp() async {
    final mobileNumber = _mobileController.text.trim();
    if (mobileNumber.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(mobileNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid 10-digit mobile number first.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final fullPhoneNumber = '+91$mobileNumber';

    setState(() {
      _isSendingOtp = true;
      _isOtpVerified = false;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': fullPhoneNumber}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final otp = data['otp'];
        if (mounted) {
          setState(() {
            _isOtpSent = true;
            _isSendingOtp = false;
            _developmentOtp = otp;
          });

          // TODO: Replace with Firebase/Fast2SMS in production.
          _showOtpDevelopmentDialog(otp);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.mark_email_read_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'OTP sent to +91 $mobileNumber. Enter code below.',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 6),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isSendingOtp = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to send OTP. Please check your number.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to connect to local server. Please check backend connection.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // Submit & Registration Action
  void _handleRegistration() async {
    // 1. Validate Form
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please complete all required fields correctly.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // 2. Validate DOB
    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your Date of Birth.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // 3. Validate & Verify OTP
    final enteredOtp = _otpController.text.trim();
    if (enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter the full 6-digit OTP code received on your phone.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final mobileNumber = _mobileController.text.trim();
    final fullPhoneNumber = '+91$mobileNumber';

    setState(() {
      _isSubmitting = true;
    });

    if (!_isOtpVerified) {
      if (!_isOtpSent) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please tap "Send OTP" to receive a verification code first.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/verify-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone': fullPhoneNumber,
            'otp': enteredOtp,
          }),
        );

        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          setState(() {
            _isOtpVerified = true;
          });
        } else {
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Invalid OTP code. Please try again.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          return;
        }
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP verification failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }
    }

    // 4. Validate Terms & Conditions
    if (!_acceptedTerms) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept the Terms & Conditions to register.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // 5. Submit User Details to MongoDB backend
    try {
      final dobStr = "${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}";
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': _fullNameController.text.trim(),
          'surname': _surnameController.text.trim(),
          'fatherName': _fatherNameController.text.trim(),
          'phoneNumber': fullPhoneNumber,
          'gender': _selectedGender,
          'dateOfBirth': dobStr,
          'nativePlace': _nativePlaceController.text.trim(),
          'address': _nativePlaceController.text.trim(),
          'city': _currentCityController.text.trim(),
          'state': _selectedState,
          'maritalStatus': _selectedMaritalStatus,
          'occupation': '',
          'profilePhoto': _selectedAvatar,
        }),
      );

      final data = jsonDecode(response.body);

      setState(() {
        _isSubmitting = false;
      });

      if (response.statusCode == 201 && data['success'] == true) {
        // Show Success Dialog & Redirect to Login Page
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            final isDark = widget.isDarkMode;
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF2E7D32),
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Registered Successfully!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Welcome ${_fullNameController.text.trim()} to KutumbSetu family network.\nYour account registration is completed.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // Dismiss dialog
                      Navigator.of(context).pop(); // Redirect back to Login Screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE67E22),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Proceed to Login',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Registration failed. Please try again.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration connection failed: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.isDarkMode;

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
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleRegistration,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Register Yourself',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                    ],
                  ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              final bottomPadding = 140.0 + MediaQuery.of(context).viewInsets.bottom;

              return ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                  },
                ),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(20.0, 16.0, 20.0, bottomPadding),
                    child: Form(
                      key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App Bar Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                  )
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: isDark ? Colors.white : Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Text(
                            'Member Registration',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF333333),
                            ),
                          ),
                          IconButton(
                            onPressed: widget.onToggleTheme,
                            icon: Icon(
                              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              color: isDark ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Header Banner & Profile Photo Picker
                      Card(
                        elevation: isDark ? 0 : 2,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _openAvatarPicker,
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 46,
                                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                                      child: Icon(
                                        _selectedAvatar == 'avatar_female_1'
                                            ? Icons.face_3_rounded
                                            : _selectedAvatar == 'avatar_male_2'
                                                ? Icons.face_4_rounded
                                                : Icons.face_rounded,
                                        size: 56,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.secondary,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tap to Add / Change Profile Photo',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section 1: Personal Information Card
                      _buildSectionCard(
                        title: 'Personal Details',
                        icon: Icons.person_rounded,
                        isDark: isDark,
                        children: [
                          if (isWide) ...[
                            // 2-Column layout on wide screens
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _fullNameController,
                                    label: 'Full Name',
                                    hint: 'e.g. Rahul Sharma',
                                    icon: Icons.badge_rounded,
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Full Name is required' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _surnameController,
                                    label: 'Surname / Family Name',
                                    hint: 'e.g. Sharma / Kulkarni',
                                    icon: Icons.groups_rounded,
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Surname is required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildDobField(isDark, theme),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _fatherNameController,
                                    label: "Father's Name",
                                    hint: 'e.g. Suresh Sharma',
                                    icon: Icons.person_outline_rounded,
                                    validator: (val) => val == null || val.trim().isEmpty ? "Father's Name is required" : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildGenderField(isDark, theme),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildMaritalStatusField(isDark),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Stacked responsive layout on mobile (Date of Birth placed high up right after Full Name & Surname!)
                            _buildTextField(
                              controller: _fullNameController,
                              label: 'Full Name',
                              hint: 'e.g. Rahul Sharma',
                              icon: Icons.badge_rounded,
                              validator: (val) => val == null || val.trim().isEmpty ? 'Full Name is required' : null,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _surnameController,
                              label: 'Surname / Family Name',
                              hint: 'e.g. Sharma / Kulkarni',
                              icon: Icons.groups_rounded,
                              validator: (val) => val == null || val.trim().isEmpty ? 'Surname is required' : null,
                            ),
                            const SizedBox(height: 16),

                            // Date of Birth prominently near top
                            _buildDobField(isDark, theme),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _fatherNameController,
                              label: "Father's Name",
                              hint: 'e.g. Suresh Sharma',
                              icon: Icons.person_outline_rounded,
                              validator: (val) => val == null || val.trim().isEmpty ? "Father's Name is required" : null,
                            ),
                            const SizedBox(height: 16),

                            _buildGenderField(isDark, theme),
                            const SizedBox(height: 16),

                            _buildMaritalStatusField(isDark),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Section 2: Residence & Location
                      _buildSectionCard(
                        title: 'Native & Residence Details',
                        icon: Icons.location_on_rounded,
                        isDark: isDark,
                        children: [
                          if (isWide) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _nativePlaceController,
                                    label: 'Native Place / Village',
                                    hint: 'e.g. Satara / Anand',
                                    icon: Icons.home_rounded,
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Native place is required' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _currentCityController,
                                    label: 'Current City',
                                    hint: 'e.g. Mumbai / Pune',
                                    icon: Icons.location_city_rounded,
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Current city is required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildStateField(isDark),
                          ] else ...[
                            _buildTextField(
                              controller: _nativePlaceController,
                              label: 'Native Place / Village',
                              hint: 'e.g. Satara / Anand',
                              icon: Icons.home_rounded,
                              validator: (val) => val == null || val.trim().isEmpty ? 'Native place is required' : null,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _currentCityController,
                              label: 'Current City',
                              hint: 'e.g. Mumbai / Pune',
                              icon: Icons.location_city_rounded,
                              validator: (val) => val == null || val.trim().isEmpty ? 'Current city is required' : null,
                            ),
                            const SizedBox(height: 16),

                            _buildStateField(isDark),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Section 3: Contact & OTP Verification
                      _buildSectionCard(
                        title: 'Mobile & OTP Verification',
                        icon: Icons.phonelink_ring_rounded,
                        isDark: isDark,
                        children: [
                          // Mobile Number with inline Send OTP button
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _mobileController,
                                  label: 'Mobile Number',
                                  hint: '10-digit number',
                                  icon: Icons.phone_android_rounded,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  validator: (val) {
                                    if (val == null || val.trim().length != 10) {
                                      return 'Enter 10 digits';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Padding(
                                padding: const EdgeInsets.only(top: 26.0),
                                child: ElevatedButton(
                                  onPressed: _isSendingOtp ? null : _sendOtp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.secondary,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isSendingOtp
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text(
                                          _isOtpSent ? 'Resend' : 'Send OTP',
                                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ],
                          ),

                          // Dynamic Firebase SMS OTP Status Banner
                          Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isOtpVerified
                                  ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                                  : theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isOtpVerified
                                    ? const Color(0xFF2E7D32).withValues(alpha: 0.5)
                                    : theme.colorScheme.primary.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isOtpVerified
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.info_outline_rounded,
                                  color: _isOtpVerified ? const Color(0xFF2E7D32) : theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _isOtpVerified
                                        ? 'Mobile number verified successfully!'
                                        : _isOtpSent
                                            ? 'Development OTP: $_developmentOtp. Enter the 6-digit code below.'
                                            : 'Enter your 10-digit mobile number and tap "Send OTP" to receive an SMS code.',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _isOtpVerified ? const Color(0xFF2E7D32) : theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // OTP Input Field
                          _buildTextField(
                            controller: _otpController,
                            label: 'Enter 6-Digit OTP',
                            hint: 'Enter SMS OTP code',
                            icon: Icons.lock_clock_rounded,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'OTP code is required';
                              }
                              if (val.trim().length != 6) {
                                return 'Enter full 6-digit OTP code';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Terms & Conditions Checkbox
                      Card(
                        elevation: isDark ? 0 : 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: CheckboxListTile(
                            value: _acceptedTerms,
                            onChanged: (val) {
                              setState(() {
                                _acceptedTerms = val ?? false;
                              });
                            },
                            activeColor: theme.colorScheme.primary,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text.rich(
                              TextSpan(
                                text: 'I accept all ',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Terms & Conditions',
                                    style: TextStyle(
                                      color: theme.colorScheme.tertiary,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const TextSpan(text: ' and Privacy Policy of KutumbSetu.'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  ),
);
  }

  // Section Container Helper
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  // Reusable TextField Helper
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final isDark = widget.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            counterText: '',
          ),
        ),
      ],
    );
  }

  // Helper widget for Date of Birth picker field
  Widget _buildDobField(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDateOfBirth,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDob == null
                        ? 'Select Date of Birth'
                        : '${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: _selectedDob == null
                          ? Colors.grey
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper widget for Gender choice selector
  Widget _buildGenderField(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _genders.map((gender) {
            final isSelected = _selectedGender == gender;
            return ChoiceChip(
              label: Text(gender),
              selected: isSelected,
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedGender = gender;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // Helper widget for Marital Status dropdown
  Widget _buildMaritalStatusField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Marital Status',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedMaritalStatus,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.favorite_rounded),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: _maritalStatuses.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedMaritalStatus = val;
              });
            }
          },
        ),
      ],
    );
  }

  // Helper widget for State dropdown
  Widget _buildStateField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'State',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedState,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.map_rounded),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: _indianStates.map((state) {
            return DropdownMenuItem(
              value: state,
              child: Text(state),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedState = val;
              });
            }
          },
        ),
      ],
    );
  }
}
