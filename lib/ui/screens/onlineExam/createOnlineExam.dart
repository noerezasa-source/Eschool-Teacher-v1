import 'package:flutter/material.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/cubits/onlineExam/onlineExamCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/classSectionsAndSubjects.dart';
import 'package:eschool_saas_staff/data/models/academic/teacherSubject.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:eschool_saas_staff/cubits/academics/sessionYearsAndMediumsCubit.dart';
import 'package:collection/collection.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';

class CreateOnlineExam extends StatefulWidget {
  const CreateOnlineExam({super.key});

  @override
  State<CreateOnlineExam> createState() => _CreateOnlineExamState();
}

class _CreateOnlineExamState extends State<CreateOnlineExam>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  TeacherSubject? selectedSubject;
  String? selectedTingkatan;
  String? selectedKelas;
  String? selectedMapel;
  List<String> tingkatanList = [];
  List<String> kelasList = [];
  List<String> mapelList = [];
  String title = '';
  String examKey = '';
  int duration = 0;
  DateTime? startDate;
  TimeOfDay? startTime;
  // Animation controllers for the UI elements
  late AnimationController _animationController; // For the AppBar
  // Theme colors for elements within the screen

  // Text controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _examKeyController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ensure exams and class/subject data are loaded
    context.read<OnlineExamCubit>().getOnlineExams();
    Future.delayed(Duration.zero, () {
      if (mounted) {
        context
            .read<ClassSectionsAndSubjectsCubit>()
            .getClassSectionsAndSubjects();
      }
    });

    // Initialize animation controllers
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomModernAppBar(
        title: 'Buat Ujian Online',
        icon: Icons.assignment,
        fabAnimationController: _animationController,
        primaryColor: AppColorPalette.primaryMaroon,
        lightColor: AppColorPalette.secondaryMaroon,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: BlocListener<OnlineExamCubit, OnlineExamState>(
        listener: (context, state) {
          if (state is CreateOnlineExamSuccess) {
            // Close loading dialog if it's open
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            _showSuccessDialog();
          } else if (state is CreateOnlineExamFailure) {
            // Close loading dialog if it's open
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  FadeInDown(
                    duration: const Duration(milliseconds: 500),
                    child: _buildBasicInfoSection(),
                  ),
                  const SizedBox(height: 20),
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 100),
                    child: _buildExamDetailsSection(),
                  ),
                  const SizedBox(height: 20),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Stop animations before disposing
    // Dispose animation controllers
    _animationController.dispose();

    // Dispose text controllers
    _titleController.dispose();
    _examKeyController.dispose();
    _durationController.dispose();
    _startDateController.dispose();
    _startTimeController.dispose();
    super.dispose();
  }

  // Header methods copied from onlineExamScreen

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
        _startDateController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: startTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && picked != startTime) {
      setState(() {
        startTime = picked;
        _startTimeController.text = picked.format(context);
      });
    }
  }

  // Add this method to generate random exam key
  String _generateExamKey() {
    const chars = '0123456789'; // Changed to only numbers
    final random = Random();
    return List.generate(
            6,
            (index) => chars[random.nextInt(
                chars.length)]) // Changed length to 6 for better readability
        .join();
  }

  // Update the _buildAnimatedTextField method to accept a suffix icon
  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLines = 1,
    int? minLines,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    Color? iconColor,
    Color? labelColor,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator ?? (v) => v!.isEmpty ? 'Required' : null,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: labelColor ?? Colors.grey.shade600,
        ),
        prefixIcon: Icon(
          icon,
          color: iconColor ?? Theme.of(context).colorScheme.primary,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.secondary),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 5,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Dasar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 20),
          // Subject dropdown moved above title input
          _buildSubjectDropdown(),
          const SizedBox(height: 15),
          _buildAnimatedTextField(
            controller: _titleController,
            label: 'Judul Ujian',
            icon: Icons.title,
            maxLines: null,
            minLines: 2,
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: 15),
          _buildAnimatedTextField(
            controller: _examKeyController,
            label: 'Kunci Ujian',
            icon: Icons.key,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            suffixIcon: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                setState(() {
                  _examKeyController.text = _generateExamKey();
                });
              },
              tooltip: 'Generate Kunci Ujian',
              color: AppColorPalette.primaryMaroon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 5,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Ujian',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildAnimatedTextField(
                  controller: _startDateController,
                  label: 'Tgl Mulai',
                  icon: Icons.calendar_today,
                  onTap: () => _selectStartDate(context),
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildAnimatedTextField(
                  controller: _startTimeController,
                  label: 'Jam Mulai',
                  icon: Icons.access_time,
                  onTap: () => _selectStartTime(context),
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAnimatedTextField(
            controller: _durationController,
            label: 'Durasi (menit) Max 999 menit',
            icon: Icons.timer,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Durasi harus diisi';
              }
              if (value.length > 3) {
                return 'Durasi tidak boleh lebih dari 3 digit';
              }
              final duration = int.tryParse(value);
              if (duration == null || duration <= 0) {
                return 'Durasi harus lebih dari 0';
              }
              return null;
            },
            onChanged: (value) {
              if (value.length > 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Maksimal durasi adalah 999 menit'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
                // Truncate to 3 digits
                _durationController.text = value.substring(0, 3);
                _durationController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _durationController.text.length),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: FadeInUp(
        duration: const Duration(milliseconds: 600),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _submitForm,
              borderRadius: BorderRadius.circular(15),
              splashColor: Colors.white.withValues(alpha: 0.2),
              highlightColor: Colors.white.withValues(alpha: 0.1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Buat Ujian',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 22,
                    ).animate(onPlay: (controller) {
                      controller.repeat(reverse: true);
                    }).slideX(
                      begin: 0,
                      end: 0.3,
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    return BlocBuilder<ClassSectionsAndSubjectsCubit, ClassSectionsAndSubjectsState>(
      builder: (context, state) {
        if (state is ClassSectionsAndSubjectsFetchSuccess) {
          final classSections = state.classSections;
          
          tingkatanList = classSections
              .map((e) => (e.name ?? "").split(RegExp(r"\s+")).first.trim())
              .where((t) => t.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          kelasList = selectedTingkatan == null
              ? []
              : classSections
                  .where((e) => (e.name ?? "").split(RegExp(r"\s+")).first.trim() == selectedTingkatan)
                  .map((e) => e.name ?? "")
                  .toSet()
                  .toList()
            ..sort();

          mapelList = selectedKelas == null
              ? []
              : state.subjects.map((e) => e.subject.name ?? "").toSet().toList()
            ..sort();

          return Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedTingkatan,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.layers, color: AppColorPalette.primaryMaroon),
                  labelText: 'Pilih Tingkatan',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: tingkatanList
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    selectedTingkatan = v;
                    selectedKelas = null;
                    selectedMapel = null;
                    selectedSubject = null;
                  });
                },
                isExpanded: true,
                hint: const Text('Pilih Tingkatan'),
              ),
              if (selectedTingkatan != null) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedKelas,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.class_, color: AppColorPalette.primaryMaroon),
                    labelText: 'Pilih Kelas',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: kelasList
                      .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedKelas = v;
                      selectedMapel = null;
                      selectedSubject = null;
                    });
                    if (v != null) {
                      try {
                        final selectedClass = classSections.firstWhere((e) => (e.name ?? "") == v);
                        if (selectedClass.id != null) {
                          context.read<ClassSectionsAndSubjectsCubit>().getNewSubjectsFromSelectedClassSectionIndex(newClassSectionId: selectedClass.id!);
                        }
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    }
                  },
                  isExpanded: true,
                  hint: const Text('Pilih Kelas'),
                ),
              ],
              if (selectedKelas != null) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedMapel,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.menu_book, color: AppColorPalette.primaryMaroon),
                    labelText: 'Pilih Mata Pelajaran',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: mapelList
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedMapel = v;
                    });

                    final matches = state.subjects
                        .where((e) => e.subject.name == v)
                        .toList();
                    if (matches.isNotEmpty) {
                      setState(() {
                        selectedSubject = matches.first;
                      });
                    }
                  },
                  isExpanded: true,
                  hint: const Text('Pilih Mata Pelajaran'),
                  validator: (value) => value == null ? 'Pilih mata pelajaran' : null,
                ),
              ],
            ],
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      if (selectedSubject == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih mata pelajaran terlebih dahulu')),
        );
        return;
      }

      if (startDate == null || startTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih tanggal dan waktu ujian')),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColorPalette.primaryMaroon,
                        ),
                        strokeWidth: 4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Membuat Ujian...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      int? sessionYearId;
      final sessionState = context.read<SessionYearsAndMediumsCubit>().state;
      if (sessionState is SessionYearsAndMediumsFetchSuccess) {
        sessionYearId = sessionState.sessionYears
            .firstWhereOrNull((s) => s.defaultYear == 1)
            ?.id;
      }

      context.read<OnlineExamCubit>().createOnlineExam(
            classSectionId: selectedSubject!.classSectionId,
            classSubjectId: selectedSubject!.classSubjectId,
            title: _titleController.text,
            examKey: _examKeyController.text,
            duration: int.parse(_durationController.text),
            startDate: DateTime(
              startDate!.year,
              startDate!.month,
              startDate!.day,
              startTime!.hour,
              startTime!.minute,
            ),
            sessionYearId: sessionYearId,
          );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF4CAF50),
                        size: 45,
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Berhasil!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ujian berhasil dibuat dan siap digunakan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      _animationController.stop();
                      Navigator.pop(dialogContext);
                      Navigator.pop(context, true);
                    },
                    child: const Text(
                      'Lihat Daftar Ujian',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
