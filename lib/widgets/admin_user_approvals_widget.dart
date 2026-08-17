import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';

class AdminUserApprovalsWidget extends StatefulWidget {
  const AdminUserApprovalsWidget({super.key});

  @override
  State<AdminUserApprovalsWidget> createState() => _AdminUserApprovalsWidgetState();
}

class _AdminUserApprovalsWidgetState extends State<AdminUserApprovalsWidget> {
  List<dynamic> _pendingUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPendingUsers();
  }

  Future<void> _fetchPendingUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/pending-users'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _pendingUsers = data['users'] ?? [];
          });
        }
      }
    } catch (e) {
      print('Error fetching pending users: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approveUser(String userId, String fullName) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/admin/approve-user/$userId'),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approved user: $fullName'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchPendingUsers(); // Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to approve user.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to approve user. Check backend.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Pending Registrations',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _fetchPendingUsers,
            icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white : Colors.black87),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE67E22)))
          : _pendingUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 64,
                        color: Colors.green.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'All caught up!',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No pending approval requests.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _pendingUsers.length,
                  itemBuilder: (context, index) {
                    final user = _pendingUsers[index];
                    final String userId = user['_id'] ?? '';
                    final String fullName = user['fullName'] ?? 'New Member';
                    final String email = user['email'] ?? '';
                    final String phone = user['phoneNumber'] ?? 'No Phone';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        ),
                      ),
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFE67E22).withValues(alpha: 0.1),
                              child: Text(
                                fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFE67E22),
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  if (email.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 2),
                                  Text(
                                    phone,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _approveUser(userId, fullName),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              child: Text(
                                'Approve',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
