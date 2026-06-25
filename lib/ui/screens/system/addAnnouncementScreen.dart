import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/cubits/announcement/sendGeneralAnnouncementCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/ui/widgets/system/uploadImageOrFileButton.dart';
import 'package:eschool_saas_staff/utils/system/optimized_file_compression_mixin.dart';
import 'package:eschool_saas_staff/utils/system/optimized_file_compression_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';


class AddAnnouncementScreen extends StatefulWidget {
  const AddAnnouncementScreen({super.key});

  static Widget getRouteInstance() {
    //final arguments = Get.arguments as Map<String,dynamic>;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SendGeneralAnnouncementCubit(),
        ),
        BlocProvider(
          create: (context) => ClassesCubit(),
        ),
      ],
      child: const AddAnnouncementScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<AddAnnouncementScreen> createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends State<AddAnnouncementScreen>
    with TickerProviderStateMixin, OptimizedFileCompressionMixin {
  final _formKey = GlobalKey<FormState>();

  List<ClassSection> _selectedClassSections = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final List<PlatformFile> _pickedFiles = [];

  // Animation controllers for the UI elements
  late AnimationController _animationController; // For the AppBar
  late AnimationController _pulseController; // For pulsing effects
  static Color get _highlightColor => AppColorPalette.secondaryMaroon;

  @override
  void initState() {
    super.initState();
    context.read<ClassesCubit>().getClasses();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
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
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator ?? (v) => v!.isEmpty ? 'Required' : null,
      onChanged: onChanged,
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

  Widget _buildClassSectionDropdown() {
    return BlocBuilder<ClassesCubit, ClassesState>(
      builder: (context, state) {
        List<ClassSection> classes = [];
        if (state is ClassesFetchSuccess) {
          classes = state.classes;
        }
        return FormField<List<ClassSection>>(
          validator: (value) => (_selectedClassSections.isEmpty)
              ? 'Pilih minimal satu kelas'
              : null,
          builder: (FormFieldState<List<ClassSection>> field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _showClassSelectionDialog(context, classes),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            field.hasError ? Colors.red : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.school_rounded,
                            color: AppColorPalette.primaryMaroon),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedClassSections.isEmpty
                                ? 'Pilih Kelas'
                                : '${_selectedClassSections.length} Kelas dipilih',
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedClassSections.isEmpty
                                  ? Colors.grey[600]
                                  : Colors.grey[800],
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 8),
                    child: Text(
                      field.errorText!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showClassSelectionDialog(
      BuildContext context, List<ClassSection> classes) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header dengan gradient
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColorPalette.primaryMaroon, AppColorPalette.secondaryMaroon],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.school_rounded, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Pilih Kelas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Pilih Semua button dengan animasi hover
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            if (_selectedClassSections.length !=
                                classes.length) {
                              _selectedClassSections = List.from(classes);
                            } else {
                              _selectedClassSections.clear();
                            }
                          });
                          this.setState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                _selectedClassSections.length == classes.length
                                    ? Icons.check_circle
                                    : Icons.select_all,
                                color: AppColorPalette.primaryMaroon,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Pilih Semua',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: AppColorPalette.primaryMaroon,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColorPalette.primaryMaroon
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${classes.length} Kelas',
                                  style: TextStyle(
                                    color: AppColorPalette.primaryMaroon,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
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
                const Divider(height: 1),
                // List kelas dengan animasi
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: classes.length,
                    itemBuilder: (context, index) {
                      final classSection = classes[index];
                      final isSelected =
                          _selectedClassSections.contains(classSection);
                      return TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 200),
                        tween: Tween(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, (1 - value) * 20),
                            child: Opacity(
                              opacity: value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                child: Material(
                                  color: isSelected
                                      ? const Color(0xFFFBE9E7)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedClassSections
                                              .remove(classSection);
                                        } else {
                                          _selectedClassSections
                                              .add(classSection);
                                        }
                                      });
                                      this.setState(() {});
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppColorPalette.primaryMaroon
                                                    : Colors.grey.shade400,
                                                width: 2,
                                              ),
                                              color: isSelected
                                                  ? AppColorPalette.primaryMaroon
                                                  : Colors.transparent,
                                            ),
                                            padding: const EdgeInsets.all(2),
                                            child: const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              classSection.fullName ?? '-',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                                color: isSelected
                                                    ? AppColorPalette.primaryMaroon
                                                    : Colors.black87,
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
                          );
                        },
                      );
                    },
                  ),
                ),
                // Footer dengan efek elevated
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColorPalette.primaryMaroon
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 18,
                                  color: AppColorPalette.primaryMaroon,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_selectedClassSections.length} dari ${classes.length} kelas dipilih',
                                  style: TextStyle(
                                    color: AppColorPalette.primaryMaroon,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Batal',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColorPalette.primaryMaroon,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Selesai',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
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
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      debugPrint(
          '🎯 [ANNOUNCEMENT SCREEN] Memulai upload file dengan kompresi otomatis');

      // Gunakan mixin untuk pick dan kompres otomatis dengan loading dialog
      final compressedFiles = await pickAndCompressFiles(
        allowMultiple: true,
        fileType: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        maxSizeInMB: 0.5, // Target 500KB
        forceCompress: true,
        context: context,
      );

      if (compressedFiles != null && compressedFiles.isNotEmpty) {
        // Convert File to PlatformFile for compatibility
        for (final file in compressedFiles) {
          final fileSize = await file.length();
          final fileName = file.path.split('/').last;

          debugPrint(
              '✅ [ANNOUNCEMENT SCREEN] File berhasil diproses: $fileName');
          debugPrint(
              '   📊 Ukuran final: ${OptimizedFileCompressionUtils.formatFileSize(fileSize)}');

          final platformFile = PlatformFile(
            name: fileName,
            size: fileSize,
            path: file.path,
          );

          _pickedFiles.add(platformFile);
        }
        if (!mounted) return;
        setState(() {});
      } else {
        debugPrint(
            '❌ [ANNOUNCEMENT SCREEN] Tidak ada file yang dipilih atau diproses');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFileUploadSection() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Container(
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Lampiran',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 20),
          UploadImageOrFileButton(
            uploadFile: true,
            includeImageFileOnlyAllowedNote: true,
            onTap: _pickFiles,
          ),
          const SizedBox(height: 15),
          ..._pickedFiles.map(
            (file) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListTile(
                  leading: Icon(
                    file.extension == 'pdf'
                        ? Icons.picture_as_pdf
                        : file.extension == 'doc' || file.extension == 'docx'
                            ? Icons.description
                            : Icons.image,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    file.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _pickedFiles.remove(file);
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
        ]),
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
            'Informasi Pengumuman',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 20),
          _buildClassSectionDropdown(),
          const SizedBox(height: 15),
          _buildAnimatedTextField(
            controller: _titleController,
            label: 'Judul Pengumuman',
            icon: Icons.title,
          ),
          const SizedBox(height: 15),
          _buildAnimatedTextField(
            controller: _descController,
            label: 'Deskripsi',
            icon: Icons.description,
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: BlocConsumer<SendGeneralAnnouncementCubit,
          SendGeneralAnnouncementState>(
        listener: (context, state) {
          if (state is SendGeneralAnnouncementSuccess) {
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
                        'Pengumuman dikirim!',
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
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
            );

            // Clear the form
            _titleController.clear();
            _descController.clear();
            _selectedClassSections.clear();
            _pickedFiles.clear();
          } else if (state is SendGeneralAnnouncementFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Gagal mengirim pengumuman: ${state.errorMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return FadeInUp(
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
                  onTap: state is SendGeneralAnnouncementInProgress
                      ? null
                      : _submitForm,
                  borderRadius: BorderRadius.circular(15),
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (state is SendGeneralAnnouncementInProgress)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        else ...[
                          const Text(
                            'Kirim Pengumuman',
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedClassSections.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih kelas terlebih dahulu')),
        );
        return;
      }
      try {
        context.read<SendGeneralAnnouncementCubit>().sendGeneralAnnouncement(
              title: _titleController.text,
              description: _descController.text,
              classSectionIds:
                  _selectedClassSections.map((e) => e.id ?? 0).toList(),
              filePaths: _pickedFiles
                  .map((file) => file.path ?? '')
                  .where((path) => path.isNotEmpty)
                  .toList(),
            );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim pengumuman: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomModernAppBar(
        title: 'Tambah Pengumuman',
        icon: Icons.campaign,
        fabAnimationController: _animationController,
        primaryColor: AppColorPalette.primaryMaroon,
        lightColor: _highlightColor,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
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
                _buildFileUploadSection(),
                const SizedBox(height: 30),
                _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
