import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart';
import 'routes/app_router.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    print('Firebase initialization skipped or failed: $e');
  }
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
      title: 'KutumbSetu',
      debugShowCheckedModeBanner: false,
      theme: KutumbSetuTheme.lightTheme,
      darkTheme: KutumbSetuTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
