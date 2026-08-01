import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/matrimonial_providers.dart';

class SuccessStoriesScreen extends ConsumerWidget {
  const SuccessStoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(matrimonialStoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryOrange = const Color(0xFFE67E22);
    final primaryBlue = const Color(0xFF1B4F72);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: primaryOrange,
        title: Text(
          'Success Stories',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: storiesAsync.when(
        data: (stories) {
          if (stories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_stories_outlined, size: 70, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('No success stories posted yet', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              final mDate = DateTime.parse(story['marriageDate'].toString());
              final formattedDate = '${mDate.day}/${mDate.month}/${mDate.year}';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Couple Header / Ring icon
                    Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        gradient: LinearGradient(
                          colors: [primaryOrange.withValues(alpha: 0.8), primaryBlue.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.favorite_rounded, color: Colors.white, size: 48),
                            const SizedBox(height: 8),
                            Text(
                              story['coupleName'] ?? '',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Married on $formattedDate',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Description text
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.format_quote_rounded, color: Colors.grey, size: 28),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  story['description'] ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    fontStyle: FontStyle.italic,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '— KutumbSetu Couple',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11, color: primaryOrange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error loading stories: $err')),
      ),
    );
  }
}
