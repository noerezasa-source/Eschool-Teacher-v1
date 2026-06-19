import 'package:eschool_saas_staff/ui/widgets/student/recapAttendanceContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/cubits/authentication/authCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/data/repositories/auth/authRepository.dart';
import 'package:get/get.dart' as getx;

class RecapAttendanceSubjectScreen extends StatefulWidget {
  static Widget getRouteInstance() {
    return BlocProvider(
      create: (context) => ClassesCubit()..getClasses(),
      child: const RecapAttendanceSubjectScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  const RecapAttendanceSubjectScreen({super.key});

  @override
  State<RecapAttendanceSubjectScreen> createState() =>
      _RecapAttendanceSubjectScreenState();
}

class _RecapAttendanceSubjectScreenState
    extends State<RecapAttendanceSubjectScreen> with TickerProviderStateMixin {
  int _selectedYear = DateTime.now().year;
  int? _selectedMonth;
  ClassSection? _selectedClassSection;
  List<ClassSection> _filteredClassSections = [];
  int? teacherId;
  int? schoolId;
  String? email;

  final Color _maroonPrimary = const Color(0xFF800020);
  final Color _maroonLight = const Color(0xFFAA6976);

  late AnimationController _fabAnimationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.offset > 50) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadClassTeacherData();
  }

  void _loadClassTeacherData() {
    final userDetails = context.read<AuthCubit>().getUserDetails();

    setState(() {
      teacherId = userDetails.id;
      schoolId = userDetails.schoolId;
      email = userDetails.email ?? "";
    });
    context.read<ClassesCubit>().getClasses();
  }

  void getRecap({int? type}) {
    if (_selectedClassSection == null || _selectedMonth == null) {
      return;
    }
    // Add your logic here to fetch data based on selected year and month
    debugPrint('Getting recap for Year: $_selectedYear, Month: $_selectedMonth');
  }

  void _showYearPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Tahun'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(2020),
              lastDate: DateTime(DateTime.now().year + 1),
              selectedDate: DateTime(_selectedYear),
              onChanged: (DateTime dateTime) {
                setState(() {
                  _selectedYear = dateTime.year;
                  // Reset month selection when year changes
                  _selectedMonth = null;
                });
                Navigator.pop(context);
                // After selecting year, show month picker
                _showMonthPicker();
              },
            ),
          ),
        );
      },
    );
  }

  void _showMonthPicker() {
    final months = [
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pilih Bulan untuk Tahun $_selectedYear'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: ListView.builder(
              itemCount: months.length,
              itemBuilder: (context, index) {
                final monthIndex = index + 1;
                return ListTile(
                  title: Text(months[index]),
                  trailing: _selectedMonth == monthIndex
                      ? Icon(Icons.check, color: _maroonPrimary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedMonth = monthIndex;
                    });
                    Navigator.pop(context);
                    getRecap();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  void downloadRecap(int classId, int classSectionId, int month) async {
    if (schoolId == null) {
      return;
    }

    final token = AuthRepository.getAuthToken();

    getx.Get.toNamed(
      Routes.attendanceRecapScreen,
      arguments: {
        'schoolId': schoolId,
        'token': token,
        'month': month,
        'year': _selectedYear,
        'classId': classId,
        'classSectionId': classSectionId,
      },
    );
  }

  void filterClassSections(List<ClassSection> classSections, int teacherId) {
    _filteredClassSections = classSections.where((classSection) {
      if (classSection.classTeachers == null ||
          classSection.classTeachers!.isEmpty) {
        return false;
      }

      for (var classTeacher in classSection.classTeachers!) {
        if (classTeacher.teacher?.id == teacherId &&
            classTeacher.teacherId == teacherId &&
            classTeacher.classSectionId == classSection.id) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  String _getMonthName(int month) {
    final months = [
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

  Widget _buildRecapTable(List<ClassSection> classes) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        // Adjust top padding to position content below the app bar
        top: 180, // Reduced padding to minimize white space
        bottom: 25,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recap attendance container
          RecapAttendanceContainer(
            classSections: classes,
            selectedYear: _selectedYear,
            selectedMonth: _selectedMonth,
            email: email,
            schoolId: schoolId,
            onDownload: (classSection, month) {
              final classId = classSection.classDetails?.id ?? 0;
              final classSectionId = classSection.id ?? 0;
              downloadRecap(classId, classSectionId, month);
            },
          ).animate().fadeIn(duration: 500.ms).slideY(
                begin: 0.05,
                end: 0,
                curve: Curves.easeOutQuad,
                duration: 500.ms,
              ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return CustomModernAppBar(
      title: Utils.getTranslatedLabel(recapAttendanceSubjectKey),
      icon: Icons.receipt_long_rounded,
      fabAnimationController: _fabAnimationController,
      primaryColor: _maroonPrimary,
      lightColor: _maroonLight,
      onBackPressed: () => Navigator.of(context).pop(),
      height: 150, // Increased height to accommodate the tab filter
      tabBuilder: (context) {
        return BlocBuilder<ClassesCubit, ClassesState>(
          builder: (context, state) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // If month is already selected, show month picker directly
                  // If not, start with year picker
                  if (_selectedMonth != null) {
                    _showMonthPicker();
                  } else {
                    _showYearPicker();
                  }
                },
                borderRadius: BorderRadius.circular(12),
                highlightColor: Colors.white.withValues(alpha: 0.1),
                splashColor: Colors.white.withValues(alpha: 0.2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.9),
                              Colors.white.withValues(alpha: 0.4),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: _maroonPrimary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedMonth != null
                            ? '${_getMonthName(_selectedMonth!)} $_selectedYear'
                            : 'Pilih Bulan & Tahun',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            const Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BlocBuilder<ClassesCubit, ClassesState>(
            builder: (context, state) {
              if (state is ClassesFetchSuccess) {
                // Get ALL classes (both primary and other)
                List<ClassSection> allClasses =
                    context.read<ClassesCubit>().getAllClasses();

                // Debugging to check if we're getting classes
                debugPrint(
                    "Received ${allClasses.length} total classes (primary + other)");

                if (teacherId != null) {
                  // Process for teacher's classes
                  // First try to filter by teacher ID
                  filterClassSections(allClasses, teacherId!);

                  // If no filtered classes found, just show all classes
                  if (_filteredClassSections.isEmpty) {
                    debugPrint(
                        "No filtered classes found, showing all ${allClasses.length} classes");
                    return _buildRecapTable(allClasses);
                  } else {
                    debugPrint(
                        "Found ${_filteredClassSections.length} classes for teacher ID: $teacherId");
                    return _buildRecapTable(_filteredClassSections);
                  }
                } else {
                  // If teacherId is null, show all classes
                  debugPrint("Teacher ID is null, showing all classes");
                  return _buildRecapTable(allClasses);
                }
              }
              if (state is ClassesFetchFailure) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: topPaddingOfErrorAndLoadingContainer,
                  ),
                  child: CustomErrorWidget(
                    message: ErrorMessageUtils.getReadableErrorMessage(
                        state.errorMessage),
                    onRetry: () {
                      context.read<ClassesCubit>().getClasses();
                    },
                    primaryColor: _maroonPrimary,
                  ),
                );
              }
              return Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: topPaddingOfErrorAndLoadingContainer,
                  ),
                  child: const SkeletonRecapAttendanceScreen(itemCount: 6),
                ),
              );
            },
          ),
          _buildAppBar(),
        ],
      ),
    );
  }
}
