import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../community/community_feed.dart';

class ReelDetailScreen extends ConsumerStatefulWidget {
  final String reelId;

  const ReelDetailScreen({super.key, required this.reelId});

  @override
  ConsumerState<ReelDetailScreen> createState() => _ReelDetailScreenState();
}

class _ReelDetailScreenState extends ConsumerState<ReelDetailScreen> {
  dynamic _reel;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReel();
  }

  Future<void> _fetchReel() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/community/reels/${widget.reelId}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _reel = data['reel'];
              _isLoading = false;
            });
          }
          return;
        }
      }
      if (mounted) {
        setState(() {
          _error = 'Failed to load reel. It may have been deleted.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error connecting to server: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Community Reel'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 54),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchReel,
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          label: const Text('Retry', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFe67e22),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : InstagramStyleReel(
                  reel: _reel,
                  onRefresh: _fetchReel,
                ),
    );
  }
}
