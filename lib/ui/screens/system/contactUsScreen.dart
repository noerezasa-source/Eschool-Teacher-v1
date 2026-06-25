import 'dart:math';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/services.dart';
import 'package:eschool_saas_staff/cubits/settings/settingCubit.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  static Widget getRouteInstance() {
    //final arguments = Get.arguments as Map<String,dynamic>;
    return BlocProvider(
      create: (context) => SettingsCubit(),
      child: const ContactUsScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen>
    with TickerProviderStateMixin {
  // Changed from SingleTickerProviderStateMixin to TickerProviderStateMixin  late AnimationController _controller;
  late AnimationController _fabAnimationController;
  final ScrollController _scrollController = ScrollController();
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;
  Color get _maroonLight => AppColorPalette.secondaryMaroon;
  String? cachedData;
  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_scrollListener);
    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    context.read<SettingsCubit>().getSettings("contact_us");
    _loadCachedData();
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
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  String generateRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  String parseCustomHtml(String input) {
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

  Future<void> _loadCachedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cachedData = prefs.getString("contact_us");
    });
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorPalette.warmBeige,
      appBar: CustomModernAppBar(
        title: Utils.getTranslatedLabel(contactUsKey),
        icon: Icons.contact_support_outlined,
        fabAnimationController: _fabAnimationController,
        primaryColor: _maroonPrimary,
        lightColor: _maroonLight,
        onBackPressed: () => Get.back(),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return Stack(
            children: [
              // Animated Background Pattern
              AnimatedPositioned(
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height,
                child: CustomPaint(
                  painter: BackgroundPainter(
                    color: AppColorPalette.lightMaroon.withValues(alpha: 0.1),
                  ),
                ),
              ),

              // Main Content with Animation
              SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(
                  top: 20,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildHeaderCard(),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: state is SettingsProgress
                          ? const Center(
                              child: CustomCircularProgressIndicator())
                          : state is SettingsFailure
                              ? CustomErrorWidget(
                                  message:
                                      ErrorMessageUtils.getReadableErrorMessage(
                                          state.errorMessage),
                                  onRetry: () {
                                    context
                                        .read<SettingsCubit>()
                                        .getSettings("contact_us");
                                  },
                                  primaryColor: _maroonPrimary,
                                )
                              : Column(
                                  children: [
                                    if (state is SettingsSuccess) ...[
                                      // Parse the state data into sections
                                      ...(() {
                                        final data =
                                            parseCustomHtml(state.data);
                                        RegExp emailRegex = RegExp(
                                            r'([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})');
                                        RegExp phoneRegex =
                                            RegExp(r'(\+?[\d\s-]{10,})');
                                        RegExp addressRegex = RegExp(
                                            r'(?:alamat|lokasi|address)[:\s]*(.*?)(?=\n\n|\n(?:[a-z]+[:\s]|$)|$)',
                                            caseSensitive: false,
                                            multiLine: true);

                                        String? email = emailRegex
                                            .firstMatch(data)
                                            ?.group(1);
                                        String? phone = phoneRegex
                                            .firstMatch(data)
                                            ?.group(1);
                                        String? address = addressRegex
                                            .firstMatch(data)
                                            ?.group(1)
                                            ?.trim();

                                        return [
                                          if (email != null)
                                            _buildContactCard(
                                              Icons.email_rounded,
                                              'Kirim Email',
                                              email.trim(),
                                            ),
                                          if (phone != null)
                                            _buildContactCard(
                                              Icons.phone_rounded,
                                              'Hubungi Kami',
                                              phone.trim(),
                                            ),
                                          if (address != null)
                                            _buildContactCard(
                                              Icons.location_on_rounded,
                                              'Kunjungi Kami',
                                              address.trim(),
                                            ),
                                        ];
                                      })(),
                                    ],
                                  ],
                                ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColorPalette.primaryMaroon,
            AppColorPalette.secondaryMaroon,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColorPalette.primaryMaroon.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  'Bagaimana kami dapat membantu Anda?',
                  textStyle: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  speed: const Duration(milliseconds: 100),
                ),
              ],
              totalRepeatCount: 1,
            ),
            const SizedBox(height: 16),
            Text(
              'Kami siap membantu Anda dengan segala pertanyaan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColorPalette.lightMaroon,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(IconData icon, String title, String content) {
    void handleTap() async {
      HapticFeedback.lightImpact();
      String urlString = '';
      switch (icon) {
        case Icons.email_rounded:
          urlString = 'mailto:$content';
          break;
        case Icons.phone_rounded:
          urlString = 'tel:$content';
          break;
        case Icons.location_on_rounded:
          urlString =
              'https://maps.google.com/?q=${Uri.encodeComponent(content)}';
          break;
      }
      if (urlString.isNotEmpty) {
        try {
          await _launchUrl(urlString);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tidak dapat membuka $title')),
            );
          }
        }
      }
    }

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0.95, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColorPalette.primaryMaroon.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: handleTap,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColorPalette.accentPink.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          icon,
                          color: AppColorPalette.primaryMaroon,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColorPalette.primaryMaroon,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              content,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: AppColorPalette.secondaryMaroon,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColorPalette.primaryMaroon.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.7,
      size.width * 0.5,
      size.height * 0.8,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.9,
      size.width,
      size.height * 0.8,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
