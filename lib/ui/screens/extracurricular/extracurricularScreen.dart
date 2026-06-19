import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/cubits/extracurricular/extracurricularCubit.dart';
import 'package:eschool_saas_staff/data/repositories/extracurricular/extracurricularRepository.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/data/models/extracurricular/extracurricular.dart';
import '../../../app/routes.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/no_search_results_widget.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';

class ExtracurricularScreen extends StatefulWidget {
  const ExtracurricularScreen({super.key});

  static Widget getRouteInstance() {
    return BlocProvider(
      create: (context) => ExtracurricularCubit(ExtracurricularRepository()),
      child: const ExtracurricularScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<ExtracurricularScreen> createState() => _ExtracurricularScreenState();
}

class _ExtracurricularScreenState extends State<ExtracurricularScreen>
    with TickerProviderStateMixin {
  String searchQuery = "";
  String? _restoredExtracurricularId;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _appBarAnimationController;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _extracurricularSub;

  // Filter variables
  String? selectedCoachName;
  List<String> coachNameList = [];

  // Theme colors - Softer Maroon palette (same as onlineExamScreen)
  static const Color _primaryColor = Color(0xFF7A1E23); // Softer deep maroon
  static const Color _highlightColor =
      Color(0xFFB84D4D); // Softer bright maroon

  @override
  void initState() {
    super.initState();
    debugPrint('🎯 [EXTRACURRICULAR SCREEN] Initialized');
    _refreshExtracurriculars();

    // Listen for state changes
    _extracurricularSub =
        context.read<ExtracurricularCubit>().stream.listen((state) {
      if (state is ExtracurricularSuccess) {
        debugPrint(
            '✅ [EXTRACURRICULAR SCREEN] UI Updated: ${state.extracurriculars.length} extracurriculars');
        setState(() {});
      } else if (state is ExtracurricularFailure) {
        debugPrint(
            '❌ [EXTRACURRICULAR SCREEN] UI Error: ${state.errorMessage}');
        setState(() {});
      } else if (state is ExtracurricularLoading) {
        debugPrint('⏳ [EXTRACURRICULAR SCREEN] Loading...');
      }
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _appBarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _extracurricularSub?.cancel();
    _animationController.stop();
    _pulseController.stop();
    _appBarAnimationController.stop();
    _animationController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    _appBarAnimationController.dispose();
    super.dispose();
  }

  void _refreshExtracurriculars() {
    debugPrint('🔄 [EXTRACURRICULAR SCREEN] Refreshing data...');
    if (mounted) {
      context.read<ExtracurricularCubit>().getExtracurriculars();
    } else {
      debugPrint(
          '⚠️ [EXTRACURRICULAR SCREEN] Widget not mounted, skipping refresh');
    }
  }



  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshExtracurriculars();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _animationController.stop();
        _pulseController.stop();
        _appBarAnimationController.stop();
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        extendBodyBehindAppBar: true,
        appBar: CustomModernAppBar(
          title: 'Kurikuler',
          icon: Icons.sports_soccer,
          fabAnimationController: _appBarAnimationController,
          primaryColor: _primaryColor,
          lightColor: _highlightColor,
          onBackPressed: () {
            _animationController.stop();
            _pulseController.stop();
            _appBarAnimationController.stop();
            Get.back();
          },
          showAddButton: true,
          onAddPressed: () async {
            final result = await Get.toNamed(Routes.createExtracurricular);
            if (result == true) {
              _refreshExtracurriculars();
            }
          },
          showArchiveButton: true,
          onArchivePressed: () async {
            final result = await Get.toNamed(Routes.archiveExtracurricular);
            if (!context.mounted) return;
            if (result != null && result is Map) {
              // Handle restore result from archive page
              if (result['action'] == 'restored') {
                setState(() {
                  _restoredExtracurricularId =
                      result['extracurricularId'].toString();
                });

                // Immediately inject restored extracurricular into active list
                if (result['extracurricular'] != null &&
                    result['extracurricular'] is Extracurricular) {
                  final restoredEC = (result['extracurricular'] as Extracurricular)
                      .copyWith(clearDeletedAt: true);
                  context.read<ExtracurricularCubit>().addExtracurricular(restoredEC);
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Ekstrakurikuler berhasil dipulihkan!',
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

                // Background sync: refresh from backend to ensure consistency
                Future.delayed(const Duration(milliseconds: 1200), () {
                  if (mounted) {
                    _refreshExtracurriculars();
                  }
                });

                // Remove highlight after 8 seconds
                Future.delayed(const Duration(seconds: 8), () {
                  if (mounted) {
                    setState(() {
                      _restoredExtracurricularId = null;
                    });
                  }
                });
              }
            }
          },
        ),
        body: _buildAnimatedBody(),
      ),
    );
  }

  Widget _buildAnimatedBody() {
    return AnimationLimiter(
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Add padding for the app bar
          const SliverPadding(
            padding: EdgeInsets.only(top: 120),
            sliver: SliverToBoxAdapter(child: SizedBox()),
          ),
          _buildSearchAndFilter(),
          BlocBuilder<ExtracurricularCubit, ExtracurricularState>(
            builder: (context, state) {
              if (state is ExtracurricularLoading) {
                debugPrint('🎨 [EXTRACURRICULAR SCREEN] Building loading UI');
                return SliverFillRemaining(
                  child: _buildShimmerLoading(),
                );
              }

              if (state is ExtracurricularFailure) {
                debugPrint('🎨 [EXTRACURRICULAR SCREEN] Building error UI');
                return SliverFillRemaining(
                  child: CustomErrorWidget(
                    message: state.errorMessage,
                    onRetry: _refreshExtracurriculars,
                    primaryColor: _primaryColor,
                  ),
                );
              }

              if (state is ExtracurricularSuccess) {
                debugPrint('🎨 [EXTRACURRICULAR SCREEN] Building success UI');
                return state.extracurriculars.isEmpty
                    ? SliverFillRemaining(child: _buildEmptyState())
                    : _buildExtracurricularGrid(state);
              }

              debugPrint('🎨 [EXTRACURRICULAR SCREEN] Building default UI');
              return const SliverToBoxAdapter(child: SizedBox());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),
            _buildFilterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
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
          decoration: InputDecoration(
            hintText: 'Cari ekstrakurikuler...',
            prefixIcon: const Icon(Icons.search, color: _primaryColor),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: _primaryColor),
                    onPressed: () {
                      setState(() {
                        searchQuery = "";
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return BlocBuilder<ExtracurricularCubit, ExtracurricularState>(
      builder: (context, state) {
        List<String> coaches = [];
        if (state is ExtracurricularSuccess) {
          coaches = state.extracurriculars
              .map((e) => e.coachName)
              .where((name) => name.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
        }

        coachNameList = coaches;

        return FadeInDown(
          duration: const Duration(milliseconds: 700),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.filter_list, color: _primaryColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Filter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                    if (selectedCoachName != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedCoachName = null;
                          });
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 15),
                // Coach Name Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedCoachName,
                  decoration: InputDecoration(
                    labelText: 'Pelatih/Coach',
                    labelStyle: const TextStyle(color: _primaryColor),
                    prefixIcon: const Icon(Icons.person, color: _primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primaryColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _primaryColor, width: 2),
                    ),
                  ),
                  items: coachNameList
                      .map((coach) => DropdownMenuItem(
                            value: coach,
                            child: Text(coach),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCoachName = value;
                    });
                  },
                  isExpanded: true,
                  hint: Text('Pilih Pelatih',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExtracurricularGrid(ExtracurricularSuccess state) {
    var filteredExtracurriculars = state.extracurriculars;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filteredExtracurriculars = filteredExtracurriculars
          .where((e) =>
              e.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              e.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
              e.coachName.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    // Apply coach filter
    if (selectedCoachName != null) {
      filteredExtracurriculars = filteredExtracurriculars
          .where((e) => e.coachName == selectedCoachName)
          .toList();
    }

    // Sort to prioritize restored extracurricular if exists
    if (_restoredExtracurricularId != null) {
      filteredExtracurriculars.sort((a, b) {
        if (a.id.toString() == _restoredExtracurricularId) return -1;
        if (b.id.toString() == _restoredExtracurricularId) return 1;
        return b.id.compareTo(a.id);
      });
    } else {
      filteredExtracurriculars.sort((a, b) => b.id.compareTo(a.id));
    }

    if (filteredExtracurriculars.isEmpty &&
        (searchQuery.isNotEmpty || selectedCoachName != null)) {
      return SliverFillRemaining(
        child: NoSearchResultsWidget(
          searchQuery: searchQuery.isNotEmpty ? searchQuery : 'filter',
          onClearSearch: () {
            setState(() {
              searchQuery = "";
              selectedCoachName = null;
            });
          },
          primaryColor: _primaryColor,
          accentColor: _highlightColor,
          title: 'Tidak Ada Ekstrakurikuler',
          description:
              'Tidak ditemukan ekstrakurikuler yang sesuai dengan pencarian atau filter Anda.',
          clearButtonText: 'Reset Filter',
          icon: Icons.sports_soccer,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 500),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildExtracurricularCard(
                      context, filteredExtracurriculars[index]),
                ),
              ),
            );
          },
          childCount: filteredExtracurriculars.length,
        ),
      ),
    );
  }

  Widget _buildExtracurricularCard(
      BuildContext context, Extracurricular extracurricular) {
    final bool isRecentlyRestored =
        _restoredExtracurricularId == extracurricular.id.toString();

    // Define modern color scheme with soft maroon colors (same as onlineExamScreen)
    final colorScheme = {
      'primary': const Color.fromARGB(255, 172, 33, 33),
      'gradient1': const Color(0xFF7D1F1F), // Lighter maroon
      'gradient2': const Color(0xFF9B2F2F), // Medium maroon
      'gradient3': const Color(0xFFBF4040), // Soft bright maroon
      'neutral1': const Color(0xFF333333), // Dark gray for primary text
      'neutral2': const Color(0xFF666666), // Medium gray for secondary text
      'accent': const Color(0xFF8B4513), // Brown accent color
    };

    // Improved calculation for text wrapping (same as onlineExamScreen)
    final double screenWidth = MediaQuery.of(context).size.width;
    final double availableWidth = screenWidth - 48; // 24px padding on each side
    const double titleFontSize = 24.0;
    const double lineHeight = 1.4;

    // Calculate estimated number of lines based on character count and available width
    final int estimatedCharactersPerLine =
        (availableWidth / (titleFontSize * 0.6)).floor();
    final int estimatedLines = math.max(
        1, (extracurricular.name.length / estimatedCharactersPerLine).ceil());
    final double estimatedTextHeight =
        estimatedLines * (titleFontSize * lineHeight);

    const double minHeight = 260.0; // Increased minimum height untuk header
    const double maxHeight = 450.0; // Increased maximum height untuk header

    // Sesuaikan headerHeight dengan batasan min dan max, plus extra space untuk wrapping
    final double headerHeight = math.min(
      maxHeight,
      math.max(minHeight,
          estimatedTextHeight + 200.0), // Increased padding for better spacing
    );

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: isRecentlyRestored
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.1),
                    blurRadius: 40,
                    spreadRadius: 5,
                    offset: const Offset(0, 0),
                  ),
                ],
              )
            : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            highlightColor: Colors.transparent,
            splashColor: colorScheme['primary']!.withValues(alpha: 0.05),
            child: Ink(
              decoration: BoxDecoration(
                color: isRecentlyRestored
                    ? const Color.fromARGB(
                        255, 240, 253, 244) // Light green tint for restored
                    : const Color.fromARGB(
                        255, 237, 237, 237), // Very slightly off-white
                borderRadius: BorderRadius.circular(32),
                border: isRecentlyRestored
                    ? Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                        width: 2,
                      )
                    : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardHeader(
                          extracurricular, colorScheme, headerHeight),
                      _buildCardContent(
                          extracurricular, colorScheme, headerHeight),
                    ],
                  ),
                  // Overlapping Card - Dynamic position based on header height
                  _buildOverlappingCard(
                      extracurricular, colorScheme, headerHeight),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(Extracurricular extracurricular,
      Map<String, Color> colorScheme, double headerHeight) {
    return Container(
      height: headerHeight, // Increased height
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme['gradient1']!,
            colorScheme['gradient2']!,
            colorScheme['gradient3']!,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative Pattern Overlay
          Opacity(
            opacity: 0.07,
            child: CustomPaint(
              size: Size.infinite,
              painter: Modern2025PatternPainter(
                primaryColor: Colors.white,
                secondaryColor: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),

          // Glow Effect Corner
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Coach name badge - centered above title
          Positioned(
            top: 30, // Position above the title
            left: 24,
            right: 24,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline,
                        size: 16, color: colorScheme['primary']),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        extracurricular.coachName,
                        style: TextStyle(
                          color: colorScheme['primary'],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Title - Updated position and styling with better wrapping
          Positioned(
            top: 90, // Adjust position to be below coach name
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Remove Container constraint and let text wrap naturally
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Text(
                      extracurricular.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24, // Keep consistent font size
                        fontWeight: FontWeight.w800,
                        height: 1.4, // Good line height for readability
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.left,
                      maxLines: null, // Allow unlimited lines
                    );
                  },
                ),

                Container(
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(Extracurricular extracurricular,
      Map<String, Color> colorScheme, double headerHeight) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24,
          math.max(
              120,
              (headerHeight * 0.35)
                  .round()
                  .toDouble()), // Dynamic top padding based on header height
          24,
          24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actions Row - Modern Button Design
          Row(
            children: [
              // Edit Button - Modern Design
              Expanded(
                child: _buildModernActionButton(
                  onTap: () async {
                    final result = await Get.toNamed(
                      Routes.editExtracurricular,
                      arguments: extracurricular,
                    );
                    if (result == true) {
                      _refreshExtracurriculars();
                    }
                  },
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF26A69A),
                      Color(0xFF00897B),
                      Color(0xFF00796B),
                    ],
                  ),
                  shadowColor: const Color(0xFF26A69A).withValues(alpha: 0.4),
                ),
              ),

              const SizedBox(width: 16),

              // Archive Button - Modern Design
              Expanded(
                child: _buildModernActionButton(
                  onTap: () => _showDeleteConfirmation(extracurricular),
                  icon: Icons.archive_outlined,
                  label: 'Arsip',
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF9C4146), // Softer maroon
                      Color(0xFF812A33), // Medium maroon
                      Color(0xFF6A1B24), // Deep maroon
                    ],
                  ),
                  shadowColor: const Color(0xFF812A33).withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverlappingCard(Extracurricular extracurricular,
      Map<String, Color> colorScheme, double headerHeight) {
    return Positioned(
      top: headerHeight - 85, // Dynamic positioning based on header height
      left: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: -5,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Top section: Description
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Icon Container - reduced padding
                    Container(
                      padding: const EdgeInsets.all(10), // Reduced from 12
                      decoration: BoxDecoration(
                        color: colorScheme['primary']!.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.description_rounded,
                        color: colorScheme['primary'],
                        size: 20, // Reduced from 22
                      ),
                    ),
                    const SizedBox(width: 12), // Reduced from 16

                    // Text Content - with overflow handling
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deskripsi',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: colorScheme['neutral1'],
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            extracurricular.description,
                            style: TextStyle(
                              color: colorScheme['neutral2'],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Arrow Icon - reduced padding
                    Container(
                      padding: const EdgeInsets.all(8), // Reduced from 10
                      decoration: BoxDecoration(
                        color: colorScheme['primary']!.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.sports_soccer,
                        color: colorScheme['primary'],
                        size: 16, // Reduced from 18
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme['primary']!.withValues(alpha: 0.08),
                indent: 20,
                endIndent: 20,
              ),

              // Bottom section: Category info
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme['primary']!.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.category_rounded,
                            size: 16,
                            color: colorScheme['primary'],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ekstrakurikuler',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme['neutral1'],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required Color shadowColor,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.3),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.transparent,
          child: Stack(
            children: [
              // Subtle pattern overlay
              Opacity(
                opacity: 0.05,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Colors.white, Colors.transparent],
                    ),
                  ),
                ),
              ),

              // Button content
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Top highlight for 3D effect
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (_, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: const SkeletonCard(height: 400),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return FadeIn(
      duration: const Duration(milliseconds: 800),
      child: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                Icon(
                  Icons.sports_soccer,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 20),
                Text(
                  'Belum ada ekstrakurikuler',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Tambahkan ekstrakurikuler baru dengan menekan tombol +',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Extracurricular extracurricular) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4A5A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.archive_rounded,
                  color: Color(0xFF8B4A5A),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Arsipkan Ekstrakurikuler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah Anda yakin ingin mengarsipkan "${extracurricular.name}"?',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ekstrakurikuler yang diarsipkan dapat dilihat kembali di menu Arsip.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await context
                      .read<ExtracurricularCubit>()
                      .deleteExtracurricular(extracurricular.id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ekstrakurikuler diarsipkan'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal mengarsipkan ekstrakurikuler'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4A5A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              child: const Text('Arsipkan'),
            ),
          ],
        );
      },
    );
  }
}

class Modern2025PatternPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  Modern2025PatternPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final dotPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    const double spacing = 40;

    // Draw curved lines
    for (double i = -size.width / 2; i < size.width * 1.5; i += spacing) {
      final path = Path();
      path.moveTo(i, 0);
      path.quadraticBezierTo(
          i + spacing / 2, size.height / 2, i + spacing, size.height);
      canvas.drawPath(path, paint);
    }

    // Add decorative dots
    for (int i = 0; i < 12; i++) {
      final x = (size.width * 0.1) + (i * size.width * 0.08);
      final y = size.height * 0.2 + (i % 3) * size.height * 0.3;
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
