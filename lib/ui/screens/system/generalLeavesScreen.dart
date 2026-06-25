import 'package:eschool_saas_staff/cubits/leave/generalLeavesCubit.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/leave/leaveDetailsContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class GeneralLeavesScreen extends StatefulWidget {
  const GeneralLeavesScreen({super.key});

  static Widget getRouteInstance() => BlocProvider(
        create: (context) => GeneralLeavesCubit(),
        child: const GeneralLeavesScreen(),
      );

  @override
  State<GeneralLeavesScreen> createState() => _GeneralLeavesScreenState();
}

class _GeneralLeavesScreenState extends State<GeneralLeavesScreen>
    with TickerProviderStateMixin {
  late String _selectedTabTitleKey = todayKey;
  late AnimationController _fabAnimationController;
  final ScrollController _scrollController = ScrollController();
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      getLeaves();
    });

    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scrollController.addListener(_scrollListener);
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

  void getLeaves() {
    debugPrint('\n=== DEBUG: GeneralLeavesScreen.getLeaves() ===');
    LeaveDayType leaveDayType = LeaveDayType.today;

    if (_selectedTabTitleKey == tomorrowKey) {
      leaveDayType = LeaveDayType.tomorrow;
    } else if (_selectedTabTitleKey == upcomingKey) {
      leaveDayType = LeaveDayType.upcoming;
    }

    debugPrint('Selected tab: $_selectedTabTitleKey');
    debugPrint('Leave day type: $leaveDayType');

    context
        .read<GeneralLeavesCubit>()
        .getGeneralLeaves(leaveDayType: leaveDayType);
  }

  void changeTab(String value) {
    setState(() {
      _selectedTabTitleKey = value;
    });
    getLeaves();
  }

  Widget _buildFilterTabs(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFilterTab(todayKey),
        _buildVerticalDivider(),
        _buildFilterTab(tomorrowKey),
        _buildVerticalDivider(),
        _buildFilterTab(upcomingKey),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 24,
      width: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String tabKey) {
    final bool isSelected = tabKey == _selectedTabTitleKey;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => changeTab(tabKey),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          splashColor: Colors.white.withValues(alpha: 0.2),
          child: Container(
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                Utils.getTranslatedLabel(tabKey),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: Colors.white.withValues(alpha: isSelected ? 1 : 0.7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomModernAppBar(
        title: Utils.getTranslatedLabel(leavesKey),
        icon: Icons.event_note_rounded,
        fabAnimationController: _fabAnimationController,
        primaryColor: _maroonPrimary,
        lightColor: AppColorPalette.secondaryMaroon,
        onBackPressed: () => Navigator.of(context).pop(),
        height: 140, // Increased height to accommodate filters
        tabBuilder: (context) => _buildFilterTabs(context),
      ),
      body: BlocBuilder<GeneralLeavesCubit, GeneralLeavesState>(
        builder: (context, state) {
          debugPrint('\n=== DEBUG: GeneralLeavesScreen BlocBuilder ===');
          debugPrint('Current state: ${state.runtimeType}');

          if (state is GeneralLeavesFetchSuccess) {
            debugPrint('State: GeneralLeavesFetchSuccess');
            debugPrint('Number of leaves: ${state.leaves.length}');

            if (state.leaves.isEmpty) {
              debugPrint('No leaves found - showing empty message');
              // If empty, show "No teacher on leave" text
              return Center(
                child: CustomTextContainer(
                  textKey: Utils.getTranslatedLabel('Tidak ada guru yang cuti'),
                ),
              );
            } else {
              debugPrint('Displaying ${state.leaves.length} leaves');
              return SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: 20, // Reduced padding since appBar handles spacing
                  bottom: 100,
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.symmetric(
                      vertical: appContentHorizontalPadding),
                  child: Column(
                    children: state.leaves
                        .map((leaveDetails) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: LeaveDetailsContainer(
                                  leaveDetails: leaveDetails),
                            ))
                        .toList(),
                  ).animate().fadeIn(duration: 500.ms).slideY(
                        begin: 0.05,
                        end: 0,
                        curve: Curves.easeOutQuad,
                        duration: 500.ms,
                      ),
                ),
              );
            }
          }
          if (state is GeneralLeavesFetchFailure) {
            return Center(
              child: CustomErrorWidget(
                message: state.errorMessage,
                onRetry: getLeaves,
                primaryColor: _maroonPrimary,
              ),
            );
          }
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 100,
            ),
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding:
                  EdgeInsets.symmetric(vertical: appContentHorizontalPadding),
              child: Column(
                children: List.generate(6, (index) {
                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            // Header section with teacher info
                            Row(
                              children: [
                                // Avatar placeholder
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Teacher details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 16,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        height: 14,
                                        width: 120,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Status badge
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

                            // Leave details section
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date range
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
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Type and days
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
                                        width: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Container(
                                        height: 14,
                                        width: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Reason
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              height: 14,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              height: 14,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.6,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6),
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
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms);
        },
      ),
    );
  }
}
