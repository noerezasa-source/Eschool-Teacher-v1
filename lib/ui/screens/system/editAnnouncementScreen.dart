import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/cubits/announcement/editGeneralAnnouncementCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/data/models/announcement/announcement.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/academic/studyMaterial.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/customFileContainer.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/studyMaterialContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/errorContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/multiSelectionValueBottomsheet.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class EditAnnouncementScreen extends StatefulWidget {
  final Announcement announcement;
  const EditAnnouncementScreen({super.key, required this.announcement});

  static Widget getRouteInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ClassesCubit(),
        ),
        BlocProvider(
          create: (context) => EditGeneralAnnouncementCubit(),
        ),
      ],
      child: EditAnnouncementScreen(
        announcement: arguments['announcement'],
      ),
    );
  }

  static Map<String, dynamic> buildArguments(
      {required Announcement announcement}) {
    return {"announcement": announcement};
  }

  @override
  State<EditAnnouncementScreen> createState() => _EditAnnouncementScreenState();
}

class _EditAnnouncementScreenState extends State<EditAnnouncementScreen>
    with TickerProviderStateMixin {
  List<ClassSection> _selectedClassSections = [];

  // Define the maroon color palette
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;
  Color get _maroonLight => AppColorPalette.secondaryMaroon;

  late final TextEditingController _titleTextEditingController =
      TextEditingController(text: widget.announcement.title ?? "");
  late final TextEditingController _descriptionTextEditingController =
      TextEditingController(text: widget.announcement.description ?? "");

  final List<PlatformFile> _pickedFiles = [];

  late final List<StudyMaterial> _files = widget.announcement.files ?? [];

  bool refreshAnnouncementsInPreviousPage = false;

  // Animation controllers
  late final AnimationController _fabAnimationController;
  late final AnimationController _formAnimationController;
  late final ScrollController _scrollController = ScrollController()
    ..addListener(_scrollListener);

  int _activeSection = 0; // 0 = title, 1 = description, 2 = classes, 3 = files
  double _contentOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _formAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<ClassesCubit>().getClasses();
        _formAnimationController.forward();
        Future.delayed(const Duration(milliseconds: 200), () {
          setState(() {
            _contentOpacity = 1.0;
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _titleTextEditingController.dispose();
    _descriptionTextEditingController.dispose();
    _fabAnimationController.dispose();
    _formAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 50) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  Future<void> _pickFiles() async {
    final result = await Utils.openFilePicker(context: context);
    if (result != null) {
      _pickedFiles.addAll(result.files);
      setState(() {});
    }
  }

  Widget _buildHeaderSection() {
    return CustomModernAppBar(
      title: Utils.getTranslatedLabel(editAnnouncementKey),
      icon: Icons.announcement_rounded,
      fabAnimationController: _fabAnimationController,
      primaryColor: _maroonPrimary,
      lightColor: _maroonLight,
      onBackPressed: () {
        if (context.read<EditGeneralAnnouncementCubit>().state
            is! EditGeneralAnnouncementInProgress) {
          Get.back();
        }
      },
      height: 100,
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<ClassesCubit, ClassesState>(
      builder: (context, state) {
        if (state is! ClassesFetchSuccess) {
          return const SizedBox();
        }
        return AnimatedBuilder(
            animation: _fabAnimationController,
            builder: (context, child) {
              return Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white,
                      ],
                    ),
                  ),
                  child: BlocConsumer<EditGeneralAnnouncementCubit,
                      EditGeneralAnnouncementState>(
                    listener: (context, editGeneralAnnouncementState) {
                      if (editGeneralAnnouncementState
                          is EditGeneralAnnouncementSuccess) {
                        Get.back();
                        // Show auto-dismissing success snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text(
                                    'Pengumuman  diperbarui!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            backgroundColor: Colors.green.shade400,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                          ),
                        );

                        // Add slight delay before popping
                        Future.delayed(const Duration(milliseconds: 2200), () {
                          if (context.mounted) {
                            Get.back(result: true);
                          }
                        });
                      } else if (editGeneralAnnouncementState
                          is EditGeneralAnnouncementFailure) {
                        Utils.showSnackBar(
                            message: editGeneralAnnouncementState.errorMessage,
                            context: context);
                      }
                    },
                    builder: (context, editGeneralAnnouncementState) {
                      final bool isLoading = editGeneralAnnouncementState
                          is EditGeneralAnnouncementInProgress;

                      return PopScope(
                        canPop: !isLoading,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isLoading
                                  ? [Colors.grey.shade400, Colors.grey.shade500]
                                  : [_maroonPrimary, _maroonLight],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isLoading
                                    ? Colors.grey.withValues(alpha: 0.3)
                                    : _maroonPrimary.withValues(alpha: 0.3),
                                offset: const Offset(0, 4),
                                blurRadius: 12,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              highlightColor:
                                  Colors.white.withValues(alpha: 0.1),
                              splashColor: Colors.white.withValues(alpha: 0.2),
                              onTap: () {
                                if (isLoading) return;

                                if (_titleTextEditingController.text
                                    .trim()
                                    .isEmpty) {
                                  Utils.showSnackBar(
                                      message: pleaseEnterTitleKey,
                                      context: context);
                                  return;
                                }

                                if (_selectedClassSections.isEmpty) {
                                  Utils.showSnackBar(
                                      message: pleaseSelectAtLeastOneClassKey,
                                      context: context);
                                  return;
                                }

                                context
                                    .read<EditGeneralAnnouncementCubit>()
                                    .editGeneralAnnouncement(
                                        announcementId:
                                            widget.announcement.id ?? 0,
                                        description:
                                            _descriptionTextEditingController
                                                .text
                                                .trim(),
                                        filePaths: _pickedFiles
                                            .map((e) => e.path ?? "")
                                            .toList(),
                                        title: _titleTextEditingController.text
                                            .trim(),
                                        classSectionIds: _selectedClassSections
                                            .map((e) => e.id ?? 0)
                                            .toList());
                              },
                              child: Center(
                                child: isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.save_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            Utils.getTranslatedLabel(editKey),
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
                        ).animate(target: isLoading ? 0 : 1).custom(
                              duration: 300.ms,
                              builder: (context, value, child) =>
                                  Transform.scale(
                                scale: 0.95 + (0.05 * value),
                                child: child,
                              ),
                            ),
                      );
                    },
                  ),
                ),
              );
            });
      },
    );
  }

  Widget _buildContentSection(
      Widget icon, String title, String subtitle, Widget content,
      {bool isActive = false}) {
    return AnimatedOpacity(
      opacity: _contentOpacity,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? _maroonPrimary.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: isActive ? 2 : 0,
            ),
          ],
          border: isActive
              ? Border.all(
                  color: _maroonPrimary.withValues(alpha: 0.3), width: 1.5)
              : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive
                    ? _maroonPrimary.withValues(alpha: 0.08)
                    : Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? _maroonPrimary.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: icon,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? _maroonPrimary
                                : Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: content,
            ),
          ],
        ),
      ).animate(target: isActive ? 1 : 0).custom(
            duration: 300.ms,
            builder: (context, value, child) => Transform.scale(
              scale: 0.98 + (0.02 * value),
              child: child,
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F7),
      body: Stack(
        children: [
          // Background decoration
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundDecorationPainter(),
            ),
          ),

          // Main content
          Column(
            children: [
              // Header section
              _buildHeaderSection(),

              // Scrollable content
              Expanded(
                child: BlocConsumer<ClassesCubit, ClassesState>(
                  listener: (context, state) {
                    if (state is ClassesFetchSuccess) {
                      if (_selectedClassSections.isEmpty &&
                          context
                              .read<ClassesCubit>()
                              .getAllClasses()
                              .isNotEmpty) {
                        for (var classSection
                            in context.read<ClassesCubit>().getAllClasses()) {
                          final announcementSentToThisClass = widget
                                  .announcement.announcementClasses
                                  ?.indexWhere((element) =>
                                      element.classSectionId ==
                                      classSection.id) !=
                              -1;
                          if (announcementSentToThisClass) {
                            _selectedClassSections.add(classSection);
                          }
                        }
                        setState(() {});
                      }
                    }
                  },
                  builder: (context, state) {
                    if (state is ClassesFetchSuccess) {
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: _formAnimationController.value,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 100, top: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title section
                              _buildContentSection(
                                Icon(Icons.title_rounded,
                                    color: _activeSection == 0
                                        ? _maroonPrimary
                                        : Colors.grey.shade600,
                                    size: 22),
                                'Judul Pengumuman',
                                'Masukkan judul yang jelas dan ringkas',
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      controller: _titleTextEditingController,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            Utils.getTranslatedLabel(titleKey),
                                        hintStyle: GoogleFonts.poppins(
                                          fontSize: 15,
                                          color: Colors.grey.shade400,
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: _maroonPrimary,
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                      cursorColor: _maroonPrimary,
                                      onTap: () {
                                        setState(() {
                                          _activeSection = 0;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                isActive: _activeSection == 0,
                              ),

                              // Description section
                              _buildContentSection(
                                Icon(Icons.description_outlined,
                                    color: _activeSection == 1
                                        ? _maroonPrimary
                                        : Colors.grey.shade600,
                                    size: 22),
                                'Deskripsi',
                                'Berikan detail pengumuman dengan jelas',
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      controller:
                                          _descriptionTextEditingController,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 6,
                                      decoration: InputDecoration(
                                        hintText: Utils.getTranslatedLabel(
                                            descriptionKey),
                                        hintStyle: GoogleFonts.poppins(
                                          fontSize: 15,
                                          color: Colors.grey.shade400,
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: _maroonPrimary,
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                      cursorColor: _maroonPrimary,
                                      onTap: () {
                                        setState(() {
                                          _activeSection = 1;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                isActive: _activeSection == 1,
                              ),

                              // Class selection section
                              _buildContentSection(
                                Icon(Icons.people_outlined,
                                    color: _activeSection == 2
                                        ? _maroonPrimary
                                        : Colors.grey.shade600,
                                    size: 22),
                                'Kelas Penerima',
                                'Pilih kelas yang akan menerima pengumuman',
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _activeSection = 2;
                                        });
                                        Utils.showBottomSheet(
                                                child: MultiSelectionValueBottomsheet<
                                                        ClassSection>(
                                                    values: context
                                                        .read<ClassesCubit>()
                                                        .getAllClasses(),
                                                    selectedValues: List.from(
                                                        _selectedClassSections),
                                                    titleKey: titleKey),
                                                context: context)
                                            .then((value) {
                                          if (value != null) {
                                            final classes =
                                                List<ClassSection>.from(
                                                    value as List);
                                            _selectedClassSections =
                                                List<ClassSection>.from(
                                                    classes);
                                            setState(() {});
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _activeSection == 2
                                                ? _maroonPrimary
                                                : Colors.grey.shade300,
                                            width:
                                                _activeSection == 2 ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.class_outlined,
                                              color: _maroonLight,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              Utils.getTranslatedLabel(
                                                  classSectionKey),
                                              style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const Spacer(),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              color: Colors.grey.shade400,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Selected classes
                                    if (_selectedClassSections.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: _maroonPrimary.withValues(
                                              alpha: 0.05),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle_outline,
                                                  color: _maroonPrimary,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Kelas Terpilih: ${_selectedClassSections.length}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: _maroonPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Wrap(
                                              spacing: 10,
                                              runSpacing: 10,
                                              children: _selectedClassSections
                                                  .map((classSection) {
                                                return Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                    border: Border.all(
                                                      color: _maroonLight
                                                          .withValues(
                                                              alpha: 0.3),
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                                alpha: 0.03),
                                                        blurRadius: 4,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.groups_rounded,
                                                        color: _maroonLight,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        classSection.fullName ??
                                                            "-",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 13,
                                                          color: Colors
                                                              .grey.shade800,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.amber.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.warning_amber_rounded,
                                              color: Colors.amber.shade800,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Pilih minimal satu kelas untuk melanjutkan',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: Colors.amber.shade900,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                isActive: _activeSection == 2,
                              ),

                              // Files section
                              _buildContentSection(
                                Icon(Icons.attach_file_rounded,
                                    color: _activeSection == 3
                                        ? _maroonPrimary
                                        : Colors.grey.shade600,
                                    size: 22),
                                'Lampiran',
                                'Tambah atau kelola file lampiran',
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Existing files
                                    if (_files.isNotEmpty)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _maroonPrimary,
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            child: Text(
                                              'File Yang Tersedia (${_files.length})',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Column(
                                            children:
                                                _files.map((studyMaterial) {
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 12),
                                                child: StudyMaterialContainer(
                                                  onDeleteStudyMaterial:
                                                      (fileId) {
                                                    _files.removeWhere(
                                                        (element) =>
                                                            element.id ==
                                                            fileId);
                                                    refreshAnnouncementsInPreviousPage =
                                                        true;
                                                    setState(() {});
                                                  },
                                                  showOnlyStudyMaterialTitles:
                                                      true,
                                                  showEditAndDeleteButton: true,
                                                  studyMaterial: studyMaterial,
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                          const Divider(height: 32),
                                        ],
                                      ),

                                    // File picker button
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _activeSection = 3;
                                        });
                                        _pickFiles();
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _maroonPrimary.withValues(
                                              alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _maroonPrimary.withValues(
                                                alpha: 0.2),
                                            width: 1.5,
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: _maroonPrimary
                                                    .withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.file_upload_outlined,
                                                color: _maroonPrimary,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Tambah File Lampiran',
                                              style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: _maroonPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'File gambar dan dokumen (jpg, png, pdf, doc, dll)',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Picked files list
                                    if (_pickedFiles.isNotEmpty)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade500,
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            child: Text(
                                              'File Baru Dipilih (${_pickedFiles.length})',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Column(
                                            children: List.generate(
                                                _pickedFiles.length, (index) {
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 12),
                                                child: CustomFileContainer(
                                                  backgroundColor: Colors.white,
                                                  onDelete: () {
                                                    _pickedFiles
                                                        .removeAt(index);
                                                    setState(() {});
                                                  },
                                                  title:
                                                      _pickedFiles[index].name,
                                                ),
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                isActive: _activeSection == 3,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is ClassesFetchFailure) {
                      return Center(
                        child: ErrorContainer(
                          errorMessage: state.errorMessage,
                          onTapRetry: () {
                            context.read<ClassesCubit>().getClasses();
                          },
                        ),
                      );
                    }

                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomCircularProgressIndicator(
                            indicatorColor: _maroonPrimary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Memuat data...',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms);
                  },
                ),
              ),
            ],
          ),

          // Submit button
          _buildSubmitButton(),
        ],
      ),
    );
  }
}

class BackgroundDecorationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade100
      ..style = PaintingStyle.fill;

    // Draw decorative circles
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.1), 60, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.3), 40, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.6), 30, paint);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.8), 50, paint);

    final dotPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;

    // Draw dot pattern
    for (double i = 0; i < size.width; i += 30) {
      for (double j = 0; j < size.height; j += 30) {
        if (Random().nextBool() && Random().nextInt(10) > 7) {
          canvas.drawCircle(Offset(i, j), 2, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
