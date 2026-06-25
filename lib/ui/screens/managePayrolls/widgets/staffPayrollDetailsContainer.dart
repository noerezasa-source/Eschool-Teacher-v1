import 'dart:math';
import 'package:eschool_saas_staff/cubits/payRoll/downloadPayRollSlipCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/userDetails/staffAllowedPermissionsAndModulesCubit.dart';
import 'package:eschool_saas_staff/data/models/payroll/staffPayRoll.dart';
import 'package:eschool_saas_staff/ui/screens/managePayrolls/widgets/allowanceAndDeductionsBottomsheet.dart';
import 'package:eschool_saas_staff/ui/styles/themeExtensions/customColorsExtension.dart';
import 'package:eschool_saas_staff/ui/widgets/payroll/downloadPayRollSlipDialog.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/systemModulesAndPermissions.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class StaffPayrollDetailsContainer extends StatefulWidget {
  final StaffPayRoll staffPayRoll;
  final bool isSelected;
  final Function onTapCheckBox;
  final double allowedMonthlyLeaves;

  const StaffPayrollDetailsContainer({
    super.key,
    required this.staffPayRoll,
    required this.allowedMonthlyLeaves,
    required this.isSelected,
    required this.onTapCheckBox,
  });

  @override
  State<StaffPayrollDetailsContainer> createState() =>
      StaffPayrollDetailsContainerState();
}

class StaffPayrollDetailsContainerState
    extends State<StaffPayrollDetailsContainer> with TickerProviderStateMixin {
  late final TextEditingController _netSalaryTextEditingController =
      TextEditingController();
  late final FocusNode _netSalaryFocusNode = FocusNode();
  bool _isEditingNetSalary = false;

  late final TextEditingController _basicSalaryTextEditingController =
      TextEditingController();
  late final FocusNode _basicSalaryFocusNode = FocusNode();
  bool _isEditingBasicSalary = false;

  late final AnimationController _animationController =
      AnimationController(vsync: this, duration: tileCollapsedDuration);

  // Colors for the modern maroon theme
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;
  Color get _maroonLight => AppColorPalette.secondaryMaroon;

  late final Animation<double> _opacityAnimation =
      Tween<double>(begin: 0, end: 1.0).animate(CurvedAnimation(
          parent: _animationController, curve: const Interval(0.5, 1.0)));

  late final Animation<double> _iconAngleAnimation =
      Tween<double>(begin: 0, end: 180).animate(CurvedAnimation(
          parent: _animationController, curve: Curves.easeInOut));

  String formatRupiah(double amount) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatCurrency.format(amount);
  }

  double parseRupiahToDouble(String rupiahString) {
    // Remove non-numeric characters and convert to double
    String numericString = rupiahString.replaceAll(RegExp(r'[^0-9]'), '');
    return numericString.isEmpty ? 0.0 : double.parse(numericString);
  }

  @override
  void initState() {
    super.initState();

    // Initialize with calculated net salary
    _netSalaryTextEditingController.text = widget.staffPayRoll
        .getNetSalaryAmount(allowedMonthlyLeaves: widget.allowedMonthlyLeaves)
        .toStringAsFixed(2);

    // Initialize basic salary
    _basicSalaryTextEditingController.text =
        (widget.staffPayRoll.salary ?? 0.0).toStringAsFixed(2);

    // Add listener to net salary focus node to handle editing state
    _netSalaryFocusNode.addListener(() {
      setState(() {
        _isEditingNetSalary = _netSalaryFocusNode.hasFocus;
      });

      // Format the value when focus is lost
      if (!_netSalaryFocusNode.hasFocus) {
        try {
          final value =
              double.parse(_netSalaryTextEditingController.text.trim());
          _netSalaryTextEditingController.text = value.toStringAsFixed(2);
        } catch (e) {
          // Reset to default if parsing fails
          _netSalaryTextEditingController.text = widget.staffPayRoll
              .getNetSalaryAmount(
                  allowedMonthlyLeaves: widget.allowedMonthlyLeaves)
              .toStringAsFixed(2);
        }
      }
    });

    // Add listener to basic salary focus node to handle editing state
    _basicSalaryFocusNode.addListener(() {
      setState(() {
        _isEditingBasicSalary = _basicSalaryFocusNode.hasFocus;
      });

      // Format the value when focus is lost
      if (!_basicSalaryFocusNode.hasFocus) {
        try {
          final value =
              double.parse(_basicSalaryTextEditingController.text.trim());
          _basicSalaryTextEditingController.text = value.toStringAsFixed(2);
        } catch (e) {
          // Reset to default if parsing fails
          _basicSalaryTextEditingController.text =
              (widget.staffPayRoll.salary ?? 0.0).toStringAsFixed(2);
        }
      }
    });
  }

  @override
  void dispose() {
    _netSalaryTextEditingController.dispose();
    _netSalaryFocusNode.dispose();
    _basicSalaryTextEditingController.dispose();
    _basicSalaryFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  double getNetSalary() {
    try {
      return double.parse(_netSalaryTextEditingController.text.trim());
    } catch (e) {
      return widget.staffPayRoll.getNetSalaryAmount(
          allowedMonthlyLeaves: widget.allowedMonthlyLeaves);
    }
  }

  double getBasicSalary() {
    try {
      return double.parse(_basicSalaryTextEditingController.text.trim());
    } catch (e) {
      return widget.staffPayRoll.salary ?? 0.0;
    }
  }

  // Modern styled info row for leave details
  Widget _buildInfoRow({
    required String label,
    required String value,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side - label with icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _maroonPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(
                      icon,
                      size: 16,
                      color: _maroonPrimary,
                    ),
                  ),
                Text(
                  Utils.getTranslatedLabel(label),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              ":",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ),

          // Right side - value with fixed layout to prevent vertical display
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              alignment: Alignment.centerRight,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _maroonPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canEditSalary = !widget.staffPayRoll.receivedPayroll() &&
        context
            .read<StaffAllowedPermissionsAndModulesCubit>()
            .isPermissionGiven(permission: editPayrollEditPermissionKey);

    return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return GestureDetector(
            onTap: () {
              if (_animationController.isAnimating) {
                return;
              }

              if (_animationController.isCompleted) {
                _animationController.reverse();
              } else {
                _animationController.forward();
              }

              // Dismiss keyboard if editing
              if (_isEditingNetSalary) {
                _netSalaryFocusNode.unfocus();
              }

              if (_isEditingBasicSalary) {
                _basicSalaryFocusNode.unfocus();
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(
                  vertical: 18, horizontal: 8), // Tambah jarak antar card
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isSelected
                      ? _maroonPrimary.withValues(alpha: 0.3)
                      : Colors.grey[300]!,
                  width: widget.isSelected ? 2 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isSelected
                          ? _maroonPrimary.withValues(alpha: 0.3)
                          : Colors.transparent,
                      width: widget.isSelected ? 2 : 0,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, boxConstraints) {
                      final createPayRollPermissionGiven = context
                          .read<StaffAllowedPermissionsAndModulesCubit>()
                          .isPermissionGiven(
                              permission: createPayRollPermissionKey);

                      final editPayRollPermissionGiven = context
                          .read<StaffAllowedPermissionsAndModulesCubit>()
                          .isPermissionGiven(
                              permission: editPayrollEditPermissionKey);

                      bool showCheckSelectionBox = false;

                      if (widget.staffPayRoll.receivedPayroll()) {
                        if (editPayRollPermissionGiven) {
                          showCheckSelectionBox = true;
                        }
                      } else {
                        if (createPayRollPermissionGiven) {
                          showCheckSelectionBox = true;
                        }
                      }

                      return SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header section with staff name, status and toggle
                            _buildHeaderSection(showCheckSelectionBox),

                            // Salary Cards Section
                            _buildSalaryCardsSection(canEditSalary),

                            // Expanded details section
                            _buildExpandedDetailsSection(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        });
  }

  Widget _buildHeaderSection(bool showCheckSelectionBox) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isSelected
              ? [
                  _maroonPrimary.withValues(alpha: 0.05),
                  _maroonLight.withValues(alpha: 0.08)
                ]
              : [Colors.white, Colors.white],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        children: [
          // Checkbox or Person icon
          if (showCheckSelectionBox)
            GestureDetector(
              onTap: () {
                widget.onTapCheckBox.call();
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color:
                        widget.isSelected ? _maroonPrimary : Colors.grey[400]!,
                    width: 2,
                  ),
                  color:
                      widget.isSelected ? _maroonPrimary : Colors.transparent,
                ),
                child: widget.isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16.0,
                        color: Colors.white,
                      )
                    : const SizedBox(),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
              ),
              child: Icon(
                Icons.person_outline,
                size: 16,
                color: Colors.grey[700],
              ),
            ),

          const SizedBox(width: 12),

          // Staff name & status badge (rapi, nama di atas, status di bawah)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.staffPayRoll.userDetails?.firstName ??
                      (((widget.staffPayRoll.userDetails?.firstName ?? "") +
                              (widget.staffPayRoll.userDetails?.lastName !=
                                          null &&
                                      widget.staffPayRoll.userDetails
                                              ?.lastName !=
                                          ''
                                  ? " ${widget.staffPayRoll.userDetails!.lastName!}"
                                  : ""))
                          .trim()),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  softWrap: true,
                  // Tidak ada maxLines dan overflow
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.staffPayRoll.receivedPayroll()
                        ? Theme.of(context)
                            .extension<CustomColors>()!
                            .totalStaffOverviewBackgroundColor!
                            .withValues(alpha: 0.1)
                        : _maroonPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.staffPayRoll.receivedPayroll()
                            ? Icons.check_circle_outline
                            : Icons.pending_outlined,
                        size: 14,
                        color: widget.staffPayRoll.receivedPayroll()
                            ? Theme.of(context)
                                .extension<CustomColors>()!
                                .totalStaffOverviewBackgroundColor
                            : _maroonPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        Utils.getTranslatedLabel(
                            widget.staffPayRoll.receivedPayroll()
                                ? paidKey
                                : unpaidKey),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: widget.staffPayRoll.receivedPayroll()
                              ? Theme.of(context)
                                  .extension<CustomColors>()!
                                  .totalStaffOverviewBackgroundColor
                              : _maroonPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Toggle indicator
          Transform.rotate(
            angle: (pi * _iconAngleAnimation.value) / 180,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
              ),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: _maroonPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryCardsSection(bool canEditNetSalary) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Salary labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  Utils.getTranslatedLabel(basicSalaryKey),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  Utils.getTranslatedLabel(netSalaryKey),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Salary amounts in cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Basic Salary Card
              Expanded(
                child: GestureDetector(
                  onTap: canEditNetSalary
                      ? () {
                          setState(() {
                            _isEditingBasicSalary = true;
                          });
                          // Set focus to the text field
                          _basicSalaryFocusNode.requestFocus();
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _isEditingBasicSalary
                              ? _maroonPrimary
                              : Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (canEditNetSalary) ...[
                              const Spacer(),
                              Icon(
                                Icons.edit,
                                size: 14,
                                color: Colors.grey[400],
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Show either editable text field or static text
                        if (_isEditingBasicSalary && canEditNetSalary)
                          TextFormField(
                            controller: _basicSalaryTextEditingController,
                            focusNode: _basicSalaryFocusNode,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]')),
                            ],
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              hintText: "0.00",
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[400],
                              ),
                              prefix: Text(
                                "Rp ",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            onEditingComplete: () {
                              setState(() {
                                _isEditingBasicSalary = false;
                              });
                              _basicSalaryFocusNode.unfocus();
                            },
                          )
                        else
                          Text(
                            formatRupiah(getBasicSalary()),
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
                ),
              ),

              const SizedBox(width: 12),

              // Net Salary Card - Now editable when applicable
              Expanded(
                child: GestureDetector(
                  onTap: canEditNetSalary
                      ? () {
                          setState(() {
                            _isEditingNetSalary = true;
                          });
                          // Set focus to the text field
                          _netSalaryFocusNode.requestFocus();
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _maroonPrimary.withValues(alpha: 0.08),
                          _maroonLight.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _isEditingNetSalary
                              ? _maroonPrimary
                              : _maroonPrimary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (canEditNetSalary) ...[
                              const Spacer(),
                              Icon(
                                Icons.edit,
                                size: 14,
                                color: _maroonPrimary.withValues(alpha: 0.7),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Show either editable text field or static text
                        if (_isEditingNetSalary && canEditNetSalary)
                          TextFormField(
                            controller: _netSalaryTextEditingController,
                            focusNode: _netSalaryFocusNode,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]')),
                            ],
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _maroonPrimary,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              hintText: "0.00",
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _maroonPrimary.withValues(alpha: 0.5),
                              ),
                              prefix: Text(
                                "Rp ",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _maroonPrimary,
                                ),
                              ),
                            ),
                            onEditingComplete: () {
                              setState(() {
                                _isEditingNetSalary = false;
                              });
                              _netSalaryFocusNode.unfocus();
                            },
                          )
                        else
                          Text(
                            formatRupiah(getNetSalary()),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _maroonPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetailsSection() {
    return AnimatedOpacity(
      opacity: _opacityAnimation.value,
      duration: const Duration(milliseconds: 300),
      child: _animationController.value > 0.5
          ? Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Section title
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 12),
                      margin: const EdgeInsets.only(bottom: 16),
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
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: _maroonPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Detail Informasi',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _maroonPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Leave details
                    _buildInfoRow(
                      label: monthlyAllowedPaidLeavesKey,
                      value: widget.allowedMonthlyLeaves.toStringAsFixed(0),
                      icon: Icons.event_available,
                    ),

                    _buildInfoRow(
                      label: monthlyTakenLeavesKey,
                      value: widget.staffPayRoll
                          .totalTakenLeaves()
                          .toStringAsFixed(1)
                          .replaceAll('.0', ''),
                      icon: Icons.event_busy,
                    ),

                    _buildInfoRow(
                      label: "Potongan",
                      value: formatRupiah(
                          widget.staffPayRoll.getPossibleSalaryDeductionAmount(
                        allowedLeaves: widget.allowedMonthlyLeaves,
                      )),
                      icon: Icons.remove_circle_outline,
                    ),

                    // Action button
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            if (widget.staffPayRoll.receivedPayroll()) {
                              Get.dialog(BlocProvider(
                                create: (context) => DownloadPayRollSlipCubit(),
                                child: DownloadPayRollSlipDialog(
                                  payRoll: widget.staffPayRoll.payRolls!.first,
                                ),
                              ));
                            } else {
                              Utils.showBottomSheet(
                                child: AllowanceAndDeductionsBottomsheet(
                                  allowances:
                                      widget.staffPayRoll.getAllowances(),
                                  deductions:
                                      widget.staffPayRoll.getDeductions(),
                                  baseSalary: widget.staffPayRoll.salary,
                                ),
                                context: context,
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _maroonPrimary,
                                  const Color(0xFF9A1E3C),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: _maroonPrimary.withValues(alpha: 0.2),
                                  offset: const Offset(0, 2),
                                  blurRadius: 5,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.staffPayRoll.receivedPayroll()
                                        ? Icons.download_rounded
                                        : Icons.list_alt_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    Utils.getTranslatedLabel(
                                      widget.staffPayRoll.receivedPayroll()
                                          ? downloadSalarySlipKey
                                          : allowancesAndDeductionsKey,
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
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
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad)
          : const SizedBox(),
    );
  }
}

