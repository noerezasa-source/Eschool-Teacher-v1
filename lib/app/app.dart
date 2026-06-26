import 'dart:io';

import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/settings/appThemeCubit.dart';
import 'package:eschool_saas_staff/app/appTranslation.dart';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/cubits/settings/appConfigurationCubit.dart';
import 'package:eschool_saas_staff/cubits/settings/appLocalizationCubit.dart';
import 'package:eschool_saas_staff/cubits/authentication/authCubit.dart';
import 'package:eschool_saas_staff/cubits/chat/socketSettingsCubit.dart';
import 'package:eschool_saas_staff/cubits/settings/homeScreenDataCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/teacherMyTimetableCubit.dart';
import 'package:eschool_saas_staff/cubits/userDetails/staffAllowedPermissionsAndModulesCubit.dart';
import 'package:eschool_saas_staff/data/repositories/system/settingsRepository.dart';
import 'package:eschool_saas_staff/firebase_options.dart';
import 'package:eschool_saas_staff/ui/styles/themeExtensions/customColorsExtension.dart';
import 'package:eschool_saas_staff/ui/widgets/system/globalEnvFab.dart';
import 'package:eschool_saas_staff/utils/system/app_config.dart';
import 'package:eschool_saas_staff/utils/system/hiveBoxKeys.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/route_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:eschool_saas_staff/cubits/questionOnlineExam/questionOnlineExamCubit.dart';
import 'package:eschool_saas_staff/data/repositories/exam/onlineExamRepository.dart';

//to avoid handshake error on some devices
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  //Register the licence of font
  //If using google-fonts
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark));

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await AppTranslation.loadJsons();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Firebase already initialized: $e');
    }
  }

  await Hive.initFlutter();
  await AppConfig.init();
  await Hive.openBox(authBoxKey);
  await Hive.openBox(settingsBoxKey);

  await Hive.openBox(notificationsBoxKey);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
        providers: [
          BlocProvider<AppLocalizationCubit>(
            create: (_) => AppLocalizationCubit(SettingsRepository()),
          ),
          BlocProvider<AppConfigurationCubit>(
            create: (_) => AppConfigurationCubit(),
          ),
          BlocProvider<AppThemeCubit>(
            create: (_) => AppThemeCubit(),
          ),
          BlocProvider<AuthCubit>(
            create: (_) => AuthCubit(),
          ),
          BlocProvider<StaffAllowedPermissionsAndModulesCubit>(
            create: (_) => StaffAllowedPermissionsAndModulesCubit(),
          ),
          BlocProvider<TeacherMyTimetableCubit>(
            create: (_) => TeacherMyTimetableCubit(),
          ),
          BlocProvider<ClassesCubit>(
            create: (_) => ClassesCubit(),
          ),
          BlocProvider<HomeScreenDataCubit>(
            create: (context) => HomeScreenDataCubit(),
          ),
          BlocProvider<SocketSettingCubit>(create: (_) => SocketSettingCubit()),
          BlocProvider<QuestionOnlineExamCubit>(
            create: (context) => QuestionOnlineExamCubit(
              OnlineExamRepository(),
            ),
          ),
        ],
        child: BlocBuilder<AppThemeCubit, AppThemeState>(
          builder: (context, state) {
            final String currentTheme = state.themeMode;
            return GetMaterialApp(
              builder: (context, child) {
                return Stack(
                  textDirection: TextDirection.ltr,
                  children: [
                    if (child != null) child,
                    const GlobalEnvFab(),
                  ],
                );
              },
              title: 'eSchool - Guru & Staff',
              debugShowCheckedModeBanner: false,
              translationsKeys: AppTranslation.translationsKeys,
              theme: (() {
                final isDark = currentTheme == 'dark';
                final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();

                // Get colors based on current theme
                final primaryMaroon = AppColorPalette.getPrimaryColor(currentTheme);
                final secondaryMaroon = AppColorPalette.getSecondaryColor(currentTheme);
                final surfaceColor = isDark ? AppColorPalette.getLightColor(currentTheme) : Colors.white;
                final bgColor = AppColorPalette.getWarmBeigeColor(currentTheme);

                return baseTheme.copyWith(
                  extensions: <ThemeExtension<dynamic>>[
                    CustomColors(
                      redColor: const Color(0xffBA1A1A),
                      successColor: const Color(0xff56B35A),
                      leaveRequestOverviewBackgroundColor: primaryMaroon.withValues(alpha: 0.8),
                      totalStaffOverviewBackgroundColor: secondaryMaroon,
                      totalStudentOverviewBackgroundColor: primaryMaroon.withValues(alpha: 0.7),
                      totalTeacherOverviewBackgroundColor: primaryMaroon,
                      sickBackgroundColor: const Color(0xff518EF4),
                      permissionBackgroundColor: const Color(0xffff6e00),
                    )
                  ],
                  textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),
                  scaffoldBackgroundColor: bgColor,
                  colorScheme: ColorScheme.fromSeed(
                    brightness: isDark ? Brightness.dark : Brightness.light,
                    seedColor: primaryMaroon,
                    primary: primaryMaroon,
                    secondary: isDark ? Colors.white70 : secondaryMaroon,
                    surface: surfaceColor,
                    error: const Color(0xffBA1A1A),
                  ),
                );
              }()),
              getPages: Routes.getPages,
              initialRoute: Routes.splashScreen,
              locale: context.read<AppLocalizationCubit>().state.language,
              fallbackLocale: const Locale("id"),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('id', 'ID'),
              ],
            );
          },
        ));
  }
}
