import 'dart:math' as math;
import 'package:eschool_saas_staff/ui/widgets/system/errorContainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/services.dart';
import 'package:eschool_saas_staff/app/routes.dart';
import '../../../cubits/teacherAcademics/assignment/questionBankCubit.dart';
import '../../../data/models/exam/questionBank.dart';
import '../../../data/models/exam/subjectQuestion.dart';
import 'package:eschool_saas_staff/data/repositories/exam/questionBankRepository.dart';
import '../../widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/no_search_results_widget.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';

// Controller GetX untuk lifecycle
class QuestionBankListController extends GetxController {
  final BuildContext context;
  final int subjectId;

  QuestionBankListController(this.context, this.subjectId);

  @override
  void onInit() {
    super.onInit();
    _reloadData();
  }

  @override
  void onReady() {
    super.onReady();
    _reloadData(); // Reload saat halaman siap
  }

  void _reloadData() {
    debugPrint("Reloading QuestionBankListScreen for subject ID: $subjectId");
    context.read<QuestionBankCubit>().fetchBankSoal(subjectId);
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

class QuestionBankListScreen extends StatefulWidget {
  final SubjectQuestion subject;

  static Widget getRouteInstance(SubjectQuestion subject) {
    return BlocProvider(
      create: (context) => QuestionBankCubit(
        repository: QuestionBankRepository(),
      )..fetchBankSoal(subject.subject.id),
      child: QuestionBankListScreen(subject: subject),
    );
  }

  const QuestionBankListScreen({super.key, required this.subject});

  @override
  State<QuestionBankListScreen> createState() => _QuestionBankListScreenState();
}

class _QuestionBankListScreenState extends State<QuestionBankListScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController(text: 'multiple_choice');
  final _defaultPointController = TextEditingController(text: '10');
  // Animation controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _waveAnimationController;
  late AnimationController _floatingIconsController;
  late AnimationController _cardHoverController;
  late AnimationController _breathingController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _loadingController;
  late AnimationController _tabTransitionController;
  // Animations
  late Animation<double> _backgroundAnimation;
  late Animation<double> _pulseAnimation;

  int _hoveredCardIndex = -1;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  List<BankSoal> _filteredBanks = [];

  // Particles
  // final List<ParticleModel> _particles = [];

  // Theme colors - Softer Maroon palette
  static Color get _primaryColor => AppColorPalette.primaryMaroon; // Softer deep maroon
  static Color get _accentColor => AppColorPalette.secondaryMaroon; // Softer medium maroon
  static Color get _highlightColor =>
      AppColorPalette.secondaryMaroon; // Softer bright maroon
  static Color get _glowColor => AppColorPalette.secondaryMaroon; // Softer rich maroon

  final List<Color> _cardGradients = [
    const Color(0xFF7A2828), // Softer dark maroon
    AppColorPalette.secondaryMaroon, // Softer classic maroon
    AppColorPalette.secondaryMaroon, // Softer rich maroon
    AppColorPalette.secondaryMaroon, // Softer brown-maroon
    const Color(0xFFC65454), // Softer firebrick
    const Color(0xFFAA3939), // Softer dark red
    const Color(0xFF8F2D2D), // Softer deep maroon
    const Color(0xFFB14040), // Softer bright maroon
  ];

  @override
  void initState() {
    super.initState();
    // Setup animation controllers
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 30000),
    )..repeat();

    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )..repeat();

    _floatingIconsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _cardHoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    )..repeat();

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

    // Delay to ensure animations look good on first load
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _defaultPointController.dispose();
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
    Get.delete<QuestionBankListController>();
    super.dispose();
  }

  void _reloadData() {
    debugPrint("Manual reload triggered for QuestionBankListScreen");
    context.read<QuestionBankCubit>().fetchBankSoal(widget.subject.subject.id);
  }

  void _filterBanks(String query, List<BankSoal> banks) {
    debugPrint(
        '_filterBanks called with query: "$query", total banks: ${banks.length}');

    // Defer setState to avoid calling it during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        if (query.isEmpty) {
          _filteredBanks = List.from(banks);
          debugPrint('Query empty, showing all ${_filteredBanks.length} banks');
        } else {
          _filteredBanks = banks.where((bank) {
            final bankNameMatch =
                bank.name.toLowerCase().contains(query.toLowerCase());

            return bankNameMatch;
          }).toList();

          // Debug: Print hasil filter
          debugPrint(
              'Search query: "$query", Found: ${_filteredBanks.length} results from ${banks.length} total banks');
        }
      });
    });
  }

  void _clearSearch(List<BankSoal> banks) {
    // Defer setState to avoid calling it during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _searchController.clear();
        _filteredBanks = List.from(banks);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: CustomModernAppBar(
          title: widget.subject.subject.name,
          icon: Icons.school_rounded,
          fabAnimationController: _breathingController,
          primaryColor: _primaryColor,
          lightColor: _accentColor,
          showAddButton: true,
          onAddPressed: () {
            HapticFeedback.mediumImpact();
            _showAddBankDialog();
          },
          onBackPressed: () => Navigator.of(context).pop(),
        ),
        body: BlocBuilder<QuestionBankCubit, QuestionBankState>(
          builder: (context, state) {
            return Stack(
              children: [
                // Animated background with advanced effects
                // Content with parallax scroll effect
                SafeArea(
                  top:
                      false, // Don't add padding at the top to allow white background to extend to status bar
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollUpdateNotification) {}
                      return false;
                    },
                    child: Column(
                      children: [
                        // Main content with container positioned below AppBar
                        Expanded(
                          child: Container(
                            // Add top margin to start content below the AppBar
                            margin:
                                const EdgeInsets.only(top: kToolbarHeight + 30),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.95),
                                  const Color(0xFFFFF0F0),
                                ],
                              ),
                              // Add top border radius for a nice curve
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
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
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                              child: Column(
                                children: [
                                  // No need for additional padding since we have an AppBar now

                                  // Content area takes remaining space
                                  Expanded(
                                    child: _buildContentArea(state),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

    if (state is BankSoalFetchSuccess) {
      // Tampilkan pesan kosong hanya jika benar-benar tidak ada bank soal
      if (state.bankSoal.isEmpty) {
        return _buildEmptyView();
      }

      // Selalu tampilkan bank soal yang ada, terlepas dari jumlahnya
      return Column(
        children: [
          // Bagian ini selalu ditampilkan selama ada bank soal
          Expanded(
            child: _buildBankList(state.bankSoal),
          ),
        ],
      );
    }

    if (state is QuestionBankError) {
      return Center(
        child: ErrorContainer(
          errorMessage:
              "Tidak dapat terhubung ke server, mohon periksa koneksi internet anda dan coba lagi",
          onTapRetry: _reloadData,
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildLoadingView() {
    return const SkeletonQuestionBankListScreen(
      itemCount: 6,
      showSearch: false,
    );
  }

  Widget _buildEmptyView() {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.source_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada bank soal',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddBankDialog,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Bank Soal'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
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
            _filteredBanks = [];
          });
        });
      },
      primaryColor: _primaryColor,
      accentColor: _highlightColor,
      title: 'Tidak Ada Bank Soal',
      description:
          'Tidak ditemukan bank soal yang sesuai dengan pencarian Anda. Coba gunakan kata kunci yang berbeda.',
      clearButtonText: 'Hapus Pencarian',
      icon: Icons.source_outlined,
    );
  }

  Widget _buildBankList(List<BankSoal> banks) {
    if (banks.isEmpty) {
      return _buildEmptyView();
    }

    // Determine if search should be shown (more than 5 banks)
    final bool shouldShowSearch = banks.length > 5;

    // Update filtered banks only if search is not active or if banks changed
    if (_searchController.text.isEmpty) {
      _filteredBanks = List.from(banks);
    } else if (_filteredBanks.isEmpty || _filteredBanks.length > banks.length) {
      // Re-filter if banks list changed
      _filterBanks(_searchController.text, banks);
    }

    // Use filtered banks if search is active, otherwise use all banks
    final displayBanks =
        _searchController.text.isNotEmpty ? _filteredBanks : banks;

    return Column(children: [
      // Search bar if needed
      if (shouldShowSearch)
        FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 50, 20, 20),
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
                hintText: 'Cari bank soal...',
                prefixIcon: Icon(Icons.search, color: _primaryColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: _primaryColor),
                        onPressed: () {
                          _clearSearch(banks);
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              onChanged: (value) {
                _filterBanks(value, banks);
              },
            ),
          ),
        ),

      // Banks list
      Expanded(
        child: Stack(
          children: [
            // Show no search results if search is active and no results found
            if (_searchController.text.isNotEmpty && _filteredBanks.isEmpty)
              _buildNoSearchResultsWidget(),

            // Banks list
            if (_searchController.text.isEmpty || _filteredBanks.isNotEmpty)
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
                          20, shouldShowSearch ? 15 : 50, 20, 100),
                      physics: const BouncingScrollPhysics(),
                      itemCount: displayBanks.length,
                      itemBuilder: (context, index) {
                        final bank = displayBanks[index];
                        final Color cardBaseColor =
                            _cardGradients[index % _cardGradients.length];
                        // Generate bank-specific neon colors for glow effects
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
                              await Get.toNamed(
                                Routes.bankQuestionScreen,
                                arguments: {
                                  'bankSoal': bank,
                                  'subjectId': widget.subject.subject.id,
                                  'subject': widget.subject,
                                },
                              );
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
                                          // Content layout
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Bank text & details with advanced effects
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        // Elaborated bank title with glow
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
                                                            bank.name,
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

                                                        // Question count badge
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 7),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white
                                                                .withValues(
                                                                    alpha:
                                                                        0.15),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        30),
                                                            border: Border.all(
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
                                                                blurRadius: 8,
                                                                spreadRadius: 0,
                                                              ),
                                                            ],
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Text(
                                                                '${bank.soalCount} Soal',
                                                                style:
                                                                    const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  // Three-dots menu button
                                                  _buildMoreOptionsButton(
                                                    bank: bank,
                                                    banks: displayBanks,
                                                    index: index,
                                                    isHovered: isHovered,
                                                    neonGlowColor:
                                                        neonGlowColor,
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 0),

                                              // Arrow button repositioned at bottom right for better layout
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: AnimatedBuilder(
                                                  animation: _pulseAnimation,
                                                  builder: (context, child) {
                                                    return Container(
                                                      width: 42,
                                                      height: 42,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: isHovered
                                                                    ? 0.2
                                                                    : 0.15),
                                                        border: Border.all(
                                                          color: Colors.white
                                                              .withValues(
                                                                  alpha:
                                                                      isHovered
                                                                          ? 0.3
                                                                          : 0.2),
                                                          width: 1.5,
                                                        ),
                                                        boxShadow: isHovered
                                                            ? [
                                                                BoxShadow(
                                                                  color: neonGlowColor
                                                                      .withValues(
                                                                          alpha:
                                                                              0.2 + 0.1 * _pulseAnimation.value),
                                                                  blurRadius:
                                                                      10,
                                                                  spreadRadius: 1 *
                                                                      _pulseAnimation
                                                                          .value,
                                                                )
                                                              ]
                                                            : [],
                                                      ),
                                                      child: Center(
                                                        child: Transform.scale(
                                                          scale: isHovered
                                                              ? 1.0 +
                                                                  0.15 *
                                                                      _pulseAnimation
                                                                          .value
                                                              : 1.0,
                                                          child: const Icon(
                                                            Icons
                                                                .arrow_forward_rounded,
                                                            color: Colors.white,
                                                            size: 22,
                                                          ),
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

  Widget _buildMoreOptionsButton({
    required BankSoal bank,
    required List<BankSoal> banks,
    required int index,
    required bool isHovered,
    required Color neonGlowColor,
  }) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 12,
      offset: const Offset(0, 50),
      color: Colors.white,
      onSelected: (value) {
        if (value == 'edit') {
          _showEditBankDialog(banks, index);
        } else if (value == 'delete') {
          _showDeleteConfirmation(context, bank);
        }
      },
      itemBuilder: (context) => [
        // Enhanced Edit button
        PopupMenuItem<String>(
          value: 'edit',
          height: 64,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.9, end: 1.0),
            duration: const Duration(milliseconds: 200),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade500.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: -2,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Edit',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Enhanced Delete button
        PopupMenuItem<String>(
          value: 'delete',
          height: 64,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.9, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade500.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: -2,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hapus',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Icon(
                Icons.more_vert_rounded,
                color: _primaryColor,
                size: 22,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddBankDialog() {
    final questionBankCubit = context.read<QuestionBankCubit>();
    bool isSubmitting = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return StatefulBuilder(
          builder: (context, setState) {
            return ScaleTransition(
              scale: CurvedAnimation(
                parent: anim1,
                curve: Curves.elasticOut,
                reverseCurve: Curves.easeOutCubic,
              ),
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.add_box_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Tambah Bank',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        enabled: !isSubmitting,
                        maxLines: 4,
                        minLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Nama Bank Soal',
                          prefixIcon: const Icon(Icons.folder_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.secondary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Nama bank soal tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () {
                            _nameController.clear();
                            Navigator.pop(context);
                          },
                    child: Text(
                      'Batal',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: MaterialButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                try {
                                  setState(() {
                                    isSubmitting = true;
                                  });

                                  await questionBankCubit.createQuestionBank(
                                    subjectId: widget.subject.subject.id,
                                    name: _nameController.text.trim(),
                                  );

                                  // Fetch updated bank list
                                  await questionBankCubit.fetchBankSoal(
                                    widget.subject.subject.id,
                                  );

                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  _nameController.clear();

                                  // Show custom success notification
                                  if (context.mounted) {
                                    // Auto-dismissing success banner
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.check_circle,
                                                  color: Colors.white),
                                              SizedBox(width: 12),
                                              Text(
                                                'Bank soal berhasil dibuat!',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        backgroundColor: Colors.green.shade400,
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        elevation: 4,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content:
                                        Text('Gagal membuat bank soal: $e'),
                                    backgroundColor: Colors.red,
                                  ));
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      isSubmitting = false;
                                    });
                                  }
                                }
                              }
                            },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Simpan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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

  void _showEditBankDialog(List<BankSoal> banks, int index) {
    final bank = banks[index];
    final editController = TextEditingController(text: bank.name);
    final editFormKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    // Simpan cubit di luar showDialog untuk menghindari masalah provider
    final questionBankCubit = context.read<QuestionBankCubit>();
    final BuildContext currentContext = context;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return ScaleTransition(
              scale: CurvedAnimation(
                parent: anim1,
                curve: Curves.elasticOut,
                reverseCurve: Curves.easeOutCubic,
              ),
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(dialogContext)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        color: Theme.of(dialogContext).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Edit Bank Soal',
                      style: TextStyle(
                        color: Theme.of(dialogContext).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Form(
                  key: editFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: editController,
                        enabled: !isSubmitting,
                        maxLines: 4,
                        minLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Nama Bank Soal',
                          prefixIcon: const Icon(Icons.folder_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  Theme.of(dialogContext).colorScheme.secondary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Nama bank soal tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: Text(
                      'Batal',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(dialogContext).colorScheme.primary,
                          Theme.of(dialogContext).colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: MaterialButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (editFormKey.currentState?.validate() ??
                                  false) {
                                try {
                                  setState(() {
                                    isSubmitting = true;
                                  });

                                  // Gunakan questionBankCubit yang sudah disimpan
                                  await questionBankCubit.updateQuestionBank(
                                    subjectId: widget.subject.subject.id,
                                    banksoalId: bank.id,
                                    name: editController.text.trim(),
                                  );

                                  if (!dialogContext.mounted) return;
                                  Navigator.pop(dialogContext);

                                  // Refresh bank soal list
                                  _reloadData();

                                  // Gunakan currentContext yang disimpan
                                  if (currentContext.mounted) {
                                    ScaffoldMessenger.of(currentContext)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.check_circle,
                                                  color: Colors.white),
                                              SizedBox(width: 12),
                                              Text(
                                                'Bank soal berhasil diperbarui',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        backgroundColor: Colors.green.shade400,
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        elevation: 4,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (currentContext.mounted) {
                                    ScaffoldMessenger.of(currentContext)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Gagal memperbarui: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      isSubmitting = false;
                                    });
                                  }
                                }
                              }
                            },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Simpan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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

  void _showDeleteConfirmation(BuildContext dialogContext, BankSoal bank) {
    // Simpan context di luar fungsi asynchronous
    final BuildContext currentContext = context;
    final cubit = context.read<QuestionBankCubit>();

    showDialog(
      context: dialogContext,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              const SizedBox(width: 16),
              const Text(
                'Bank Soal',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus bank soal "${bank.name}"? Tindakan ini tidak dapat dibatalkan.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[400]!, Colors.red[700]!],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: MaterialButton(
                onPressed: () async {
                  try {
                    // Tutup dialog terlebih dahulu
                    Navigator.pop(context); // Lakukan proses delete
                    await cubit.deleteBankSoal(
                      subjectId: widget.subject.subject.id,
                      banksoalId: bank.id,
                    );

                    // Refresh data
                    _reloadData();

                    // Gunakan currentContext yang disimpan di awal function
                    // dan periksa apakah context masih mounted sebelum menampilkan SnackBar
                    if (currentContext.mounted) {
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        SnackBar(
                          content: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  'Bank soal berhasil dihapus!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          backgroundColor: Colors.green.shade400,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                      );
                    }
                  } catch (e) {
                    // Gunakan currentContext yang disimpan di awal function
                    // dan periksa apakah context masih mounted
                    if (currentContext.mounted) {
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Gagal menghapus bank soal: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
                child: const Text(
                  'Hapus',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
