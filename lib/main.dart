import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const EcoQuestApp());
}

class EcoQuestApp extends StatelessWidget {
  const EcoQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eco Quest',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF2F8FB), // Soft beachy breeze blue-white
        primaryColor: Colors.cyan,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          primary: Colors.cyan.shade600,
          secondary: Colors.amber, // Sandy yellow accent
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Roboto', color: Color(0xFF2C3E50)),
          bodyMedium: TextStyle(fontFamily: 'Roboto', color: Color(0xFF34495E)),
          titleLarge: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFF1ABC9C)), // Ocean teal
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan, // Solid bright blue
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}