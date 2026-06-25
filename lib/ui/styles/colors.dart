import 'package:eschool_saas_staff/ui/styles/themeExtensions/customColorsExtension.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:flutter/material.dart';

//Replace these colors accoridng to ui
Color get primaryColor => AppColorPalette.primaryMaroon;
Color get secondaryColor => AppColorPalette.secondaryMaroon;
Color get pageBackgroundColor => AppColorPalette.warmBeige;
Color get backgroundColor => Colors.white;
Color get errorColor => const Color(0xffBA1A1A);
Color get tertiaryColor => AppColorPalette.lightMaroon; //Border color define in design style

CustomColors get customColorsExtension => CustomColors(
      redColor: const Color(0xffBA1A1A),
      successColor: const Color(0xff56B35A),
      leaveRequestOverviewBackgroundColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.8),
      totalStaffOverviewBackgroundColor: AppColorPalette.secondaryMaroon,
      totalStudentOverviewBackgroundColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.7),
      totalTeacherOverviewBackgroundColor: AppColorPalette.primaryMaroon,
      sickBackgroundColor: const Color(0xff518EF4),
      permissionBackgroundColor: const Color(0xffff6e00),
    );
