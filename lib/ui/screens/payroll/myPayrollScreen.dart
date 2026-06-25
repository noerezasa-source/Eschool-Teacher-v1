import 'package:eschool_saas_staff/cubits/academics/sessionYearsCubit.dart';
import 'package:eschool_saas_staff/cubits/payRoll/downloadPayRollSlipCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/payRoll/myPayRollCubit.dart';
import 'package:eschool_saas_staff/data/models/payroll/payRoll.dart';
import 'package:eschool_saas_staff/data/models/academic/sessionYear.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/payroll/downloadPayRollSlipDialog.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';

class MyPayrollScreen extends StatefulWidget {
  const MyPayrollScreen({super.key});

  static Widget getRouteInstance() {
    //final arguments = Get.arguments as Map<String,dynamic>;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SessionYearsCubit(),
        ),
        BlocProvider(create: (context) => MyPayRollCubit())
      ],
      child: const MyPayrollScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<MyPayrollScreen> createState() => _MyPayrollScreenState();
}

class _MyPayrollScreenState extends State<MyPayrollScreen>
    with TickerProviderStateMixin {
  SessionYear? _selectedSessionYear;

  // Color scheme for maroon theme
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;
  Color get _maroonLight => AppColorPalette.secondaryMaroon;

  // Animation controller for various animated elements
  late AnimationController _fabAnimationController;
  late final ScrollController _scrollController = ScrollController()
    ..addListener(scrollListener);

  // State variables for UI interactions
  bool _isFilterVisible = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<SessionYearsCubit>().getSessionYears();
      }
    });
  }

  void scrollListener() {
    // Animate elements based on scroll
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
    super.dispose();
  }

  void changeSelectedSessionYear(SessionYear value) {
    _selectedSessionYear = value;
    setState(() {});
    getPayRoll();
  }

  void getPayRoll() {
    context
        .read<MyPayRollCubit>()
        .getMyPayRoll(sessionYearId: _selectedSessionYear?.id ?? 0);
  }

  Widget _buildSessionYearFilter() {
    return BlocBuilder<SessionYearsCubit, SessionYearsState>(
      builder: (context, state) {
        if (state is SessionYearsFetchSuccess &&
            state.sessionYears.isNotEmpty) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Utils.showBottomSheet(
                  child: FilterSelectionBottomsheet<SessionYear>(
                    onSelection: (value) {
                      changeSelectedSessionYear(value!);
                      Get.back();
                    },
                    selectedValue: _selectedSessionYear!,
                    titleKey: sessionYearKey,
                    values: state.sessionYears,
                  ),
                  context: context,
                );
              },
              highlightColor: Colors.white.withValues(alpha: 0.1),
              splashColor: Colors.white.withValues(alpha: 0.2),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedSessionYear?.name ?? "Tahun Ajaran",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildPayRolls() {
    return BlocBuilder<MyPayRollCubit, MyPayRollState>(
      builder: (context, state) {
        if (state is MyPayRollFetchSuccess) {
          if (state.payrolls.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _maroonPrimary.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 70,
                      color: _maroonPrimary.withValues(alpha: 0.7),
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 24),
                  Text(
                    'Gaji Belum Tersedia',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _maroonPrimary,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 12),
                  Text(
                    'Gaji Anda untuk periode ini belum tersedia',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              getPayRoll();
            },
            color: _maroonPrimary,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(
                bottom: 100,
                // Adjust padding since we're now using PreferredSizeWidget
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
                          'Riwayat Gaji',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _maroonPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lihat riwayat lengkap gaji Anda',
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

                  // Payroll list with container styling
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
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(16)),
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
                                  Icons.account_balance_wallet,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Gaji Periode',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      '${state.payrolls.length} pembayaran tersedia',
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
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: Color(0xFF28A745),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Dibayar",
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF28A745),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Payroll items list
                        Column(
                          children: List.generate(
                            state.payrolls.length,
                            (index) => MyPayrollDetailsContainer(
                              payRoll: state.payrolls[index],
                              index: index,
                              maroonPrimary: _maroonPrimary,
                              maroonLight: _maroonLight,
                            ),
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
          );
        }

        if (state is MyPayRollFetchFailure) {
          return Center(
            child: CustomErrorWidget(
              message:
                  ErrorMessageUtils.getReadableErrorMessage(state.errorMessage),
              onRetry: () {
                getPayRoll();
              },
              primaryColor: _maroonPrimary,
            ),
          );
        }

        return const SkeletonPayrollCard().animate().fadeIn(duration: 300.ms);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomModernAppBar(
        title: 'Gaji Saya',
        icon: Icons.payments_rounded,
        fabAnimationController: _fabAnimationController,
        primaryColor: _maroonPrimary,
        lightColor: _maroonLight,
        height: 150,
        showFilterButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
        onFilterPressed: () {
          setState(() {
            _isFilterVisible = !_isFilterVisible;
          });
        },
        tabBuilder:
            _isFilterVisible ? (context) => _buildSessionYearFilter() : null,
      ),
      body: Stack(
        children: [
          BlocBuilder<SessionYearsCubit, SessionYearsState>(
            builder: (context, state) {
              if (state is SessionYearsFetchSuccess) {
                if (state.sessionYears.isNotEmpty) {
                  return _buildPayRolls();
                }
                return const SizedBox();
              }

              if (state is SessionYearsFetchFailure) {
                return Center(
                  child: CustomErrorWidget(
                    message: ErrorMessageUtils.getReadableErrorMessage(
                        state.errorMessage),
                    onRetry: () {
                      context.read<SessionYearsCubit>().getSessionYears();
                    },
                    primaryColor: _maroonPrimary,
                  ),
                );
              }

              return const SkeletonPayrollCard();
            },
          ),

          // Code for SessionYearsCubit listener
          BlocListener<SessionYearsCubit, SessionYearsState>(
            listener: (context, state) {
              if (state is SessionYearsFetchSuccess &&
                  state.sessionYears.isNotEmpty) {
                changeSelectedSessionYear(state.sessionYears
                    .where((element) => element.isThisDefault())
                    .toList()
                    .first);
              }
            },
            child: const SizedBox(),
          ),
        ],
      ),
    );
  }
}

class MyPayrollDetailsContainer extends StatefulWidget {
  final int index;
  final PayRoll payRoll;
  final Color maroonPrimary;
  final Color maroonLight;

  const MyPayrollDetailsContainer({
    super.key,
    required this.index,
    required this.payRoll,
    required this.maroonPrimary,
    required this.maroonLight,
  });

  @override
  State<MyPayrollDetailsContainer> createState() =>
      _MyPayrollDetailsContainerState();
}

class _MyPayrollDetailsContainerState extends State<MyPayrollDetailsContainer>
    with TickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));

  late final AnimationController _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
    ..repeat(reverse: true);

  // Remove fixed height animation
  bool get _isExpanded => _animationController.value > 0.5;

  late final Animation<double> _opacityAnimation =
      Tween<double>(begin: 0, end: 1.0).animate(CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));

  late final Animation<double> _iconAngleAnimation =
      Tween<double>(begin: 0, end: 0.5).animate(CurvedAnimation(
          parent: _animationController, curve: Curves.easeInOut));

  late final Animation<double> _pulseAnimation =
      Tween<double>(begin: 1.0, end: 1.08).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

  bool _isHovered = false;

  String _formatToRupiah(double? value) {
    if (value == null) return "Rp -";
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  String getIndonesianMonth(int monthNumber) {
    const List<String> indonesianMonths = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];

    if (monthNumber >= 1 && monthNumber <= 12) {
      return indonesianMonths[monthNumber - 1];
    }
    return 'Bulan tidak valid';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // Modern styled info row for payroll details
  Widget _buildInfoRow({
    required String label,
    required String value,
    IconData? icon,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side - label with icon
          Expanded(
            flex: 2,
            child: Row(
              children: [
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: widget.maroonPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: widget.maroonPrimary,
                    ),
                  ),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              ":",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ),

          // Right side - value
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? widget.maroonPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_animationController, _pulseAnimation]),
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? widget.maroonPrimary.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: _isHovered ? 10 : 4,
                  offset: const Offset(0, 2),
                  spreadRadius: _isHovered ? 1 : 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (_animationController.isAnimating) {
                      return;
                    }

                    if (_animationController.isCompleted) {
                      _animationController.reverse();
                    } else {
                      _animationController.forward();
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  splashColor: widget.maroonPrimary.withValues(alpha: 0.05),
                  highlightColor: widget.maroonPrimary.withValues(alpha: 0.05),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isHovered
                            ? widget.maroonPrimary.withValues(alpha: 0.2)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with month and year
                        Row(
                          children: [
                            // Left side with month and year
                            Expanded(
                              child: Row(
                                children: [
                                  // Container(
                                  //   padding: const EdgeInsets.all(10),
                                  //   decoration: BoxDecoration(
                                  //     gradient: LinearGradient(
                                  //       begin: Alignment.topLeft,
                                  //       end: Alignment.bottomRight,
                                  //       colors: [
                                  //         widget.maroonPrimary.withValues(alpha: 0.8),
                                  //         widget.maroonLight,
                                  //       ],
                                  //     ),
                                  //     borderRadius: BorderRadius.circular(12),
                                  //     boxShadow: [
                                  //       BoxShadow(
                                  //         color: widget.maroonPrimary
                                  //             .withValues(alpha: 0.2),
                                  //         blurRadius: 8,
                                  //         offset: const Offset(0, 4),
                                  //       ),
                                  //     ],
                                  //   ),
                                  //   child: Text(
                                  //     "${widget.index + 1}",
                                  //     style: GoogleFonts.poppins(
                                  //       fontSize: 16,
                                  //       fontWeight: FontWeight.bold,
                                  //       color: Colors.white,
                                  //     ),
                                  //   ),
                                  // ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          getIndonesianMonth(widget.payRoll.month ?? 1),
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          "${widget.payRoll.year ?? ''}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Right side with status and expand button
                            Row(
                              children: [
                                const SizedBox(width: 8),
                                Transform.rotate(
                                  angle:
                                      _iconAngleAnimation.value * 2 * 3.14159,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _animationController.isCompleted
                                          ? widget.maroonPrimary
                                              .withValues(alpha: 0.1)
                                          : Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.keyboard_arrow_down,
                                      color: _animationController.isCompleted
                                          ? widget.maroonPrimary
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Salary information section
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Basic salary
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.account_balance_wallet_outlined,
                                          size: 16,
                                          color: Colors.grey[700],
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Gaji Pokok",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatToRupiah(
                                          widget.payRoll.basicSalary),
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.grey[300],
                                margin: const EdgeInsets.symmetric(horizontal: 12),
                              ),

                              // Net salary
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.payments_rounded,
                                          size: 16,
                                          color: widget.maroonPrimary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Gaji Bersih",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: widget.maroonPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatToRupiah(widget.payRoll.amount),
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: widget.maroonPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Expanded details section with AnimatedSize
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _isExpanded
                              ? AnimatedOpacity(
                                  opacity: _opacityAnimation.value,
                                  duration: const Duration(milliseconds: 300),
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Section title
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 16,
                                              color: widget.maroonPrimary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Detail Gaji',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: widget.maroonPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Leave details
                                        _buildInfoRow(
                                          label: "Cuti Bulanan",
                                          value: widget.payRoll.paidLeaves
                                                  ?.toStringAsFixed(0) ??
                                              "-",
                                          icon: Icons.event_available,
                                        ),

                                        _buildInfoRow(
                                          label: "Cuti Diambil",
                                          value: widget.payRoll.takenLeaves
                                                  ?.toStringAsFixed(0) ??
                                              "-",
                                          icon: Icons.calendar_month,
                                        ),

                                        // Download button
                                        Container(
                                          width: double.infinity,
                                          margin:
                                              const EdgeInsets.only(top: 12),
                                          child: Material(
                                            color: Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              onTap: () {
                                                Get.dialog(BlocProvider(
                                                  create: (context) =>
                                                      DownloadPayRollSlipCubit(),
                                                  child:
                                                      DownloadPayRollSlipDialog(
                                                    payRoll: widget.payRoll,
                                                  ),
                                                ));
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      widget.maroonPrimary,
                                                      const Color(0xFF9A1E3C),
                                                    ],
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: widget
                                                          .maroonPrimary
                                                          .withValues(alpha: 0.3),
                                                      offset:
                                                          const Offset(0, 3),
                                                      blurRadius: 6,
                                                      spreadRadius: 0,
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.download_rounded,
                                                        color: Colors.white,
                                                        size: 18,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        Utils.getTranslatedLabel(
                                                            downloadSalarySlipKey),
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

