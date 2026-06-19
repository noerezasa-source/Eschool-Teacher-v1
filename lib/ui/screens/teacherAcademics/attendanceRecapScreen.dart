import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';

class AttendanceRecapScreen extends StatefulWidget {
  final int schoolId;
  final String token;
  final int month;
  final int year;
  final int classId;
  final int classSectionId;

  const AttendanceRecapScreen({
    super.key,
    required this.schoolId,
    required this.token,
    required this.month,
    required this.year,
    required this.classId,
    required this.classSectionId,
  });

  static Widget getRouteInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return AttendanceRecapScreen(
      schoolId: arguments['schoolId'],
      token: arguments['token'],
      month: arguments['month'],
      year: arguments['year'],
      classId: arguments['classId'],
      classSectionId: arguments['classSectionId'],
    );
  }

  @override
  State<AttendanceRecapScreen> createState() => _AttendanceRecapScreenState();
}

class _AttendanceRecapScreenState extends State<AttendanceRecapScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    final String url = "${Api.recapDownload}?"
        "school_id=${widget.schoolId}"
        "&token=${widget.token}"
        "&month=${widget.month}"
        "&year=${widget.year}"
        "&class_id=${widget.classId}"
        "&class_section_id=${widget.classSectionId}"
        "&gm=true";

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("WebView Error: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Utils.getTranslatedLabel(recapAttendanceSubjectKey)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
