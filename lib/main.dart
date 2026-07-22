import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/login_screen.dart';

void main()async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const KutumbSetuApp());
}

class KutumbSetuApp extends StatefulWidget {
  const KutumbSetuApp({super.key});

  @override
  State<KutumbSetuApp> createState() => _KutumbSetuAppState();
}

class _KutumbSetuAppState extends State<KutumbSetuApp> {
  // Application-wide Theme State (Default to Light)
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KutumbSetu',
      debugShowCheckedModeBanner: false,
      theme: KutumbSetuTheme.lightTheme,
      darkTheme: KutumbSetuTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: LoginScreen(
        isDarkMode: _isDarkMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}
