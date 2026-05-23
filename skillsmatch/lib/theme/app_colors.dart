// lib/theme/app_colors.dart

import 'package:flutter/material.dart';

// Akcentne boje — ostaju iste u oba moda
const kPrimary      = Color(0xFF4F46E5);
const kPrimaryDark  = Color(0xFF312E81);
const kPrimaryLight = Color(0xFF818CF8);
const kViolet       = Color(0xFF7C3AED);
const kAmber        = Color(0xFFD97706);
const kGreen        = Color(0xFF059669);
const kRed          = Color(0xFFEF4444);

// Dinamičke boje — mijenjaju se po modu
extension AppColors on BuildContext {
  bool get _dark => Theme.of(this).brightness == Brightness.dark;
  bool get isDark => _dark;

  Color get kBg       => _dark ? const Color(0xFF0F0E1A) : const Color(0xFFF0F0FF);
  Color get kSurface  => _dark ? const Color(0xFF252438) : const Color(0xFFF5F5FF);
  Color get kCardBg   => _dark ? const Color(0xFF1C1B2E) : Colors.white;
  Color get kBorder   => _dark ? const Color(0xFF2E2D45) : const Color(0xFFE2E8F0);
  Color get kText     => _dark ? const Color(0xFFE8E7FF) : const Color(0xFF1E1B4B);
  Color get kTextSub  => _dark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
}