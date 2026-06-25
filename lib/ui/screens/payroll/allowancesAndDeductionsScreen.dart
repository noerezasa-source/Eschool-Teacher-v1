import 'package:eschool_saas_staff/cubits/payRoll/allowancesAndDeductionsCubit.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';

class AllowancesAndDeductionsScreen extends StatefulWidget {
  const AllowancesAndDeductionsScreen({super.key});

  static Widget getRouteInstance() {
    return BlocProvider(
      create: (context) => AllowancesAndDeductionsCubit(),
      child: const AllowancesAndDeductionsScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<AllowancesAndDeductionsScreen> createState() =>
      _AllowancesAndDeductionsScreenState();
}

class _AllowancesAndDeductionsScreenState
    extends State<AllowancesAndDeductionsScreen> with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _pulseAnimationController;
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  // Fresh Soft Maroon Palette - Complete redesign
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;
  final Color _maroonLight = const Color(0xFFA6677A);
  final Color _maroonSoft = const Color(0xFFE8D5DA);
  final Color _maroonDeep = const Color(0xFF6B3A47);
  final Color _neutralBg = const Color(0xFFFBFAFA);
  final Color _cardBg = const Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));

    context.read<AllowancesAndDeductionsCubit>().fetchAllowancesAndDeductions();

    // Start animations
    _slideAnimationController.forward();
    _pulseAnimationController.repeat();
  }

  void _scrollListener() {
    // Calculate the height needed to scroll past the summary cards
    // This includes: net salary card height (~240) + margin (32) + summary cards height (~160) + margin (16)
    // Total approximate height: ~320 pixels (scroll starts from summary cards)
    const double summaryCardsPosition = 320.0;

    if (_scrollController.offset > summaryCardsPosition) {
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
    _slideAnimationController.dispose();
    _pulseAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildFloatingTabBar() {
    return AnimatedBuilder(
      animation: _slideAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              0,
              Tween<double>(
                begin: -50.0,
                end: 0.0,
              )
                  .animate(CurvedAnimation(
                    parent: _slideAnimationController,
                    curve: Curves.elasticOut,
                  ))
                  .value),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: _maroonPrimary.withValues(alpha: 0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    title: 'Tunjangan',
                    icon: Icons.trending_up_rounded,
                    isSelected: _currentPageIndex == 0,
                    onTap: () => _switchTab(0),
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    title: 'Potongan',
                    icon: Icons.trending_down_rounded,
                    isSelected: _currentPageIndex == 1,
                    onTap: () => _switchTab(1),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? _maroonPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : _maroonPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : _maroonPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _switchTab(int index) {
    setState(() {
      _currentPageIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required bool isPositive,
  }) {
    const baseSalary = 5000000.0;
    final percentage = (amount / baseSalary * 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: color,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'dari gaji pokok',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetSalaryCard(double allowances, double deductions) {
    const baseSalary = 5000000.0;
    final netSalary = baseSalary + allowances - deductions;
    final salaryIncrease = allowances - deductions;
    final increasePercentage = (salaryIncrease / baseSalary * 100);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _maroonPrimary,
            _maroonLight,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _maroonPrimary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'GAJI BERSIH',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Total Gaji Diterima',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: salaryIncrease >= 0
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      salaryIncrease >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${salaryIncrease >= 0 ? '+' : ''}${increasePercentage.toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rp ${netSalary.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gaji Pokok',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'Rp',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              baseSalary.toStringAsFixed(0).replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                  (Match m) => '${m[1]}.'),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selisih',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${salaryIncrease >= 0 ? '+' : '-'}Rp',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              salaryIncrease
                                  .abs()
                                  .toStringAsFixed(0)
                                  .replaceAllMapped(
                                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                      (Match m) => '${m[1]}.'),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernItemCard({
    required String title,
    required double amount,
    required String description,
    required bool isAllowance,
    required int index,
  }) {
    const baseSalary = 5000000.0;
    final percentage = (amount / baseSalary * 100);

    return Container(
      margin: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 16,
        top: index == 0 ? 8 : 0,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            // Could add detail view here
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isAllowance
                    ? _maroonLight.withValues(alpha: 0.2)
                    : _maroonDeep.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isAllowance ? _maroonLight : _maroonDeep)
                      .withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: (isAllowance ? _maroonLight : _maroonDeep)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isAllowance
                        ? Icons.add_circle_outline_rounded
                        : Icons.remove_circle_outline_rounded,
                    color: isAllowance ? _maroonLight : _maroonDeep,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _maroonDeep,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isAllowance ? _maroonLight : _maroonDeep)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isAllowance ? _maroonLight : _maroonDeep,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (description.isNotEmpty)
                        Text(
                          description,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isAllowance ? '+' : '-'}Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isAllowance ? _maroonLight : _maroonDeep,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isAllowance ? _maroonLight : _maroonDeep)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isAllowance ? 'BONUS' : 'POTONGAN',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isAllowance ? _maroonLight : _maroonDeep,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 500.ms)
        .slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildPageContent(List<dynamic> items, bool isAllowance) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _maroonSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isAllowance ? Icons.savings_outlined : Icons.money_off_outlined,
                color: _maroonPrimary,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isAllowance ? 'Belum Ada Tunjangan' : 'Belum Ada Potongan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _maroonDeep,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAllowance
                  ? 'Tunjangan akan muncul di sini'
                  : 'Potongan akan muncul di sini',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _buildModernItemCard(
          title: item.payRollSetting?.name ?? 'Unnamed',
          amount: calculateActualAmount(item),
          description: item.payRollSetting?.type == 'allowance'
              ? 'Tunjangan tambahan untuk staff'
              : 'Potongan dari gaji pokok',
          isAllowance: isAllowance,
          index: index,
        );
      }).toList(),
    );
  }

  // Helper function to calculate actual amount from StaffSalary
  double calculateActualAmount(dynamic item) {
    const baseSalary = 5000000.0;

    if (item.allowanceOrDeductionInPercentage()) {
      // If it's percentage-based, calculate from base salary
      final percentage = item.percentage ?? 0.0;
      return baseSalary * percentage / 100;
    } else {
      // If it's amount-based, use the amount directly
      return item.amount ?? 0.0;
    }
  }

  Widget _buildContent(AllowancesAndDeductionsFetchSuccess state) {
    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<AllowancesAndDeductionsCubit>()
            .fetchAllowancesAndDeductions();
      },
      color: _maroonPrimary,
      backgroundColor: _cardBg,
      strokeWidth: 3,
      child: Container(
        color: _neutralBg,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Net Salary Card - moved to top position
            SliverToBoxAdapter(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildNetSalaryCard(
                  state.allowances.fold<double>(
                      0, (sum, item) => sum + calculateActualAmount(item)),
                  state.deductions.fold<double>(
                      0, (sum, item) => sum + calculateActualAmount(item)),
                ),
              )
                  .animate()
                  .fadeIn(duration: 800.ms, delay: 100.ms)
                  .slideY(begin: 0.1, end: 0),
            ),

            // Summary Cards - moved below Net Salary Card
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Total Tunjangan',
                        amount: state.allowances.fold<double>(
                          0,
                          (sum, item) => sum + calculateActualAmount(item),
                        ),
                        icon: Icons.add_circle_outline,
                        color: _maroonLight,
                        isPositive: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Total Potongan',
                        amount: state.deductions.fold<double>(
                          0,
                          (sum, item) => sum + calculateActualAmount(item),
                        ),
                        icon: Icons.remove_circle_outline,
                        color: _maroonDeep,
                        isPositive: false,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 800.ms, delay: 200.ms)
                  .slideY(begin: 0.1, end: 0),
            ),

            // Floating Tab Bar
            SliverToBoxAdapter(
              child: _buildFloatingTabBar(),
            ),

            // Page Content
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.height *
                    0.6, // Constrain height
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageIndex = index;
                    });
                  },
                  children: [
                    // Allowances Page
                    SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _buildPageContent(state.allowances, true),
                    ),

                    // Deductions Page
                    SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _buildPageContent(state.deductions, false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _neutralBg,
      extendBodyBehindAppBar: false,
      appBar: CustomModernAppBar(
        title: 'Tunjangan & Potongan',
        icon: Icons.assessment_outlined,
        fabAnimationController: _fabAnimationController,
        primaryColor: _maroonPrimary,
        lightColor: _maroonLight,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: BlocBuilder<AllowancesAndDeductionsCubit,
          AllowancesAndDeductionsState>(
        builder: (context, state) {
          if (state is AllowancesAndDeductionsFetchSuccess) {
            return _buildContent(state);
          }
          if (state is AllowancesAndDeductionsFetchFailure) {
            return Container(
              color: _neutralBg,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _maroonPrimary.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _maroonSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          color: _maroonPrimary,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Oops! Terjadi Kesalahan',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _maroonDeep,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ErrorMessageUtils.getReadableErrorMessage(
                            state.errorMessage),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<AllowancesAndDeductionsCubit>()
                              .fetchAllowancesAndDeductions();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _maroonPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Coba Lagi',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return const SkeletonAllowancesAndDeductionsCard()
              .animate()
              .fadeIn(duration: 500.ms)
              .scaleXY(
                begin: 0.95,
                end: 1.0,
                curve: Curves.easeOutCubic,
              );
        },
      ),
    );
  }
}
