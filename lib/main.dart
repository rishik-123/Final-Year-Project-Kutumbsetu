import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: KutumbSetuApp(),
    ),
  );
}

class KutumbSetuApp extends ConsumerWidget {
  const KutumbSetuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'KutumbSetu Member Directory',
      debugShowCheckedModeBanner: false,
      theme: KutumbSetuTheme.lightTheme,
      darkTheme: KutumbSetuTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
