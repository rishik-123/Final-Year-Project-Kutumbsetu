/// ============================================================================
/// KutumbSetu - Application Theme Mode Riverpod Provider
/// ============================================================================
/// Controls dynamic light/dark UI theme switching across the KutumbSetu application.
/// Provides immediate reactive rebuilding of MaterialApp themes and user preference toggling.
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global [StateNotifierProvider] exposing the active [ThemeMode] across the entire widget hierarchy.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// State notifier managing the active display theme mode (Light or Dark).
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light);

  /// Toggles between [ThemeMode.light] and [ThemeMode.dark].
  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  /// Sets an explicit theme mode (e.g. system default, light, or dark).
  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

