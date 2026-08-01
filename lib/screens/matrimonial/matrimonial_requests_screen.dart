import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/matrimonial_providers.dart';

class MatrimonialRequestsScreen extends ConsumerStatefulWidget {
  const MatrimonialRequestsScreen({super.key});

  @override
  ConsumerState<MatrimonialRequestsScreen> createState() => _MatrimonialRequestsScreenState();
}

class _MatrimonialRequestsScreenState extends ConsumerState<MatrimonialRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleResponse(String requestId, String status, String candidateName) async {
    final service = ref.read(matrimonialServiceProvider);
    final success = await service.respondToRequest(requestId, status);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request $status for $candidateName successfully!')),
      );
      ref.invalidate(matrimonialRequestsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(matrimonialRequestsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryOrange = const Color(0xFFE67E22);
    final primaryBlue = const Color(0xFF1B4F72);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: primaryOrange,
        title: Text(
          'Interest Requests',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Received Interests'),
            Tab(text: 'Sent Interests'),
          ],
        ),
      ),
      body: requestsAsync.when(
        data: (data) {
          final sent = data['sent'] ?? [];
          final received = data['received'] ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildReceivedTab(received, primaryBlue, primaryOrange, isDark),
              _buildSentTab(sent, primaryBlue, primaryOrange, isDark),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error loading requests: $err')),
      ),
    );
  }

  Widget _buildReceivedTab(List<dynamic> list, Color blue, Color orange, bool isDark) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.question_answer_outlined, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No incoming interests yet', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final req = list[index];
        final sender = req['senderId']; // User object
        if (sender == null) return const SizedBox();

        final requestId = req['_id'] as String? ?? '';
        final status = req['status'] as String? ?? 'Pending';
        final senderName = sender['fullName'] as String? ?? '';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      senderName,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    _buildStatusChip(status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'City: ${sender['city'] ?? ''} • Native: ${sender['nativePlace'] ?? ''}',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                if (status == 'Pending')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => _handleResponse(requestId, 'Rejected', senderName),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Decline'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => _handleResponse(requestId, 'Accepted', senderName),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blue,
                        ),
                        child: const Text('Accept Connection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Connection ${status.toLowerCase()}',
                      style: TextStyle(color: status == 'Accepted' ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSentTab(List<dynamic> list, Color blue, Color orange, bool isDark) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.outbox_outlined, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No sent requests yet', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final req = list[index];
        final receiver = req['receiverId'];
        if (receiver == null) return const SizedBox();

        final receiverName = receiver['fullName'] as String? ?? '';
        final status = req['status'] as String? ?? 'Pending';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            title: Text(
              receiverName,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('City: ${receiver['city'] ?? ''} • Contact details will unlock on approval.'),
              ],
            ),
            trailing: _buildStatusChip(status),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg = Colors.amber.shade100;
    Color fg = Colors.amber.shade900;
    if (status == 'Accepted') {
      bg = Colors.green.shade100;
      fg = Colors.green.shade900;
    } else if (status == 'Rejected') {
      bg = Colors.red.shade100;
      fg = Colors.red.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11, color: fg),
      ),
    );
  }
}
