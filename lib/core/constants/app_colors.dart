import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Mountain & Slate Theme (Dark Mode Dominant)
  static const Color background = Color(0xFF0B0F19);
  static const Color surface = Color(0xFF131B2E);
  static const Color surfaceElevated = Color(0xFF1E293B);
  
  static const Color primary = Color(0xFF0EA5E9); // Karakoram Sky Blue
  static const Color primaryDark = Color(0xFF0284C7);
  static const Color accent = Color(0xFFF472B6); // Glacier Rose
  
  // Status Colors (Gilgit-Baltistan Road Hazards)
  static const Color statusOpen = Color(0xFF10B981);      // Emerald Safe
  static const Color statusCaution = Color(0xFFF59E0B);   // Warn Amber (One-way / Under construction)
  static const Color statusDanger = Color(0xFFEF4444);    // Hazard Crimson (Blocked / Landslide)
  static const Color statusUnknown = Color(0xFF94A3B8);   // Grey (No reports yet)

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Borders & Accents
  static const Color border = Color(0xFF1E293B);
  static const Color borderBright = Color(0xFF334155);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF020617)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient hazardGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1FFFFFFF),
      Color(0x0AFFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
