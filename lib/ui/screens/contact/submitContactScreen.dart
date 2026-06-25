import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/contact/submitContactCubit.dart';
import 'package:eschool_saas_staff/cubits/authentication/authCubit.dart';
import 'package:eschool_saas_staff/models/contact.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SubmitContactScreen extends StatefulWidget {
  const SubmitContactScreen({super.key});

  @override
  State<SubmitContactScreen> createState() => _SubmitContactScreenState();
}

class _SubmitContactScreenState extends State<SubmitContactScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _subjectController;
  late TextEditingController _messageController;

  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'inquiry';

  Color get _primaryColor => AppColorPalette.primaryMaroon;
  Color get _lightColor => AppColorPalette.secondaryMaroon;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _subjectController = TextEditingController();
    _messageController = TextEditingController();

    // Pre-fill user data if authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated) {
        final userDetails = context.read<AuthCubit>().getUserDetails();
        _nameController.text =
            '${userDetails.firstName ?? ''} ${userDetails.lastName ?? ''}'
                .trim();
        _emailController.text = userDetails.email ?? '';
      }
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          CustomModernAppBar(
            title: 'Kirim Kontak',
            icon: Icons.send_rounded,
            fabAnimationController: _fabAnimationController,
            primaryColor: _primaryColor,
            lightColor: _lightColor,
            onBackPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: BlocListener<SubmitContactCubit, SubmitContactState>(
              listener: (context, state) {
                if (state is SubmitContactSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kontak berhasil dikirim!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context, true);
                } else if (state is SubmitContactFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormCard(),
                      const SizedBox(height: 24),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.contact_support_rounded,
                  color: _primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Form Kontak',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Sampaikan pertanyaan atau laporan Anda',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Type Selection
          Text(
            'Tipe Kontak',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTypeOption('inquiry', 'Pertanyaan',
                    Icons.help_outline_rounded, Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeOption('report', 'Laporan',
                    Icons.report_problem_outlined, Colors.red),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Name Field
          _buildTextField(
            controller: _nameController,
            label: 'Nama Lengkap',
            icon: Icons.person_rounded,
            validator: (value) => SubmitContactRequest(
              name: value ?? '',
              email: '',
              subject: '',
              message: '',
              type: 'inquiry',
            ).validateName(),
          ),

          const SizedBox(height: 16),

          // Email Field
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => SubmitContactRequest(
              name: '',
              email: value ?? '',
              subject: '',
              message: '',
              type: 'inquiry',
            ).validateEmail(),
          ),

          const SizedBox(height: 16),

          // Subject Field
          _buildTextField(
            controller: _subjectController,
            label: 'Subjek',
            icon: Icons.subject_rounded,
            validator: (value) => SubmitContactRequest(
              name: '',
              email: '',
              subject: value ?? '',
              message: '',
              type: 'inquiry',
            ).validateSubject(),
          ),

          const SizedBox(height: 16),

          // Message Field
          _buildTextField(
            controller: _messageController,
            label: 'Pesan',
            icon: Icons.message_rounded,
            maxLines: 5,
            validator: (value) => SubmitContactRequest(
              name: '',
              email: '',
              subject: '',
              message: value ?? '',
              type: 'inquiry',
            ).validateMessage(),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: 0.3, end: 0);
  }

  Widget _buildTypeOption(
      String type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[500],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _primaryColor, size: 20),
            hintText: 'Masukkan $label',
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<SubmitContactCubit, SubmitContactState>(
      builder: (context, state) {
        final isLoading = state is SubmitContactLoading;

        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [_primaryColor, _lightColor],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isLoading ? null : _submitContact,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    const SizedBox(width: 12),
                    Text(
                      isLoading ? 'Mengirim...' : 'Kirim Kontak',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    )
        .animate(delay: 200.ms)
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: 0.3, end: 0);
  }

  void _submitContact() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Get user ID if authenticated
    int? userId;
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      userId = context.read<AuthCubit>().getUserDetails().id;
    }

    final request = SubmitContactRequest(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      subject: _subjectController.text.trim(),
      message: _messageController.text.trim(),
      type: _selectedType,
      userId: userId,
    );

    context.read<SubmitContactCubit>().submitContact(request);
  }
}
