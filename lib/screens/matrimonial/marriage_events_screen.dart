import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/matrimonial_providers.dart';

class MarriageEventsScreen extends ConsumerStatefulWidget {
  const MarriageEventsScreen({super.key});

  @override
  ConsumerState<MarriageEventsScreen> createState() => _MarriageEventsScreenState();
}

class _MarriageEventsScreenState extends ConsumerState<MarriageEventsScreen> {
  String _selectedFilter = 'All'; // 'All', 'Current', 'Past'

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(matrimonialEventsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryOrange = const Color(0xFFE67E22);
    final primaryBlue = const Color(0xFF1B4F72);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: primaryOrange,
        title: Text(
          'Marriage Events & Meetups',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterChip('All', Icons.all_inclusive_rounded),
                _buildFilterChip('Current', Icons.event_available_rounded),
                _buildFilterChip('Past', Icons.history_rounded),
              ],
            ),
          ),
          const Divider(height: 1),

          // Events List Content
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                // Filter events in real-time
                final now = DateTime.now();
                final todayStart = DateTime(now.year, now.month, now.day);

                final filteredEvents = events.where((ev) {
                  final date = DateTime.parse(ev['date'].toString());
                  if (_selectedFilter == 'Current') {
                    // Current / Upcoming events: starting today or in the future
                    return date.isAfter(todayStart) || date.year == todayStart.year && date.month == todayStart.month && date.day == todayStart.day;
                  } else if (_selectedFilter == 'Past') {
                    // Past events: strictly before today
                    return date.isBefore(todayStart);
                  }
                  return true; // 'All'
                }).toList();

                if (filteredEvents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 70, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No events found for this filter',
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final ev = filteredEvents[index];
                    final date = DateTime.parse(ev['date'].toString());
                    final formattedDate = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                    final isPast = date.isBefore(todayStart);

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPast
                                        ? Colors.grey.shade200
                                        : primaryOrange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isPast ? 'PAST EVENT' : 'UPCOMING',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      color: isPast ? Colors.grey.shade700 : primaryOrange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              ev['title'] ?? '',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.calendar_month, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 6),
                                Text(formattedDate, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    ev['location'] ?? '',
                                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              ev['description'] ?? '',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            if (!isPast)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.check, color: Colors.white, size: 16),
                                    label: const Text('RSVP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Thank you! Your RSVP has been registered.')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFD35400))),
              error: (err, st) => Center(child: Text('Error loading events: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    final saffronColor = const Color(0xFFE67E22);

    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade600),
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedFilter = label;
          });
        }
      },
      selectedColor: saffronColor,
      disabledColor: Colors.grey.shade200,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.grey.shade100,
      labelStyle: GoogleFonts.poppins(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
