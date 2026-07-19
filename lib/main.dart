import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const KutumbSetuApp());
}

class KutumbSetuApp extends StatefulWidget {
  const KutumbSetuApp({Key? key}) : super(key: key);

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
