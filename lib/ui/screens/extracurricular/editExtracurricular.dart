import 'package:flutter/material.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/cubits/extracurricular/extracurricularCubit.dart';
import 'package:eschool_saas_staff/data/models/extracurricular/extracurricular.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';

class EditExtracurricular extends StatefulWidget {
  final Extracurricular extracurricular;

  const EditExtracurricular({super.key, required this.extracurricular});

  @override
  State<EditExtracurricular> createState() => _EditExtracurricularState();
}

class _EditExtracurricularState extends State<EditExtracurricular>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _coachController;

  int? selectedCoachId;
  late AnimationController _animationController;
  late AnimationController _pulseController;

  static Color get _primaryColor => AppColorPalette.primaryMaroon;
  static Color get _highlightColor => AppColorPalette.secondaryMaroon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.extracurricular.name);
    _descriptionController =
        TextEditingController(text: widget.extracurricular.description);
    _coachController =
        TextEditingController(text: widget.extracurricular.coachId.toString());
    selectedCoachId = widget.extracurricular.coachId;

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
    _nameController.dispose();
    _descriptionController.dispose();
    _coachController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomModernAppBar(
        title: 'Edit Ekstrakurikuler',
        icon: Icons.edit,
        fabAnimationController: _animationController,
        primaryColor: _primaryColor,
        lightColor: _highlightColor,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildBasicInfoSection(),
                const SizedBox(height: 20),
                _buildCoachSection(),
                const SizedBox(height: 30),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
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
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildAnimatedTextField(
              controller: _nameController,
              label: 'Nama Ekstrakurikuler',
              icon: Icons.sports_soccer,
              validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _buildAnimatedTextField(
              controller: _descriptionController,
              label: 'Deskripsi',
              icon: Icons.description,
              maxLines: 4,
              minLines: 3,
              validator: (v) => v!.isEmpty ? 'Deskripsi wajib diisi' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachSection() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pelatih/Pembina',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildAnimatedTextField(
              controller: _coachController,
              label: 'ID Pelatih',
              icon: Icons.person,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v!.isEmpty) return 'ID Pelatih wajib diisi';
                if (int.tryParse(v) == null) return 'ID harus berupa angka';
                return null;
              },
              onChanged: (value) {
                if (value.isNotEmpty && int.tryParse(value) != null) {
                  setState(() {
                    selectedCoachId = int.parse(value);
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Pelatih saat ini: ${widget.extracurricular.coachName}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLines = 1,
    int? minLines,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: _primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryColor, _highlightColor],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _submitForm,
            borderRadius: BorderRadius.circular(15),
            child: const Center(
              child: Text(
                'Simpan Perubahan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (selectedCoachId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID Pelatih tidak valid'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

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
                      'Menyimpan perubahan...',
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

      try {
        await context.read<ExtracurricularCubit>().updateExtracurricular(
              id: widget.extracurricular.id,
              name: _nameController.text,
              description: _descriptionController.text,
              coachId: selectedCoachId!,
            );

        if (!mounted) return;

        Navigator.pop(context); // Close loading dialog

        Get.dialog(
          Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Berhasil!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Perubahan berhasil disimpan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Get.back(); // Close dialog
                      Get.back(result: true); // Return to list
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
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
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan perubahan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
