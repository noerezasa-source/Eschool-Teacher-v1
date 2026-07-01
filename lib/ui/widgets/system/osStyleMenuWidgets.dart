import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warna icon yang menyesuaikan intensitas tema primary
/// Setiap section punya "hue" sendiri, tapi saturation & brightness
/// diselaraskan dengan primary theme color secara otomatis.
class OsMenuIconColors {
  // Hue per kategori — icon warna berbeda tapi tetap selaras dengan tema
  static const double hueSchedule      = 210.0; // Biru
  static const double hueAttendance    = 150.0; // Hijau
  static const double hueSubject       = 270.0; // Ungu
  static const double hueAssignment    = 35.0;  // Oranye
  static const double hueAnnouncement  = 0.0;   // Merah
  static const double hueExamOffline   = 20.0;  // Coklat
  static const double hueExamOnline    = 185.0; // Cyan
  static const double hueExtra         = 320.0; // Pink
  static const double hueFinance       = 160.0; // Hijau tua
  static const double hueLeave         = 45.0;  // Kuning/amber
  static const double huePersonal      = 340.0; // Pink maroon (primary-ish)
  static const double hueInfo          = 200.0; // Biru abu
  static const double hueSchool        = 230.0; // Biru tua
  static const double hueClass         = 260.0; // Indigo
  static const double hueQuestion      = 170.0; // Teal
  static const double huePayroll       = 140.0; // Lime hijau
  static const double hueMonitor       = 60.0;  // Kuning

  /// Hasilkan warna icon yang harmonis dengan primary theme color.
  /// [baseHue]: hue sudut warna kategori (0-360)
  /// [primaryColor]: warna utama tema aktif
  static Color fromHue(double baseHue, Color primaryColor, {String? themeMode}) {
    // Tentukan mode tema aktif secara eksplisit atau inferensi
    final String mode = themeMode ?? _inferThemeMode(primaryColor);

    if (mode == 'indonesia') {
      // Palette Indonesia: Merah - Putih - Garuda Emas/Amber
      double targetHue;
      double saturation = 0.75;
      double lightness = 0.45;

      if (baseHue == hueSchedule || baseHue == hueClass || baseHue == hueSchool) {
        // Deep Crimson
        targetHue = 354.0;
        saturation = 0.70;
        lightness = 0.42;
      } else if (baseHue == hueAttendance || baseHue == hueFinance || baseHue == huePayroll) {
        // Bright Indonesian Red
        targetHue = 0.0;
        saturation = 0.85;
        lightness = 0.46;
      } else if (baseHue == hueSubject || baseHue == hueQuestion || baseHue == hueAssignment) {
        // Garuda Gold / Amber
        targetHue = 42.0;
        saturation = 0.90;
        lightness = 0.46;
      } else if (baseHue == hueAnnouncement || baseHue == hueExtra) {
        // Terracotta / Orange-Red
        targetHue = 12.0;
        saturation = 0.85;
        lightness = 0.45;
      } else if (baseHue == hueExamOffline || baseHue == hueExamOnline || baseHue == hueMonitor) {
        // Deep Mahogany
        targetHue = 342.0;
        saturation = 0.65;
        lightness = 0.38;
      } else {
        // Crimson Red
        targetHue = 360.0;
        saturation = 0.75;
        lightness = 0.45;
      }

      return HSLColor.fromAHSL(1.0, targetHue, saturation, lightness).toColor();
    } else if (mode == 'violet') {
      // Palette Violet: Shades of violet, purple, indigo, lavender, plum
      double targetHue;
      double saturation = 0.68;
      double lightness = 0.50;

      if (baseHue == hueSchedule || baseHue == hueClass || baseHue == hueSchool) {
        // Deep Royal Purple
        targetHue = 270.0;
        saturation = 0.65;
        lightness = 0.44;
      } else if (baseHue == hueAttendance || baseHue == hueFinance || baseHue == huePayroll) {
        // Indigo Blue-Purple
        targetHue = 248.0;
        saturation = 0.70;
        lightness = 0.48;
      } else if (baseHue == hueSubject || baseHue == hueQuestion || baseHue == hueAssignment) {
        // Bright Violet
        targetHue = 262.0;
        saturation = 0.75;
        lightness = 0.52;
      } else if (baseHue == hueAnnouncement || baseHue == hueExtra) {
        // Magenta / Orchid
        targetHue = 295.0;
        saturation = 0.65;
        lightness = 0.48;
      } else if (baseHue == hueExamOffline || baseHue == hueExamOnline || baseHue == hueMonitor) {
        // Deep Plum / Dark Violet
        targetHue = 282.0;
        saturation = 0.60;
        lightness = 0.40;
      } else {
        targetHue = 263.0;
        saturation = 0.68;
        lightness = 0.50;
      }

      return HSLColor.fromAHSL(1.0, targetHue, saturation, lightness).toColor();
    } else if (mode == 'dark') {
      // Sleek vibrant neon/pastel palette for Dark Mode to pop on obsidian background
      double targetHue = baseHue;
      double saturation = 0.72;
      double lightness = 0.58;

      if (baseHue == hueSchedule || baseHue == hueClass || baseHue == hueSchool) {
        targetHue = 210.0; // Cool Neon Blue
      } else if (baseHue == hueAttendance || baseHue == hueFinance || baseHue == huePayroll) {
        targetHue = 145.0; // Soft Neon Emerald Green
      } else if (baseHue == hueSubject || baseHue == hueQuestion) {
        targetHue = 270.0; // Pastel Purple
      } else if (baseHue == hueAssignment || baseHue == hueMonitor) {
        targetHue = 38.0;  // Neon Amber/Gold
      } else if (baseHue == hueAnnouncement) {
        targetHue = 355.0; // Neon Rose/Red
      } else if (baseHue == hueExamOffline || baseHue == hueExamOnline) {
        targetHue = 185.0; // Neon Teal/Cyan
      } else if (baseHue == hueExtra) {
        targetHue = 320.0; // Hot Pink
      }

      return HSLColor.fromAHSL(1.0, targetHue, saturation, lightness).toColor();
    } else {
      // Default / Light Maroon Palette: shades of maroon, rose, plum, burgundy
      double targetHue;
      double saturation = 0.65;
      double lightness = 0.44;

      if (baseHue == hueSchedule || baseHue == hueClass || baseHue == hueSchool) {
        // Deep Wine Maroon
        targetHue = 338.0;
        saturation = 0.60;
        lightness = 0.38;
      } else if (baseHue == hueAttendance || baseHue == hueFinance || baseHue == huePayroll) {
        // Rose Maroon
        targetHue = 345.0;
        saturation = 0.65;
        lightness = 0.42;
      } else if (baseHue == hueSubject || baseHue == hueQuestion || baseHue == hueAssignment) {
        // Rose Gold / Soft Plum
        targetHue = 352.0;
        saturation = 0.55;
        lightness = 0.52;
      } else if (baseHue == hueAnnouncement || baseHue == hueExtra) {
        // Raspberry Red
        targetHue = 328.0;
        saturation = 0.70;
        lightness = 0.45;
      } else if (baseHue == hueExamOffline || baseHue == hueExamOnline || baseHue == hueMonitor) {
        // Dark Plum
        targetHue = 322.0;
        saturation = 0.55;
        lightness = 0.34;
      } else {
        targetHue = 341.0;
        saturation = 0.65;
        lightness = 0.44;
      }

      return HSLColor.fromAHSL(1.0, targetHue, saturation, lightness).toColor();
    }
  }

  static String _inferThemeMode(Color primaryColor) {
    if (primaryColor == const Color(0xFFD32F2F)) return 'indonesia';
    if (primaryColor == const Color(0xFF6D28D9)) return 'violet';
    if (primaryColor == const Color(0xFF1E1E1E)) return 'dark';
    return 'light'; // default maroon
  }
}

/// Section group seperti iOS/Android Settings.
/// Menampilkan label kecil di atas, lalu card dengan list item.
class OsStyleMenuSection extends StatelessWidget {
  final String title;
  final List<Widget> menus;
  final Color primaryColor;

  const OsStyleMenuSection({
    super.key,
    required this.title,
    required this.menus,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? const Color(0xFF1E1E1E).withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.95);
    final shadowColor = primaryColor.withValues(alpha: isDark ? 0.08 : 0.12);
    final labelColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.45);

    // Filter out SizedBox.shrink / empty SizedBox items (conditional menus)
    final visibleMenus = menus
        .where((w) {
          if (w is SizedBox) return w.child != null;
          return true;
        })
        .toList();

    if (visibleMenus.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: labelColor,
                letterSpacing: 0.8,
              ),
            ),
          ),

          // Card container
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                children: visibleMenus,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Item row seperti iOS Settings:
/// [icon box berwarna] | [label] | [chevron]
/// Dengan separator di antara item (kecuali item terakhir).
class OsStyleMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconBgColor;
  final Color primaryColor;
  final bool isLast;
  final String? subtitle;
  final Widget? trailing;

  const OsStyleMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.iconBgColor,
    required this.primaryColor,
    this.isLast = false,
    this.subtitle,
    this.trailing,
  });

  @override
  State<OsStyleMenuItem> createState() => _OsStyleMenuItemState();
}

class _OsStyleMenuItemState extends State<OsStyleMenuItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.975).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.07);
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.4);
    final chevronColor = isDark
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.22);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) {
            _controller.reverse();
            widget.onTap();
          },
          onTapCancel: () => _controller.reverse(),
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                splashColor: widget.iconBgColor.withValues(alpha: 0.08),
                highlightColor: widget.iconBgColor.withValues(alpha: 0.04),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      // Colored icon badge
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: widget.iconBgColor,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                              color: widget.iconBgColor.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Label + optional subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 1),
                              Text(
                                widget.subtitle!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Trailing widget or chevron
                      widget.trailing ??
                          Icon(
                            Icons.chevron_right_rounded,
                            color: chevronColor,
                            size: 22,
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Separator (skip for last item)
        if (!widget.isLast)
          Padding(
            padding: const EdgeInsets.only(left: 66),
            child: Divider(
              height: 0.5,
              thickness: 0.5,
              color: dividerColor,
            ),
          ),
      ],
    );
  }
}
