import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/announcement/sendNotificationCubit.dart';
import 'package:eschool_saas_staff/cubits/settings/rolesCubit.dart';
import 'package:eschool_saas_staff/data/models/auth/userDetails.dart';
import 'package:eschool_saas_staff/ui/screens/manageNotification/manageNotificationScreen.dart';
import 'package:eschool_saas_staff/ui/screens/system/searchUsersScreen.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';

import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/system/multiSelectionValueBottomsheet.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:eschool_saas_staff/utils/system/optimized_file_compression_mixin.dart';
import 'package:eschool_saas_staff/utils/system/optimized_file_compression_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
// Import pustaka animasi dan komponen visual
import 'package:animate_do/animate_do.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddNotificationScreen extends StatefulWidget {
  const AddNotificationScreen({super.key});

  static Widget getRouteInstance() {
    //final arguments = Get.arguments as Map<String,dynamic>;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => RolesCubit(),
        ),
        BlocProvider(
          create: (context) => SendNotificationCubit(),
        ),
      ],
      child: const AddNotificationScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<AddNotificationScreen> createState() => _AddNotificationScreenState();
}

class _AddNotificationScreenState extends State<AddNotificationScreen>
    with TickerProviderStateMixin, OptimizedFileCompressionMixin {
  String _sendToUserValue = "";

  final TextEditingController _titleTextEditingController =
      TextEditingController();

  final TextEditingController _messageTextEditingController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomModernAppBar(
        title: 'Tambah Notifikasi',
        icon: Icons.notifications_active,
        fabAnimationController: _animationController,
        primaryColor: _primaryColor,
        lightColor: _accentColor,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(appContentHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildBasicInfoSection(),
                  const SizedBox(height: 20),
                  _buildRecipientDetailsSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildAnimatedSubmitButton(),
        ],
      ),
    );
  }

  List<String> _selectedRoles = [];

  List<UserDetails> _selectedUsers = [];

  PlatformFile? _pickedFile;

  // Tambahkan controller animasi - sesuai dengan createOnlineExam
  late AnimationController _animationController;
  late AnimationController _pulseController;

  // Tema warna - Palette maroon yang lebih lembut - sesuai dengan createOnlineExam
  static Color get _primaryColor =>
      AppColorPalette.primaryMaroon; // Maroon dalam yang lebih lembut
  static Color get _accentColor =>
      AppColorPalette.secondaryMaroon; // Maroon medium yang lebih lembut

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted) {
        debugPrint('🔄 [NOTIFICATION INIT] Fetching roles...');
        context.read<RolesCubit>().getRoles();
      }
    });

    // Inisialisasi controller animasi - sesuai dengan createOnlineExam
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
    _titleTextEditingController.dispose();
    _messageTextEditingController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    debugPrint(
        '🎯 [NOTIFICATION SCREEN] Memulai upload file dengan kompresi otomatis');

    // Gunakan mixin untuk pick dan kompres otomatis dengan loading dialog
    final compressedFiles = await pickAndCompressFiles(
      allowMultiple: false,
      fileType: FileType.image,
      maxSizeInMB: 0.5, // Target 500KB
      forceCompress: true,
      context: context,
    );

    if (compressedFiles != null && compressedFiles.isNotEmpty) {
      final file = compressedFiles.first;
      final fileSize = await file.length();
      final fileName = file.path.split('/').last;

      debugPrint('✅ [NOTIFICATION SCREEN] File berhasil diproses: $fileName');
      debugPrint(
          '   📊 Ukuran final: ${OptimizedFileCompressionUtils.formatFileSize(fileSize)}');

      // Convert File to PlatformFile for compatibility
      _pickedFile = PlatformFile(
        name: fileName,
        size: fileSize,
        path: file.path,
      );
      setState(() {});
    } else {
      debugPrint(
          '❌ [NOTIFICATION SCREEN] Tidak ada file yang dipilih atau diproses');
    }
  }

  void onTapSubmitButton() {
    debugPrint('🔍 [NOTIFICATION SUBMIT] Starting submit validation...');
    debugPrint('   📝 Title: "${_titleTextEditingController.text.trim()}"');
    debugPrint('   💬 Message: "${_messageTextEditingController.text.trim()}"');
    debugPrint('   👥 Send To: "$_sendToUserValue"');
    debugPrint('   🎭 Selected Roles: $_selectedRoles');
    debugPrint(
        '   👤 Selected Users: ${_selectedUsers.map((u) => u.fullName).toList()}');
    debugPrint('   📎 File: ${_pickedFile?.name ?? "No file"}');

    if (_titleTextEditingController.text.trim().isEmpty) {
      debugPrint('❌ [NOTIFICATION SUBMIT] Validation failed: Title is empty');
      Utils.showSnackBar(message: pleaseEnterTitleKey, context: context);
      return;
    }
    if (_messageTextEditingController.text.trim().isEmpty) {
      debugPrint('❌ [NOTIFICATION SUBMIT] Validation failed: Message is empty');
      Utils.showSnackBar(message: pleaseEnterMessageKey, context: context);
      return;
    }
    if (_sendToUserValue.isEmpty) {
      debugPrint(
          '❌ [NOTIFICATION SUBMIT] Validation failed: Send to value is empty');
      Utils.showSnackBar(message: pleaseSelectSendToKey, context: context);
      return;
    }

    if (_sendToUserValue == specificRolesKey && _selectedRoles.isEmpty) {
      debugPrint(
          '❌ [NOTIFICATION SUBMIT] Validation failed: Specific roles selected but no roles chosen');
      Utils.showSnackBar(message: pleaseSelectSendToKey, context: context);
      return;
    }

    if (_sendToUserValue == specificUsersKey && _selectedUsers.isEmpty) {
      debugPrint(
          '❌ [NOTIFICATION SUBMIT] Validation failed: Specific users selected but no users chosen');
      Utils.showSnackBar(message: pleaseSelectUserKey, context: context);
      return;
    }

    debugPrint(
        '✅ [NOTIFICATION SUBMIT] All validations passed, sending notification...');
    context.read<SendNotificationCubit>().sendNotification(
        title: _titleTextEditingController.text.trim(),
        userIds: _selectedUsers.map((e) => e.id ?? 0).toList(),
        filePath: _pickedFile?.path,
        message: _messageTextEditingController.text.trim(),
        roles: _selectedRoles,
        sendToType: _sendToUserValue);
  }

  // Metode untuk membuat TextField beranimasi yang identical dengan createOnlineExam.dart
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

  // Menambahkan section untuk Informasi Dasar - identik dengan createOnlineExam
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
            'Informasi Notifikasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 20),
          _buildAnimatedTextField(
            controller: _titleTextEditingController,
            label: 'Judul Notifikasi',
            icon: Icons.title,
          ),
          const SizedBox(height: 15),
          _buildAnimatedTextField(
            controller: _messageTextEditingController,
            label: 'Pesan Notifikasi',
            icon: Icons.message,
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  // Menambahkan section untuk Detail Penerima - identik dengan format createOnlineExam
  Widget _buildRecipientDetailsSection() {
    return BlocBuilder<RolesCubit, RolesState>(
      builder: (context, state) {
        if (state is RolesFetchSuccess) {
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
                  'Detail Penerima',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 15),
                // Dropdown untuk memilih tipe penerima
                _buildSendToDropdown(),
                const SizedBox(height: 20),

                // Render UI berdasarkan pilihan tipe penerima
                _sendToUserValue == specificRolesKey
                    ? _buildRoleSelectionUI(state)
                    : _sendToUserValue == specificUsersKey
                        ? _buildUserSelectionUI()
                        : const SizedBox(),

                const SizedBox(height: 20),
                // Upload file section
                _buildFileUploadSection(),
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildSendToDropdown() {
    return GestureDetector(
      onTap: () {
        Utils.showBottomSheet(
          child: FilterSelectionBottomsheet<String>(
            onSelection: (value) {
              if (_sendToUserValue != value) {
                _sendToUserValue = value!;
                _selectedRoles.clear();
                setState(() {});
                Get.back();
              }
            },
            selectedValue: _sendToUserValue,
            titleKey: "Penerima",
            values: const [
              allUsersKey,
              overDueFeesKey,
              specificRolesKey,
              specificUsersKey
            ],
          ),
          context: context,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              Icons.people,
              color: AppColorPalette.primaryMaroon,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _sendToUserValue.isEmpty ? "Pilih Penerima" : _sendToUserValue,
                style: TextStyle(
                  fontSize: 14,
                  color: _sendToUserValue.isEmpty
                      ? Colors.grey[600]
                      : Colors.grey[800],
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelectionUI(RolesFetchSuccess state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            List<String> roles = [
              "Teacher",
              "Student",
              "Parent",
            ];
            roles.addAll(state.roles.map((role) => role.name ?? "-").toList());
            Utils.showBottomSheet(
              child: MultiSelectionValueBottomsheet<String>(
                values: roles,
                selectedValues: _selectedRoles,
                titleKey: roleKey,
              ),
              context: context,
            ).then((value) {
              if (value != null) {
                final updatedSelectedRoles = List<String>.from(value as List);
                _selectedRoles = updatedSelectedRoles;
                setState(() {});
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.assignment_ind,
                  color: AppColorPalette.primaryMaroon,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Pilih Peran",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        _selectedRoles.isNotEmpty
            ? Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedRoles.map((role) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            role,
                            style: TextStyle(
                              fontSize: 12,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(width: 5),
                          InkWell(
                            onTap: () {
                              _selectedRoles.remove(role);
                              setState(() {});
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: _primaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              )
            : const SizedBox(),
      ],
    );
  }

  Widget _buildUserSelectionUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            Get.toNamed(
              Routes.searchUsersScreen,
              arguments: SearchUsersScreen.buildArguments(
                selectedUsers: _selectedUsers,
              ),
            )?.then((value) {
              if (value != null) {
                _selectedUsers = value as List<UserDetails>;
                setState(() {});
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_add,
                  color: AppColorPalette.primaryMaroon,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectUsersKey,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        _selectedUsers.isNotEmpty
            ? Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedUsers.map((user) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.fullName ?? "-",
                            style: TextStyle(
                              fontSize: 12,
                              color: _accentColor,
                            ),
                          ),
                          const SizedBox(width: 5),
                          InkWell(
                            onTap: () {
                              _selectedUsers.removeWhere(
                                (element) => element.id == user.id,
                              );
                              setState(() {});
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: _accentColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              )
            : const SizedBox(),
      ],
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Lampiran",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickFiles,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.file_upload_outlined,
                  color: _primaryColor,
                ),
                const SizedBox(width: 10),
                Text(
                  "Upload Gambar",
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _pickedFile != null
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.image_outlined,
                      color: _accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _pickedFile?.name ?? "-",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey[700],
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _pickedFile = null;
                        });
                      },
                    ),
                  ],
                ),
              )
            : const SizedBox(),
      ],
    );
  }

  Widget _buildAnimatedSubmitButton() {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -2),
            blurRadius: 6,
          )
        ],
      ),
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
            child: BlocConsumer<SendNotificationCubit, SendNotificationState>(
              listener: (context, sendNotificationState) {
                debugPrint(
                    '📡 [NOTIFICATION STATE] State changed: ${sendNotificationState.runtimeType}');
                if (sendNotificationState is SendNotificationFailure) {
                  debugPrint(
                      '❌ [NOTIFICATION ERROR] SendNotificationFailure: ${sendNotificationState.errorMessage}');
                  Utils.showSnackBar(
                    message: sendNotificationState.errorMessage,
                    context: context,
                  );
                } else if (sendNotificationState is SendNotificationSuccess) {
                  ManageNotificationScreen.screenKey.currentState
                      ?.getNotifications();
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
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Notifikasi berhasil dikirim',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Get.back(); // Close dialog
                                Get.offAllNamed(Routes
                                    .manageNotificationScreen); // Navigate to notification list
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Lihat Daftar Notifikasi',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    barrierDismissible: false,
                  );

                  _titleTextEditingController.clear();
                  _messageTextEditingController.clear();
                  _sendToUserValue = "";
                  _selectedRoles.clear();
                  _selectedUsers.clear();
                  _pickedFile = null;
                  setState(() {});
                }
              },
              builder: (context, sendNotificationState) {
                return PopScope(
                  canPop: sendNotificationState is! SendNotificationInProgress,
                  child: InkWell(
                    onTap: () {
                      debugPrint(
                          '🔘 [NOTIFICATION BUTTON] Submit button tapped, current state: ${sendNotificationState.runtimeType}');
                      if (sendNotificationState is SendNotificationInProgress) {
                        debugPrint(
                            '⏳ [NOTIFICATION BUTTON] Ignoring tap - already in progress');
                        return;
                      }
                      debugPrint(
                          '🚀 [NOTIFICATION BUTTON] Calling onTapSubmitButton');
                      onTapSubmitButton();
                    },
                    borderRadius: BorderRadius.circular(15),
                    splashColor: Colors.white.withValues(alpha: 0.2),
                    highlightColor: Colors.white.withValues(alpha: 0.1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child:
                            sendNotificationState is SendNotificationInProgress
                                ? const CustomCircularProgressIndicator(
                                    indicatorColor: Colors.white,
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Kirim Notifikasi',
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
                                        duration:
                                            const Duration(milliseconds: 1000),
                                        curve: Curves.easeInOut,
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
        ),
      ),
    );
  }
}
