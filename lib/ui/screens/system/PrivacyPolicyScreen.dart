import 'dart:math';
import 'package:eschool_saas_staff/cubits/settings/settingCubit.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/route_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  static Widget getRouteInstance() {
    return BlocProvider(
      create: (context) => SettingsCubit(),
      child: const PrivacyPolicyScreen(),
    );
  }

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with TickerProviderStateMixin {
  String? cachedData;
  late AnimationController _controller;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fabAnimationController;
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;
  Color get _maroonLight => AppColorPalette.secondaryMaroon;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _scrollController.addListener(_scrollListener);
    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    context.read<SettingsCubit>().getSettings("privacy_policy");
    _loadDataCached();
  }

  void _scrollListener() {
    if (_scrollController.offset > 50) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadDataCached() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cachedData = prefs.getString("privacy_policy");
    });
  }

  String generateRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  String parseCustomHtml(String input) {
    // If input already contains HTML tags, don't use custom parsing
    if (input.contains('<') && input.contains('>')) {
      return input.replaceAll("\n", "<br/>");
    }

    String placeholderBold = generateRandomString(10);
    String placeholderItalic = generateRandomString(10);

    while (placeholderItalic == placeholderBold) {
      placeholderItalic = generateRandomString(10);
      placeholderBold = generateRandomString(10);
    }

    input = input
        .replaceAll('\\*', placeholderBold)
        .replaceAll('\\/', placeholderItalic);

    bool isBold = false;
    bool isItalic = false;
    String output = '';

    for (int i = 0; i < input.length; i++) {
      if (input[i] == '*') {
        isBold = !isBold;
        output += isBold ? '<b>' : '</b>';
      } else if (input[i] == '/') {
        isItalic = !isItalic;
        output += isItalic ? '<i>' : '</i>';
      } else {
        output += input[i];
      }
    }

    output = output
        .replaceAll(placeholderBold, '*')
        .replaceAll(placeholderItalic, '/')
        .replaceAll("\n", "<br/>");

    return output;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColorPalette.primaryMaroon,
              secondary: AppColorPalette.secondaryMaroon,
              surface: AppColorPalette.warmBeige,
            ),
      ),
      child: Scaffold(
        backgroundColor: AppColorPalette.warmBeige,
        appBar: CustomModernAppBar(
          title: "Kebijakan Privasi",
          icon: Icons.privacy_tip_outlined,
          fabAnimationController: _fabAnimationController,
          primaryColor: _maroonPrimary,
          lightColor: _maroonLight,
          onBackPressed: () => Get.back(),
          height: 80,
        ),
        body: Stack(
          children: [
            // Animated Background Pattern
            AnimatedPositioned(
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height,
              child: AnimatedOpacity(
                duration: const Duration(seconds: 1),
                opacity: 0.1,
                child: CustomPaint(
                  painter: BackgroundPainter(
                    color: AppColorPalette.primaryMaroon,
                  ),
                ),
              ),
            ),
            // Main Content
            BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, state) {
                return SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(
                    top: 20, // Reduced padding since we have the app bar
                  ),
                  child: Column(
                    children: [
                      // Hero Section
                      FadeInDown(
                        duration: const Duration(milliseconds: 800),
                        child: _buildHeroSection(),
                      ),

                      // Privacy Features Section
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _buildFeatureCard(
                                icon: Icons.security,
                                title: "Keamanan Data",
                                description: "Data Anda selalu aman",
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFeatureCard(
                                icon: Icons.lock,
                                title: "Privasi",
                                description: "Terjamin 100%",
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Main Content
                      if (state is SettingsSuccess)
                        FadeInUp(
                          duration: const Duration(milliseconds: 800),
                          child:
                              _buildContentSection(parseCustomHtml(state.data)),
                        )
                      else if (state is SettingsFailure)
                        CustomErrorWidget(
                          message: ErrorMessageUtils.getReadableErrorMessage(
                              state.errorMessage),
                          onRetry: () {
                            context
                                .read<SettingsCubit>()
                                .getSettings("privacy_policy");
                          },
                          primaryColor: _maroonPrimary,
                        )
                      else if (state is SettingsProgress)
                        const Center(
                          child: CustomCircularProgressIndicator(),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColorPalette.primaryMaroon,
                  AppColorPalette.secondaryMaroon,
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColorPalette.primaryMaroon.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -50,
                  bottom: -50,
                  child: Icon(
                    Icons.security,
                    size: 200,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.privacy_tip,
                        size: 40,
                        color: AppColorPalette.primaryMaroon,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Kebijakan Privasi",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Kami menghargai privasi Anda dan berkomitmen untuk melindungi informasi pribadi Anda",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Container(
        height: 180, // Further increased from 175 to 180 to fit all text
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColorPalette.primaryMaroon.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 36,
              color: AppColorPalette.primaryMaroon,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColorPalette.primaryMaroon,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(String content) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColorPalette.primaryMaroon.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: HtmlWidget(
        content,
        customStylesBuilder: (element) {
          if (element.localName == 'p') {
            return {
              'font-family': 'Poppins',
              'font-size': '16px',
              'line-height': '1.8',
              'color': '#333333',
              'margin': '16px 0',
            };
          }
          if (element.localName == 'h1' ||
              element.localName == 'h2' ||
              element.localName == 'h3') {
            return {
              'font-family': 'Poppins',
              'color': AppColorPalette.primaryMaroon.toString(),
              'margin': '24px 0 16px 0',
            };
          }
          return null;
        },
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.black87,
          height: 1.8,
        ),
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final Color color;

  BackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var i = 0; i < size.width; i += 20) {
      for (var j = 0; j < size.height; j += 20) {
        canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => false;
}
