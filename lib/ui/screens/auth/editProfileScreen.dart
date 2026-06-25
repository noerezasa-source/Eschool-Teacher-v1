import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/authentication/authCubit.dart';
import 'package:eschool_saas_staff/cubits/authentication/editProfileCubit.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static Widget getRouteInstance() {
    return BlocProvider(
      create: (context) => EditProfileCubit(),
      child: const EditProfileScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  TextEditingController firstName = TextEditingController();
  TextEditingController lastName = TextEditingController();
  TextEditingController mobileNumber = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController dateOfBirth = TextEditingController();
  TextEditingController currentAddress = TextEditingController();
  TextEditingController permanentAddress = TextEditingController();
  late DateTime _dateOfBirth = DateTime.now();
  String selectedGender = '';
  String profileImage = '';
  String? uploadedPicture;

  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Soft maroon color scheme
  Color get primaryMaroon => AppColorPalette.primaryMaroon;
  final Color lightMaroon = const Color(0xFFBF6680);
  final Color accentMaroon = const Color(0xFF5D1429);
  final Color backgroundMaroon = const Color(0xFFFDF6F8);

  @override
  void initState() {
    // Initialize animation controllers
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuint),
    );

    // Start animations
    _animationController.forward();
    _fabAnimationController.repeat();

    firstName = TextEditingController(
        text: context.read<AuthCubit>().getUserDetails().firstName ?? "");
    lastName = TextEditingController(
        text: context.read<AuthCubit>().getUserDetails().lastName ?? "");
    mobileNumber = TextEditingController(
        text: context.read<AuthCubit>().getUserDetails().mobile ?? "");
    email = TextEditingController(
        text: context.read<AuthCubit>().getUserDetails().email ?? "");

    final initialDate = context.read<AuthCubit>().getUserDetails().dob;
    if (initialDate != null && initialDate.isNotEmpty) {
      try {
        // Parse the initial date assuming it's in yyyy-MM-dd format
        final parsedDate = DateTime.parse(initialDate);
        dateOfBirth = TextEditingController(
            text: DateFormat("dd-MM-yyyy").format(parsedDate));
        _dateOfBirth = parsedDate;
      } catch (e) {
        dateOfBirth = TextEditingController(text: initialDate);
      }
    } else {
      dateOfBirth = TextEditingController();
    }

    currentAddress = TextEditingController(
        text: context.read<AuthCubit>().getUserDetails().currentAddress ?? "");
    permanentAddress = TextEditingController(
        text:
            context.read<AuthCubit>().getUserDetails().permanentAddress ?? "");
    selectedGender = context.read<AuthCubit>().getUserDetails().gender ?? "";
    profileImage = context.read<AuthCubit>().getUserDetails().image ?? "";
    super.initState();
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    mobileNumber.dispose();
    email.dispose();
    dateOfBirth.dispose();
    currentAddress.dispose();
    permanentAddress.dispose();
    _animationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _addFiles() async {
    HapticFeedback.mediumImpact();
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Pilih Sumber Gambar',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: primaryMaroon,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: primaryMaroon),
                title: Text(
                  'Galeri',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final result = await Utils.openFilePicker(
                      context: context,
                      allowMultiple: false,
                      type: FileType.image);
                  if (result != null) {
                    uploadedPicture = result.files.first.path;
                    setState(() {});
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: primaryMaroon),
                title: Text(
                  'Kamera',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final ImagePicker picker = ImagePicker();
                  final XFile? image =
                      await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    uploadedPicture = image.path;
                    setState(() {});
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(
                  color: primaryMaroon,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLabelWithTextEditingController(
      {required String labelTitle,
      required String textFieldHintTextKey,
      required TextEditingController textEditingController,
      IconData? prefixIcon}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Row(
              children: [
                Icon(
                  prefixIcon ?? Icons.person_outline,
                  size: 18,
                  color: primaryMaroon,
                ),
                const SizedBox(width: 8),
                Text(
                  labelTitle.tr,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: accentMaroon,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  offset: const Offset(0, 3),
                  blurRadius: 10,
                  spreadRadius: 0,
                )
              ],
            ),
            child: TextFormField(
              controller: textEditingController,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: textFieldHintTextKey.tr,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black26,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryMaroon, width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateOfBirthContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.cake_outlined,
                  size: 18,
                  color: primaryMaroon,
                ),
                const SizedBox(width: 8),
                Text(
                  dateOfBirthKey.tr,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: accentMaroon,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              final selectedDate = await showDatePicker(
                context: context,
                currentDate: _dateOfBirth,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: primaryMaroon,
                        onPrimary: Colors.white,
                        onSurface: Colors.black,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: primaryMaroon,
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (selectedDate != null) {
                _dateOfBirth = selectedDate;
                dateOfBirth.text =
                    DateFormat("dd-MM-yyyy").format(_dateOfBirth);
                setState(() {});
              }
            },
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    offset: const Offset(0, 3),
                    blurRadius: 10,
                    spreadRadius: 0,
                  )
                ],
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateOfBirth.text.isEmpty
                          ? dateOfBirthKey.tr
                          : dateOfBirth.text,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: dateOfBirth.text.isEmpty
                            ? Colors.black26
                            : Colors.black87,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today,
                      color: primaryMaroon,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 18,
                  color: primaryMaroon,
                ),
                const SizedBox(width: 8),
                Text(
                  genderKey.tr,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: accentMaroon,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildGenderOption("male", Icons.male),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGenderOption("female", Icons.female),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    bool isSelected = selectedGender == gender;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          selectedGender = gender;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? primaryMaroon.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryMaroon : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryMaroon.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 6,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryMaroon : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              gender.tr,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? primaryMaroon : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateProfileButton(EditProfileState state) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryMaroon, accentMaroon],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryMaroon.withValues(alpha: 0.3),
              offset: const Offset(0, 4),
              blurRadius: 15,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (state is EditProfileProgress) {
                return;
              }

              HapticFeedback.mediumImpact();

              if (firstName.text.trim().isEmpty ||
                  mobileNumber.text.trim().isEmpty ||
                  email.text.trim().isEmpty ||
                  dateOfBirth.text.trim().isEmpty) {
                Utils.showSnackBar(
                    message: pleaseAddNeededDetailsKey, context: context);
                return;
              }

              String formattedDate = "";
              try {
                final inputDate =
                    DateFormat("dd-MM-yyyy").parse(dateOfBirth.text.trim());
                formattedDate = DateFormat("yyyy-MM-dd").format(inputDate);
              } catch (e) {
                formattedDate = dateOfBirth.text.trim();
              }
              context.read<EditProfileCubit>().editProfile(
                  firstName: firstName.text.trim(),
                  lastName: lastName.text.trim(),
                  mobileNumber: mobileNumber.text.trim(),
                  email: email.text.trim(),
                  dateOfBirth: formattedDate,
                  currentAddress: currentAddress.text.trim(),
                  permanentAddress: permanentAddress.text.trim(),
                  gender: selectedGender,
                  image: uploadedPicture ?? "");
            },
            child: Center(
              child: state is EditProfileProgress
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          updateProfileKey.tr,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundMaroon,
      appBar: CustomModernAppBar(
        title: editProfileKey.tr,
        icon: Icons.person_outline,
        fabAnimationController: _fabAnimationController,
        primaryColor: primaryMaroon,
        lightColor: lightMaroon,
        onBackPressed: () {
          if (context.read<EditProfileCubit>().state is EditProfileProgress) {
            return;
          }
          Navigator.pop(context);
        },
      ),
      body: BlocConsumer<EditProfileCubit, EditProfileState>(
          listener: (context, state) {
        if (state is EditProfileSuccess) {
          context.read<AuthCubit>().updateuserDetail(state.userDetails);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      'Profil berhasil diperbarui!',
                      style: GoogleFonts.poppins(
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
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
          );
        } else if (state is EditProfileFailure) {
          Utils.showSnackBar(message: state.errorMessage, context: context);
        }
      }, builder: (context, state) {
        return PopScope(
          canPop: state is! EditProfileProgress,
          child: Stack(
            children: [
              // Background container dengan rounded corners
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFDF6F8),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
              ),
              // Main scrollable content
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                        top: 40, bottom: 40, left: 24, right: 24),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Image Section with Decorative Elements
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(bottom: 32.0),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Decorative Background Circle 1
                              Positioned(
                                left: 50,
                                top: 20,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        primaryMaroon.withValues(alpha: 0.1),
                                        lightMaroon.withValues(alpha: 0.05),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Decorative Background Circle 2
                              Positioned(
                                right: 60,
                                top: 10,
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topRight,
                                      end: Alignment.bottomLeft,
                                      colors: [
                                        accentMaroon.withValues(alpha: 0.08),
                                        primaryMaroon.withValues(alpha: 0.03),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Decorative Icons
                              Positioned(
                                left: 40,
                                bottom: 30,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: lightMaroon.withValues(alpha: 0.1),
                                    border: Border.all(
                                      color: lightMaroon.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.school_outlined,
                                    color: primaryMaroon.withValues(alpha: 0.6),
                                    size: 24,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 45,
                                bottom: 40,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: accentMaroon.withValues(alpha: 0.1),
                                    border: Border.all(
                                      color: accentMaroon.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.star_outline,
                                    color: accentMaroon.withValues(alpha: 0.7),
                                    size: 20,
                                  ),
                                ),
                              ),
                              // Small decorative dots
                              Positioned(
                                left: 80,
                                top: 5,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primaryMaroon.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 30,
                                top: 60,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: lightMaroon.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 25,
                                top: 45,
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: accentMaroon.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              // Main Profile Image Container
                              Hero(
                                tag: "profileImage",
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white,
                                        Colors.white.withValues(alpha: 0.95),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryMaroon.withValues(alpha: 0.15),
                                        blurRadius: 20,
                                        spreadRadius: 8,
                                        offset: const Offset(0, 8),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: lightMaroon.withValues(alpha: 0.1),
                                      width: 2,
                                    ),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          primaryMaroon.withValues(alpha: 0.05),
                                          lightMaroon.withValues(alpha: 0.03),
                                        ],
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(62),
                                            child: uploadedPicture != null
                                                ? Image.file(
                                                    File(uploadedPicture!),
                                                    width: 124,
                                                    height: 124,
                                                    fit: BoxFit.cover,
                                                  )
                                                : profileImage.isNotEmpty
                                                    ? CachedNetworkImage(
                                                        imageUrl: profileImage,
                                                        width: 124,
                                                        height: 124,
                                                        fit: BoxFit.cover,
                                                        placeholder:
                                                            (context, url) =>
                                                                Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            gradient:
                                                                LinearGradient(
                                                              colors: [
                                                                lightMaroon
                                                                    .withValues(alpha: 
                                                                        0.3),
                                                                primaryMaroon
                                                                    .withValues(alpha: 
                                                                        0.2),
                                                              ],
                                                            ),
                                                          ),
                                                          child: const Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                              strokeWidth: 3,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                          Color>(
                                                                      Colors
                                                                          .white),
                                                            ),
                                                          ),
                                                        ),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            gradient:
                                                                LinearGradient(
                                                              colors: [
                                                                lightMaroon
                                                                    .withValues(alpha: 
                                                                        0.3),
                                                                primaryMaroon
                                                                    .withValues(alpha: 
                                                                        0.2),
                                                              ],
                                                            ),
                                                          ),
                                                          child: const Icon(
                                                            Icons.person,
                                                            size: 60,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      )
                                                    : Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          gradient:
                                                              LinearGradient(
                                                            colors: [
                                                              lightMaroon
                                                                  .withValues(alpha: 
                                                                      0.3),
                                                              primaryMaroon
                                                                  .withValues(alpha: 
                                                                      0.2),
                                                            ],
                                                          ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.person,
                                                          size: 60,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                          ),
                                          // Enhanced Camera Button
                                          Positioned(
                                            bottom: 5,
                                            right: 5,
                                            child: GestureDetector(
                                              onTap: _addFiles,
                                              child: Container(
                                                width: 45,
                                                height: 45,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      primaryMaroon,
                                                      accentMaroon
                                                    ],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: primaryMaroon
                                                          .withValues(alpha: 0.4),
                                                      blurRadius: 12,
                                                      spreadRadius: 3,
                                                      offset:
                                                          const Offset(0, 4),
                                                    ),
                                                  ],
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 3,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.camera_alt,
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Text(
                            "Informasi Pribadi",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: accentMaroon,
                            ),
                          ),
                        ),
                        _buildLabelWithTextEditingController(
                          labelTitle: firstNameKey,
                          textFieldHintTextKey: firstNameKey,
                          textEditingController: firstName,
                          prefixIcon: Icons.person_outline,
                        ),
                        _buildLabelWithTextEditingController(
                          labelTitle: lastNameKey,
                          textFieldHintTextKey: lastNameKey,
                          textEditingController: lastName,
                          prefixIcon: Icons.person_outline,
                        ),
                        _buildLabelWithTextEditingController(
                          labelTitle: emailKey,
                          textFieldHintTextKey: emailKey,
                          textEditingController: email,
                          prefixIcon: Icons.email_outlined,
                        ),
                        _buildLabelWithTextEditingController(
                          labelTitle: mobileNumberKey,
                          textFieldHintTextKey: mobileNumberKey,
                          textEditingController: mobileNumber,
                          prefixIcon: Icons.phone_outlined,
                        ),
                        _buildDateOfBirthContainer(),
                        _buildGenderSelector(),
                        if (context.read<AuthCubit>().isTeacher()) ...[
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              "Address Information",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: accentMaroon,
                              ),
                            ),
                          ),
                          _buildLabelWithTextEditingController(
                            labelTitle: currentAddressKey,
                            textFieldHintTextKey: currentAddressKey,
                            textEditingController: currentAddress,
                            prefixIcon: Icons.home_outlined,
                          ),
                          _buildLabelWithTextEditingController(
                            labelTitle: permanentAddressKey,
                            textFieldHintTextKey: permanentAddressKey,
                            textEditingController: permanentAddress,
                            prefixIcon: Icons.location_on_outlined,
                          ),
                        ],
                        const SizedBox(height: 24),
                        _buildUpdateProfileButton(state),
                      ],
                    ),
                  ),
                ),
              ),
              // Profile image - COMPLETELY SEPARATE dari scrollable area
              // Loading indicator overlay
              if (state is EditProfileProgress)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: CustomCircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
