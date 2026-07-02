import 'package:flutter/material.dart';

/// 应用主题：清新薄荷绿 + 木色
/// 设计灵感来自尤克里里的木质手感和绿色琴弦
class AppTheme {
  AppTheme._();

  // 主色：清新薄荷绿（音乐 + 自然）
  static const Color primary = Color(0xFF4ECDC4);
  static const Color primaryDark = Color(0xFF2E8B85);
  static const Color primaryLight = Color(0xFFA8E6E0);

  // 强调色：温暖木色（琴身材质）
  static const Color accent = Color(0xFFD4A574);
  static const Color accentDark = Color(0xFF8B6F47);

  // 状态色
  static const Color success = Color(0xFF52C41A);
  static const Color warning = Color(0xFFFAAD14);
  static const Color error = Color(0xFFFF4D4F);

  // 中性色
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF666666);

  /// 浅色主题
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: accent,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}