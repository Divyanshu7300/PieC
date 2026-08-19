import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0B0D17);
  static const Color surface = Color(0xFF141726);
  static const Color surfaceLight = Color(0xFF1E2238);
  static const Color surfaceHover = Color(0xFF282E4B);

  // Neon & Brand Accents
  static const Color primaryNeon = Color(0xFF00F0FF); // Cyber Cyan
  static const Color primaryPurple = Color(0xFF8B5CF6); // Electric Purple
  static const Color accentPink = Color(0xFFFF2A85); // Neon Pink
  static const Color accentGreen = Color(0xFF00FF9D); // Matrix Green
  static const Color accentYellow = Color(0xFFFFD600); // Glow Yellow
  static const Color accentOrange = Color(0xFFFF6B00); // Flare Orange

  // Chat Bubble Colors
  static const Color myMessageBg = Color(0xFF6366F1);
  static const Color otherMessageBg = Color(0xFF1E2337);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Status & Utility
  static const Color online = Color(0xFF00FF9D);
  static const Color offline = Color(0xFF64748B);
  static const Color homeTag = Color(0xFFFF6B00);
  static const Color officeTag = Color(0xFF00F0FF);
  static const Color hangoutTag = Color(0xFFFF2A85);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF00F0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkPurpleGradient = LinearGradient(
    colors: [Color(0xFFFF2A85), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E2238), Color(0xFF121422)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
