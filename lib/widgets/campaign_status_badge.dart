import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CampaignStatusBadge extends StatelessWidget {
  final String status;
  final bool isCompact;

  const CampaignStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(status);
    final normalizedStatus = _normalizeStatus(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 6 : 8,
            height: isCompact ? 6 : 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isCompact ? 4 : 6),
          Text(
            normalizedStatus,
            style: GoogleFonts.inter(
              color: statusColor,
              fontSize: isCompact ? 11 : 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  String _normalizeStatus(String raw) {
    if (raw.isEmpty) return 'Active';
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  Color _getStatusColor(String s) {
    switch (s.toLowerCase()) {
      case 'active':
        return const Color(0xFF10B981); // Emerald Green
      case 'upcoming':
        return const Color(0xFF3B82F6); // Vibrant Blue
      case 'completed':
        return const Color(0xFF8B5CF6); // Purple
      case 'draft':
        return const Color(0xFF6B7280); // Slate Grey
      case 'cancelled':
      case 'canceled':
        return const Color(0xFFEF4444); // Crimson Red
      default:
        return const Color(0xFF10B981);
    }
  }
}
