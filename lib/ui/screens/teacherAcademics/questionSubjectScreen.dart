import 'dart:math' as math;
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:lottie/lottie.dart';
import '../../../cubits/teacherAcademics/assignment/questionBankCubit.dart';
import '../../../data/models/exam/subjectQuestion.dart';
import '../../../ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/no_search_results_widget.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';

class QuestionSubjectController extends GetxController {
  final BuildContext context;
  final bool isStaffView;

  QuestionSubjectController(this.context, this.isStaffView);

  @override
  void onInit() {
    super.onInit();
    _reloadData();
  }

  @override
  void onReady() {
    super.onReady();
    _reloadData();
  }

  void _reloadData() {
    debugPrint("Reloading QuestionSubjectScreen");
    context
        .read<QuestionBankCubit>()
        .fetchTeacherSubjects(isStaffView: isStaffView);
  }
}

// Light rays painter
class LightRaysPainter extends CustomPainter {
  final Color color;

  LightRaysPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw multiple rays from center
    final center = Offset(size.width / 2, size.height / 2);
    const rays = 12; // Number of rays
    final maxLength = size.width > size.height ? size.width : size.height;

    for (int i = 0; i < rays; i++) {
      final angle = (i * 2 * math.pi / rays);
      final x = math.cos(angle) * maxLength;
      final y = math.sin(angle) * maxLength;

      // Draw triangular ray
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

class QuestionSubjectScreen extends StatefulWidget {
  final bool isStaffView;

  const QuestionSubjectScreen({
    super.key,
    this.isStaffView = false,
  });

  @override
  State<QuestionSubjectScreen> createState() => _QuestionSubjectScreenState();
}

class _QuestionSubjectScreenState extends State<QuestionSubjectScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _floatingIconsController;
  late AnimationController _cardHoverController;
  late AnimationController _pulseController;
  late AnimationController _loadingController;
  late AnimationController _tabTransitionController;

  // Animations
  late Animation<double> _backgroundAnimation;
  late Animation<double> _pulseAnimation;

  int _hoveredCardIndex = -1;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  List<SubjectQuestion> _filteredSubjects = [];

  // // Particles
  // final List<ParticleModel> _particles = [];

  // Theme colors - Softer Maroon palette
  static Color get _primaryColor =>
      AppColorPalette.primaryMaroon; // Softer deep maroon (was 0xFF4A0000)
  static Color get _accentColor =>
      AppColorPalette.secondaryMaroon; // Softer medium maroon (was 0xFF800000)
  static Color get _highlightColor =>
      AppColorPalette.secondaryMaroon; // Softer bright maroon (was 0xFFA52A2A)
  static Color get _energyColor =>
      AppColorPalette.lightMaroon; // Softer light maroon (was 0xFFC13E3E)
  static Color get _glowColor =>
      AppColorPalette.secondaryMaroon; // Softer rich maroon (was 0xFF9E2A2A)

  final List<Color> _cardGradients = [
    const Color(0xFF7A2828), // Softer dark maroon (was 0xFF5D0000)
    AppColorPalette.secondaryMaroon, // Softer classic maroon (was 0xFF800000)
    AppColorPalette.secondaryMaroon, // Softer rich maroon (was 0xFF9E2A2A)
    AppColorPalette.secondaryMaroon, // Softer brown-maroon (was 0xFFA52A2A)
    const Color(0xFFC65454), // Softer firebrick (was 0xFFB22222)
    const Color(0xFFAA3939), // Softer dark red (was 0xFF8B0000)
    const Color(0xFF8F2D2D), // Softer deep maroon (was 0xFF700000)
    const Color(0xFFB14040), // Softer bright maroon (was 0xFF940000)
  ];

  @override
  void initState() {
    super.initState();
    Get.put(QuestionSubjectController(context, widget.isStaffView));

    // Setup animation controllers
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 30000),
    )..repeat();

    _floatingIconsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _cardHoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _tabTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Setup animations
    _backgroundAnimation = CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.linear,
    );

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    // // Initialize particles with enhanced properties
    // _initializeParticles();

    _reloadData();

    // Add device orientation listener for responsive design
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Set system UI style for immersive experience
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _primaryColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _floatingIconsController.dispose();
    _cardHoverController.dispose();
    _pulseController.dispose();
    _loadingController.dispose();
    _tabTransitionController.dispose();
    _searchController.dispose();
    Get.delete<QuestionSubjectController>();
    super.dispose();
  }

  void _reloadData() {
    context
        .read<QuestionBankCubit>()
        .fetchTeacherSubjects(isStaffView: widget.isStaffView);
  }

  void _filterSubjects(String query, List<SubjectQuestion> subjects) {
    debugPrint(
        '_filterSubjects called with query: "$query", total subjects: ${subjects.length}');

    // Defer setState to avoid calling it during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        if (query.isEmpty) {
          _filteredSubjects = List.from(subjects);
          debugPrint(
              'Query empty, showing all ${_filteredSubjects.length} subjects');
        } else {
          _filteredSubjects = subjects.where((subject) {
            final subjectNameMatch = subject.subject.name
                .toLowerCase()
                .contains(query.toLowerCase());
            // Subject does not have a 'code' getter; use the combined display name instead
            final subjectCombinedMatch = subject.subjectWithName
                .toLowerCase()
                .contains(query.toLowerCase());

            final isMatch = subjectNameMatch || subjectCombinedMatch;

            return isMatch;
          }).toList();

          // Debug: Print hasil filter
          debugPrint(
              'Search query: "$query", Found: ${_filteredSubjects.length} results from ${subjects.length} total subjects');
        }
      });
    });
  }

  void _clearSearch(List<SubjectQuestion> subjects) {
    // Defer setState to avoid calling it during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _searchController.clear();
        _filteredSubjects = List.from(subjects);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        appBar: CustomModernAppBar(
          title: 'Bank Soal',
          icon: Icons.book,
          fabAnimationController: _pulseController,
          primaryColor: _primaryColor,
          lightColor: _energyColor,
          onBackPressed: () => Navigator.pop(context),
        ),
        body: BlocBuilder<QuestionBankCubit, QuestionBankState>(
          builder: (context, state) {
            return Container(
              color: Colors.white,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  return false;
                },
                child: Column(
                  children: [
                    // Leave space for the app bar
                    const SizedBox(height: 90),

                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.95),
                              const Color(0xFFFFF0F0),
                            ],
                          ),
                          borderRadius: BorderRadius.zero,
                          boxShadow: [
                            BoxShadow(
                              color: _glowColor.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                              offset: const Offset(0, -5),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 30,
                              offset: const Offset(0, -10),
                            ),
                          ],
                        ),
                        child: _buildContentArea(state),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContentArea(QuestionBankState state) {
    if (state is QuestionBankLoading) {
      return _buildLoadingView();
    }

    if (state is SubjectsFetchSuccess) {
      return _buildSubjectsList(state.subjects);
    }

    if (state is QuestionBankError) {
      return _buildErrorView(state.message);
    }

    return const SizedBox();
  }

  Widget _buildLoadingView() {
    return const SkeletonQuestionSubjectScreen(
      itemCount: 6,
      showSearch: true,
    );
  }

  Widget _buildErrorView(String message) {
    return CustomErrorWidget(
      message: message,
      onRetry: () {
        Get.delete<QuestionSubjectController>();
        context
            .read<QuestionBankCubit>()
            .fetchTeacherSubjects(isStaffView: widget.isStaffView);
      },
      retryButtonText: "Coba Lagi",
      primaryColor: _accentColor,
      title:
          "Tidak dapat terhubung ke server, mohon periksa koneksi internet Anda dan coba lagi.",
    );
  }

  Widget _buildEmptyView() {
    return FadeIn(
      duration: const Duration(milliseconds: 800),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.network(
                'https://assets9.lottiefiles.com/packages/lf20_yuiimsha.json',
                width: 180,
                height: 180,
              ),
              const SizedBox(height: 20),
              Text(
                'Belum ada mata pelajaran',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _accentColor, // Using maroon instead of purple
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsWidget() {
    return NoSearchResultsWidget(
      searchQuery: _searchController.text,
      onClearSearch: () {
        // Defer setState to avoid calling it during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _searchController.clear();
            _filteredSubjects = [];
          });
        });
      },
      primaryColor: _primaryColor,
      accentColor: _highlightColor,
      title: 'Tidak Ada Mata Pelajaran',
      description:
          'Tidak ditemukan mata pelajaran yang sesuai dengan pencarian Anda. Coba gunakan kata kunci yang berbeda.',
      clearButtonText: 'Hapus Pencarian',
      icon: Icons.subject_outlined,
    );
  }

  Widget _buildSubjectsList(List<SubjectQuestion> subjects) {
    if (subjects.isEmpty) {
      return _buildEmptyView();
    }

    // Determine if search should be shown (more than 5 subjects)
    final bool shouldShowSearch = subjects.length > 5;

    // Update filtered subjects only if search is not active or if subjects changed
    if (_searchController.text.isEmpty) {
      _filteredSubjects = List.from(subjects);
    } else if (_filteredSubjects.isEmpty ||
        _filteredSubjects.length > subjects.length) {
      // Re-filter if subjects list changed
      _filterSubjects(_searchController.text, subjects);
    }

    // Use filtered subjects if search is active, otherwise use all subjects
    final displaySubjects =
        _searchController.text.isNotEmpty ? _filteredSubjects : subjects;

    return Column(children: [
      // Search bar if needed
      if (shouldShowSearch)
        FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 25, 20, 20),
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari mata pelajaran...',
                prefixIcon: Icon(Icons.search, color: _primaryColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: _primaryColor),
                        onPressed: () {
                          _clearSearch(subjects);
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              onChanged: (value) {
                _filterSubjects(value, subjects);
              },
            ),
          ),
        ),

      // Subjects list
      Expanded(
        child: Stack(
          children: [
            // Show no search results if search is active and no results found
            if (_searchController.text.isNotEmpty && _filteredSubjects.isEmpty)
              _buildNoSearchResultsWidget(),

            // Subjects list
            if (_searchController.text.isEmpty || _filteredSubjects.isNotEmpty)
              Positioned.fill(
                child: Stack(
                  children: [
                    // Holographic background effect
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _backgroundAnimationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _backgroundAnimation.value * 0.05,
                            child: ShaderMask(
                              blendMode: BlendMode.srcATop,
                              shaderCallback: (bounds) => RadialGradient(
                                center: Alignment(
                                  math.sin(_backgroundAnimation.value *
                                          math.pi *
                                          2) *
                                      0.5,
                                  math.cos(_backgroundAnimation.value *
                                          math.pi *
                                          2) *
                                      0.5,
                                ),
                                colors: [
                                  Colors.transparent,
                                  _highlightColor.withValues(alpha: 0.01),
                                  _accentColor.withValues(alpha: 0.02),
                                  Colors.transparent,
                                ],
                                radius: 1.0,
                              ).createShader(bounds),
                              child: Container(
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Interactive card list with 3D effects
                    ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                          20, shouldShowSearch ? 15 : 25, 20, 100),
                      physics: const BouncingScrollPhysics(),
                      itemCount: displaySubjects.length,
                      itemBuilder: (context, index) {
                        final subject = displaySubjects[index];
                        final Color cardBaseColor =
                            _cardGradients[index % _cardGradients.length];
                        // Generate subject-specific neon colors for glow effects
                        final neonGlowColor = HSLColor.fromColor(cardBaseColor)
                            .withLightness(0.7)
                            .withSaturation(0.9)
                            .toColor();

                        final bool isHovered = _hoveredCardIndex == index;

                        return GestureDetector(
                          onTap: () async {
                            // Add spectacular tap effect
                            setState(() {
                              _hoveredCardIndex = index;
                            });

                            // Elaborate haptic pattern
                            HapticFeedback.mediumImpact();
                            await Future.delayed(
                                const Duration(milliseconds: 50));
                            HapticFeedback.lightImpact();

                            // Exaggerated scale animation on tap
                            _cardHoverController.forward().then((_) {
                              _cardHoverController.reverse();
                            });

                            try {
                              await Get.toNamed(Routes.questionBankScreen,
                                  arguments: subject);
                              _reloadData();
                            } catch (e, stacktrace) {
                              debugPrint("Navigation error: $e");
                              debugPrint(stacktrace.toString());
                              Get.snackbar(
                                'Error Navigasi',
                                e.toString(),
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                                duration: const Duration(seconds: 5),
                              );
                            }
                          },
                          onTapDown: (_) {
                            setState(() {
                              _hoveredCardIndex = index;
                            });
                            HapticFeedback.selectionClick();
                          },
                          onTapCancel: () {
                            setState(() {
                              _hoveredCardIndex = -1;
                            });
                          },
                          onTapUp: (_) {
                            Future.delayed(const Duration(milliseconds: 300),
                                () {
                              if (mounted) {
                                setState(() {
                                  _hoveredCardIndex = -1;
                                });
                              }
                            });
                          },
                          child: Transform.translate(
                            offset:
                                Offset(0, index == _hoveredCardIndex ? -5 : 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.only(bottom: 24),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // 3D Card Background with "holographic" effect
                                  Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.001) // Perspective
                                      ..rotateX(isHovered ? 0.05 : 0.0)
                                      ..rotateY(isHovered ? -0.05 : 0.0),
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            cardBaseColor.withValues(
                                                alpha: isHovered ? 1.0 : 0.85),
                                            HSLColor.fromColor(cardBaseColor)
                                                .withLightness(
                                                  HSLColor.fromColor(
                                                              cardBaseColor)
                                                          .lightness *
                                                      0.7,
                                                )
                                                .toColor()
                                                .withValues(
                                                    alpha:
                                                        isHovered ? 0.95 : 0.8),
                                          ],
                                          stops: const [0.3, 1.0],
                                        ),
                                        borderRadius: BorderRadius.circular(28),
                                        boxShadow: [
                                          // Outer glow shadow
                                          BoxShadow(
                                            color: neonGlowColor.withValues(
                                                alpha: isHovered ? 0.35 : 0.15),
                                            blurRadius: isHovered ? 25 : 15,
                                            spreadRadius: isHovered ? 2 : 0,
                                          ),
                                          // Inner depth shadow
                                          BoxShadow(
                                            color: cardBaseColor.withValues(
                                                alpha: 0.5),
                                            blurRadius: 15,
                                            spreadRadius: -3,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          // Holographic overlay

                                          // Content layout
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Subject text & details with advanced effects
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        // Elaborated subject title with glow
                                                        ShaderMask(
                                                          blendMode:
                                                              BlendMode.srcIn,
                                                          shaderCallback:
                                                              (bounds) =>
                                                                  LinearGradient(
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight,
                                                            colors: [
                                                              Colors.white
                                                                  .withValues(
                                                                      alpha:
                                                                          1.0),
                                                              Colors.white
                                                                  .withValues(
                                                                      alpha:
                                                                          0.9),
                                                              Colors.white
                                                                  .withValues(
                                                                      alpha:
                                                                          1.0),
                                                            ],
                                                          ).createShader(
                                                                      bounds),
                                                          child: Text(
                                                            subject
                                                                .subjectWithName,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 20,
                                                              height: 1.2,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              letterSpacing:
                                                                  0.5,
                                                              shadows: [
                                                                Shadow(
                                                                  color: Colors
                                                                      .black26,
                                                                  blurRadius: 3,
                                                                  offset:
                                                                      Offset(
                                                                          1, 1),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),

                                                        const SizedBox(
                                                            height: 4),

                                                        // Divider with animation
                                                        AnimatedContainer(
                                                          duration:
                                                              const Duration(
                                                                  milliseconds:
                                                                      400),
                                                          margin:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 8),
                                                          height: 2,
                                                          width: isHovered
                                                              ? 180
                                                              : 80,
                                                          decoration:
                                                              BoxDecoration(
                                                            gradient:
                                                                LinearGradient(
                                                              begin: Alignment
                                                                  .centerLeft,
                                                              end: Alignment
                                                                  .centerRight,
                                                              colors: [
                                                                Colors.white
                                                                    .withValues(
                                                                        alpha:
                                                                            0.8),
                                                                Colors.white
                                                                    .withValues(
                                                                        alpha:
                                                                            0.2),
                                                              ],
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        2),
                                                          ),
                                                        ),

                                                        const SizedBox(
                                                            height: 4),

                                                        // Question count chip with advanced styling
                                                        Row(
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          7),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .white
                                                                    .withValues(
                                                                        alpha:
                                                                            0.15),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            30),
                                                                border:
                                                                    Border.all(
                                                                  color: Colors
                                                                      .white
                                                                      .withValues(
                                                                          alpha:
                                                                              0.2),
                                                                  width: 1,
                                                                ),
                                                                boxShadow: const [
                                                                  BoxShadow(
                                                                    color: Colors
                                                                        .black12,
                                                                    blurRadius:
                                                                        8,
                                                                    spreadRadius:
                                                                        0,
                                                                  ),
                                                                ],
                                                              ),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Text(
                                                                    '${subject.bankSoalCount} Bank Soal',
                                                                    style:
                                                                        const TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  // Arrow button with animations and effects
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 300),
                                                    width: isHovered ? 50 : 45,
                                                    height: isHovered ? 50 : 45,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                        colors: isHovered
                                                            ? [
                                                                Colors.white
                                                                    .withValues(
                                                                        alpha:
                                                                            0.3),
                                                                Colors.white
                                                                    .withValues(
                                                                        alpha:
                                                                            0.1)
                                                              ]
                                                            : [
                                                                Colors.white
                                                                    .withValues(
                                                                        alpha:
                                                                            0.2),
                                                                Colors.white
                                                                    .withValues(
                                                                        alpha:
                                                                            0.05)
                                                              ],
                                                      ),
                                                      boxShadow: isHovered
                                                          ? [
                                                              BoxShadow(
                                                                color: neonGlowColor
                                                                    .withValues(
                                                                        alpha:
                                                                            0.4),
                                                                blurRadius: 15,
                                                                spreadRadius: 1,
                                                              ),
                                                            ]
                                                          : [],
                                                      border: Border.all(
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.3),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: AnimatedBuilder(
                                                      animation:
                                                          _pulseAnimation,
                                                      builder:
                                                          (context, child) {
                                                        return Transform.rotate(
                                                          angle: isHovered
                                                              ? 0.1
                                                              : 0,
                                                          child:
                                                              Transform.scale(
                                                            scale: isHovered
                                                                ? 1.0 +
                                                                    0.15 *
                                                                        _pulseAnimation
                                                                            .value
                                                                : 1.0,
                                                            child: Icon(
                                                              Icons
                                                                  .arrow_forward_rounded,
                                                              color:
                                                                  Colors.white,
                                                              size: isHovered
                                                                  ? 25
                                                                  : 22,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Decorative elements
                                  Positioned(
                                    right: 20,
                                    top: -10,
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: neonGlowColor.withValues(
                                            alpha: 0.1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      )
    ]);
  }
}
