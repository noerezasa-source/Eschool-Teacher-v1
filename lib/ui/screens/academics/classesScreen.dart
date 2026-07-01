import 'dart:ui';
import 'dart:math';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/settings/appThemeCubit.dart';
import 'package:eschool_saas_staff/cubits/academics/classesWithTeacherDetailsCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/subjectTeacher.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/no_search_results_widget.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  static Widget getRouteInstance() {
    return BlocProvider(
      create: (context) => ClassesWithTeacherDetailsCubit(),
      child: const ClassesScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen>
    with SingleTickerProviderStateMixin {
  String get _themeMode => context.watch<AppThemeCubit>().state.themeMode;
  Color get _primaryColor => AppColorPalette.getPrimaryColor(_themeMode);
  Color get _secondaryColor => AppColorPalette.getSecondaryColor(_themeMode);
  bool get _isDark => _themeMode == 'dark';
  Color get _scaffoldBg => _isDark ? const Color(0xFF121212) : Colors.white;
  Color get _cardBg => _isDark ? const Color(0xFF1E1E1E) : Colors.white;

  late AnimationController _controller;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isScrolled = false;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..forward();

    _scrollController.addListener(_scrollListener);

    Future.delayed(Duration.zero, () {
      getClassesWithTeacherDetails();
    });
  }

  void _scrollListener() {
    if (_scrollController.offset > 10 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 10 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void getClassesWithTeacherDetails() async {
    context
        .read<ClassesWithTeacherDetailsCubit>()
        .getClassesWithTeacherDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _primaryColor,
              secondary: _secondaryColor,
              surface: _cardBg,
            ),
      ),
      child: Scaffold(
        backgroundColor: _scaffoldBg,
        appBar: CustomModernAppBar(
          title: 'Daftar Kelas',
          icon: Icons.school,
          fabAnimationController: _controller,
          primaryColor: _primaryColor,
          lightColor: _secondaryColor,
          onBackPressed: () => Navigator.of(context).pop(),
          showHelperButton: true,
          helperIcon: _isSearchActive ? Icons.close : Icons.search,
          onHelperPressed: () {
            setState(() {
              _isSearchActive = !_isSearchActive;
              if (!_isSearchActive) {
                _searchController.clear();
                _searchQuery = "";
              }
            });

            // Add haptic feedback
            HapticFeedback.lightImpact();

            // Auto focus when search becomes active
            if (_isSearchActive) {
              // Use a shorter delay and ensure focus is requested properly
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  _searchFocusNode.requestFocus();
                }
              });
            } else {
              // Unfocus when search is deactivated
              _searchFocusNode.unfocus();
            }
          },
        ),
        body: Stack(
          children: [
            // Enhanced Animated Background Pattern
            AnimatedPositioned(
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height,
              child: AnimatedOpacity(
                duration: const Duration(seconds: 1),
                opacity: 0.15,
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: BackgroundPatternPainter(
                        color: _primaryColor,
                      ),
                    ),
                    // Decorative particles for modern look
                    ...List.generate(10, (index) {
                      return Positioned(
                        top: Random().nextDouble() *
                            MediaQuery.of(context).size.height,
                        left: Random().nextDouble() *
                            MediaQuery.of(context).size.width,
                        child: AnimatedContainer(
                          duration: Duration(seconds: 2 + index),
                          width: 4 + Random().nextDouble() * 8,
                          height: 4 + Random().nextDouble() * 8,
                          decoration: BoxDecoration(
                            color:
                                _primaryColor.withValues(alpha: _isDark ? 0.15 : 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Enhanced Search Bar
            _buildSearchBar(),

            // Main Content with Enhanced Animation
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - _controller.value) * 30),
                  child: Opacity(
                    opacity: _controller.value,
                    child: BlocBuilder<ClassesWithTeacherDetailsCubit,
                        ClassesWithTeacherDetailsState>(
                      builder: (context, state) {
                        if (state is ClassesWithTeacherDetailsFetchSuccess) {
                          if (state.classes.isEmpty) {
                            return _buildEmptyState(context);
                          }
                          return _buildSuccessState(context, state);
                        }

                        if (state is ClassesWithTeacherDetailsFetchFailure) {
                          return _buildErrorState(context, state);
                        }

                        return _buildLoadingState(context);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height:
            _isSearchActive ? 70 : 0, // Increased height for better touch area
        curve: Curves.easeInOut,
        child: ClipRect(
          child: _isSearchActive
              ? Container(
                  margin:
                      const EdgeInsets.fromLTRB(16, 8, 16, 8), // Better margins
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: _primaryColor.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: true,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: _primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari kelas berdasarkan nama...',
                      hintStyle: GoogleFonts.poppins(
                        color: _secondaryColor.withValues(alpha: 0.6),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.search_rounded,
                          color: _primaryColor,
                          size: 22,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                    ),
                    onChanged: (value) {
                      final trimmedValue = value.trim();
                      if (_searchQuery != trimmedValue) {
                        setState(() {
                          _searchQuery = trimmedValue;
                        });
                      }
                    },
                    onSubmitted: (value) {
                      final trimmedValue = value.trim();
                      if (_searchQuery != trimmedValue) {
                        setState(() {
                          _searchQuery = trimmedValue;
                        });
                      }
                    },
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.5, end: 0)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Enhanced animated empty state icon
                TweenAnimationBuilder(
                    duration: const Duration(seconds: 2),
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _primaryColor.withValues(alpha: 0.1),
                          ),
                          child: Center(
                            child: Transform.scale(
                              scale: 1 + sin(_controller.value * 2 * pi) * 0.05,
                              child: Icon(
                                Icons.school_outlined,
                                size: 100,
                                color: _primaryColor
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                const SizedBox(height: 32),

                // Enhanced no classes text
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      _primaryColor,
                      _secondaryColor,
                    ],
                  ).createShader(bounds),
                  child: CustomTextContainer(
                    textKey:
                        Utils.getTranslatedLabel(noClassSectionSelectedKey),
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action button
                ElevatedButton.icon(
                  onPressed: () {
                    getClassesWithTeacherDetails();
                    HapticFeedback.mediumImpact();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    "Refresh Classes",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessState(
      BuildContext context, ClassesWithTeacherDetailsFetchSuccess state) {
    // Enhanced filter classes based on search query
    final classes = _searchQuery.isEmpty
        ? state.classes
        : state.classes.where((classSection) {
            final firstName = (classSection.fullName ?? "").toLowerCase();
            final searchLower = _searchQuery.toLowerCase();

            // Search in first name
            if (firstName.contains(searchLower)) return true;

            // Search in individual words for better matching
            final nameWords = firstName.split(' ');
            final searchWords = searchLower.split(' ');

            for (String searchWord in searchWords) {
              if (searchWord.trim().isNotEmpty) {
                bool found = false;
                for (String nameWord in nameWords) {
                  if (nameWord.contains(searchWord.trim())) {
                    found = true;
                    break;
                  }
                }
                if (!found) return false;
              }
            }

            return true;
          }).toList();

    return AnimationLimiter(
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: _isSearchActive
                    ? 85 // Increased to accommodate new search bar height
                    : 16,
                bottom: 16,
                left: appContentHorizontalPadding,
                right: appContentHorizontalPadding,
              ),
              child: classes.isEmpty && _searchQuery.isNotEmpty
                  ? Center(
                      child: NoSearchResultsWidget(
                        searchQuery: _searchQuery,
                        onClearSearch: () {
                          setState(() {
                            _searchQuery = "";
                            _searchController.clear();
                            // Keep search active, just clear the query
                          });
                        },
                        primaryColor: _primaryColor,
                        accentColor: _secondaryColor,
                        title: 'Kelas Tidak Ditemukan',
                        description:
                            'Tidak ditemukan kelas yang sesuai dengan pencarian "$_searchQuery". Coba gunakan kata kunci yang berbeda.',
                        icon: Icons.search_off_rounded,
                      ).animate().fadeIn(delay: 300.ms),
                    )
                  : Column(
                      children: [
                        // Search results indicator
                        if (_searchQuery.isNotEmpty && classes.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _primaryColor
                                    .withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: _primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Ditemukan ${classes.length} kelas untuk "$_searchQuery"',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 200.ms),

                        // Header card (hidden when searching)
                        if (_searchQuery.isEmpty)
                          _buildEnhancedHeaderCard(context),
                      ],
                    ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 600),
                  child: SlideAnimation(
                    horizontalOffset: 50.0,
                    child: FadeInAnimation(
                      curve: Curves.easeOut,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildEnhancedClassCard(
                            context, classes[index], index),
                      ),
                    ),
                  ),
                ),
                childCount: classes.length,
              ),
            ),
          ),
          // Add some bottom padding for better scroll experience
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeaderCard(BuildContext context) {
    return Hero(
      tag: 'class_list_title',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Stack(
          children: [
            // Enhanced Main Card with Improved Frosted Glass Effect
            Card(
              elevation: 16,
              shadowColor: _primaryColor.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _primaryColor.withValues(alpha: 0.9),
                          _secondaryColor.withValues(alpha: 0.9),
                        ],
                        stops: const [0.2, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced Top Section with Title and Icon
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CustomTextContainer(
                                        textKey: classListKey,
                                        style: GoogleFonts.poppins(
                                          fontSize:
                                              Utils.getScaledValue(context, 24),
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.workspace_premium,
                                        color: Colors.white.withValues(alpha: 0.9),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 60,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Enhanced Decorative Elements
            Positioned(
              right: -25,
              bottom: -15,
              child: Icon(
                Icons.school,
                size: 100,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),

            // Enhanced Decorative Elements
            ...List.generate(4, (index) {
              return Positioned(
                left: 15 + (index * 15),
                top: 15 + (index * 10),
                child: Container(
                  width: 30 - (index * 5),
                  height: 30 - (index * 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1 - (index * 0.02)),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedClassCard(
      BuildContext context, dynamic classSection, int index) {
    final bool isEven = index.isEven;
    final cardGradient = [
      _cardBg,
      _cardBg,
    ];

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0.96, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Utils.showBottomSheet(
                      child: _buildEnhancedBottomSheet(
                          classSection.subjectTeachers ?? []),
                      context: context);
                },
                borderRadius: BorderRadius.circular(24),
                splashColor: _primaryColor.withValues(alpha: 0.2),
                highlightColor: _primaryColor.withValues(alpha: 0.1),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: cardGradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: _primaryColor.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildEnhancedCardHeader(context, classSection, isEven),
                      _buildEnhancedCardBody(context, classSection, isEven),
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

  Widget _buildEnhancedCardHeader(
      BuildContext context, dynamic details, bool isEven) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _primaryColor.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        gradient: LinearGradient(
          begin: isEven ? Alignment.centerLeft : Alignment.centerRight,
          end: isEven ? Alignment.centerRight : Alignment.centerLeft,
          colors: [
            _primaryColor.withValues(alpha: 0.15),
            _secondaryColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.name ?? 'Class Section',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCardBody(
      BuildContext context, dynamic details, bool isEven) {
    // For class teacher names
    final classTeacherNames = details.getClassTeacherNames();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildEnhancedInfoRow(
              context, 'Guru Kelas', classTeacherNames, Icons.person_outline,
              gradient: [
                _primaryColor.withValues(alpha: 0.08),
                _secondaryColor.withValues(alpha: 0.02),
              ]),

          // Add spacing before button
          const SizedBox(height: 20),

          // Smaller Selengkapnya button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Utils.showBottomSheet(
                    child: _buildEnhancedBottomSheet(
                        details.subjectTeachers ?? []),
                    context: context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Selengkapnya",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInfoRow(
      BuildContext context, String label, String value, IconData icon,
      {required List<Color> gradient}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor.withValues(alpha: 0.12),
            _secondaryColor.withValues(alpha: 0.08),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _secondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedBottomSheet(List<SubjectTeacher> subjectTeachers) {
    return ClassSubjectsBottomsheet(subjectTeachers: subjectTeachers);
  }

  Widget _buildErrorState(
      BuildContext context, ClassesWithTeacherDetailsFetchFailure state) {
    return CustomErrorWidget(
      message: state.errorMessage,
      onRetry: () => getClassesWithTeacherDetails(),
      primaryColor: _primaryColor,
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: 16,
        bottom: 80,
        left: appContentHorizontalPadding,
        right: appContentHorizontalPadding,
      ),
      child: Column(
        children: [
          // Header card skeleton (only shown when not searching)
          if (_searchQuery.isEmpty) _buildHeaderCardSkeleton(),

          // Class cards skeleton
          ...List.generate(
              5, (index) => _buildDetailedClassCardSkeleton(index)),

          // Add some bottom padding
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeaderCardSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      child: Shimmer.fromColors(
        baseColor: _isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        highlightColor: _isDark ? Colors.grey.shade700 : Colors.grey.shade100,
        child: Card(
          elevation: 16,
          shadowColor: _primaryColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade400,
                  Colors.grey.shade300,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 24,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedClassCardSkeleton(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: _isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        highlightColor: _isDark ? Colors.grey.shade700 : Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with class info and status
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 14,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Teacher info section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Class details section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject count
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 14,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Student count
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 14,
                          width: 130,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Academic year
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 14,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Action button
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 100,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClassSubjectsBottomsheet extends StatelessWidget {
  final List<SubjectTeacher> subjectTeachers;
  const ClassSubjectsBottomsheet({super.key, required this.subjectTeachers});

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<AppThemeCubit>().state;
    final primaryColor = AppColorPalette.getPrimaryColor(themeState.themeMode);
    final isDark = themeState.themeMode == 'dark';
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return CustomBottomsheet(
      // removed
      child: Column(
        children: [
          // Elegant header with subtle gradient
          Container(
            margin: const EdgeInsets.only(bottom: 24, left: 12, right: 12),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.9),
                  primaryColor.withValues(alpha: 0.85),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: isDark ? 0.08 : 0.25),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daftar Mata Pelajaran',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      height: 2,
                      width: 40,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${subjectTeachers.length} mata pelajaran',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Elegant subject list with minimalist design
          AnimationLimiter(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjectTeachers.length,
              itemBuilder: (context, index) {
                // Get subject name and teacher
                final subject =
                    subjectTeachers[index].subject?.getSybjectNameWithType() ??
                        '';
                final teacher =
                    subjectTeachers[index].teacher?.firstName ?? '-';

                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 450),
                  child: SlideAnimation(
                    horizontalOffset: 50,
                    child: FadeInAnimation(
                      child: Container(
                        margin:
                            const EdgeInsets.only(bottom: 16, left: 12, right: 12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                primaryColor.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                              blurRadius: 15,
                              spreadRadius: 1,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                              },
                              splashColor: primaryColor
                                  .withValues(alpha: 0.1),
                              highlightColor: primaryColor
                                  .withValues(alpha: 0.05),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Subject title
                                    CustomTextContainer(
                                      textKey: subject,
                                      style: GoogleFonts.poppins(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                        height: 1.3,
                                      ),
                                    ),

                                    // Divider line
                                    Padding(
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 12),
                                      child: Container(
                                        height: 1,
                                        width: double.infinity,
                                        color: primaryColor
                                            .withValues(alpha: 0.1),
                                      ),
                                    ),

                                    // Teacher info - elegant and simple
                                    Row(
                                      children: [
                                        // Profile avatar
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: primaryColor
                                                .withValues(alpha: 0.1),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.person_rounded,
                                              color:
                                                  primaryColor,
                                              size: 24,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 14),

                                        // Teacher name and role
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                teacher,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                'Guru Pengajar',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w400,
                                                  color: isDark ? Colors.white70 : Colors.black54,
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
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  final Color color;

  BackgroundPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Main wave
    final path = Path()
      ..moveTo(0, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.05,
        size.width * 0.5,
        size.height * 0.15,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.25,
        size.width,
        size.height * 0.2,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);

    // Secondary decorative waves
    final path2 = Path()
      ..moveTo(0, size.height * 0.45)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.4,
        size.width * 0.6,
        size.height * 0.55,
        size.width,
        size.height * 0.47,
      )
      ..lineTo(size.width, size.height * 0.45)
      ..lineTo(0, size.height * 0.45)
      ..close();

    canvas.drawPath(
      path2,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EnhancedCurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);

    path.quadraticBezierTo(
      size.width * 0.1,
      size.height,
      size.width * 0.3,
      size.height - 25,
    );

    path.quadraticBezierTo(
      size.width * 0.5,
      size.height - 50,
      size.width * 0.7,
      size.height - 25,
    );

    path.quadraticBezierTo(
      size.width * 0.9,
      size.height,
      size.width,
      size.height - 40,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}


