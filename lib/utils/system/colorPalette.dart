import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:eschool_saas_staff/utils/system/hiveBoxKeys.dart';

class AppColorPalette {
  static String get currentTheme {
    try {
      final box = Hive.box(settingsBoxKey);
      return box.get(appThemeModeKey, defaultValue: 'light') as String;
    } catch (_) {
      return 'light';
    }
  }

  // Reactive version for theme construction
  static Color getPrimaryColor(String theme) {
    if (theme == 'violet') {
      return const Color(0xFF6D28D9); // Violet
    } else if (theme == 'dark') {
      return const Color(0xFF1E1E1E); // Dark Mode primary
    } else if (theme == 'indonesia') {
      return const Color(0xFFD32F2F); // Merah Indonesia
    } else {
      return const Color(0xFF8B1F41); // Light Mode primary maroon
    }
  }

  static Color getSecondaryColor(String theme) {
    if (theme == 'violet') {
      return const Color(0xFF8B5CF6); // Violet light
    } else if (theme == 'dark') {
      return const Color(0xFF333333); // Dark Mode secondary
    } else if (theme == 'indonesia') {
      return const Color(0xFFE53935); // Lighter Red Indonesia for visibility
    } else {
      return const Color(0xFFA84B5C); // Light Mode secondary maroon
    }
  }

  static Color getLightColor(String theme) {
    if (theme == 'violet') {
      return const Color(0xFFEDE9FE); // Very light violet
    } else if (theme == 'dark') {
      return const Color(0xFF2C2C2C); // Dark light
    } else if (theme == 'indonesia') {
      return const Color(0xFFFFEBEE); // Soft red background accent
    } else {
      return const Color(0xFFE7C8CD); // Light Maroon
    }
  }

  static Color getAccentColor(String theme) {
    if (theme == 'violet') {
      return const Color(0xFFF3E8FF); // Accent violet/purple
    } else if (theme == 'dark') {
      return const Color(0xFF1A1A1A); // Accent dark
    } else if (theme == 'indonesia') {
      return const Color(0xFFFFCDD2); // Light red accent
    } else {
      return const Color(0xFFF4D0D9); // Accent Pink
    }
  }

  static Color getWarmBeigeColor(String theme) {
    if (theme == 'violet') {
      return const Color(0xFFF5F3FF); // Warm beige for violet
    } else if (theme == 'dark') {
      return const Color(0xFF121212); // Dark warm beige
    } else if (theme == 'indonesia') {
      return const Color(0xFFFFFDFD); // Soft off-white red
    } else {
      return const Color(0xFFF5E6E8); // Warm Beige
    }
  }

  static Color getShadowColor(String theme) {
    if (theme == 'violet') {
      return const Color(0x296D28D9); // Violet shadow
    } else if (theme == 'dark') {
      return const Color(0x29000000); // Dark shadow
    } else if (theme == 'indonesia') {
      return const Color(0x29D32F2F); // Indonesia red shadow
    } else {
      return const Color(0x298B1F41); // Light maroon shadow
    }
  }

  // Legacy static getters for backward compatibility
  static Color get primaryMaroon => getPrimaryColor(currentTheme);
  static Color get secondaryMaroon => getSecondaryColor(currentTheme);
  static Color get lightMaroon => getLightColor(currentTheme);
  static Color get accentPink => getAccentColor(currentTheme);
  static Color get warmBeige => getWarmBeigeColor(currentTheme);
  static Color get shadowColor => getShadowColor(currentTheme);
}
