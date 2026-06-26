import 'package:eschool_saas_staff/cubits/settings/appThemeCubit.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/backgroundExperimentScreen.dart';
import 'dart:math';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/settings/appLocalizationCubit.dart';
import 'package:eschool_saas_staff/cubits/authentication/authCubit.dart';
import 'package:eschool_saas_staff/data/repositories/system/settingsRepository.dart';
import 'package:eschool_saas_staff/ui/screens/leaves/leavesScreen.dart';
import 'package:eschool_saas_staff/ui/screens/login/widgets/schoolListScreen.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionTile.dart';
import 'package:eschool_saas_staff/utils/system/appLanguages.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';



class ProfileContainer extends StatefulWidget {
  const ProfileContainer({super.key});

  @override
  State<ProfileContainer> createState() => _ProfileContainerState();
}

class _ProfileContainerState extends State<ProfileContainer>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _hoveredMenuIndex = -1;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Animation controllers from homeContainerAppbar
  late AnimationController _glowAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _rotationAnimationController;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  Color get maroonPrimary => AppColorPalette.primaryMaroon; // Deep maroon
  Color get maroonLight => AppColorPalette.secondaryMaroon; // Light maroon
  Color get maroonDark => maroonPrimary.withValues(alpha: 0.8); // Darker variant
  Color get maroonMiddle => maroonPrimary.withValues(alpha: 0.9); // Middle variant

  @override
  void initState() {
    super.initState();

    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _animation =
        Tween<double>(begin: 0, end: 2 * pi).animate(_animationController);

    // Refined glow animation - more subtle and elegant
    _glowAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowAnimationController,
        curve: Curves.easeInOutSine, // Smoother curve
      ),
    );

    // Gentle pulse animation - less aggressive
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOutCubic, // More elegant curve
      ),
    );

    // Slower, more graceful rotation
    _rotationAnimationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _rotationAnimationController,
        curve: Curves.linear,
      ),
    );

    // Start animations with delays for more natural feel
    _glowAnimationController.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _pulseAnimationController.repeat(reverse: true);
      }
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _rotationAnimationController.repeat();
      }
    });

    // Set system UI overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _glowAnimationController.stop();
        _pulseAnimationController.stop();
        _rotationAnimationController.stop();
        break;
      case AppLifecycleState.resumed:
        if (!_glowAnimationController.isAnimating) {
          _glowAnimationController.repeat(reverse: true);
        }
        if (!_pulseAnimationController.isAnimating) {
          _pulseAnimationController.repeat(reverse: true);
        }
        if (!_rotationAnimationController.isAnimating) {
          _rotationAnimationController.repeat();
        }
        break;
      case AppLifecycleState.inactive:
        _glowAnimationController.stop();
        _pulseAnimationController.stop();
        _rotationAnimationController.stop();
        break;
      case AppLifecycleState.detached:
        _glowAnimationController.stop();
        _pulseAnimationController.stop();
        _rotationAnimationController.stop();
        break;
      case AppLifecycleState.hidden:
        _glowAnimationController.stop();
        _pulseAnimationController.stop();
        _rotationAnimationController.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _glowAnimationController.dispose();
    _pulseAnimationController.dispose();
    _rotationAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppThemeCubit, AppThemeState>(
      builder: (context, themeState) {
        final currentTheme = themeState.themeMode;
        final maroonPrimary = AppColorPalette.getPrimaryColor(currentTheme);
        final maroonLight = AppColorPalette.getSecondaryColor(currentTheme);

        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authstate) {
            return Stack(
              children: [
                // Animated Background Pattern
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(MediaQuery.of(context).size.width,
                          MediaQuery.of(context).size.height),
                      painter: BackgroundPatternPainter(
                        animation: _animation,
                        primaryColor: maroonPrimary.withValues(alpha: 0.03),
                        accentColor: maroonLight.withValues(alpha: 0.02),
                      ),
                    );
                  },
                ),

            // Main Content
            AnimationLimiter(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsetsDirectional.only(
                  top: Utils.appContentTopScrollPadding(context: context) +
                      190, // Increased top padding to accommodate new app bar
                  end: appContentHorizontalPadding,
                  start: appContentHorizontalPadding,
                  bottom: 100,
                ),
                child: Column(
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 600),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 30.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: <Widget>[
                      const SizedBox(height: 8),

                      // // Welcome message
                      // _buildWelcomeSection(context),

                      // const SizedBox(height: 32),

                      _buildMenuSection(
                        context: context,
                        title: "Pengaturan Personal",
                        icon: Icons.person_outline,
                        iconColor: maroonPrimary.withValues(alpha: 0.9),
                        index: 0,
                        menus: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.edit,
                            title: "Edit Profil",
                            index: 0,
                            onTap: () => Get.toNamed(Routes.editProfileScreen),
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.lock_outline,
                            title: "Ubah Kata Sandi",
                            index: 1,
                            onTap: () =>
                                Get.toNamed(Routes.changePasswordScreen),
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.notifications_active_outlined,
                            title: "Pengaturan Notifikasi",
                            index: 11,
                            onTap: () =>
                                _showNotificationSettingsBottomSheet(context),
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.palette_outlined,
                            title: "Tema Aplikasi",
                            index: 12,
                            onTap: () => _showThemeSelectionBottomSheet(context),
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.science_outlined,
                            title: "BACKGROUND EXPERIMEN",
                            index: 13,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BackgroundExperimentScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      _buildMenuSection(
                        context: context,
                        title: "Cuti",
                        icon: Icons.event_available,
                        iconColor: maroonPrimary.withValues(alpha: 0.9),
                        index: 1,
                        menus: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.add_circle_outline,
                            title: "Ajukan Cuti",
                            index: 2,
                            onTap: () => Get.toNamed(Routes.applyLeaveScreen),
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.history,
                            title: "Riwayat Cuti Saya",
                            index: 3,
                            onTap: () => Get.toNamed(Routes.leavesScreen,
                                arguments: LeavesScreen.buildArguments(
                                    showMyLeaves: true)),
                          ),
                        ],
                      ),

                      _buildMenuSection(
                        context: context,
                        title: "Penggajian",
                        icon: Icons.account_balance_wallet,
                        iconColor: maroonPrimary.withValues(alpha: 0.9),
                        index: 2,
                        menus: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.receipt_long,
                            title: "Slip Gaji Saya",
                            index: 4,
                            onTap: () => Get.toNamed(Routes.myPayrollScreen),
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.monetization_on_outlined,
                            title: "Tunjangan & Potongan",
                            index: 5,
                            onTap: () => Get.toNamed(
                                Routes.allowancesAndDeductionsScreen),
                          ),
                        ],
                      ),

                      _buildMenuSection(
                        context: context,
                        title: "Informasi",
                        icon: Icons.info_outline,
                        iconColor: maroonPrimary.withValues(alpha: 0.9),
                        index: 3,
                        menus: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.business,
                            title: "Tentang Kami",
                            index: 6,
                            onTap: () => Get.toNamed(Routes.aboutUsScreen),
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.contact_mail,
                            title: "Hubungi Kami",
                            index: 7,
                            onTap: () => Get.toNamed(Routes.contactUsScreen),
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.contact_support_rounded,
                            title: "Kontak & Laporan",
                            index: 71,
                            onTap: () => Get.toNamed(Routes.contactListScreen),
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.privacy_tip_outlined,
                            title: "Kebijakan Privasi",
                            index: 8,
                            onTap: () =>
                                Get.toNamed(Routes.privacyPolicyScreen),
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.gavel_outlined,
                            title: "Syarat & Ketentuan",
                            index: 9,
                            onTap: () =>
                                Get.toNamed(Routes.termsAndConditionScreen),
                          ),
                        ],
                      ),

                      _buildMenuSection(
                        context: context,
                        title: "Sekolah",
                        icon: Icons.school_outlined,
                        iconColor: maroonPrimary.withValues(alpha: 0.9),
                        index: 4,
                        menus: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.swap_horiz,
                            title: "Pindah Sekolah",
                            index: 10,
                            onTap: () async {
                              // Show loading dialog
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return Dialog(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          maroonPrimary,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );

                              try {
                                final authCubit = context.read<AuthCubit>();
                                final userDetails = authCubit.getUserDetails();

                                final schoolsData =
                                    await authCubit.getSchoolsData();

                                debugPrint(
                                    'DEBUG: schoolsData type: ${schoolsData.runtimeType}');
                                debugPrint(
                                    'DEBUG: schoolsData length: ${schoolsData.length}');
                                if (schoolsData.isNotEmpty) {
                                  debugPrint(
                                      'DEBUG: first school type: ${schoolsData.first.runtimeType}');
                                  debugPrint(
                                      'DEBUG: first school keys: ${schoolsData.first.keys}');
                                }

                                // Validate schools data
                                if (schoolsData.isEmpty) {
                                  throw Exception(
                                      'Data sekolah tidak tersedia. Silakan coba lagi.');
                                }

                                final userData = {
                                  'data': {
                                    'first_name': userDetails.firstName,
                                    'last_name': userDetails.lastName,
                                    'email': userDetails.email,
                                    'mobile': userDetails.mobile,
                                    'image': userDetails.image,
                                    'id': userDetails.id,
                                    'schools': schoolsData,
                                  },
                                };

                                debugPrint(
                                    'DEBUG: userData created successfully');
                                debugPrint(
                                    'DEBUG: userData[data][schools] type: ${userData['data']?['schools']?.runtimeType}');

                                if (!context.mounted) return;

                                // Close loading dialog
                                Navigator.of(context).pop();

                                // Navigate to school list
                                Get.to(
                                    () => SchoolListScreen(userData: userData));
                              } catch (e) {
                                if (!context.mounted) return;

                                // Close loading dialog
                                Navigator.of(context).pop();

                                // Show error message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Terjadi kesalahan: ${e.toString()}',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 4),
                                    action: SnackBarAction(
                                      label: 'Tutup',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .hideCurrentSnackBar();
                                      },
                                    ),
                                  ),
                                );

                                debugPrint('Error in Pindah Sekolah: $e');
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      _buildLogoutButton(context),
                    ],
                  ),
                ),
              ),
            ),

            // Enhanced Curved App Bar
            _buildDramaticCurvedAppBar(context: context),
          ],
        );
      },
    );
      },
    );
  }

  // Widget _buildWelcomeSection(BuildContext context) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [
  //           Colors.white,
  //           AppColorPalette.warmBeige.withValues(alpha: 0.4),
  //         ],
  //       ),
  //       borderRadius: BorderRadius.circular(24),
  //       boxShadow: [
  //         BoxShadow(
  //           color: AppColorPalette.primaryMaroon.withValues(alpha: 0.05),
  //           blurRadius: 15,
  //           offset: const Offset(0, 8),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(10),
  //               decoration: BoxDecoration(
  //                 color: AppColorPalette.primaryMaroon.withValues(alpha: 0.1),
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Icon(
  //                 Icons.waving_hand_rounded,
  //                 color: AppColorPalette.primaryMaroon.withValues(alpha: 0.9),
  //                 size: 22,
  //               ),
  //             ),
  //             const SizedBox(width: 14),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     "Selamat datang,",
  //                     style: GoogleFonts.poppins(
  //                       fontSize: 15,
  //                       fontWeight: FontWeight.w500,
  //                       color:
  //                           Colors.black.withValues(alpha: 0.7), // Changed to black
  //                     ),
  //                   ),
  //                   const SizedBox(height: 4),
  //                   Text(
  //                     context.read<AuthCubit>().getUserDetails().firstName ??
  //                         "Pengguna",
  //                     style: GoogleFonts.poppins(
  //                       fontSize: 24,
  //                       fontWeight: FontWeight.bold,
  //                       color: Colors.black, // Changed to black
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildMenuSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required int index,
    required List<Widget> menus,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 400),
      child: SlideAnimation(
        verticalOffset: 40,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColorPalette.getLightColor(context.read<AppThemeCubit>().state.themeMode),
                        AppColorPalette.getLightColor(context.read<AppThemeCubit>().state.themeMode).withValues(alpha: 0.95),
                      ]
                    : [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.95),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: iconColor.withValues(alpha: isDark ? 0.2 : 0.05),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              iconColor.withValues(alpha: 0.2),
                              iconColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: iconColor.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        iconColor.withValues(alpha: 0.05),
                        iconColor.withValues(alpha: 0.2),
                        iconColor.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
                ...menus,
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int index,
    required VoidCallback onTap,
  }) {
    final isHovered = _hoveredMenuIndex == index;

    return StatefulBuilder(builder: (context, setState) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final themeMode = context.read<AppThemeCubit>().state.themeMode;
      final maroonPrimary = AppColorPalette.getPrimaryColor(themeMode);
      final maroonLight = AppColorPalette.getSecondaryColor(themeMode);
      return MouseRegion(
        onEnter: (_) => this.setState(() => _hoveredMenuIndex = index),
        onExit: (_) => this.setState(() => _hoveredMenuIndex = -1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: isHovered
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      maroonPrimary.withValues(alpha: 0.05),
                      maroonLight.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            border: isHovered
                ? Border.all(
                    color: maroonPrimary.withValues(alpha: 0.1),
                    width: 1,
                  )
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              splashColor: maroonPrimary.withValues(alpha: 0.1),
              highlightColor: Colors.transparent,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isHovered
                            ? maroonPrimary.withValues(alpha: 0.1)
                            : (isDark
                                ? AppColorPalette.getLightColor(themeMode)
                                : AppColorPalette.getWarmBeigeColor(themeMode)
                                    .withValues(alpha: 0.5)),
                        shape: BoxShape.circle,
                        boxShadow: isHovered
                            ? [
                                BoxShadow(
                                  color: maroonPrimary.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        icon,
                        color: isHovered
                            ? maroonPrimary
                            : (isDark ? Colors.white70 : maroonLight),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight:
                              isHovered ? FontWeight.w600 : FontWeight.w500,
                          color: isDark
                              ? (isHovered
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.8))
                              : (isHovered
                                  ? Colors.black
                                  : Colors.black.withValues(alpha: 0.8)),
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      transform: Matrix4.translationValues(
                          isHovered ? 8.0 : 0.0, 0.0, 0.0),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: isHovered
                            ? maroonPrimary
                            : (isDark
                                ? Colors.white30
                                : maroonLight.withValues(alpha: 0.5)),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  void _showThemeSelectionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pilih Tema Aplikasi",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            _buildThemeOption(
              context: context,
              title: "Terang (Default)",
              themeValue: 'light',
              icon: Icons.light_mode_outlined,
              color: const Color(0xFF8B1F41),
            ),
            _buildThemeOption(
              context: context,
              title: "Malam (Gelap)",
              themeValue: 'dark',
              icon: Icons.dark_mode_outlined,
              color: const Color(0xFF1E1E1E),
            ),
            _buildThemeOption(
              context: context,
              title: "Violet (Ungu)",
              themeValue: 'violet',
              icon: Icons.auto_awesome_outlined,
              color: const Color(0xFF6D28D9),
            ),
            _buildThemeOption(
              context: context,
              title: "Indonesia (Merah Putih)",
              themeValue: 'indonesia',
              icon: Icons.celebration_rounded,
              color: const Color(0xFFD32F2F),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required String themeValue,
    required IconData icon,
    required Color color,
  }) {
    final currentTheme = context.read<AppThemeCubit>().state.themeMode;
    final isSelected = currentTheme == themeValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected
            ? color.withValues(alpha: 0.1)
            : (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.read<AppThemeCubit>().changeTheme(themeValue);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? color
                          : (isDark
                              ? Colors.white
                              : Colors.black87),
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: color, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationSettingsBottomSheet(BuildContext context) {
    final settingsRepository = SettingsRepository();
    bool vibrationEnabled = settingsRepository.getVibrationEnabled();
    final themeMode = context.read<AppThemeCubit>().state.themeMode;
    final maroonPrimary = AppColorPalette.getPrimaryColor(themeMode);
    final maroonLight = AppColorPalette.getSecondaryColor(themeMode);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Pengaturan Notifikasi',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.3)
                          : AppColorPalette.getWarmBeigeColor(themeMode)
                              .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.2)
                            : maroonPrimary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.vibration,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Getar Saat Notifikasi',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Aktifkan getaran saat menerima notifikasi baru',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: vibrationEnabled,
                          onChanged: (value) async {
                            setState(() {
                              vibrationEnabled = value;
                            });
                            await settingsRepository.setVibrationEnabled(value);
                          },
                          activeThumbColor: maroonPrimary,
                          activeTrackColor:
                              maroonLight.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: maroonPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Tutup',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final themeMode = context.read<AppThemeCubit>().state.themeMode;
    final maroonPrimary = AppColorPalette.getPrimaryColor(themeMode);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const LogoutConfirmationDialog(),
          ).then((value) {
            final logoutUser = (value as bool?) ?? false;
            if (logoutUser && context.mounted) {
              context.read<AuthCubit>().signOut();
              Get.offNamed(Routes.loginScreen);
            }
          });
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: maroonPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              "Keluar",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDramaticCurvedAppBar({required BuildContext context}) {
    return BlocBuilder<AppThemeCubit, AppThemeState>(
      builder: (context, themeState) {
        final isDark = themeState.themeMode == 'dark';
        
        final maroonPrimary = AppColorPalette.getPrimaryColor(themeState.themeMode);
        final maroonLight = AppColorPalette.getSecondaryColor(themeState.themeMode);
        final maroonDark = maroonPrimary.withValues(alpha: 0.8);
        final maroonMiddle = maroonPrimary.withValues(alpha: 0.9);

        // Set system UI overlay style for status bar
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light, // Always light for dark background
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ));

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: 210 + MediaQuery.of(context).padding.top,
            width: MediaQuery.of(context).size.width,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CustomPaint(
                    painter: DramaticCurvedGradientPainter(
                      colors: [
                        maroonDark,
                        maroonPrimary,
                        maroonMiddle,
                        maroonLight,
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                  ),
                ),

                // Decorative design elements with enhanced animations
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _glowAnimationController,
                      _pulseAnimationController,
                      _rotationAnimationController,
                    ]),
                    builder: (context, _) {
                      return CustomPaint(
                        painter: AnimatedAppBarDecorationPainter(
                          color: Colors.white.withValues(
                              alpha: 0.07 + (_glowAnimation.value * 0.05)),
                          glowValue: _glowAnimation.value,
                          pulseValue: _pulseAnimation.value,
                          rotationValue: _rotationAnimation.value,
                        ),
                      );
                    },
                  ),
                ),

                // Refined animated glowing effect - more subtle and elegant
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _glowAnimationController,
                    _pulseAnimationController,
                  ]),
                  builder: (context, _) {
                    return Stack(
                      children: [
                        // Primary glow circle - softer movement
                        Positioned(
                          top: MediaQuery.of(context).padding.top -
                              100 +
                              (sin(_glowAnimation.value * 2 * pi) * 5),
                          right: -60 + (cos(_glowAnimation.value * 2 * pi) * 3),
                          child: Transform.scale(
                            scale: 0.95 + (_pulseAnimation.value * 0.1),
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withValues(
                                        alpha:
                                            0.15 + (_glowAnimation.value * 0.05)),
                                    Colors.white.withValues(
                                        alpha:
                                            0.08 + (_glowAnimation.value * 0.03)),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.0, 0.6, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Secondary glow circle - gentle floating
                        Positioned(
                          top: MediaQuery.of(context).padding.top -
                              70 +
                              (sin(_glowAnimation.value * 2 * pi + 1.5) * 4),
                          left:
                              -30 + (cos(_glowAnimation.value * 2 * pi + 1.5) * 2),
                          child: Transform.scale(
                            scale: 1.0 + (sin(_pulseAnimation.value * pi) * 0.05),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withValues(
                                        alpha:
                                            0.12 + (_glowAnimation.value * 0.04)),
                                    Colors.white.withValues(
                                        alpha:
                                            0.06 + (_glowAnimation.value * 0.02)),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.0, 0.7, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Tertiary glow circle - micro floating animation
                        Positioned(
                          top: MediaQuery.of(context).padding.top +
                              25 +
                              (sin(_glowAnimation.value * 2 * pi + 3) * 3),
                          right: -15 + (cos(_glowAnimation.value * 2 * pi + 3) * 2),
                          child: Transform.rotate(
                            angle: _rotationAnimation.value * 0.3,
                            child: Transform.scale(
                              scale: 0.9 +
                                  (sin(_pulseAnimation.value * pi + 2) * 0.08),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withValues(
                                          alpha:
                                              0.08 + (_glowAnimation.value * 0.03)),
                                      Colors.white.withValues(
                                          alpha: 0.04 +
                                              (_glowAnimation.value * 0.015)),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                    stops: const [0.0, 0.8, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // Enhanced static wave pattern
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: CustomPaint(
                    painter: EnhancedWavePatternPainter(
                      color1: Colors.white.withValues(alpha: 0.1),
                      color2: Colors.white.withValues(alpha: 0.07),
                    ),
                    child: SizedBox(
                      height: 80,
                      width: MediaQuery.of(context).size.width,
                    ),
                  ),
                ),

                // App bar title
                Positioned(
                  top: MediaQuery.of(context).padding.top + 15,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      "Profil",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Profile card
                Positioned(
                  bottom: 15,
                  left: 16,
                  right: 16,
                  child: Container(
                    height: 120,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: maroonPrimary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: maroonLight.withValues(alpha: 0.15),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: _buildProfileInfo(context,
                        maroonPrimary: maroonPrimary, maroonDark: maroonDark),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileInfo(BuildContext context,
      {required Color maroonPrimary, required Color maroonDark}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        // Profile image with tap to zoom
        GestureDetector(
          onTap: () {
            final profileImage =
                context.read<AuthCubit>().getUserDetails().image ?? "";
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                  backgroundColor: Colors.transparent,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Stack(
                      children: [
                        InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: profileImage.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: profileImage,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          maroonPrimary),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Center(
                                    child: Icon(
                                      Icons.error,
                                      color: maroonPrimary,
                                      size: 50,
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.person,
                                    color: maroonPrimary,
                                    size: 100,
                                  ),
                                ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Material(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 24,
                                  ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [maroonPrimary, maroonDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: maroonPrimary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            padding: const EdgeInsets.all(2),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              radius: 35,
              backgroundImage:
                  (context.read<AuthCubit>().getUserDetails().image ?? "")
                          .isNotEmpty
                      ? CachedNetworkImageProvider(
                          context.read<AuthCubit>().getUserDetails().image ??
                              "",
                        )
                      : null,
              child: (context.read<AuthCubit>().getUserDetails().image ?? "")
                      .isEmpty
                  ? Icon(
                      Icons.person,
                      color: maroonPrimary,
                      size: 38,
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
// User Name
              Builder(
                builder: (context) {
                  final userDetails =
                      context.read<AuthCubit>().getUserDetails();
                  final fullName = (userDetails.firstName ?? "").trim();
                  debugPrint(
                      'DEBUG ProfileContainer: firstName="${userDetails.firstName}", email="${userDetails.email}", schoolName="${userDetails.school?.name}"');
                  return Text(
                    fullName.isEmpty ? "Pengguna" : fullName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.white
                          : maroonPrimary,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
              const SizedBox(height: 4),

              // School Info
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : maroonPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.school_outlined,
                      size: 14,
                      color: isDark
                          ? Colors.white70
                          : maroonPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.read<AuthCubit>().getUserDetails().school?.name ??
                          "Belum ada sekolah",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white70
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Email Info
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : maroonPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: isDark
                          ? Colors.white70
                          : maroonPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.read<AuthCubit>().getUserDetails().email ??
                          "Belum ada email",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white70
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primaryColor;
  final Color accentColor;

  BackgroundPatternPainter({
    required this.animation,
    required this.primaryColor,
    required this.accentColor,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Optimized dots pattern - increased spacing to reduce draw calls
    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    // Use a larger step (60 instead of 30) to significantly reduce complexity
    for (var x = 0.0; x < width; x += 60.0) {
      for (var y = 0.0; y < height; y += 60.0) {
        // Simplified math for offset
        final offset = sin(x * 0.02 + y * 0.02 + animation.value) * 2;
        canvas.drawCircle(
          Offset(x + offset, y + offset),
          1.2,
          dotPaint,
        );
      }
    }

    // Draw static wave instead of animated one if needed, or simplify
    final wavePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var startY = 100.0; startY < height; startY += 250) {
      final path = Path();
      path.moveTo(0, startY);

      // Draw wave with fewer segments
      for (var x = 0.0; x < width; x += 20.0) {
        final y = startY + sin(x * 0.01 + animation.value) * 15;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(BackgroundPatternPainter oldDelegate) => true;
}

class AppLanguagesBottomsheet extends StatelessWidget {
  const AppLanguagesBottomsheet({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomBottomsheet(
        titleLabelKey: changeLanguageKey,
        child: BlocBuilder<AppLocalizationCubit, AppLocalizationState>(
          builder: (context, state) {
            return Padding(
              padding: EdgeInsets.all(appContentHorizontalPadding),
              child: Column(
                children: appLanguages
                    .map((language) => FilterSelectionTile(
                        onTap: () {
                          context
                              .read<AppLocalizationCubit>()
                              .changeLanguage(language.languageCode);
                        },
                        isSelected: state.language.languageCode ==
                            language.languageCode,
                        title: language.languageName))
                    .toList(),
              ),
            );
          },
        ));
  }
}

class LogoutConfirmationDialog extends StatelessWidget {
  const LogoutConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = context.read<AppThemeCubit>().state.themeMode;
    final maroonPrimary = AppColorPalette.getPrimaryColor(themeMode);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: FadeInUp(
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.9),
                    ]
                  : [
                      Colors.white,
                      AppColorPalette.getWarmBeigeColor(themeMode)
                          .withValues(alpha: 0.9),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: maroonPrimary.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Illustration
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(bottom: 20),
                child: Icon(
                  Icons.logout_rounded,
                  size: 60,
                  color: isDark ? Colors.white : maroonPrimary,
                ),
              ),

              // Title
              Text(
                "Konfirmasi Keluar",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : maroonPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Message
              Text(
                "Apakah Anda yakin ingin keluar dari aplikasi?",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: false),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : Colors.black87,
                        backgroundColor: isDark
                            ? AppColorPalette.getLightColor(themeMode)
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Batal",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Confirm button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: maroonPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Keluar",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for dramatically curved gradient background
class DramaticCurvedGradientPainter extends CustomPainter {
  final List<Color> colors;
  final List<double> stops;

  DramaticCurvedGradientPainter({
    required this.colors,
    required this.stops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Create gradient
    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
      stops: stops,
    ).createShader(rect);

    // Create dramatic double-curved path with deep valleys
    final path = Path();
    path.lineTo(0, size.height - 60);

    // First dramatic curve
    final firstControlPoint = Offset(size.width * 0.25, size.height + 30);
    final firstEndPoint = Offset(size.width * 0.5, size.height - 40);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    // Second dramatic curve
    final secondControlPoint = Offset(size.width * 0.75, size.height - 110);
    final secondEndPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    // Complete the path
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Add more dramatic highlights for enhanced depth
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final highlightPath = Path();
    highlightPath.moveTo(0, size.height - 58);
    highlightPath.quadraticBezierTo(firstControlPoint.dx,
        firstControlPoint.dy - 4, firstEndPoint.dx, firstEndPoint.dy - 3);
    highlightPath.quadraticBezierTo(secondControlPoint.dx,
        secondControlPoint.dy - 3, secondEndPoint.dx, secondEndPoint.dy - 3);

    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant DramaticCurvedGradientPainter oldDelegate) {
    return colors != oldDelegate.colors || stops != oldDelegate.stops;
  }
}

// Enhanced wave pattern for more visual impact
class EnhancedWavePatternPainter extends CustomPainter {
  final Color color1;
  final Color color2;

  EnhancedWavePatternPainter({
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    // First enhanced wave with more dramatic peaks and valleys
    final path = Path();
    path.moveTo(0, size.height * 0.3);

    // First dramatic curve set - more pronounced waves
    path.cubicTo(size.width * 0.15, size.height * 0.1, size.width * 0.35,
        size.height * 0.6, size.width * 0.5, size.height * 0.2);

    // Second dramatic curve set
    path.cubicTo(size.width * 0.65, size.height * -0.2, size.width * 0.85,
        size.height * 0.4, size.width, size.height * 0.3);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    paint.color = color1;
    canvas.drawPath(path, paint);

    // Second enhanced wave with different pattern
    final secondPath = Path();
    secondPath.moveTo(0, size.height * 0.5);

    // First dramatic curve
    secondPath.cubicTo(size.width * 0.2, size.height * 0.3, size.width * 0.4,
        size.height * 0.8, size.width * 0.6, size.height * 0.4);

    // Second dramatic curve
    secondPath.cubicTo(size.width * 0.75, size.height * 0.1, size.width * 0.9,
        size.height * 0.6, size.width, size.height * 0.35);

    secondPath.lineTo(size.width, size.height);
    secondPath.lineTo(0, size.height);
    secondPath.close();

    paint.color = color2;
    canvas.drawPath(secondPath, paint);

    // Add more dramatic decorative elements
    final circlePaint = Paint()
      ..color = color1
      ..style = PaintingStyle.fill;

    // Larger circles for better visibility
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.2), 25, circlePaint);
    canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.7), 20, circlePaint);
    canvas.drawCircle(
        Offset(size.width * 0.6, size.height * 0.6), 15, circlePaint);
  }

  @override
  bool shouldRepaint(covariant EnhancedWavePatternPainter oldDelegate) {
    return color1 != oldDelegate.color1 || color2 != oldDelegate.color2;
  }
}

// Enhanced custom painter for animated decorative elements in the app bar
class AnimatedAppBarDecorationPainter extends CustomPainter {
  final Color color;
  final double glowValue;
  final double pulseValue;
  final double rotationValue;

  AnimatedAppBarDecorationPainter({
    required this.color,
    required this.glowValue,
    required this.pulseValue,
    required this.rotationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: color.a * (0.3 + glowValue * 0.3))
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1 + glowValue * 2);

    // Refined animated decorative circles - more subtle movement
    final circles = [
      {
        'center': Offset(size.width * (0.88 + sin(glowValue * 2 * pi) * 0.01),
            size.height * (0.22 + cos(glowValue * 2 * pi) * 0.008)),
        'radius': 25 * (0.9 + sin(pulseValue * pi) * 0.15),
        'hasGlow': true,
      },
      {
        'center': Offset(
            size.width * (0.12 + cos(glowValue * 2 * pi + 1.5) * 0.008),
            size.height * (0.78 + sin(glowValue * 2 * pi + 1.5) * 0.01)),
        'radius': 18 * (0.95 + sin(pulseValue * pi + 0.5) * 0.1),
        'hasGlow': false,
      },
      {
        'center': Offset(
            size.width * (0.52 + sin(glowValue * 2 * pi + 3) * 0.012),
            size.height * (0.18 + cos(glowValue * 2 * pi + 3) * 0.006)),
        'radius': 12 * (1.0 + sin(pulseValue * pi + 1) * 0.2),
        'hasGlow': true,
      },
      {
        'center': Offset(
            size.width * (0.72 + cos(glowValue * 2 * pi + 4.5) * 0.008),
            size.height * (0.68 + sin(glowValue * 2 * pi + 4.5) * 0.01)),
        'radius': 8 * (0.8 + sin(pulseValue * pi + 1.5) * 0.3),
        'hasGlow': false,
      },
      {
        'center': Offset(
            size.width * (0.25 + sin(glowValue * 2 * pi + 6) * 0.01),
            size.height * (0.42 + cos(glowValue * 2 * pi + 6) * 0.008)),
        'radius': 6 * (1.0 + sin(pulseValue * pi + 2) * 0.15),
        'hasGlow': true,
      },
    ];

    // Draw refined animated circles
    for (var circle in circles) {
      final center = circle['center'] as Offset;
      final radius = circle['radius'] as double;
      final hasGlow = circle['hasGlow'] as bool;

      if (hasGlow) {
        // Draw subtle glow effect
        canvas.drawCircle(center, radius * 1.3, glowPaint);
      }
      // Draw main circle
      canvas.drawCircle(center, radius, paint);
    }

    // Refined animated arcs - smoother movement
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 + glowValue * 0.5;

    final glowArcPaint = Paint()
      ..color = color.withValues(alpha: color.a * (0.2 + glowValue * 0.3))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 + glowValue * 1
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.5 + glowValue * 1.5);

    // First refined animated arc
    final arcRect = Rect.fromLTRB(
        size.width * (0.12 + sin(glowValue * 2 * pi) * 0.02),
        size.height * (0.25 + cos(glowValue * 2 * pi) * 0.015),
        size.width * (0.58 + sin(glowValue * 2 * pi + 1) * 0.025),
        size.height * (0.58 + cos(glowValue * 2 * pi + 1) * 0.02));

    final arcSweep = 1.2 + sin(glowValue * 2 * pi) * 0.2;
    final arcStart = 0.3 + rotationValue * 0.05;

    // Draw subtle glow arc
    canvas.drawArc(arcRect, arcStart, arcSweep, false, glowArcPaint);
    // Draw main arc
    canvas.drawArc(arcRect, arcStart, arcSweep, false, arcPaint);

    // Second refined animated arc
    final arcRect2 = Rect.fromLTRB(
        size.width * (0.48 + cos(glowValue * 2 * pi + 2) * 0.015),
        size.height * (0.42 + sin(glowValue * 2 * pi + 2) * 0.01),
        size.width * (0.88 + cos(glowValue * 2 * pi + 3) * 0.02),
        size.height * (0.78 + sin(glowValue * 2 * pi + 3) * 0.015));

    final arcSweep2 = 1.3 + sin(glowValue * 2 * pi + 1) * 0.15;
    final arcStart2 = 2.8 - rotationValue * 0.08;

    // Draw subtle glow arc
    canvas.drawArc(arcRect2, arcStart2, arcSweep2, false, glowArcPaint);
    // Draw main arc
    canvas.drawArc(arcRect2, arcStart2, arcSweep2, false, arcPaint);

    // Refined floating particles - gentler movement
    for (int i = 0; i < 6; i++) {
      final angle = (i * 1.047) + rotationValue * 0.3; // 1.047 = 2π/6
      final baseDistance = 25 + sin(glowValue * 2 * pi + i) * 8;
      final particleSize = 1.5 + sin(glowValue * 2 * pi + i * 1.5) * 0.8;

      final particleCenter = Offset(
        size.width * 0.5 + (baseDistance * cos(angle)),
        size.height * 0.5 + (baseDistance * sin(angle)),
      );

      final particlePaint = Paint()
        ..color =
            color.withValues(alpha: 0.4 + sin(glowValue * 2 * pi + i * 2) * 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(particleCenter, particleSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedAppBarDecorationPainter oldDelegate) {
    return oldDelegate.glowValue != glowValue ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.rotationValue != rotationValue ||
        oldDelegate.color != color;
  }
}
