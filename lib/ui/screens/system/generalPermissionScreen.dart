import 'package:eschool_saas_staff/cubits/leave/generalPermissionCubit.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/permissionDetailsContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:intl/intl.dart';

class GeneralPermissionScreen extends StatefulWidget {
  const GeneralPermissionScreen({super.key});

  static Widget getRouteInstance() => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => GeneralPermissionCubit(),
          ),
        ],
        child: const GeneralPermissionScreen(),
      );

  @override
  State<GeneralPermissionScreen> createState() =>
      _GeneralPermissionScreenState();
}

class _GeneralPermissionScreenState extends State<GeneralPermissionScreen>
    with TickerProviderStateMixin {
  DateTime _selectedDateTime = DateTime.now();
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;
  Color get _maroonLight => AppColorPalette.secondaryMaroon;

  late AnimationController _fabAnimationController;
  final ScrollController _scrollController = ScrollController();

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
    LeaveDayType leaveDayType = LeaveDayType.today;
    debugPrint("Fetching leaves for date: $_selectedDateTime");
    debugPrint(
        "Formatted date: ${_selectedDateTime.toIso8601String().split('T')[0]}");

    context
        .read<GeneralPermissionCubit>()
        .getGeneralLeaves(leaveDayType: leaveDayType, date: _selectedDateTime);
  }

  Widget _buildAppBar() {
    return CustomModernAppBar(
      title: Utils.getTranslatedLabel(permissionStudentKey),
      icon: Icons.person_outline_rounded,
      fabAnimationController: _fabAnimationController,
      primaryColor: _maroonPrimary,
      lightColor: _maroonLight,
      height: 150,
      onBackPressed: () => Navigator.of(context).pop(),
      // showFilterButton: true,
      onFilterPressed: () async {
        final selectedDate = await Utils.openDatePicker(
          context: context,
          lastDate: DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
        );

        if (selectedDate != null) {
          _selectedDateTime = selectedDate;
          setState(() {});
          debugPrint("Tanggal Terpilih: $_selectedDateTime");
          debugPrint(
              "Tanggal ISO: ${_selectedDateTime.toIso8601String().split('T')[0]}");
          getLeaves();
        }
      },

      tabBuilder: (context) => SizedBox(
        height: 48,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final selectedDate = await Utils.openDatePicker(
                context: context,
                lastDate: DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
              );

              if (selectedDate != null) {
                _selectedDateTime = selectedDate;
                setState(() {});
                debugPrint("Tanggal Terpilih dari tab: $_selectedDateTime");
                debugPrint(
                    "Tanggal ISO dari tab: ${_selectedDateTime.toIso8601String().split('T')[0]}");
                getLeaves();
              }
            },
            borderRadius: BorderRadius.circular(12),
            highlightColor: Colors.white.withValues(alpha: 0.1),
            splashColor: Colors.white.withValues(alpha: 0.2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    Utils.formatDate(_selectedDateTime),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
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
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child:
                    BlocBuilder<GeneralPermissionCubit, GeneralPermissionState>(
                  builder: (context, state) {
                    if (state is GeneralPermissionFetchSuccess) {
                      debugPrint("Total leaves data: ${state.leaves.length}");
                      debugPrint("Selected date: $_selectedDateTime");

                      // Debug: Print all leaves data structure
                      for (int i = 0; i < state.leaves.length; i++) {
                        final permissionDetails = state.leaves[i];
                        debugPrint(
                            "Permission $i: User - ${permissionDetails.user?.fullName ?? 'Unknown'}");
                        debugPrint(
                            "Permission $i: Leaves count - ${permissionDetails.leaves.length}");

                        // Print raw object structure
                        debugPrint(
                            "Permission $i raw: ${permissionDetails.toString()}");

                        // Try to access properties directly (in case of wrong model mapping)
                        try {
                          // Check if permissionDetails has direct student info
                          if (permissionDetails is Map) {
                            debugPrint("Permission $i is Map: $permissionDetails");
                          }
                        } catch (e) {
                          debugPrint("Error checking raw object: $e");
                        }

                        for (int j = 0;
                            j < permissionDetails.leaves.length;
                            j++) {
                          final leave = permissionDetails.leaves[j];
                          debugPrint("  Leave $j: fromDate - ${leave.fromDate}");
                          debugPrint("  Leave $j: toDate - ${leave.toDate}");
                          debugPrint("  Leave $j: reason - ${leave.reason}");
                        }
                      }

                      final filteredLeaves =
                          state.leaves.where((permissionDetails) {
                        bool hasMatchingLeave =
                            permissionDetails.leaves.any((leave) {
                          try {
                            if (leave.fromDate == null ||
                                leave.fromDate!.isEmpty) {
                              debugPrint("Skipping leave with null/empty fromDate");
                              return false;
                            }

                            // Parse date with more flexible approach
                            DateTime leaveDate;
                            try {
                              // Parse dd-MM-yyyy format (e.g., "02-10-2025")
                              leaveDate = DateFormat('dd-MM-yyyy')
                                  .parse(leave.fromDate!);
                            } catch (e) {
                              debugPrint("Error parsing date ${leave.fromDate}: $e");
                              return false;
                            }

                            // Compare dates (ignoring time)
                            final leaveDay = DateTime(
                                leaveDate.year, leaveDate.month, leaveDate.day);
                            final selectedDay = DateTime(_selectedDateTime.year,
                                _selectedDateTime.month, _selectedDateTime.day);

                            final isSameDate =
                                leaveDay.isAtSameMomentAs(selectedDay);

                            if (isSameDate) {
                              debugPrint(
                                  "MATCH FOUND: Siswa izin: ${permissionDetails.user?.fullName ?? 'Unknown'} pada tanggal ${leave.fromDate}");
                            }

                            return isSameDate;
                          } catch (e) {
                            debugPrint("Error processing leave: $e");
                            return false;
                          }
                        });

                        return hasMatchingLeave;
                      }).toList();

                      debugPrint("Filtered leaves count: ${filteredLeaves.length}");

                      if (filteredLeaves.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_ind_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              CustomTextContainer(
                                textKey: Utils.getTranslatedLabel(
                                    noStudentPermissionKey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tanggal: ${Utils.formatDate(_selectedDateTime)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: getLeaves,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh Data'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _maroonPrimary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return SingleChildScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 160,
                            bottom: 25,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title section
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Utils.getTranslatedLabel(
                                          permissionStudentKey),
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: _maroonPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Izin siswa tanggal ${Utils.formatDate(_selectedDateTime)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(duration: 400.ms).slideY(
                                  begin: -0.1,
                                  end: 0,
                                  curve: Curves.easeOutQuad),

                              // Permission containers
                              Column(
                                children: filteredLeaves
                                    .map((permissionDetails) =>
                                        PermissionDetailsContainer(
                                            permissionDetails:
                                                permissionDetails,
                                            onPermissionUpdated: getLeaves))
                                    .toList(),
                              ).animate().fadeIn(duration: 500.ms).slideY(
                                  begin: 0.05,
                                  end: 0,
                                  curve: Curves.easeOutQuad,
                                  duration: 500.ms),
                            ],
                          ),
                        );
                      }
                    } else if (state is GeneralPermissionFetchFailure) {
                      return Center(
                        child: CustomErrorWidget(
                          message: ErrorMessageUtils.getReadableErrorMessage(
                              state.errorMessage),
                          onRetry: getLeaves,
                          primaryColor: _maroonPrimary,
                        ),
                      );
                    } else {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 160,
                          bottom: 25,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title section skeleton
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey.shade300,
                                highlightColor: Colors.grey.shade100,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 24,
                                      width: 200,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 14,
                                      width: 300,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Permission containers skeleton
                            Column(
                              children: List.generate(5, (index) {
                                return Container(
                                  margin:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Student info section
                                          Row(
                                            children: [
                                              // Avatar
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              // Student details
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
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Container(
                                                      height: 14,
                                                      width: 120,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
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
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 16),

                                          // Permission details section
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                // Reason
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
                                                    Expanded(
                                                      child: Container(
                                                        height: 14,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
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
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          _buildAppBar(),
        ],
      ),
    );
  }
}
