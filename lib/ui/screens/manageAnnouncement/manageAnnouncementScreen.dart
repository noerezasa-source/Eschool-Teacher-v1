import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/announcement/announcementsCubit.dart';
import 'package:eschool_saas_staff/cubits/userDetails/staffAllowedPermissionsAndModulesCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/ui/screens/manageAnnouncement/widgets/announcementFilesBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customRoundedButton.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/no_search_results_widget.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/systemModulesAndPermissions.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class ManageAnnouncementScreen extends StatefulWidget {
  const ManageAnnouncementScreen({super.key});

  static Widget getRouteInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AnnouncementsCubit(),
        ),
        BlocProvider(
          create: (context) => ClassesCubit(),
        ),
      ],
      child: ManageAnnouncementScreen(
        key: screenKey,
      ),
    );
  }

  static GlobalKey<ManageAnnouncementScreenState> screenKey =
      GlobalKey<ManageAnnouncementScreenState>();

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<ManageAnnouncementScreen> createState() =>
      ManageAnnouncementScreenState();
}

class ManageAnnouncementScreenState extends State<ManageAnnouncementScreen>
    with TickerProviderStateMixin {
  ClassSection? _selectedClassSection;

  late final ScrollController _scrollController = ScrollController()
    ..addListener(scrollListener);

  late AnimationController _fabAnimationController;
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;
  Color get _maroonLight => AppColorPalette.secondaryMaroon;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<ClassesCubit>().getClasses();
      }
    });
  }

  void getAnnouncements() {
    context
        .read<AnnouncementsCubit>()
        .getAnnouncements(classSectionId: _selectedClassSection?.id ?? 0);
  }

  void getMoreAnnouncements() {
    context
        .read<AnnouncementsCubit>()
        .fetchMore(classSectionId: _selectedClassSection?.id ?? 0);
  }

  void changeSelectedClassSection(ClassSection value) {
    _selectedClassSection = value;
    setState(() {});
    getAnnouncements();
  }

  @override
  void dispose() {
    _scrollController.removeListener(scrollListener);
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void scrollListener() {
    if (_scrollController.offset ==
        _scrollController.position.maxScrollExtent) {
      if (context.read<AnnouncementsCubit>().hasMore()) {
        getMoreAnnouncements();
      }
    }

    // Animate FAB based on scroll
    if (_scrollController.offset > 50) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  Widget _buildAddAnnouncementButton() {
    return context
            .read<StaffAllowedPermissionsAndModulesCubit>()
            .isPermissionGiven(permission: createAnnouncementPermissionKey)
        ? BlocBuilder<AnnouncementsCubit, AnnouncementsState>(
            builder: (context, state) {
              if (state is AnnouncementsFetchSuccess) {
                return AnimatedBuilder(
                  animation: _fabAnimationController,
                  builder: (context, child) {
                    // Scale FAB from the bottom
                    return ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 0.0)
                          .animate(CurvedAnimation(
                        parent: _fabAnimationController,
                        curve: Curves.easeInOut,
                      )),
                      child: child,
                    );
                  },
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: EdgeInsets.all(appContentHorizontalPadding),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.white,
                            Colors.white,
                          ],
                        ),
                      ),
                      width: MediaQuery.of(context).size.width,
                      height: 90,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _maroonPrimary,
                              _maroonLight,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: _maroonPrimary.withValues(alpha: 0.3),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            highlightColor: Colors.white.withValues(alpha: 0.1),
                            splashColor: Colors.white.withValues(alpha: 0.2),
                            onTap: () {
                              Get.toNamed(Routes.addAnnouncementScreen);
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    Utils.getTranslatedLabel(
                                        addAnnouncementKey),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return const SizedBox();
            },
          )
        : const SizedBox();
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isSearchActive ? 56 : 0,
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
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari pengumuman...',
                  prefixIcon: Icon(Icons.search, color: _maroonLight),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.close, color: _maroonLight),
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
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kelola Pengumuman',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _maroonPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kelola semua pengumuman yang dikirim ke pengguna',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.1, end: 0, curve: Curves.easeOutQuad);
  }

  Widget _buildAnnouncementItemSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with number badge and title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number badge skeleton
                  Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 12, top: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Title and metadata skeleton
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title skeleton
                        Container(
                          height: 16,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),

                        // Metadata row skeleton
                        Row(
                          children: [
                            const SizedBox(width: 12),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              height: 12,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Arrow icon skeleton
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),

              // Description preview skeleton
              Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 48),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
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
                      Expanded(
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Status badge skeleton
              Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 48),
                child: Row(
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      width: 80,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
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

  Widget _buildManageAnnouncementSkeleton() {
    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100, top: 0),
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Header skeleton
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
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
                          child: Row(
                            children: [
                              // Icon skeleton
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Title and count skeleton
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 16,
                                      width: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      height: 12,
                                      width: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Counter badge skeleton
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Announcement items skeleton
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: List.generate(
                            6,
                            (index) => Column(
                              children: [
                                _buildAnnouncementItemSkeleton(),
                                if (index < 5)
                                  Divider(
                                    color: Colors.grey[100],
                                    thickness: 1,
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16,
                                  ),
                              ],
                            ),
                          ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomModernAppBar(
        title: 'Pengumuman',
        icon: Icons.campaign,
        fabAnimationController: _fabAnimationController,
        primaryColor: _maroonPrimary,
        lightColor: _maroonLight,
        onBackPressed: () => Navigator.of(context).pop(),
        showSearchButton: true,
        onSearchPressed: () {
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
          BlocBuilder<ClassesCubit, ClassesState>(
            builder: (context, classState) {
              if (classState is ClassesFetchSuccess) {
                if (classState.classes.isNotEmpty &&
                    _selectedClassSection == null) {
                  // Initialize selected class when classes are loaded
                  Future.microtask(() {
                    changeSelectedClassSection(classState.classes.first);
                  });
                }

                return BlocBuilder<AnnouncementsCubit, AnnouncementsState>(
                  builder: (context, state) {
                    if (state is AnnouncementsFetchSuccess) {
                      // Filter announcements based on search query if active
                      final announcements = _searchQuery.isEmpty
                          ? state.announcements
                          : state.announcements
                              .where((announcement) =>
                                  (announcement.title ?? "")
                                      .toLowerCase()
                                      .contains(_searchQuery.toLowerCase()) ||
                                  (announcement.description ?? "")
                                      .toLowerCase()
                                      .contains(_searchQuery.toLowerCase()))
                              .toList();

                      return Align(
                        alignment: Alignment.topCenter,
                        child: RefreshIndicator(
                          onRefresh: () async {
                            getAnnouncements();
                          },
                          color: _maroonPrimary,
                          displacement: Utils.appContentTopScrollPadding(
                                  context: context) +
                              25,
                          child: Column(
                            children: [
                              _buildHeader(),
                              _buildSearchBar(),
                              Expanded(
                                child: announcements.isEmpty &&
                                        _searchQuery.isNotEmpty
                                    ? NoSearchResultsWidget(
                                        searchQuery: _searchQuery,
                                        onClearSearch: () {
                                          setState(() {
                                            _searchQuery = "";
                                            _searchController.clear();
                                            _isSearchActive = false;
                                          });
                                        },
                                        primaryColor: _maroonPrimary,
                                        accentColor: _maroonLight,
                                        title: 'Pengumuman Tidak Ditemukan',
                                        description:
                                            'Tidak ditemukan pengumuman yang sesuai dengan pencarian Anda. Coba gunakan kata kunci yang berbeda.',
                                        icon: Icons.campaign_outlined,
                                      ).animate().fadeIn(delay: 300.ms)
                                    : ListView(
                                        controller: _scrollController,
                                        padding: const EdgeInsets.only(
                                          bottom: 100,
                                          top: 0,
                                        ),
                                        children: [
                                          // Updated container design for the announcement items section
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 16),
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Column(
                                              children: [
                                                // Elegant header with animated gradient
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20,
                                                      vertical: 16),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        _maroonPrimary
                                                            .withValues(
                                                                alpha: 0.9),
                                                        _maroonPrimary,
                                                        _maroonLight,
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        const BorderRadius
                                                            .vertical(
                                                            top:
                                                                Radius.circular(
                                                                    16)),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: _maroonPrimary
                                                            .withValues(
                                                                alpha: 0.3),
                                                        blurRadius: 10,
                                                        offset:
                                                            const Offset(0, 3),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      // Animated icon
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white
                                                              .withValues(
                                                                  alpha: 0.2),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons
                                                              .campaign_rounded,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                      )
                                                          .animate()
                                                          .fadeIn(
                                                              duration: 300.ms)
                                                          .slideX(
                                                              begin: -0.2,
                                                              end: 0),

                                                      const SizedBox(width: 16),

                                                      // Title text
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              Utils.getTranslatedLabel(
                                                                  announcementKey),
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                                color: Colors
                                                                    .white,
                                                                letterSpacing:
                                                                    0.5,
                                                              ),
                                                            ),
                                                            Text(
                                                              '${announcements.length} pengumuman tersedia',
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .white
                                                                    .withValues(
                                                                        alpha:
                                                                            0.8),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                      // Counter badge with animation
                                                      Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white
                                                              .withValues(
                                                                  alpha: 0.2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            announcements.length
                                                                .toString(),
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                          .animate()
                                                          .fadeIn(
                                                              duration: 400.ms)
                                                          .scale(
                                                              begin:
                                                                  const Offset(
                                                                      0.8, 0.8),
                                                              end: const Offset(
                                                                  1.0, 1.0),
                                                              duration: 400.ms),
                                                    ],
                                                  ),
                                                ),

                                                // Announcements list with enhanced styling
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        const BorderRadius
                                                            .vertical(
                                                            bottom:
                                                                Radius.circular(
                                                                    16)),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                                alpha: 0.05),
                                                        blurRadius: 10,
                                                        offset:
                                                            const Offset(0, 5),
                                                        spreadRadius: 0,
                                                      ),
                                                    ],
                                                  ),
                                                  child: announcements.isEmpty
                                                      ? Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 40),
                                                          child: Column(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .notifications_off_rounded,
                                                                size: 60,
                                                                color: Colors
                                                                    .grey[300],
                                                              ),
                                                              const SizedBox(
                                                                  height: 16),
                                                              Text(
                                                                'Belum ada pengumuman',
                                                                style:
                                                                    GoogleFonts
                                                                        .poppins(
                                                                  fontSize: 16,
                                                                  color: Colors
                                                                          .grey[
                                                                      600],
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 8),
                                                              Text(
                                                                'Pengumuman yang dibuat akan ditampilkan di sini',
                                                                style:
                                                                    GoogleFonts
                                                                        .poppins(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                          .grey[
                                                                      400],
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ],
                                                          ),
                                                        ).animate().fadeIn(
                                                          duration: 400.ms)
                                                      : ClipRRect(
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .vertical(
                                                                  bottom: Radius
                                                                      .circular(
                                                                          16)),
                                                          child: ListView
                                                              .separated(
                                                            physics:
                                                                const NeverScrollableScrollPhysics(),
                                                            shrinkWrap: true,
                                                            padding:
                                                                EdgeInsets.zero,
                                                            itemCount:
                                                                _buildAnnouncementItems(
                                                                        announcements,
                                                                        state)
                                                                    .length,
                                                            separatorBuilder:
                                                                (context,
                                                                        index) =>
                                                                    Divider(
                                                              color: Colors
                                                                  .grey[100],
                                                              thickness: 1,
                                                              height: 1,
                                                              indent: 16,
                                                              endIndent: 16,
                                                            ),
                                                            itemBuilder: (context,
                                                                    index) =>
                                                                _buildAnnouncementItems(
                                                                    announcements,
                                                                    state)[index],
                                                          ),
                                                        ),
                                                ),
                                              ],
                                            ),
                                          )
                                              .animate()
                                              .fadeIn(duration: 500.ms)
                                              .slideY(
                                                  begin: 0.05,
                                                  end: 0,
                                                  curve: Curves.easeOutQuad),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is AnnouncementsFetchFailure) {
                      return Center(
                        child: CustomErrorWidget(
                          message: state.errorMessage,
                          onRetry: () {
                            getAnnouncements();
                          },
                          primaryColor: _maroonPrimary,
                        ),
                      );
                    }

                    if (_selectedClassSection != null) {
                      return _buildManageAnnouncementSkeleton();
                    }

                    return const SizedBox();
                  },
                );
              }

              if (classState is ClassesFetchFailure) {
                return Center(
                  child: CustomErrorWidget(
                    message: classState.errorMessage,
                    onRetry: () {
                      context.read<ClassesCubit>().getClasses();
                    },
                    primaryColor: _maroonPrimary,
                  ),
                );
              }

              return _buildManageAnnouncementSkeleton();
            },
          ),
          _buildAddAnnouncementButton(),
        ],
      ),
    );
  }

  List<Widget> _buildAnnouncementItems(
      List<dynamic> announcements, AnnouncementsFetchSuccess state) {
    List<Widget> items = [];

    for (int index = 0; index < announcements.length; index++) {
      final announcement = announcements[index];
      // Add announcement item with enhanced styling and animation
      items.add(
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                // Handle tap to show announcement details
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) {
                    return DraggableScrollableSheet(
                      initialChildSize: 0.8,
                      minChildSize: 0.5,
                      maxChildSize: 0.95,
                      builder: (context, scrollController) {
                        return Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Handle bar
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),

                              // Header with edit and close buttons
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Detail Pengumuman',
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: _maroonPrimary,
                                        ),
                                      ),
                                    ),
                                    // Edit button
                                    IconButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pushNamed(
                                          context,
                                          Routes.editAnnouncementScreen,
                                          arguments: {
                                            "announcement": announcement,
                                          },
                                        ).then((result) {
                                          if (!context.mounted) return;
                                          if (result != null &&
                                              result == true) {
                                            context
                                                .read<AnnouncementsCubit>()
                                                .getAnnouncements(
                                                    classSectionId:
                                                        _selectedClassSection
                                                                ?.id ??
                                                            0);
                                          }
                                        });
                                      },
                                      icon: const Icon(Icons.edit_outlined),
                                      color: _maroonPrimary,
                                      tooltip: 'Edit Pengumuman',
                                    ),
                                    // Close button
                                    IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(Icons.close),
                                      color: Colors.grey[600],
                                      tooltip: 'Tutup',
                                    ),
                                  ],
                                ),
                              ),

                              // Content
                              Expanded(
                                child: SingleChildScrollView(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Title section
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: _maroonPrimary.withValues(
                                              alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _maroonPrimary.withValues(
                                                alpha: 0.3),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: _maroonPrimary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.title,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Judul Pengumuman',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: _maroonPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              announcement.title ??
                                                  'Tanpa judul',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      // Description section
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _maroonPrimary.withValues(
                                                alpha: 0.3),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.05),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: _maroonPrimary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.description_outlined,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Deskripsi',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: _maroonPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              announcement.description ??
                                                  'Tidak ada deskripsi',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.black87,
                                                height: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Files section if available
                                      if ((announcement.files ?? [])
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 20),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: _maroonLight.withValues(
                                                alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _maroonLight,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: _maroonLight,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.attach_file_rounded,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'File Terlampir',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: _maroonLight,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                '${announcement.files?.length ?? 0} file tersedia',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              ElevatedButton(
                                                onPressed: () {
                                                  // Show files in separate bottom sheet
                                                  Utils.showBottomSheet(
                                                    child:
                                                        AnnouncementFilesBottomsheet(
                                                      files:
                                                          announcement.files ??
                                                              [],
                                                    ),
                                                    context: context,
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: _maroonLight,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Lihat File',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      const SizedBox(
                                          height: 40), // Extra space at bottom
                                    ],
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
              },
              splashColor: _maroonPrimary.withValues(alpha: 0.1),
              highlightColor: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with number and title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Elegant number badge
                        Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(right: 12, top: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _maroonPrimary.withValues(alpha: 0.8),
                                _maroonLight.withValues(alpha: 0.9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: _maroonPrimary.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),

                        // Title and metadata
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title with truncation
                              Text(
                                announcement.title ?? 'Tanpa judul',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.grey[800],
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 6),

                              // Modified date info (removed createdBy reference)
                              Row(
                                children: [
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.label_outline,
                                    size: 14,
                                    color:
                                        _maroonPrimary.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Pengumuman',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Interactive icon button
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: _maroonPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Preview of announcement content
                    if ((announcement.description ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0, left: 48),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey[100]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 16,
                                color: _maroonLight,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  announcement.description ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Status and actions row - Fixed status property reference
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0, left: 48),
                      child: Row(
                        children: [
                          // Generic status indicator (doesn't rely on model properties)

                          const Spacer(),

                          // Badge showing type
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _maroonPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Pengumuman',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _maroonPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: (50 * index).ms).slideY(
              begin: 0.1,
              end: 0,
              curve: Curves.easeOutQuad,
              duration: 500.ms,
              delay: (50 * index).ms,
            ),
      );

      // Load more indicator section
      if (context.read<AnnouncementsCubit>().hasMore() &&
          index == announcements.length - 1) {
        if (state.fetchMoreError) {
          items.add(
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Material(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      getMoreAnnouncements();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: _maroonPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            Utils.getTranslatedLabel(retryKey),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _maroonPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
          );
        } else {
          items.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _maroonPrimary.withValues(alpha: 0.8),
                        _maroonLight.withValues(alpha: 0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _maroonPrimary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),
          );
        }
      }
    }

    return items;
  }
}

// Custom painter for decorative elements
// Error container widget to display errors with retry option
class ErrorContainer extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onTapRetry;

  const ErrorContainer({
    required this.errorMessage,
    required this.onTapRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 60,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Terjadi Kesalahan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          CustomRoundedButton(
            onTap: onTapRetry,
            widthPercentage: 0.7,
            backgroundColor: Colors.red[300] ?? Colors.red,
            buttonTitle: 'Coba Lagi',
            showBorder: false,
            titleColor: Colors.white,
            height: 45,
          ),
        ],
      ),
    );
  }
}
