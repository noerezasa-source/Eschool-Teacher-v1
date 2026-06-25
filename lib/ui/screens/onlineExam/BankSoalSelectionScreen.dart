import 'dart:math' as math;
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/data/models/exam/BankOnlineQuestion.dart';
import 'package:eschool_saas_staff/cubits/questionOnlineExam/questionOnlineExamCubit.dart';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:get/get.dart' as getx;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';

class LightRaysPainter extends CustomPainter {
  final Color color;

  LightRaysPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    const rays = 12;
    final maxLength = size.width > size.height ? size.width : size.height;

    for (int i = 0; i < rays; i++) {
      final angle = (i * 2 * math.pi / rays);
      final x = math.cos(angle) * maxLength;
      final y = math.sin(angle) * maxLength;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + x * 0.2, center.dy + y * 0.2)
        ..lineTo(center.dx + x, center.dy + y)
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class BankSoalSelectionScreen extends StatefulWidget {
  final int examId;

  const BankSoalSelectionScreen({
    super.key,
    required this.examId,
  });

  @override
  State<BankSoalSelectionScreen> createState() =>
      _BankSoalSelectionScreenState();
}

class _BankSoalSelectionScreenState extends State<BankSoalSelectionScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<BankSoalQuestion> _filteredBanks = [];
  bool _showSearch = false;
  int _hoveredCardIndex = -1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: const SizedBox.shrink(),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.of(context).padding.top + 80),
        child: CustomModernAppBar(
          title: 'Bank Soal',
          icon: Icons.auto_stories_rounded,
          fabAnimationController: _breathingController,
          primaryColor: _primaryColor,
          lightColor: _accentColor,
          onBackPressed: () => Navigator.of(context).pop(),
          showFilterButton: false,
          height: 80,
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: BlocBuilder<QuestionOnlineExamCubit, QuestionOnlineExamState>(
          builder: (context, state) {
            return Column(
              children: [
                SizedBox(
                    height: MediaQuery.of(context).padding.top +
                        10), // Further reduced padding for AppBar
                if (state is QuestionBanksLoaded && _showSearch)
                  _buildSearchBar(state.banks),
                Expanded(
                  child: _buildContentArea(state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  late AnimationController _backgroundAnimationController;
  late AnimationController _waveAnimationController;
  late AnimationController _floatingIconsController;
  late AnimationController _cardHoverController;
  late AnimationController _breathingController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _loadingController;
  late AnimationController _tabTransitionController;
  late AnimationController _searchExpandController;

  late Animation<double> _pulseAnimation;
  static Color get _primaryColor => AppColorPalette.primaryMaroon;
  static Color get _accentColor => AppColorPalette.secondaryMaroon;
  static Color get _highlightColor => AppColorPalette.secondaryMaroon;
  final List<Color> _cardGradients = [
    const Color(0xFF7A2828),
    AppColorPalette.secondaryMaroon,
    AppColorPalette.secondaryMaroon,
    AppColorPalette.secondaryMaroon,
    const Color(0xFFC65454),
    const Color(0xFFAA3939),
    const Color(0xFF8F2D2D),
    const Color(0xFFB14040),
  ];
  @override
  void initState() {
    super.initState();
    context.read<QuestionOnlineExamCubit>().getBankSoal(widget.examId);

    _backgroundAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 30000))
      ..repeat();
    _waveAnimationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 7000))
          ..repeat();
    _floatingIconsController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
          ..repeat(reverse: true);
    _cardHoverController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _breathingController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
          ..repeat(reverse: true);
    _rotationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 10000))
      ..repeat();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
          ..repeat(reverse: true);
    _loadingController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
          ..repeat();
    _tabTransitionController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _searchExpandController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _pulseAnimation =
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Fix untuk menghilangkan warna maroon di bagian bawah layar
    // Set system navigation bar menjadi putih, bukan maroon
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _backgroundAnimationController.dispose();
    _waveAnimationController.dispose();
    _floatingIconsController.dispose();
    _cardHoverController.dispose();
    _breathingController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _loadingController.dispose();
    _tabTransitionController.dispose();
    _searchExpandController.dispose();
    // Reset system UI overlay style to default untuk mencegah warna maroon
    // mengikuti ke halaman lain
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    super.dispose();
  }

  void _filterBanks(String query, List<BankSoalQuestion> banks) {
    setState(() {
      if (query.isEmpty) {
        _filteredBanks = banks;
      } else {
        _filteredBanks = banks
            .where(
                (bank) => bank.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
        if (_filteredBanks.isNotEmpty) HapticFeedback.selectionClick();
      }
    });
  }

  Widget _buildSearchBar(List<BankSoalQuestion> banks) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: _highlightColor.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: _accentColor.withValues(alpha: 0.2),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 5))
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (query) => _filterBanks(query, banks),
          style: TextStyle(color: _primaryColor),
          decoration: InputDecoration(
            hintText: 'Cari bank soal...',
            hintStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: Icon(Icons.search, color: _primaryColor),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(
        begin: -0.2, end: 0, duration: 800.ms, curve: Curves.easeOutQuad);
  }

  Widget _buildContentArea(QuestionOnlineExamState state) {
    if (state is QuestionBanksLoading) return _buildLoadingView();
    if (state is QuestionBanksLoaded) {
      _showSearch = false; // Remove filter functionality
      if (_searchController.text.isEmpty) {
        _filteredBanks = state.banks;
      } else {
        _filteredBanks = state.banks
            .where((bank) => bank.name
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();
      }
      if (state.banks.isEmpty) {
        return _buildEmptyView("Tidak ada bank soal yang tersedia",
            "Silakan tambahkan bank soal baru.");
      }
      return Column(
          children: [Expanded(child: _buildBankList(_filteredBanks))]);
    }
    if (state is QuestionOnlineExamFailure) {
      return Center(
        child: CustomErrorWidget(
          message: "Tidak dapat memuat bank soal. Silakan coba lagi.",
          onRetry: () => context
              .read<QuestionOnlineExamCubit>()
              .getBankSoal(widget.examId),
          primaryColor: _primaryColor,
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildLoadingView() {
    return const SkeletonBankSoalSelectionScreen(
      itemCount: 6,
      showSearch: false,
    );
  }

  Widget _buildEmptyView(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: _accentColor.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: _accentColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildBankList(List<BankSoalQuestion> banks) {
    if (banks.isEmpty && _searchController.text.isNotEmpty) {
      return _buildEmptyView(
        "Tidak ada bank soal yang cocok",
        "Coba gunakan kata kunci lain untuk pencarian.",
      );
    }
    return Stack(children: [
      ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        physics: const BouncingScrollPhysics(),
        itemCount: banks.length,
        itemBuilder: (context, index) {
          final bank = banks[index];
          final Color cardBaseColor =
              _cardGradients[index % _cardGradients.length];
          final neonGlowColor = HSLColor.fromColor(cardBaseColor)
              .withLightness(0.7)
              .withSaturation(0.9)
              .toColor();
          final bool isHovered = _hoveredCardIndex == index;

          return GestureDetector(
            onTap: () => navigateToPreview(bank),
            onTapDown: (_) {
              setState(() => _hoveredCardIndex = index);
              HapticFeedback.selectionClick();
            },
            onTapCancel: () => setState(() => _hoveredCardIndex = -1),
            onTapUp: (_) => Future.delayed(const Duration(milliseconds: 300),
                () => mounted ? setState(() => _hoveredCardIndex = -1) : null),
            child: Transform.translate(
              offset: Offset(0, isHovered ? -5 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(bottom: 24),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            cardBaseColor.withValues(alpha: isHovered ? 1.0 : 0.85),
                            HSLColor.fromColor(cardBaseColor)
                                .withLightness(HSLColor.fromColor(cardBaseColor)
                                        .lightness *
                                    0.7)
                                .toColor()
                                .withValues(alpha: isHovered ? 0.95 : 0.8),
                          ],
                          stops: const [0.3, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                              color: neonGlowColor
                                  .withValues(alpha: isHovered ? 0.35 : 0.15),
                              blurRadius: isHovered ? 25 : 15,
                              spreadRadius: isHovered ? 2 : 0),
                          BoxShadow(
                              color: cardBaseColor.withValues(alpha: 0.5),
                              blurRadius: 15,
                              spreadRadius: -3,
                              offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ShaderMask(
                                      blendMode: BlendMode.srcIn,
                                      shaderCallback: (bounds) =>
                                          LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withValues(alpha: 1.0),
                                          Colors.white.withValues(alpha: 0.9),
                                          Colors.white.withValues(alpha: 1.0)
                                        ],
                                      ).createShader(bounds),
                                      child: Text(
                                        bank.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          height: 1.2,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                          shadows: [
                                            Shadow(
                                                color: Colors.black26,
                                                blurRadius: 3,
                                                offset: Offset(1, 1))
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 400),
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      height: 2,
                                      width: isHovered ? 180 : 80,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Colors.white.withValues(alpha: 0.8),
                                            Colors.white.withValues(alpha: 0.2)
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                            color:
                                                Colors.white.withValues(alpha: 0.2),
                                            width: 1),
                                        boxShadow: const [
                                          BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 8,
                                              spreadRadius: 0)
                                        ],
                                      ),
                                      child: Text(
                                        '${bank.soal.length} Soal',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: isHovered ? 50 : 45,
                                height: isHovered ? 50 : 45,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isHovered
                                        ? [
                                            Colors.white.withValues(alpha: 0.3),
                                            Colors.white.withValues(alpha: 0.1)
                                          ]
                                        : [
                                            Colors.white.withValues(alpha: 0.2),
                                            Colors.white.withValues(alpha: 0.05)
                                          ],
                                  ),
                                  boxShadow: isHovered
                                      ? [
                                          BoxShadow(
                                              color: neonGlowColor
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 15,
                                              spreadRadius: 1)
                                        ]
                                      : [],
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 1),
                                ),
                                child: AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: isHovered ? 0.1 : 0,
                                      child: Transform.scale(
                                        scale: isHovered
                                            ? 1.0 + 0.15 * _pulseAnimation.value
                                            : 1.0,
                                        child: Icon(Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: isHovered ? 25 : 22),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 20,
                      top: -10,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: neonGlowColor.withValues(alpha: 0.1)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ]);
  }

  void navigateToPreview(BankSoalQuestion bank) {
    debugPrint('Navigating to preview with:');
    debugPrint('Bank ID: ${bank.id}');
    debugPrint('Exam ID: ${widget.examId}');
    debugPrint('Class Section ID: ${bank.classSectionId}');
    debugPrint('Class Subject ID: ${bank.classSubjectId}');

    // Removed the strict check for classSectionId and classSubjectId because 
    // global bank soals might not be tied to a specific class section.

    getx.Get.toNamed(Routes.previewQuestionBank, arguments: {
      'bank': bank,
      'examId': widget.examId,
      'classSectionId': bank.classSectionId,
      'classSubjectId': bank.classSubjectId
    });
  }
}
