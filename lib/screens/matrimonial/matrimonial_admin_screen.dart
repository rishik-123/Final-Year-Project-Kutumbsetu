import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class MatrimonialAdminScreen extends ConsumerStatefulWidget {
  const MatrimonialAdminScreen({super.key});

  @override
  ConsumerState<MatrimonialAdminScreen> createState() => _MatrimonialAdminScreenState();
}

class _MatrimonialAdminScreenState extends ConsumerState<MatrimonialAdminScreen> {
  final List<Map<String, String>> _pendingProfiles = [
    {
      'id': 'MP001',
      'name': 'Arjunbhai Patel',
      'age': '28',
      'gender': 'Male',
      'city': 'Vadodara',
      'education': 'M.Tech IT',
      'occupation': 'DevOps Engineer',
    },
    {
      'id': 'MP002',
      'name': 'Bhavnaben Shah',
      'age': '25',
      'gender': 'Female',
      'city': 'Ahmedabad',
      'education': 'MBA Finance',
      'occupation': 'Investment Analyst',
    },
  ];

  void _approveProfile(int index, String name) {
    setState(() {
      _pendingProfiles.removeAt(index);
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Approved'),
        content: Text('Matrimonial biodata for $name has been verified and successfully published to the community.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryOrange = const Color(0xFFE67E22);
    final primaryBlue = const Color(0xFF1B4F72);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: primaryOrange,
        title: Text(
          'Admin Verification Board',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _pendingProfiles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined, size: 70, color: Colors.green.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'All profiles are verified!',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey.shade600),
                  ),
                  Text(
                    'No pending matrimonial approvals found.',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingProfiles.length,
              itemBuilder: (context, index) {
                final item = _pendingProfiles[index];
                final name = item['name'] ?? '';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Pending Review',
                                style: TextStyle(color: Colors.orange.shade900, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Age: ${item['age']} • Gender: ${item['gender']} • City: ${item['city']}',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        Text(
                          'Edu: ${item['education']} • Occupation: ${item['occupation']}',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _pendingProfiles.removeAt(index);
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => _approveProfile(index, name),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                              ),
                              child: const Text('Approve & Publish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
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
