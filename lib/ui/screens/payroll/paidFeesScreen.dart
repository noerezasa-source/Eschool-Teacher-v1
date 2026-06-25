import 'package:eschool_saas_staff/cubits/fee/sessionYearAndFeesCubit.dart';
import 'package:eschool_saas_staff/cubits/fee/studentsFeeStatusCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/data/models/fee/fee.dart';
import 'package:eschool_saas_staff/data/models/academic/sessionYear.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customFilterModernAppbar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/system/no_search_results_widget.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eschool_saas_staff/ui/screens/widgets/studentPaidFeeDetailsContainer.dart';

class PaidFeesScreen extends StatefulWidget {
  const PaidFeesScreen({super.key});

  static Widget getRouteInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SessionYearAndFeesCubit(),
        ),
        BlocProvider(
          create: (context) => StudentsFeeStatusCubit(),
        ),
      ],
      child: const PaidFeesScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<PaidFeesScreen> createState() => _PaidFeesScreenState();
}

// Add missing key constant
const String totalFeeKey = "totalFee";

class _PaidFeesScreenState extends State<PaidFeesScreen>
    with TickerProviderStateMixin {
  String _selectedFeeStatus = "";
  Fee? _selectedFee;
  SessionYear? _selectedSessionYear;

  // Color scheme for maroon theme
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;
  Color get _maroonLight => AppColorPalette.secondaryMaroon;

  // Search functionality
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Animation controller for scroll-based animations
  late AnimationController _fabAnimationController;
  late final ScrollController _scrollController = ScrollController()
    ..addListener(scrollListener);

  String formatRupiah(double amount) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatCurrency.format(amount);
  }

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    debugPrint('=================== SCREEN INITIALIZED ===================');
    debugPrint('Initial Session Year: ${_selectedSessionYear?.name ?? "Not set"}');
    debugPrint('Initial Fee Status: $_selectedFeeStatus');
    debugPrint('Initial Fee: ${_selectedFee?.name ?? "Not set"}');
    debugPrint('Initial Search Query: "$_searchQuery"');
    debugPrint('Initial Search Active: $_isSearchActive');
    debugPrint('=========================================================');

    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<SessionYearAndFeesCubit>().getSessionYearsAndFees();
      }
    });
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
    // Animate based on scroll position
    if (_scrollController.offset > 50) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }

    // Load more data if at the bottom of the list
    if (_scrollController.offset ==
        _scrollController.position.maxScrollExtent) {
      if (context.read<StudentsFeeStatusCubit>().hasMore()) {
        getMoreStudentFees();
      }
    }
  }

  void getStudentFees() {
    // Print parameter values for debugging
    debugPrint('===================== PARAMETER VALUES =====================');
    debugPrint('Session Year ID: ${_selectedSessionYear?.id ?? 0}');
    debugPrint('Session Year Name: ${_selectedSessionYear?.name ?? "Not selected"}');
    debugPrint(
        'Fee Status: $_selectedFeeStatus (${_selectedFeeStatus == paidKey ? 1 : 0})');
    debugPrint('Fee ID: ${_selectedFee?.id ?? 0}');
    debugPrint('Fee Name: ${_selectedFee?.name ?? "Not selected"}');
    debugPrint('Search Query: $_searchQuery');
    debugPrint('==========================================================');

    context.read<StudentsFeeStatusCubit>().getStudentFeePaymentStatus(
        sessionYearId: _selectedSessionYear?.id ?? 0,
        status: _selectedFeeStatus == paidKey ? 1 : 0,
        feeId: _selectedFee?.id ?? 0,
        search: _searchQuery);
  }

  void getMoreStudentFees() {
    // Print parameter values for pagination
    debugPrint('================ PAGINATION PARAMETER VALUES ================');
    debugPrint('Session Year ID: ${_selectedSessionYear?.id ?? 0}');
    debugPrint('Session Year Name: ${_selectedSessionYear?.name ?? "Not selected"}');
    debugPrint(
        'Fee Status: $_selectedFeeStatus (${_selectedFeeStatus == paidKey ? 1 : 0})');
    debugPrint('Fee ID: ${_selectedFee?.id ?? 0}');
    debugPrint('Fee Name: ${_selectedFee?.name ?? "Not selected"}');
    debugPrint('Search Query: $_searchQuery');
    debugPrint('============================================================');

    context.read<StudentsFeeStatusCubit>().fetchMore(
        sessionYearId: _selectedSessionYear?.id ?? 0,
        status: _selectedFeeStatus == paidKey ? 1 : 0,
        feeId: _selectedFee?.id ?? 0);
  }

  void changeSelectedSessionYear(SessionYear value) {
    setState(() {
      _selectedSessionYear = value;
    });
    debugPrint('Session Year changed to: ${value.name} (ID: ${value.id})');
  }

  void changeSelectedFeeStatus(String value) {
    setState(() {
      _selectedFeeStatus = value;
    });
    debugPrint('Fee Status changed to: $value (${value == paidKey ? 1 : 0})');
  }

  void changeSelectedFee(Fee value) {
    setState(() {
      _selectedFee = value;
    });
    debugPrint('Fee Type changed to: ${value.name} (ID: ${value.id})');
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
                  hintText: 'Cari siswa...',
                  prefixIcon: Icon(Icons.search, color: _maroonLight),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.close, color: _maroonLight),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = "";
                        _isSearchActive = false;
                      });
                      // Trigger search with empty query when clearing
                      getStudentFees();
                      debugPrint('Search cleared and deactivated');
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  // Use debounce technique for search
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchQuery == value) {
                      getStudentFees();
                    }
                  });
                  debugPrint('Search Query changed to: "$value"');
                },
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildAppBar() {
    return BlocConsumer<SessionYearAndFeesCubit, SessionYearAndFeesState>(
      listener: (context, state) {
        if (state is SessionYearAndFeesFetchSuccess) {
          if (state.fees.isNotEmpty && state.sessionYears.isNotEmpty) {
            changeSelectedFee(state.fees.first);
            changeSelectedSessionYear(state.sessionYears
                .where((element) => element.isThisDefault())
                .toList()
                .first);
            changeSelectedFeeStatus(paidKey);
            getStudentFees();
          }
        }
      },
      builder: (context, state) {
        if (state is SessionYearAndFeesFetchSuccess) {
          return CustomFilterModernAppBar(
            title: 'Biaya yang Dibayar',
            titleIcon: Icons.payments_rounded,
            primaryColor: _maroonPrimary,
            secondaryColor: _maroonLight,
            onBackPressed: () => Navigator.of(context).pop(),
            animationController: _fabAnimationController,
            enableAnimations: true,
            height: MediaQuery.of(context).padding.top + 200,
            showFiltersRow: true,
            showSearchButton: true,
            isSearchActive: _isSearchActive,
            onSearchPressed: () {
              setState(() {
                _isSearchActive = !_isSearchActive;
                if (!_isSearchActive) {
                  _searchController.clear();
                  _searchQuery = "";
                  getStudentFees(); // Reload data when search is cleared
                }
              });
              debugPrint(
                  'Search toggled: ${_isSearchActive ? "activated" : "deactivated"}');
            },

            // First filter - Session Year
            firstFilterItem: FilterItemConfig(
              title: _selectedSessionYear?.name ?? 'Tahun Ajaran',
              icon: Icons.calendar_today_rounded,
              onTap: () {
                if (state.sessionYears.isNotEmpty) {
                  Utils.showBottomSheet(
                    child: FilterSelectionBottomsheet<SessionYear>(
                      onSelection: (value) {
                        changeSelectedSessionYear(value!);
                        getStudentFees();
                        Get.back();
                      },
                      selectedValue: _selectedSessionYear!,
                      titleKey: sessionYearKey,
                      values: state.sessionYears,
                    ),
                    context: context,
                  );
                }
              },
            ),

            // Second filter - Status
            secondFilterItem: FilterItemConfig(
              title: _selectedFeeStatus.isEmpty
                  ? 'Status'
                  : Utils.getTranslatedLabel(_selectedFeeStatus),
              icon: Icons.payment_rounded,
              onTap: () {
                Utils.showBottomSheet(
                  child: FilterSelectionBottomsheet<String>(
                    onSelection: (value) {
                      changeSelectedFeeStatus(value!);
                      getStudentFees();
                      Get.back();
                    },
                    selectedValue: _selectedFeeStatus,
                    titleKey: statusKey,
                    values: const [paidKey, unpaidKey],
                  ),
                  context: context,
                );
              },
            ),

            // Third filter - Fee
            thirdFilterItem: FilterItemConfig(
              title: _selectedFee?.name ?? 'Biaya',
              icon: Icons.monetization_on_rounded,
              onTap: () {
                if (state.fees.isNotEmpty) {
                  Utils.showBottomSheet(
                    child: FilterSelectionBottomsheet<Fee>(
                      onSelection: (value) {
                        changeSelectedFee(value!);
                        getStudentFees();
                        Get.back();
                      },
                      selectedValue: _selectedFee!,
                      titleKey: feeKey,
                      values: state.fees,
                    ),
                    context: context,
                  );
                }
              },
            ),
          );
        }

        // Return a simple modern AppBar when data is loading
        return CustomFilterModernAppBar(
          title: 'Biaya yang Dibayar',
          titleIcon: Icons.payments_rounded,
          primaryColor: _maroonPrimary,
          secondaryColor: _maroonLight,
          onBackPressed: () => Navigator.of(context).pop(),
          animationController: _fabAnimationController,
          enableAnimations: true,
          height: MediaQuery.of(context).padding.top + 200,
          showFiltersRow: false,
          showSearchButton: true,
          isSearchActive: _isSearchActive,
          onSearchPressed: () {
            setState(() {
              _isSearchActive = !_isSearchActive;
              if (!_isSearchActive) {
                _searchController.clear();
                _searchQuery = "";
              }
            });
            debugPrint(
                'Search toggled: ${_isSearchActive ? "activated" : "deactivated"}');
          },
        );
      },
    );
  }

  Widget _buildStudentFeeItemSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with student info
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Index number skeleton
                  Container(
                    width: 30,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Student details
                  Expanded(
                    child: Row(
                      children: [
                        // Student avatar skeleton
                        Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),

                        // Name and class skeleton
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name skeleton
                              Container(
                                height: 14,
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              // Class skeleton
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
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Toggle indicator skeleton
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),

            // Expanded details skeleton (shown as collapsed)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section title skeleton
                  Container(
                    width: 120,
                    height: 16,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  // Info rows skeleton
                  ...List.generate(
                      4,
                      (index) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left side - label
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: [
                                      // Icon skeleton
                                      Container(
                                        width: 26,
                                        height: 26,
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      // Label skeleton
                                      Container(
                                        height: 13,
                                        width: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Divider
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: const Text(
                                    ":",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),

                                // Right side - value
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    height: 14,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),

                  // Payment history section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 12, top: 16),
                    margin: const EdgeInsets.only(bottom: 12, top: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Icon skeleton
                        Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        // Title skeleton
                        Container(
                          height: 14,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Spacer(),
                        // Count badge skeleton
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          width: 30,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Payment history items skeleton
                  ...List.generate(
                      2,
                      (index) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header with date and method
                                Row(
                                  children: [
                                    // Date section
                                    Expanded(
                                      child: Row(
                                        children: [
                                          // Icon skeleton
                                          Container(
                                            width: 24,
                                            height: 24,
                                            margin:
                                                const EdgeInsets.only(right: 6),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          // Date skeleton
                                          Container(
                                            height: 12,
                                            width: 80,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Method badge skeleton
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      width: 60,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Amount row skeleton
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      height: 13,
                                      width: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    Container(
                                      height: 14,
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
                          )),

                  // Download button skeleton
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon skeleton
                        Container(
                          width: 34,
                          height: 34,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Text skeleton
                        Container(
                          height: 14,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
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
    );
  }

  Widget _buildPaidFeesSkeleton() {
    return Align(
      alignment: Alignment.topCenter,
      child: RefreshIndicator(
        onRefresh: () async {},
        color: _maroonPrimary,
        displacement: 100,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: 100,
            top: MediaQuery.of(context).padding.top + 210,
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
                      height: 20,
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),

              _buildSearchBar(),

              // Students list container skeleton
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
                                    width: 180,
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
                        border: Border.all(color: Colors.grey[200]!),
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
                                width: 80,
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

                    // Student items skeleton
                    Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children: List.generate(
                            5,
                            (index) => Column(
                              children: [
                                _buildStudentFeeItemSkeleton(),
                                if (index < 4)
                                  Divider(
                                    color: Colors.grey[100],
                                    thickness: 1,
                                    height: 1,
                                  ),
                              ],
                            ),
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

  Widget _buildStudents() {
    return BlocBuilder<StudentsFeeStatusCubit, StudentsFeeStatusState>(
      builder: (context, state) {
        if (state is StudentsFeeStatusFetchSuccess) {
          // Debug output
          debugPrint('=================== STUDENT DATA DEBUG ===================');
          debugPrint('Total students in state: ${state.students.length}');

          if (state.students.isNotEmpty) {
            final firstStudent = state.students.first;
            debugPrint(
                'First student: ${firstStudent.fullName ?? "No name"} (ID: ${firstStudent.id})');
            debugPrint(
                'First student roll number: ${firstStudent.rollNumber ?? "No roll number"}');
            debugPrint('Has payment_status: ${firstStudent.paymentStatus != null}');
            if (firstStudent.paymentStatus != null) {
              debugPrint('Payment status details:');
              debugPrint(
                  '  isFullyPaid: ${firstStudent.paymentStatus!.isFullyPaid}');
              debugPrint(
                  '  totalAmount: ${firstStudent.paymentStatus!.totalAmount}');
              debugPrint('  paidAmount: ${firstStudent.paymentStatus!.paidAmount}');
            }

            debugPrint(
                'Has payment_history: ${firstStudent.paymentHistory?.length ?? 0} items');
            if (firstStudent.paymentHistory != null &&
                firstStudent.paymentHistory!.isNotEmpty) {
              debugPrint('First payment history item:');
              debugPrint('  ID: ${firstStudent.paymentHistory!.first.id}');
              debugPrint('  Amount: ${firstStudent.paymentHistory!.first.amount}');
              debugPrint(
                  '  Date: ${firstStudent.paymentHistory!.first.paymentDate}');
              debugPrint(
                  '  Method: ${firstStudent.paymentHistory!.first.paymentMethod}');
            }
          } else {
            debugPrint('No students in state!');
          }
          debugPrint('=========================================================');

          // Filter students by search query when search is active
          final studentsList = _searchQuery.isEmpty
              ? state.students
              : state.students
                  .where((student) => ((student.fullName ?? "")
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase())))
                  .toList();

          if (studentsList.isEmpty && _searchQuery.isNotEmpty) {
            return Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top +
                    170, // Added top padding to avoid app bar
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
                title: 'Siswa Tidak Ditemukan',
                description:
                    'Tidak ditemukan siswa yang sesuai dengan pencarian Anda. Coba gunakan kata kunci yang berbeda.',
                icon: Icons.person_search_outlined,
              ).animate().fadeIn(delay: 300.ms),
            );
          }

          if (studentsList.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada data pembayaran',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Data pembayaran akan ditampilkan di sini',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms),
            );
          }

          return Align(
            alignment: Alignment.topCenter,
            child: RefreshIndicator(
              onRefresh: () async {
                getStudentFees();
              },
              color: _maroonPrimary,
              displacement: 100,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  bottom: 100,
                  // Increasing top padding to ensure title appears below app bar
                  top: MediaQuery.of(context).padding.top + 210,
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
                            'Biaya yang Dibayar',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _maroonPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Data pembayaran biaya sekolah siswa',
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
                        .slideY(begin: -0.1, end: 0, curve: Curves.easeOutQuad),

                    // Search bar
                    _buildSearchBar(),

                    // Students list with container styling
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
                                    Icons.receipt_long_rounded,
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
                                        'Daftar Pembayaran Siswa',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        '${studentsList.length} siswa',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white.withValues(alpha: 0.8),
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
                                      studentsList.length.toString(),
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
                              ],
                            ),
                          ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

                          // Students list items
                          Container(
                            margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: studentsList.length,
                                itemBuilder: (context, index) {
                                  final student = studentsList[index];

                                  return StudentPaidFeeDetailsContainer(
                                    index: index,
                                    compolsoryFeeAmount:
                                        state.compolsoryFeeAmount,
                                    optionalFeeAmount: state.optionalFeeAmount,
                                    studentDetails: student,
                                    maroonPrimary: _maroonPrimary,
                                    maroonLight: _maroonLight,
                                  );
                                },
                              ),
                            ),
                          ),

                          // Load more button if needed
                          if (context.read<StudentsFeeStatusCubit>().hasMore())
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: state.fetchMoreError
                                  ? TextButton(
                                      onPressed: () => getMoreStudentFees(),
                                      child: Text(
                                        Utils.getTranslatedLabel(retryKey),
                                        style: GoogleFonts.poppins(
                                          color: _maroonPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: _buildStudentFeeItemSkeleton(),
                                    ),
                            ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is StudentsFeeStatusFetchFailure) {
          return Center(
            child: CustomErrorWidget(
              message: state.errorMessage,
              onRetry: () {
                getStudentFees();
              },
              primaryColor: _maroonPrimary,
            ),
          );
        }

        return _buildPaidFeesSkeleton();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BlocBuilder<SessionYearAndFeesCubit, SessionYearAndFeesState>(
            builder: (context, state) {
              if (state is SessionYearAndFeesFetchSuccess) {
                if (state.sessionYears.isEmpty || state.fees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 64,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Data tidak tersedia',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[800],
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada data tahun ajaran atau biaya',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ).animate().fadeIn().scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.0, 1.0),
                          duration: 400.ms,
                        ),
                  );
                }
                return _buildStudents();
              }
              if (state is SessionYearAndFeesFetchFailure) {
                return Center(
                  child: CustomErrorWidget(
                    message: state.errorMessage,
                    onRetry: () {
                      context
                          .read<SessionYearAndFeesCubit>()
                          .getSessionYearsAndFees();
                    },
                    primaryColor: _maroonPrimary,
                  ),
                );
              }

              return _buildPaidFeesSkeleton();},
          ),

          // Modern app bar
          _buildAppBar(),
        ],
      ),
    );
  }
}

