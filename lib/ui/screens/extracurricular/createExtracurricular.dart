import 'package:flutter/material.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/cubits/extracurricular/extracurricularCubit.dart';
import 'package:eschool_saas_staff/data/models/auth/user.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';

class CreateExtracurricular extends StatefulWidget {
  const CreateExtracurricular({super.key});

  @override
  State<CreateExtracurricular> createState() => _CreateExtracurricularState();
}

class _CreateExtracurricularState extends State<CreateExtracurricular>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  int? selectedCoachId;
  String? selectedCoachName;
  List<User> allUsers = [];
  List<User> filteredUsers = [];
  late AnimationController _animationController;
  late AnimationController _pulseController;

  static Color get _primaryColor => AppColorPalette.primaryMaroon;
  static Color get _highlightColor => AppColorPalette.secondaryMaroon;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Fetch teachers/staff list
    context.read<ExtracurricularCubit>().getTeachersStaffList();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomModernAppBar(
        title: 'Buat Ekstrakurikuler',
        icon: Icons.sports_soccer,
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
              'Pembina',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            BlocConsumer<ExtracurricularCubit, ExtracurricularState>(
              listener: (context, state) {
                if (state is TeachersStaffSuccess) {
                  setState(() {
                    allUsers = state.users;
                    filteredUsers = state.users;
                  });
                }
              },
              builder: (context, state) {
                if (state is TeachersStaffLoading) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: _primaryColor),
                    ),
                  );
                }

                if (state is TeachersStaffFailure) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Gagal memuat daftar guru/staff',
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context
                                .read<ExtracurricularCubit>()
                                .getTeachersStaffList();
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Selected coach display
                    if (selectedCoachId != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _primaryColor, width: 2),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: _primaryColor,
                              child: const Icon(Icons.person,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pelatih Terpilih',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    selectedCoachName ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  selectedCoachId = null;
                                  selectedCoachName = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                    // Modern Dropdown button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showCoachSelectionDialog(),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: selectedCoachId == null
                                ? LinearGradient(
                                    colors: [
                                      Colors.grey.shade50,
                                      Colors.grey.shade100,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      _primaryColor.withValues(alpha: 0.05),
                                      _primaryColor.withValues(alpha: 0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selectedCoachId == null
                                  ? Colors.grey.shade300
                                  : _primaryColor.withValues(alpha: 0.5),
                              width: selectedCoachId == null ? 1.5 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: selectedCoachId == null
                                    ? Colors.grey.withValues(alpha: 0.1)
                                    : _primaryColor.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Icon with modern styling
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: selectedCoachId == null
                                      ? Colors.grey.shade200
                                      : _primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  selectedCoachId == null
                                      ? Icons.person_search_rounded
                                      : Icons.person_pin_circle_rounded,
                                  color: selectedCoachId == null
                                      ? Colors.grey.shade600
                                      : _primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Text content with better hierarchy
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedCoachId == null
                                          ? 'Pilih Pelatih/Pembina'
                                          : selectedCoachName ??
                                              'Pelatih Terpilih',
                                      style: TextStyle(
                                        color: selectedCoachId == null
                                            ? Colors.grey.shade700
                                            : _primaryColor,
                                        fontSize: 16,
                                        fontWeight: selectedCoachId == null
                                            ? FontWeight.w500
                                            : FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedCoachId == null
                                          ? 'Ketuk untuk memilih guru atau staff'
                                          : 'Ketuk untuk mengganti pilihan',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Arrow with modern styling
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: selectedCoachId == null
                                      ? Colors.grey.shade100
                                      : _primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: selectedCoachId == null
                                      ? Colors.grey.shade600
                                      : _primaryColor,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Enhanced helper text with better styling
            if (selectedCoachId == null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade100,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.blue.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pilih guru atau staff yang akan menjadi pelatih/pembina ekstrakurikuler ini',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
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

  void _showCoachSelectionDialog() {
    _searchController.clear();
    setState(() {
      filteredUsers = allUsers;
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 16,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.98,
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Modern Header with gradient background
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryColor.withValues(alpha: 0.1),
                        _primaryColor.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Modern icon container
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.person_search_rounded,
                          color: _primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pilih Pembina',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pilih guru atau staff sebagai pembina',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Modern close button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content area with padding
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 20),
                    child: Column(
                      children: [
                        // Modern Search field
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setDialogState(() {
                                if (value.isEmpty) {
                                  filteredUsers = allUsers;
                                } else {
                                  filteredUsers = allUsers.where((user) {
                                    final name =
                                        user.fullName?.toLowerCase() ?? '';
                                    final search = value.toLowerCase();
                                    return name.contains(search);
                                  }).toList();
                                }
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Cari guru atau staff...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.search_rounded,
                                  color: _primaryColor,
                                  size: 20,
                                ),
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          setDialogState(() {
                                            _searchController.clear();
                                            filteredUsers = allUsers;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          margin: const EdgeInsets.all(12),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.clear_rounded,
                                            color: Colors.grey.shade600,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: _primaryColor.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // User count with modern styling
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _primaryColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _primaryColor.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_rounded,
                                color: _primaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${filteredUsers.length} pembina',
                                style: TextStyle(
                                  color: _primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // User list
                        Expanded(
                          child: filteredUsers.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_off,
                                          size: 64,
                                          color: Colors.grey.shade400),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Tidak ada guru/staff ditemukan',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filteredUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = filteredUsers[index];
                                    final isSelected =
                                        selectedCoachId == user.id;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? _primaryColor.withValues(
                                                alpha: 0.1)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? _primaryColor
                                              : Colors.grey.shade200,
                                          width: isSelected ? 2 : 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isSelected
                                                ? _primaryColor.withValues(
                                                    alpha: 0.1)
                                                : Colors.grey
                                                    .withValues(alpha: 0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              selectedCoachId = user.id;
                                              selectedCoachName = user.fullName;
                                            });
                                            Navigator.pop(context);
                                          },
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 16),
                                            child: Row(
                                              children: [
                                                // Avatar with modern styling
                                                Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? _primaryColor
                                                          : Colors
                                                              .grey.shade300,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: CircleAvatar(
                                                    radius: 32,
                                                    backgroundColor: isSelected
                                                        ? _primaryColor
                                                        : Colors.grey.shade200,
                                                    backgroundImage:
                                                        user.image != null &&
                                                                user.image!
                                                                    .isNotEmpty
                                                            ? NetworkImage(
                                                                user.image!)
                                                            : null,
                                                    child: user.image == null ||
                                                            user.image!.isEmpty
                                                        ? Icon(
                                                            Icons
                                                                .person_rounded,
                                                            color: isSelected
                                                                ? Colors.white
                                                                : Colors.grey
                                                                    .shade600,
                                                            size: 28,
                                                          )
                                                        : null,
                                                  ),
                                                ),
                                                const SizedBox(width: 20),

                                                // User info
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        user.fullName ??
                                                            'No Name',
                                                        style: TextStyle(
                                                          fontWeight: isSelected
                                                              ? FontWeight.bold
                                                              : FontWeight.w600,
                                                          color: isSelected
                                                              ? _primaryColor
                                                              : Colors.grey
                                                                  .shade800,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isSelected
                                                              ? _primaryColor
                                                                  .withValues(
                                                                      alpha:
                                                                          0.1)
                                                              : Colors.grey
                                                                  .shade100,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Text(
                                                          user.role ??
                                                              'No Role',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: isSelected
                                                                ? _primaryColor
                                                                : Colors.grey
                                                                    .shade600,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Selection indicator
                                                if (isSelected)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration:
                                                        BoxDecoration(
                                                      color: _primaryColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.check_rounded,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                'Simpan Ekstrakurikuler',
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
                      'Membuat Ekstrakurikuler...',
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
        await context.read<ExtracurricularCubit>().createExtracurricular(
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
                    'Ekstrakurikuler ditambahkan',
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
            content: Text('Gagal menambahkan ekstrakurikuler: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
