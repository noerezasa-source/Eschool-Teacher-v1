import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/cubits/onlineExam/onlineExamCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/classSectionsAndSubjects.dart';
import 'package:eschool_saas_staff/data/models/academic/teacherSubject.dart';
import 'package:eschool_saas_staff/data/models/exam/onlineExam.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'dart:math';

class EditOnlineExam extends StatefulWidget {
  final OnlineExam exam;

  const EditOnlineExam({super.key, required this.exam});

  @override
  State<EditOnlineExam> createState() => _EditOnlineExamState();
}

class _EditOnlineExamState extends State<EditOnlineExam>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomModernAppBar(
        title: 'Edit Ujian Online',
        icon: Icons.quiz,
        fabAnimationController: _animationController,
        primaryColor: _primaryColor,
        lightColor: _accentColor,
        onBackPressed: () => Navigator.pop(context),
        // We're not showing add or archive buttons as per requirements
        showAddButton: false,
        showArchiveButton: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 20),
              _buildExamDetailsSection(),
              const SizedBox(height: 20),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  final _formKey = GlobalKey<FormState>();

  late AnimationController _animationController;

  TeacherSubject? selectedSubject;
  String? selectedTingkatan;
  String? selectedKelas;
  String? selectedMapel;
  List<String> tingkatanList = [];
  List<String> kelasList = [];
  List<String> mapelList = [];
  late TextEditingController _titleController;
  late TextEditingController _examKeyController;
  late TextEditingController _durationController;
  late TextEditingController _startDateController;
  late TextEditingController _startTimeController;
  DateTime? startDate;
  TimeOfDay? startTime;

  // Theme colors - Softer Maroon palette
  static const Color _primaryColor = Color(0xFF7A1E23); // Softer deep maroon
  static const Color _accentColor = Color(0xFF9D3C3C); // Softer medium maroon

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing exam data

    final timeString = DateFormat('HH:mm').format(widget.exam.startDate);

    _titleController = TextEditingController(text: widget.exam.title);
    _examKeyController = TextEditingController(text: widget.exam.examKey);
    _durationController =
        TextEditingController(text: widget.exam.duration.toString());
    startDate = widget.exam.startDate;
    startTime = TimeOfDay(
        hour: int.parse(timeString.split(':')[0]),
        minute: int.parse(timeString.split(':')[1]));

    _startDateController = TextEditingController(
      text: DateFormat('dd-MM-yyyy').format(widget.exam.startDate),
    );

    _startTimeController = TextEditingController(
        text: DateFormat('HH:mm').format(widget.exam.startDate));

    // Initialize animation controllers for the CustomModernAppBar
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animationController.forward();

    // Load class sections for the teacher
    context.read<ClassSectionsAndSubjectsCubit>().getClassSectionsAndSubjects(classSectionId: widget.exam.classSectionId);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _examKeyController.dispose();
    _durationController.dispose();
    _startDateController.dispose();
    _startTimeController.dispose();

    _animationController.dispose();

    super.dispose();
  }

  // Date picker methods
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

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      if (selectedSubject == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih mata pelajaran terlebih dahulu')),
        );
        return;
      }

      // Validasi startDate
      if (startDate == null || startTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih tanggal mulai terlebih dahulu')),
        );
        return;
      }

      context
          .read<OnlineExamCubit>()
          .updateOnlineExam(
            id: widget.exam.id,
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
          )
          .then((_) {
        // Show success dialog
        Get.dialog(
          Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 60,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Berhasil!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 8, 0, 0),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ujian berhasil diperbarui',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color.fromARGB(255, 80, 80, 80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Get.back(); // Close dialog
                      // Navigasi kembali ke halaman sebelumnya dengan membawa hasil
                      Navigator.pop(
                          context, true); // Return true to indicate success
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child:
                        const Text('OK', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          barrierDismissible: false,
        );
      }).catchError((error) {
        // Handle error silently
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui ujian: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  // Helper methods for the header

  // The rest of your methods remain unchanged...
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
    void Function(String)? onChanged, // Add this line
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
      onChanged: onChanged, // Add this line
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: labelColor ?? Theme.of(context).colorScheme.secondary,
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
          // Tambahkan subject dropdown di sini
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
            label: 'Kode Ujian',
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
              color: const Color(0xFF8B0000),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    return BlocBuilder<ClassSectionsAndSubjectsCubit, ClassSectionsAndSubjectsState>(
      builder: (context, state) {
        if (state is ClassSectionsAndSubjectsFetchSuccess) {
          final classSections = state.classSections;
          
          if (selectedTingkatan == null && selectedKelas == null && selectedMapel == null) {
            // First load initialization
            try {
              final initialClassSection = classSections.firstWhere((e) => e.id == widget.exam.classSectionId);
              
              // Use Future.microtask to avoid calling setState during build
              Future.microtask(() {
                if (!mounted) return;
                setState(() {
                  selectedTingkatan = (initialClassSection.name ?? "").split(RegExp(r"\s+")).first.trim();
                  selectedKelas = initialClassSection.name;
                  
                  try {
                    final initialSubject = state.subjects.firstWhere((e) => e.classSubjectId == widget.exam.classSubjectId);
                    selectedMapel = initialSubject.subject.name;
                    selectedSubject = initialSubject;
                  } catch (e) {
                    debugPrint("Error finding initial subject: $e");
                  }
                });
              });
            } catch (e) {
              debugPrint("Error finding initial class section: $e");
            }
          }

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
                  prefixIcon: const Icon(Icons.layers, color: Color(0xFF8B0000)),
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
                    prefixIcon: const Icon(Icons.class_, color: Color(0xFF8B0000)),
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
                        debugPrint("Error fetching new subjects: $e");
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
                    prefixIcon: const Icon(Icons.menu_book, color: Color(0xFF8B0000)),
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

  // Tambahkan method untuk generate exam key
  String _generateExamKey() {
    const chars = '0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
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
                  label: 'Tanggal Mulai',
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
                      'Perbarui Ujian',
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

  // Cascading subject dropdown is implemented earlier in the file.
}
