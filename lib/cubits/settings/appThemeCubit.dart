import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:eschool_saas_staff/utils/system/hiveBoxKeys.dart';

abstract class AppThemeState {
  final String themeMode;
  AppThemeState(this.themeMode);
}

class AppThemeInitial extends AppThemeState {
  AppThemeInitial(super.themeMode);
}

class AppThemeChanged extends AppThemeState {
  AppThemeChanged(super.themeMode);
}

class AppThemeCubit extends Cubit<AppThemeState> {
  AppThemeCubit()
      : super(AppThemeInitial(
          Hive.box(settingsBoxKey).get(appThemeModeKey, defaultValue: 'light')
              as String,
        ));

  void changeTheme(String newTheme) {
    Hive.box(settingsBoxKey).put(appThemeModeKey, newTheme);
    emit(AppThemeChanged(newTheme));
  }
}
