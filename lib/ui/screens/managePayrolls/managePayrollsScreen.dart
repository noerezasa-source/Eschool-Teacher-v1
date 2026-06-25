import 'package:eschool_saas_staff/cubits/payRoll/payRollYearsCubit.dart';
import 'package:eschool_saas_staff/cubits/payRoll/staffsPayrollCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/payRoll/submitStaffsPayRollCubit.dart';
import 'package:eschool_saas_staff/cubits/userDetails/staffAllowedPermissionsAndModulesCubit.dart';
import 'package:eschool_saas_staff/data/models/payroll/staffPayRoll.dart';
import 'package:eschool_saas_staff/ui/screens/managePayrolls/widgets/staffPayrollDetailsContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/system/no_search_results_widget.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/systemModulesAndPermissions.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class ManagePayrollsScreen extends StatefulWidget {
  const ManagePayrollsScreen({super.key});

  static Widget getRouteInstance() {
    //final arguments = Get.arguments as Map<String,dynamic>;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PayRollYearsCubit(),
        ),
        BlocProvider(
          create: (context) => StaffsPayrollCubit(),
        ),
        BlocProvider(
          create: (context) => SubmitStaffsPayRollCubit(),
        ),
      ],
      child: const ManagePayrollsScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<ManagePayrollsScreen> createState() => _ManagePayrollsScreenState();
}

class _ManagePayrollsScreenState extends State<ManagePayrollsScreen>
    with TickerProviderStateMixin {
  int? _selectedYear;

  // Get the month key from month number (1-12)
  String _getMonthKey(int month) {
    switch (month) {
      case 1:
        return januaryKey;
      case 2:
        return februaryKey;
      case 3:
        return marchKey;
      case 4:
        return aprilKey;
      case 5:
        return mayKey;
      case 6:
        return juneKey;
      case 7:
        return julyKey;
      case 8:
        return augustKey;
      case 9:
        return septemberKey;
      case 10:
        return octoberKey;
      case 11:
        return novemberKey;
      case 12:
        return decemberKey;
      default:
        return januaryKey;
    }
  }

  late String _selectedMonthKey = _getMonthKey(DateTime.now().month);

  // Color scheme for maroon theme
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;
  Color get _maroonLight => AppColorPalette.secondaryMaroon;

  // Search functionality
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Animation controller for FAB and other animated elements
  late AnimationController _fabAnimationController;
  late final ScrollController _scrollController = ScrollController()
    ..addListener(scrollListener);

  final List<StaffPayRoll> _selectedStaffs = [];

  final List<GlobalKey<StaffPayrollDetailsContainerState>>
      _staffsPayRollDetailsContainerKeys = [];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<PayRollYearsCubit>().getPayRollYears();
      }
    });
  }

  void scrollListener() {
    // Animate FAB based on scroll
    if (_scrollController.offset > 50) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(scrollListener);
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void changeSelectedYear(int year) {
    _selectedYear = year;
    setState(() {});
    getStaffsPayRoll();
  }

  void changeSelectedMonth(String month) {
    _selectedMonthKey = month;
    setState(() {});
    getStaffsPayRoll();
  }

  int getSelectedMonthNumber() {
    // Get month number based on selected month key
    for (int i = 0; i < months.length; i++) {
      if (months[i].toLowerCase() == _selectedMonthKey.toLowerCase()) {
        return i + 1; // Month numbers are 1-based (January = 1)
      }
    }

    // If month key not found in the months list, try direct mapping
    final Map<String, int> monthMap = {
      // Direct mapping for common month keys
      januaryKey: 1,
      februaryKey: 2,
      marchKey: 3,
      aprilKey: 4,
      mayKey: 5,
      juneKey: 6,
      julyKey: 7,
      augustKey: 8,
      septemberKey: 9,
      octoberKey: 10,
      novemberKey: 11,
      decemberKey: 12,
    };

    // Try to get from map, otherwise default to current month
    return monthMap[_selectedMonthKey.toLowerCase()] ?? DateTime.now().month;
  }

  void getStaffsPayRoll() {
    if (_selectedStaffs.isNotEmpty) {
      _selectedStaffs.clear();
      setState(() {});
    }

    final monthNumber = getSelectedMonthNumber();
    debugPrint(
        "Getting staff payroll for: Year: ${_selectedYear ?? 0}, Month: $monthNumber ($_selectedMonthKey)");

    context
        .read<StaffsPayrollCubit>()
        .getStaffsPayroll(year: _selectedYear ?? 0, month: monthNumber);
  }

  Widget _buildSubmitButton() {
    return context
                .read<StaffAllowedPermissionsAndModulesCubit>()
                .isPermissionGiven(permission: createPayRollPermissionKey) ||
            context
                .read<StaffAllowedPermissionsAndModulesCubit>()
                .isPermissionGiven(permission: editPayrollEditPermissionKey)
        ? BlocConsumer<SubmitStaffsPayRollCubit, SubmitStaffsPayRollState>(
            listener: (context, submitStaffsPayRollState) {
              if (submitStaffsPayRollState is SubmitStaffsPayRollSuccess) {
                getStaffsPayRoll();
                _selectedStaffs.clear();
                setState(() {});
              }
            },
            builder: (context, submitStaffsPayRollState) {
              return Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.8),
                        Colors.white,
                        Colors.white,
                      ],
                      stops: const [0.0, 0.2, 0.5, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _selectedStaffs.isEmpty
                            ? [
                                _maroonPrimary.withValues(alpha: 0.5),
                                _maroonLight.withValues(alpha: 0.5),
                              ]
                            : [
                                _maroonPrimary,
                                const Color(0xFF9A1E3C),
                                _maroonLight,
                              ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _selectedStaffs.isEmpty
                          ? []
                          : [
                              BoxShadow(
                                color: _maroonPrimary.withValues(alpha: 0.3),
                                offset: const Offset(0, 4),
                                blurRadius: 12,
                                spreadRadius: 0,
                              ),
                            ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        highlightColor: Colors.white.withValues(alpha: 0.1),
                        splashColor: Colors.white.withValues(alpha: 0.2),
                        onTap: () {
                          if (_selectedStaffs.isEmpty) {
                            return;
                          }

                          if (submitStaffsPayRollState
                              is SubmitStaffsPayRollInProgress) {
                            return;
                          }

                          List<Map<String, dynamic>> staffPayRolls = [];

                          for (var staffPayRoll in _selectedStaffs) {
                            final index = context
                                .read<StaffsPayrollCubit>()
                                .staffsPayRoll()
                                .indexWhere(
                                    (element) => element.id == staffPayRoll.id);

                            final netSalary = (index != -1)
                                ? (_staffsPayRollDetailsContainerKeys[index]
                                        .currentState
                                        ?.getNetSalary() ??
                                    0.0)
                                : 0.0;

                            final basicSalary = (index != -1)
                                ? (_staffsPayRollDetailsContainerKeys[index]
                                        .currentState
                                        ?.getBasicSalary() ??
                                    0.0)
                                : (staffPayRoll.salary ?? 0.0);

                            staffPayRolls.add({
                              "staff_id": staffPayRoll.id,
                              "basic_salary": basicSalary,
                              "amount": netSalary
                            });
                          }

                          final monthNumber = getSelectedMonthNumber();
                          final year = _selectedYear ?? 0;

                          debugPrint(
                              "Submitting payrolls: Year: $year, Month: $monthNumber ($_selectedMonthKey)");

                          context
                              .read<SubmitStaffsPayRollCubit>()
                              .submitStaffsPayRoll(
                                  month: monthNumber,
                                  year: year,
                                  allowedLeaves: context
                                      .read<StaffsPayrollCubit>()
                                      .allowedLeaves(),
                                  staffPayRolls: staffPayRolls);
                        },
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: submitStaffsPayRollState
                                    is SubmitStaffsPayRollInProgress
                                ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    key: ValueKey<String>("loading"),
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : Row(
                                    key: const ValueKey<String>("button"),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        Utils.getTranslatedLabel(submitKey),
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      if (_selectedStaffs.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(left: 12),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            "${_selectedStaffs.length}",
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
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
              ).animate().fadeIn(duration: 500.ms);
            },
          )
        : const SizedBox();
  }

  Widget _buildStaffs() {
    return BlocConsumer<StaffsPayrollCubit, StaffsPayrollState>(
      listener: (context, state) {
        if (state is StaffsPayrollFetchSuccess) {
          _staffsPayRollDetailsContainerKeys.clear();
          for (var _ in state.staffsPayRoll) {
            _staffsPayRollDetailsContainerKeys
                .add(GlobalKey<StaffPayrollDetailsContainerState>());
          }
          setState(() {});
        }
      },
      builder: (context, state) {
        if (state is StaffsPayrollFetchSuccess) {
          // Filter staff by search query when search is active
          final staffList = _searchQuery.isEmpty
              ? state.staffsPayRoll
              : state.staffsPayRoll
                  .where((staff) =>
                      ((staff.userDetails?.firstName ?? "")
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase())) ||
                      ((staff.userDetails?.lastName ?? "")
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase())))
                  .toList();

          if (staffList.isEmpty && _searchQuery.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.only(
                top: 20, // Reduced padding since AppBar handles the top spacing
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: NoSearchResultsWidget(
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
                title: 'Staff Tidak Ditemukan',
                description:
                    'Tidak ditemukan staff yang sesuai dengan pencarian Anda. Coba gunakan kata kunci yang berbeda.',
                icon: Icons.people_outline,
              ).animate().fadeIn(delay: 300.ms),
            );
          }

          return BlocBuilder<PayRollYearsCubit, PayRollYearsState>(
              builder: (context, yearState) {
            return Align(
              alignment: Alignment.topCenter,
              child: RefreshIndicator(
                onRefresh: () async {
                  getStaffsPayRoll();
                },
                color: _maroonPrimary,
                displacement: 100,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(
                    bottom: 100,
                    // Reduced top padding since AppBar handles spacing
                    top: 20,
                  ),
                  child: Column(
                    children: [
                      // Title and subtitle section
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kelola Gaji',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _maroonPrimary,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(
                          begin: -0.1, end: 0, curve: Curves.easeOutQuad),

                      // Search bar
                      _buildSearchBar(),

                      // Filter buttons - now placed under title

                      // Staff list with container styling
                      Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Elegant header with animated gradient
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _maroonPrimary.withValues(alpha: 0.9),
                                    _maroonPrimary,
                                    _maroonLight,
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16)),
                                boxShadow: [
                                  BoxShadow(
                                    color: _maroonPrimary.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Animated icon
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.payments_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  )
                                      .animate()
                                      .fadeIn(duration: 300.ms)
                                      .slideX(begin: -0.2, end: 0),

                                  const SizedBox(width: 16),

                                  // Title text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Daftar Gaji Staff',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        Text(
                                          '${staffList.length} staff tersedia',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color:
                                                Colors.white.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Counter badge with animation
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        staffList.length.toString(),
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ).animate().fadeIn(duration: 400.ms).scale(
                                      begin: const Offset(0.8, 0.8),
                                      end: const Offset(1.0, 1.0),
                                      duration: 400.ms),
                                ],
                              ),
                            ),

                            // Table header with modern design
                            Container(
                              margin: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      "No",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: _maroonPrimary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      Utils.getTranslatedLabel(nameKey),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: _maroonPrimary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      Utils.getTranslatedLabel(statusKey),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: _maroonPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

                            // Staff list items
                            Container(
                              margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Column(
                                  children: List.generate(
                                          staffList.length, (index) => index)
                                      .map((index) {
                                    final staffPayRoll = staffList[index];
                                    final isSelected =
                                        _selectedStaffs.indexWhere((element) =>
                                                element.id ==
                                                staffPayRoll.id) !=
                                            -1;

                                    // Find the original index to use the correct key
                                    final originalIndex = state.staffsPayRoll
                                        .indexWhere((element) =>
                                            element.id == staffPayRoll.id);

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 2),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? _maroonPrimary.withValues(alpha: 0.05)
                                            : Colors.white,
                                        border: index != staffList.length - 1
                                            ? Border(
                                                bottom: BorderSide(
                                                    color: Colors.grey[100]!),
                                              )
                                            : null,
                                      ),
                                      child: StaffPayrollDetailsContainer(
                                        key: _staffsPayRollDetailsContainerKeys[
                                            originalIndex],
                                        allowedMonthlyLeaves:
                                            state.allowedLeaves,
                                        isSelected: isSelected,
                                        staffPayRoll: staffPayRoll,
                                        onTapCheckBox: () {
                                          if (isSelected) {
                                            _selectedStaffs.removeWhere(
                                                (element) =>
                                                    element.id ==
                                                    staffPayRoll.id);
                                          } else {
                                            _selectedStaffs.add(staffPayRoll);
                                          }
                                          setState(() {});
                                        },
                                      ),
                                    )
                                        .animate()
                                        .fadeIn(
                                            duration: 400.ms,
                                            delay: (50 * index).ms)
                                        .slideY(
                                          begin: 0.1,
                                          end: 0,
                                          curve: Curves.easeOutQuad,
                                          duration: 500.ms,
                                          delay: (50 * index).ms,
                                        );
                                  }).toList(),
                                ),
                              ),
                            ),

                            // Empty state if no staff
                            if (staffList.isEmpty && _searchQuery.isEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.people_alt_outlined,
                                      size: 60,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Belum ada data staff',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Data staff akan ditampilkan di sini',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[400],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(duration: 400.ms),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(
                          begin: 0.05, end: 0, curve: Curves.easeOutQuad),
                    ],
                  ),
                ),
              ),
            );
          });
        }

        if (state is StaffsPayrollFetchFailure) {
          return Center(
            child: CustomErrorWidget(
              message: state.errorMessage,
              onRetry: () {
                getStaffsPayRoll();
              },
              primaryColor: _maroonPrimary,
            ),
          );
        }

        return _buildManagePayrollsSkeleton();
      },
    );
  }

  Widget _buildFilterTabs() {
    return BlocBuilder<PayRollYearsCubit, PayRollYearsState>(
      builder: (context, state) {
        return Row(
          children: [
            // Year filter
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (state is PayRollYearsFetchSuccess &&
                        state.years.isNotEmpty) {
                      Utils.showBottomSheet(
                        child: FilterSelectionBottomsheet<int>(
                          onSelection: (value) {
                            changeSelectedYear(value!);
                            Get.back();
                          },
                          selectedValue: _selectedYear ?? 0,
                          titleKey: titleKey,
                          values: state.years,
                        ),
                        context: context,
                      );
                    }
                  },
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            (_selectedYear?.toString()) ?? 'Tahun',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Vertical divider
            Container(
              height: 24,
              width: 1.5,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.4),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),

            // Month filter
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (state is PayRollYearsFetchSuccess) {
                      Utils.showBottomSheet(
                        child: FilterSelectionBottomsheet<String>(
                          selectedValue: _selectedMonthKey,
                          titleKey: monthKey,
                          values: months,
                          displayFunction: (value) =>
                              Utils.getTranslatedLabel(value),
                          onSelection: (value) {
                            changeSelectedMonth(value!);
                            Get.back();
                          },
                        ),
                        context: context,
                      );
                    }
                  },
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            Utils.getTranslatedLabel(_selectedMonthKey),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
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
                  hintText: 'Cari staff...',
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

  Widget _buildStaffPayrollItemSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[100]!,
            width: 1,
          ),
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Number/checkbox skeleton
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Avatar skeleton
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),

              // Name and details skeleton
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name skeleton
                    Container(
                      height: 16,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Role skeleton
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

              // Status skeleton
              Expanded(
                flex: 3,
                child: Container(
                  height: 24,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // Amount skeleton
              Container(
                width: 80,
                height: 16,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagePayrollsSkeleton() {
    return Align(
      alignment: Alignment.topCenter,
      child: RefreshIndicator(
        onRefresh: () async {},
        color: _maroonPrimary,
        displacement: 100,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            bottom: 100,
            top: 20,
          ),
          child: Column(
            children: [
              // Title and subtitle section
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 24,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar
              _buildSearchBar(),

              // Staff list container skeleton
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header skeleton
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(16)),
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

                    // Table header skeleton
                    Container(
                      margin: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
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
                                height: 14,
                                width: 20,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Container(
                                height: 14,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Container(
                                height: 14,
                                width: 50,
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

                    // Staff items skeleton
                    Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: List.generate(
                          8,
                          (index) => Column(
                            children: [
                              _buildStaffPayrollItemSkeleton(),
                              if (index < 7)
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomModernAppBar(
          title: 'Kelola Gaji',
          icon: Icons.account_balance_wallet,
          fabAnimationController: _fabAnimationController,
          primaryColor: _maroonPrimary,
          onBackPressed: () => Get.back(),
          lightColor: _maroonLight,
          height: 160, // Increased height to accommodate all content properly
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
          tabBuilder: (context) => _buildFilterTabs(),
        ),
        body: Stack(
          children: [
            // Main content area with staff list
            BlocConsumer<PayRollYearsCubit, PayRollYearsState>(
              listener: (context, state) {
                if (state is PayRollYearsFetchSuccess) {
                  context.read<StaffsPayrollCubit>().getStaffsPayroll(
                      year: _selectedYear ?? 0,
                      month: getSelectedMonthNumber());
                }
              },
              builder: (context, state) {
                if (state is PayRollYearsFetchSuccess) {
                  return _buildStaffs();
                }

                if (state is PayRollYearsFetchFailure) {
                  return Center(
                    child: CustomErrorWidget(
                      message: state.errorMessage,
                      onRetry: () {
                        context.read<PayRollYearsCubit>().getPayRollYears();
                      },
                      primaryColor: _maroonPrimary,
                    ),
                  );
                }

                return _buildManagePayrollsSkeleton();
              },
            ),

            // Bottom submit button
            _buildSubmitButton(),
          ],
        ));
  }
}

