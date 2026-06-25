import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/announcement/notificationsCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/userDetails/staffAllowedPermissionsAndModulesCubit.dart';
import 'package:eschool_saas_staff/data/models/system/notificationDetails.dart';
import 'package:eschool_saas_staff/ui/screens/manageNotification/widgets/adminNotificationDetailsContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextButton.dart';
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

class ManageNotificationScreen extends StatefulWidget {
  const ManageNotificationScreen({super.key});

  static Widget getRouteInstance() {
    return BlocProvider(
      create: (context) => NotificationsCubit(),
      child: ManageNotificationScreen(
        key: screenKey,
      ),
    );
  }

  static GlobalKey<ManageNotificationScreenState> screenKey =
      GlobalKey<ManageNotificationScreenState>();

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<ManageNotificationScreen> createState() =>
      ManageNotificationScreenState();
}

class ManageNotificationScreenState extends State<ManageNotificationScreen>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController = ScrollController()
    ..addListener(scrollListener);

  late AnimationController _fabAnimationController;
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;
  Color get _maroonLight => AppColorPalette.secondaryMaroon;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _hasSearchText = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    // Add listener to search controller for better state management
    _searchController.addListener(() {
      setState(() {
        _hasSearchText = _searchController.text.isNotEmpty;
      });
    });

    Future.delayed(Duration.zero, () {
      getNotifications();
    });
  }

  void getNotifications() {
    context.read<NotificationsCubit>().getNotifications();
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
      if (context.read<NotificationsCubit>().hasMore()) {
        context.read<NotificationsCubit>().fetchMore();
      }
    }

    // Animate FAB based on scroll
    if (_scrollController.offset > 50) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  Widget _buildAddNotificationButton() {
    return context
            .read<StaffAllowedPermissionsAndModulesCubit>()
            .isPermissionGiven(permission: createNotificationPermissionKey)
        ? BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsFetchSuccess) {
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
                              Get.toNamed(Routes.addNotificationScreen);
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
                                        addNotificationKey),
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
      duration: const Duration(milliseconds: 400),
      height: _isSearchActive ? 80 : 0,
      curve: Curves.easeInOutCubic,
      child: _isSearchActive
          ? Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _maroonPrimary.withValues(alpha: 0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _maroonPrimary.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasSearchText
                        ? _maroonPrimary.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Search Icon with animated background
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(left: 12, right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _hasSearchText
                            ? _maroonPrimary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        color: _hasSearchText ? _maroonPrimary : _maroonLight,
                        size: 20,
                      ),
                    ),
                    // Text Field
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari berdasarkan judul',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey[450],
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.1,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(
                            top: -10,
                            bottom: 16,
                            left: 0,
                            right: 0,
                          ),
                          alignLabelWithHint: true,
                          isCollapsed: false,
                        ),
                        textAlignVertical: TextAlignVertical.center,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    // Clear Button with animation
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _hasSearchText
                          ? Container(
                              key: const ValueKey('clear_button'),
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = "";
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.clear_rounded,
                                      color: Colors.grey[600],
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox(key: ValueKey('empty'), width: 0),
                    ),
                    // Close Button with premium design
                    //   Container(
                    //     margin: const EdgeInsets.only(right: 8),
                    //     decoration: BoxDecoration(
                    //       gradient: LinearGradient(
                    //         colors: [
                    //           _maroonPrimary,
                    //           _maroonLight,
                    //         ],
                    //         begin: Alignment.topLeft,
                    //         end: Alignment.bottomRight,
                    //       ),
                    //       borderRadius: BorderRadius.circular(10),
                    //       boxShadow: [
                    //         BoxShadow(
                    //           color: _maroonPrimary.withValues(alpha: 0.3),
                    //           blurRadius: 8,
                    //           offset: const Offset(0, 2),
                    //           spreadRadius: -2,
                    //         ),
                    //       ],
                    //     ),
                    //     child: Material(
                    //       color: Colors.transparent,
                    //       child: InkWell(
                    //         borderRadius: BorderRadius.circular(10),
                    //         onTap: () {
                    //           setState(() {
                    //             _searchController.clear();
                    //             _searchQuery = "";
                    //             _isSearchActive = false;
                    //             _hasSearchText = false;
                    //           });
                    //         },
                    //         child: Padding(
                    //           padding: const EdgeInsets.all(10),
                    //           child: Icon(
                    //             Icons.close_rounded,
                    //             color: Colors.white,
                    //             size: 18,
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),
              ),
            )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: -0.5, end: 0, curve: Curves.easeOutQuart)
              .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.easeOutQuart)
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
            'Kelola Notifikasi',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _maroonPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kelola semua notifikasi yang dikirim ke pengguna',
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

  Widget _buildTableHeaderSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _maroonPrimary.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Container(
                height: 16,
                width: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItemSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with number and title
            Row(
              children: [
                // Number badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),

                const SizedBox(width: 12),

                // Icon placeholder
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 12),

                // Title and date placeholders
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
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
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow icon placeholder
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageNotificationSkeleton() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 100, top: 0),
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header Row
                    _buildTableHeaderSkeleton(),

                    // Notification Items
                    Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        color: Colors.white,
                      ),
                      child: Column(
                        children: List.generate(6, (index) {
                          return _buildNotificationItemSkeleton();
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomModernAppBar(
        title: 'Kelola Notifikasi',
        icon: Icons.notifications_active,
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
              _hasSearchText = false;
            }
          });
        },
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Stack(
              children: [
                BlocBuilder<NotificationsCubit, NotificationsState>(
                  builder: (context, state) {
                    if (state is NotificationsFetchSuccess) {
                      // Filter notifications based on search query if active
                      final notifications = _searchQuery.isEmpty
                          ? state.notifications
                          : state.notifications
                              .where((notification) =>
                                  (notification.title ?? "")
                                      .toLowerCase()
                                      .contains(_searchQuery.toLowerCase()) ||
                                  (notification.message ?? "")
                                      .toLowerCase()
                                      .contains(_searchQuery.toLowerCase()))
                              .toList();

                      return RefreshIndicator(
                        onRefresh: () async {
                          getNotifications();
                        },
                        color: _maroonPrimary,
                        displacement: 25,
                        child: Column(
                          children: [
                            _buildHeader(),
                            Expanded(
                              child: notifications.isEmpty &&
                                      _searchQuery.isNotEmpty
                                  ? NoSearchResultsWidget(
                                      searchQuery: _searchQuery,
                                      onClearSearch: () {
                                        setState(() {
                                          _searchQuery = "";
                                          _searchController.clear();
                                          _isSearchActive = false;
                                          _hasSearchText = false;
                                        });
                                      },
                                      primaryColor: _maroonPrimary,
                                      accentColor: _maroonLight,
                                      title: 'Notifikasi Tidak Ditemukan',
                                      description:
                                          'Tidak ditemukan notifikasi yang sesuai dengan pencarian Anda. Coba gunakan kata kunci yang berbeda.',
                                      icon: Icons.notifications_outlined,
                                    ).animate().fadeIn(delay: 300.ms)
                                  : ListView(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.only(
                                        bottom: 100,
                                        top: 0,
                                      ),
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.05),
                                                blurRadius: 10,
                                                spreadRadius: 0,
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            children: [
                                              // Header Row
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: _maroonPrimary
                                                      .withValues(alpha: 0.08),
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(16),
                                                    topRight:
                                                        Radius.circular(16),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 40,
                                                      child: Text(
                                                        "#",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                          color: _maroonPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        Utils
                                                            .getTranslatedLabel(
                                                                nameKey),
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                          color: _maroonPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Notification Items
                                              Container(
                                                decoration: const BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    bottomLeft:
                                                        Radius.circular(16),
                                                    bottomRight:
                                                        Radius.circular(16),
                                                  ),
                                                  color: Colors.white,
                                                ),
                                                child: Column(
                                                  children:
                                                      _buildNotificationItems(
                                                          notifications, state),
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
                    if (state is NotificationsFetchFailure) {
                      return Center(
                        child: CustomErrorWidget(
                          message: state.errorMessage,
                          onRetry: () {
                            getNotifications();
                          },
                          primaryColor: _maroonPrimary,
                        ),
                      );
                    }

                    return _buildManageNotificationSkeleton();
                  },
                ),
                _buildAddNotificationButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNotificationItems(List<NotificationDetails> notifications,
      NotificationsFetchSuccess state) {
    List<Widget> items = [];

    for (int index = 0; index < notifications.length; index++) {
      // Add notification item with animation
      items.add(
        Container(
          margin: EdgeInsets.only(
            bottom: index == notifications.length - 1 ? 0 : 1,
          ),
          child: AdminNotificationDetailsContainer(
            notificationDetails: notifications[index],
            index: index,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: (50 * index).ms).slideY(
              begin: 0.1,
              end: 0,
              curve: Curves.easeOutQuad,
              duration: 500.ms,
              delay: (50 * index).ms,
            ),
      );

      // Add 'load more' indicator or error if it's the last item
      if (context.read<NotificationsCubit>().hasMore() &&
          index == notifications.length - 1) {
        if (state.fetchMoreError) {
          items.add(
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: CustomTextButton(
                  buttonTextKey: retryKey,
                  onTapButton: () {
                    context.read<NotificationsCubit>().fetchMore();
                  },
                ),
              ),
            ),
          );
        } else {
          items.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _maroonPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_maroonPrimary),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    return items;
  }
}
