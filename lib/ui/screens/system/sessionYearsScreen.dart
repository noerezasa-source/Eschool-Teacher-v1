import 'dart:ui';
import 'dart:math';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/academics/sessionYearsCubit.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
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

class SessionYearsScreen extends StatefulWidget {
  const SessionYearsScreen({super.key});

  static Widget getRouteInstance() {
    return BlocProvider(
      create: (context) => SessionYearsCubit(),
      child: const SessionYearsScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<SessionYearsScreen> createState() => _SessionYearsScreenState();
}

class _SessionYearsScreenState extends State<SessionYearsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final ScrollController _scrollController = ScrollController();
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
      getSessionYears();
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
    super.dispose();
  }

  void getSessionYears() async {
    context.read<SessionYearsCubit>().getSessionYears();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColorPalette.primaryMaroon,
              secondary: AppColorPalette.secondaryMaroon,
              surface: Colors.white,
            ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomModernAppBar(
          title: 'Tahun Ajaran',
          icon: Icons.calendar_today_rounded,
          fabAnimationController: _controller,
          primaryColor: AppColorPalette.primaryMaroon,
          lightColor: AppColorPalette.secondaryMaroon,
          onBackPressed: () => Navigator.of(context).pop(),
          height: 80,
          showFilterButton: true,
          onFilterPressed: () {
            setState(() {
              _isSearchActive = !_isSearchActive;
              if (!_isSearchActive) {
                _searchController.clear();
                _searchQuery = "";
              }
            });
          },
        ),
        body: Stack(
          children: [
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
                        color: AppColorPalette.primaryMaroon,
                      ),
                    ),
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
                                AppColorPalette.primaryMaroon.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - _controller.value) * 30),
                    child: Opacity(
                      opacity: _controller.value,
                      child: BlocBuilder<SessionYearsCubit, SessionYearsState>(
                        builder: (context, state) {
                          if (state is SessionYearsFetchSuccess) {
                            if (state.sessionYears.isEmpty) {
                              return _buildEmptyState(context);
                            }
                            return _buildSuccessState(context, state);
                          }

                          if (state is SessionYearsFetchFailure) {
                            return _buildErrorState(context, state);
                          }

                          return _buildLoadingState(context);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final searchColor = AppColorPalette.secondaryMaroon;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isSearchActive ? 70 : 0,
        curve: Curves.easeInOut,
        child: _isSearchActive
            ? Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField( // Added comment to force refresh
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari tahun ajaran...',
                    prefixIcon: Icon(Icons.search, color: searchColor),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.close, color: searchColor),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = "";
                          _isSearchActive = false;
                        });
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              )
            : const SizedBox.shrink(),
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
                                AppColorPalette.primaryMaroon.withValues(alpha: 0.1),
                          ),
                          child: Center(
                            child: Transform.scale(
                              scale: 1 + sin(_controller.value * 2 * pi) * 0.05,
                              child: Icon(
                                Icons.calendar_today_outlined,
                                size: 100,
                                color: AppColorPalette.primaryMaroon
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                const SizedBox(height: 32),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      AppColorPalette.primaryMaroon,
                      AppColorPalette.secondaryMaroon,
                    ],
                  ).createShader(bounds),
                  child: CustomTextContainer(
                    textKey: "Tidak ada tahun ajaran",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    getSessionYears();
                    HapticFeedback.mediumImpact();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    "Refresh Tahun Ajaran",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorPalette.primaryMaroon,
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
      BuildContext context, SessionYearsFetchSuccess state) {
    final sessionYears = _searchQuery.isEmpty
        ? state.sessionYears
        : state.sessionYears
            .where((sessionYear) => (sessionYear.name ?? "")
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

    return AnimationLimiter(
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: Utils.appContentTopScrollPadding(context: context),
                bottom: 16,
                left: appContentHorizontalPadding,
                right: appContentHorizontalPadding,
              ),
              child: sessionYears.isEmpty && _searchQuery.isNotEmpty
                  ? NoSearchResultsWidget(
                      searchQuery: _searchQuery,
                      onClearSearch: () {
                        setState(() {
                          _searchQuery = "";
                          _searchController.clear();
                          _isSearchActive = false;
                        });
                      },
                      primaryColor: AppColorPalette.primaryMaroon,
                      accentColor: AppColorPalette.secondaryMaroon,
                      title: 'Tahun Ajaran Tidak Ditemukan',
                      description:
                          'Tidak ditemukan tahun ajaran yang sesuai dengan pencarian Anda. Coba gunakan kata kunci yang berbeda.',
                      icon: Icons.calendar_today_outlined,
                    ).animate().fadeIn(delay: 300.ms)
                  : _buildEnhancedHeaderCard(context),
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
                        child: _buildEnhancedSessionYearCard(
                            context, sessionYears[index], index),
                      ),
                    ),
                  ),
                ),
                childCount: sessionYears.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeaderCard(BuildContext context) {
    return Hero(
      tag: 'session_year_list_title',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Stack(
          children: [
            Card(
              elevation: 16,
              shadowColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.3),
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
                          AppColorPalette.primaryMaroon.withValues(alpha: 0.9),
                          AppColorPalette.secondaryMaroon.withValues(alpha: 0.9),
                        ],
                        stops: const [0.2, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColorPalette.primaryMaroon.withValues(alpha: 0.2),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CustomTextContainer(
                                        textKey: sessionYearKey,
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
            Positioned(
              right: -25,
              bottom: -15,
              child: Icon(
                Icons.calendar_today,
                size: 100,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
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

  Widget _buildEnhancedSessionYearCard(
      BuildContext context, dynamic sessionYear, int index) {
    final bool isEven = index.isEven;
    final cardGradient = [
      Colors.white,
      Colors.white,
    ];

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0.96, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                },
                borderRadius: BorderRadius.circular(24),
                splashColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.2),
                highlightColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.1),
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
                        color: AppColorPalette.primaryMaroon.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: AppColorPalette.primaryMaroon.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildEnhancedCardHeader(context, sessionYear, isEven),
                      _buildEnhancedCardBody(context, sessionYear, isEven),
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
      BuildContext context, dynamic sessionYear, bool isEven) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColorPalette.primaryMaroon.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        gradient: LinearGradient(
          begin: isEven ? Alignment.centerLeft : Alignment.centerRight,
          end: isEven ? Alignment.centerRight : Alignment.centerLeft,
          colors: [
            AppColorPalette.primaryMaroon.withValues(alpha: 0.15),
            AppColorPalette.secondaryMaroon.withValues(alpha: 0.08),
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
                  sessionYear.name ?? 'Session Year',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColorPalette.primaryMaroon,
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
      BuildContext context, dynamic sessionYear, bool isEven) {
    String yearStatus =
        sessionYear.isThisDefault() ? "Default" : "Tahun Ajaran";

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildEnhancedInfoRow(
              context, 'Status', yearStatus, Icons.check_circle_outline,
              gradient: [
                AppColorPalette.primaryMaroon.withValues(alpha: 0.08),
                AppColorPalette.secondaryMaroon.withValues(alpha: 0.02),
              ]),
          const SizedBox(height: 20),
          if (sessionYear.isThisDefault())
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColorPalette.primaryMaroon,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColorPalette.primaryMaroon.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Default",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
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
            AppColorPalette.primaryMaroon.withValues(alpha: 0.12),
            AppColorPalette.secondaryMaroon.withValues(alpha: 0.08),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColorPalette.primaryMaroon.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColorPalette.primaryMaroon.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColorPalette.primaryMaroon.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColorPalette.primaryMaroon.withValues(alpha: 0.3),
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
                    color: AppColorPalette.secondaryMaroon,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColorPalette.primaryMaroon,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, SessionYearsFetchFailure state) {
    return CustomErrorWidget(
      message: state.errorMessage,
      onRetry: () => getSessionYears(),
      primaryColor: AppColorPalette.primaryMaroon,
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: Utils.appContentTopScrollPadding(context: context),
        bottom: 80,
        left: appContentHorizontalPadding,
        right: appContentHorizontalPadding,
      ),
      child: Column(
        children: [
          // Header card skeleton
          _buildHeaderCardSkeleton(),

          // Session year cards skeleton
          ...List.generate(4, (index) => _buildSessionYearCardSkeleton(index)),

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
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Card(
          elevation: 16,
          shadowColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.3),
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
                        width: 140,
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

  Widget _buildSessionYearCardSkeleton(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with session year name and status
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 18,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
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

              // Status info section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
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
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 16,
                            width: 120,
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

              // Default badge (shown randomly for some cards)
              if (index % 2 == 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 90,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
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

class BackgroundPatternPainter extends CustomPainter {
  final Color color;

  BackgroundPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

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


