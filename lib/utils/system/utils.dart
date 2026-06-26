// ignore_for_file: use_build_context_synchronously
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:eschool_saas_staff/cubits/settings/downloadFileCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/assignmentSubmission.dart';
import 'package:eschool_saas_staff/data/models/academic/studyMaterial.dart';
import 'package:eschool_saas_staff/data/repositories/auth/authRepository.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/downloadFileBottomsheetContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class Utils {
  static String formatNumber(int number) {
    final formatter = intl.NumberFormat('#,###', 'id_ID');
    return formatter.format(number).replaceAll(',', '.');
  }

  String cleanClassName(String? className) {
    if (className == null) return "-";

    // Remove everything from the first opening parenthesis to the end
    int parenthesisIndex = className.indexOf('(');
    if (parenthesisIndex != -1) {
      className = className.substring(0, parenthesisIndex).trim();
    }

    // Remove " - IDN" if it exists at the end
    if (className.endsWith(" - IDN")) {
      className = className.substring(0, className.length - 6).trim();
    }

    return className.isEmpty ? "-" : className;
  }

  double getResponsiveHeight(BuildContext context, double baseHeight) {
    double screenHeight = MediaQuery.of(context).size.height;
    double scaleFactor = screenHeight / 812.0; // 812 is a common base height
    return baseHeight * scaleFactor;
  }

  double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth / 375.0; // 375 is a common base width
    return baseFontSize * scaleFactor;
  }

  static double getScaledValue(BuildContext context, double value) {
    return value / MediaQuery.of(context).textScaler.scale(1);
  }

  static Locale getLocaleFromLanguageCode(String languageCode) {
    List<String> result = languageCode.split("-");
    return result.length == 1
        ? Locale(result.first)
        : Locale(result.first, result.last);
  }

  static String getImagePath(String imageName) {
    return "assets/images/$imageName";
  }

  static String getLottieAnimationPath(String animationFileName) {
    return "assets/animations/$animationFileName";
  }

  static String getDayName(int day) {
    const List<String> days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jum\'at',
      'Sabtu',
      'Minggu'
    ];
    return days[(day - 1) %
        7]; // Menggunakan modulo untuk menghindari index out of range
  }

  static String getMonthName(int month) {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return months[month - 1];
  }

  static String getMonthFullName(int month) {
    const List<String> months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return months[month - 1];
  }

  static String getFormattedDate(DateTime date) {
    return intl.DateFormat('dd-MM-yyyy').format(date).toString();
  }

  static String getFormattedDayOfTime(TimeOfDay time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  static String formatDateAndTime(DateTime dateTime) {
    // Asumsi fungsi formatDateAndTime defaultntya adalah WIB
    final localOffset = DateTime.now().timeZoneOffset.inHours;
    final diffFromWIB = localOffset - 7;

    // Sesuaikan waktu
    final adjustedDateTime = dateTime.add(Duration(hours: diffFromWIB));

    // Format tanggal dan waktu
    final formattedDateTime =
        intl.DateFormat("dd-MM-yy, HH.mm").format(adjustedDateTime);

    // Tambahkan label zona waktu
    final timezoneLabel = getTimezoneLabel();

    return '$formattedDateTime $timezoneLabel';
  }

  static Future<dynamic> showBottomSheet(
      {required Widget child,
      required BuildContext context,
      bool? enableDrag}) async {
    final result = Get.bottomSheet(child,
        enableDrag: enableDrag ?? true,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(bottomsheetBorderRadius),
                topRight: Radius.circular(bottomsheetBorderRadius))));
    return result;
  }

  static Future<void> showSnackBar({
    required String message,
    required BuildContext context,
    TextStyle? messageTextStyle,
  }) async {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        content: CustomTextContainer(
          textKey: message,
          style: messageTextStyle ??
              const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Colors.white,
              ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showColoredSnackBar({
    required String message,
    required BuildContext context,
    required bool isSuccess, // true for success, false for warning/error
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showAnimatedSnackBar({
    required String message,
    required BuildContext context,
    required bool isSuccess,
  }) {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   // SnackBar(
    //   //   duration: const Duration(seconds: 3),
    //   //   behavior: SnackBarBehavior.floating,
    //   //   margin: EdgeInsets.only(
    //   //     bottom: MediaQuery.of(context).size.height - 100,
    //   //     left: 20,
    //   //     right: 20,
    //   //   ),
    //   //   elevation: 0,
    //   //   backgroundColor: Colors.transparent,
    //   //   // content: CustomSnackbar(
    //   //   //   message: message,
    //   //   //   isSuccess: isSuccess,
    //   //   // ),
    //   //   animation: CurvedAnimation(
    //   //     parent: const AlwaysStoppedAnimation(1),
    //   //     curve: Curves.elasticOut,
    //   //   ),
    //   // ),
    // );
  }

  static intl.DateFormat hourMinutesDateFormat = intl.DateFormat('HH.mm');

  //Date format is dd/mm/yy
  static String formatDate(DateTime date, {String format = 'dd-MM-yyyy'}) {
    String dayName = getDayName(date.weekday);
    String day = date.day.toString();
    String monthName = getMonthName(date.month);
    String year = date.year.toString();
    return '$dayName, $day $monthName $year';
  }

  static String formatDateLeave(DateTime date, {String format = 'dd-MM-yyyy'}) {
    // String dayName = getDayName(date.weekday);
    String day = date.day.toString();
    String monthName = getMonthFullName(date.month);
    String year = date.year.toString();
    return '$day $monthName $year';
  }

  static String formatTime({
    required TimeOfDay timeOfDay,
    required BuildContext context,
    String? timeZone, // Timezone now optional, and no default value
  }) {
    // Asumsikan waktu input adalah WIB
    final now = DateTime.now();
    final wibTime = DateTime(
        now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);

    // Dapatkan offset zona waktu lokal dalam jam
    final localOffset = DateTime.now().timeZoneOffset.inHours;

    // Hitung perbedaan dengan WIB (UTC+7)
    final diffFromWIB = localOffset - 7;

    // Sesuaikan waktu
    final adjustedTime = wibTime.add(Duration(hours: diffFromWIB));

    // Extract hours and minutes after adjustment
    final hour = adjustedTime.hour.toString().padLeft(2, '0');
    final minute = adjustedTime.minute.toString().padLeft(2, '0');

    return '$hour.$minute'; // Return the formatted time in HH.mm format
  }

  static String getTimezoneLabel() {
    final offset = DateTime.now().timeZoneOffset.inHours;
    if (offset == 7) return 'WIB';
    if (offset == 8) return 'WITA';
    if (offset == 9) return 'WIT';
    return ''; // Default case
  }

  static bool isUserLoggedIn() {
    return AuthRepository.getIsLogIn();
  }

  static Future<bool> hasStoragePermissionGiven() async {
    if (Platform.isIOS) {
      bool permissionGiven = await Permission.storage.isGranted;
      if (!permissionGiven) {
        permissionGiven = (await Permission.storage.request()).isGranted;
        return permissionGiven;
      }
      return permissionGiven;
    }

    //if it is for android
    final deviceInfoPlugin = DeviceInfoPlugin();
    final androidDeviceInfo = await deviceInfoPlugin.androidInfo;
    if (androidDeviceInfo.version.sdkInt < 33) {
      bool permissionGiven = await Permission.storage.isGranted;
      if (!permissionGiven) {
        permissionGiven = (await Permission.storage.request()).isGranted;
        return permissionGiven;
      }
      return permissionGiven;
    } else {
      bool permissionGiven = await Permission.photos.isGranted;
      if (!permissionGiven) {
        permissionGiven = (await Permission.photos.request()).isGranted;
        return permissionGiven;
      }
      return permissionGiven;
    }
  }

  static Future<void> openLinkInBrowser(
      {required String url, required BuildContext context}) async {
    try {
      final uri = Uri.parse(url);

      // For mailto: and tel: links prefer launching externally so native apps handle them
      if (uri.scheme == 'mailto' || uri.scheme == 'tel') {
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          Utils.showSnackBar(message: defaultErrorMessageKey, context: context);
        }
        return;
      }

      // For http/https and other links, open in external browser
      final canLaunchFlag = await canLaunchUrl(uri);
      if (canLaunchFlag) {
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          Utils.showSnackBar(message: defaultErrorMessageKey, context: context);
        }
      } else {
        Utils.showSnackBar(message: defaultErrorMessageKey, context: context);
      }
    } catch (e) {
      Utils.showSnackBar(message: defaultErrorMessageKey, context: context);
    }
  }

  static String getTranslatedLabel(String labelKey) {
    return labelKey.tr.trim();
  }

  static double appContentTopScrollPadding({required BuildContext context}) {
    return kToolbarHeight + MediaQuery.of(context).padding.top;
  }

  static final List<String> weekDays = [
    mondayKey,
    tuesdayKey,
    wednesdayKey,
    thursdayKey,
    fridayKey,
    saturdayKey,
    sundayKey
  ];

  ///[This will determine this text will take how many number of lines in the ui]
  static int calculateLinesForGivenText(
      {required double availableMaxWidth,
      required BuildContext context,
      required String text,
      required TextStyle textStyle}) {
    final span = TextSpan(
      text: text,
      style: textStyle,
    );
    final tp =
        TextPainter(text: span, textDirection: Directionality.of(context));
    tp.layout(maxWidth: availableMaxWidth);
    final numLines = tp.computeLineMetrics().length;

    return numLines;
  }

  static Future<void> launchCallLog(
      {required String mobile, required BuildContext context}) async {
    try {
      final result = await launchUrl(Uri.parse("tel:$mobile"));
      if (!result && context.mounted) {
        Utils.showSnackBar(message: defaultErrorMessageKey, context: context);
      }
    } catch (_) {
      if (context.mounted) {
        Utils.showSnackBar(message: defaultErrorMessageKey, context: context);
      }
    }
  }

  static Future<void> launchEmailLog(
      {required String email, required BuildContext context}) async {
    try {
      final result = await launchUrl(Uri.parse("mailto:$email"));
      if (!result && context.mounted) {
        Utils.showSnackBar(message: defaultErrorMessageKey, context: context);
      }
    } catch (_) {
      if (context.mounted) {
        Utils.showSnackBar(message: defaultErrorMessageKey, context: context);
      }
    }
  }

  static int getHourFromTimeDetails({required String time}) {
    final timeDetails = time.split(":");
    return int.parse(timeDetails[0]);
  }

  static int getMinuteFromTimeDetails({required String time}) {
    final timeDetails = time.split(":");
    return int.parse(timeDetails[1]);
  }

  static void viewOrDownloadStudyMaterial({
    required BuildContext context,
    required bool storeInExternalStorage,
    required StudyMaterial studyMaterial,
  }) {
    try {
      if (studyMaterial.studyMaterialType ==
              StudyMaterialType.uploadedVideoUrl ||
          studyMaterial.studyMaterialType == StudyMaterialType.youtubeVideo) {
        launchUrl(Uri.parse(studyMaterial.fileUrl));
      } else {
        Utils.openDownloadBottomsheet(
          context: context,
          studyMaterial: studyMaterial,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Utils.showSnackBar(
          context: context,
          message: Utils.getTranslatedLabel(unableToOpenFileKey),
        );
      }
    }
  }

  static void openDownloadBottomsheet({
    required BuildContext context,
    required StudyMaterial studyMaterial,
  }) {
    showBottomSheet(
      child: BlocProvider(
        create: (context) => DownloadFileCubit(),
        child: DownloadFileBottomsheetContainer(
          studyMaterial: studyMaterial,
        ),
      ),
      context: context,
    ).then((result) {
      if (result != null) {
        if (result['error']) {
          showSnackBar(
            context: context,
            message: getTranslatedLabel(
              result['message'].toString(),
            ),
          );
        } else {
          try {
            OpenFilex.open(result['filePath'].toString());
          } catch (e) {
            showSnackBar(
              context: context,
              message: getTranslatedLabel(
                unableToOpenFileKey,
              ),
            );
          }
        }
      }
    });
  }

  static Widget buildProgressContainer({
    required double width,
    required Color color,
  }) {
    return Container(
      width: width,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(3.0)),
    );
  }

  static Future<DateTime?> openDatePicker(
      {required BuildContext context,
      DateTime? lastDate,
      DateTime? inititalDate,
      DateTime? firstDate}) async {
    return await showDatePicker(
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  onPrimary: Theme.of(context).scaffoldBackgroundColor,
                ),
          ),
          child: child!,
        );
      },
      context: context,
      initialDate: inititalDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime.now(),
      lastDate: lastDate ??
          DateTime.now().add(
            const Duration(days: 30),
          ),
    );
  }

  static Future<TimeOfDay?> openTimePicker(
      {required BuildContext context}) async {
    return await showTimePicker(
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  onPrimary: Theme.of(context).scaffoldBackgroundColor,
                ),
          ),
          child: child!,
        );
      },
      context: context,
      initialTime: TimeOfDay.now(),
    );
  }

  static Future<FilePickerResult?> openFilePicker(
      {required BuildContext context,
      bool allowMultiple = true,
      FileType type = FileType.any}) async {
    Future<FilePickerResult?> pickFiles() async {
      return await FilePicker.platform
          .pickFiles(allowMultiple: allowMultiple, type: type);
    }

    final permission = await Permission.storage.request();
    if (permission.isGranted) {
      return await pickFiles();
    } else {
      try {
        return await pickFiles();
      } on Exception {
        if (context.mounted) {
          Utils.showSnackBar(
              context: context, message: allowStoragePermissionToContinueKey);
          await Future.delayed(const Duration(seconds: 2));
        }
        openAppSettings();
      }
    }
    return null;
  }

  static AssignmentSubmissionStatus getAssignmentSubmissionStatusFromTypeId(
      {required int typeId}) {
    return allAssignmentSubmissionStatus
            .firstWhereOrNull((element) => element.typeStatusId == typeId) ??
        allAssignmentSubmissionStatus.first;
  }

  static bool _shouldUpdateBasedOnVersion(
    String currentVersion,
    String updatedVersion,
  ) {
    List<int> currentVersionList =
        currentVersion.split(".").map((e) => int.parse(e)).toList();
    List<int> updatedVersionList =
        updatedVersion.split(".").map((e) => int.parse(e)).toList();

    if (updatedVersionList[0] > currentVersionList[0]) {
      return true;
    }
    if (updatedVersionList[1] > currentVersionList[1]) {
      return true;
    }
    if (updatedVersionList[2] > currentVersionList[2]) {
      return true;
    }

    return false;
  }

  static Future<bool> forceUpdate(String updatedVersion) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = "${packageInfo.version}+${packageInfo.buildNumber}";
    if (updatedVersion.isEmpty) {
      return false;
    }

    final bool updateBasedOnVersion = _shouldUpdateBasedOnVersion(
      currentVersion.split("+").first,
      updatedVersion.split("+").first,
    );

    if (updatedVersion.split("+").length == 1 ||
        currentVersion.split("+").length == 1) {
      return updateBasedOnVersion;
    }

    final bool updateBasedOnBuildNumber = _shouldUpdateBasedOnBuildNumber(
      currentVersion.split("+").last,
      updatedVersion.split("+").last,
    );

    return updateBasedOnVersion || updateBasedOnBuildNumber;
  }

  static bool _shouldUpdateBasedOnBuildNumber(
    String currentBuildNumber,
    String updatedBuildNumber,
  ) {
    return int.parse(updatedBuildNumber) > int.parse(currentBuildNumber);
  }

  static bool isRTLEnabled(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl;
  }

  static bool isCurrentTimeWithinSlot(String startTime, String endTime) {
    if (startTime.isEmpty || endTime.isEmpty) return false;
    try {
      final now = DateTime.now();
      final start = intl.DateFormat('HH:mm:ss').parse(startTime);
      final end = intl.DateFormat('HH:mm:ss').parse(endTime);

      final todayStart = DateTime(
          now.year, now.month, now.day, start.hour, start.minute, start.second);
      final todayEnd = DateTime(
          now.year, now.month, now.day, end.hour, end.minute, end.second);

      return now.isAfter(todayStart) && now.isBefore(todayEnd);
    } catch (_) {
      try {
        final now = DateTime.now();
        final start = intl.DateFormat('HH:mm').parse(startTime);
        final end = intl.DateFormat('HH:mm').parse(endTime);

        final todayStart = DateTime(
            now.year, now.month, now.day, start.hour, start.minute);
        final todayEnd = DateTime(
            now.year, now.month, now.day, end.hour, end.minute);

        return now.isAfter(todayStart) && now.isBefore(todayEnd);
      } catch (_) {
        return false;
      }
    }
  }
}


extension DateTimeExtension on DateTime {
  bool isSameDayAs(DateTime other) =>
      day == other.day && month == other.month && year == other.year;

  String get relativeFormatedDate {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (isSameDayAs(today)) {
      return "today";
    } else if (isSameDayAs(yesterday)) {
      return "yesterday";
    } else {
      // return intl.DateFormat('dd MMMM yyyy').format(this);
      final monthName = Utils.getMonthFullName(month);
      return "$day $monthName $year";
    }
  }
}
