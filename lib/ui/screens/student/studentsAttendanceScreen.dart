import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/cubits/student/studentAttendanceForStaffCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customFilterModernAppbar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextButton.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/errorContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/student/studentAttendanceItemContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class StudentsAttendanceScreen extends StatefulWidget {
  const StudentsAttendanceScreen({super.key});

  static Widget getRouteInstance() {
    //final arguments = Get.arguments as Map<String, dynamic>;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ClassesCubit(),
        ),
        BlocProvider(create: (context) => StudentAttendanceForStaffCubit())
      ],
      child: const StudentsAttendanceScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<StudentsAttendanceScreen> createState() =>
      _StudentsAttendanceScreenState();
}

class _StudentsAttendanceScreenState extends State<StudentsAttendanceScreen>
    with TickerProviderStateMixin {
  late DateTime _selectedDateTime = DateTime.now();

  ClassSection? _selectedClassSection;
  String _selectedAttendanceStatus = statusKey;
  double _headerHeight = 200.0;

  late final ScrollController _scrollController = ScrollController()
    ..addListener(scrollListener);

  // Animation controllers
  late final AnimationController _animationController;

  // Define theme colors
  static Color get maroonPrimary => AppColorPalette.primaryMaroon;
  static Color get maroonLight => AppColorPalette.secondaryMaroon;
  final Color cardColor = Colors.white;
  @override
  void initState() {
    super.initState();

    // Show welcome message
    Get.snackbar(
      'Welcome',
      'Welcome to Student Attendance Management',
      snackPosition: SnackPosition.TOP,
      backgroundColor: maroonPrimary.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(10),
    );

    // Primary animation controller for fade effects
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Start animations
    _animationController.forward();

    // Scroll listener for collapsing header effect
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && _headerHeight == 200.0) {
        setState(() {
          _headerHeight = 120.0;
        });
      } else if (_scrollController.offset <= 50 && _headerHeight == 120.0) {
        setState(() {
          _headerHeight = 200.0;
        });
      }
    });

    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<ClassesCubit>().getClasses();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(scrollListener);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void scrollListener() {
    if (_scrollController.offset ==
        _scrollController.position.maxScrollExtent) {
      if (context.read<StudentAttendanceForStaffCubit>().hasMore()) {
        getMoreStudentAttendance();
      }
    }
  }

  int? getStatus() {
    if (_selectedAttendanceStatus == absentKey) {
      return 0;
    }
    if (_selectedAttendanceStatus == presentKey) {
      return 1;
    }
    if (_selectedAttendanceStatus == sickKey) {
      return 2;
    }
    if (_selectedAttendanceStatus == permissionKey) {
      return 3;
    }
    if (_selectedAttendanceStatus == alpaKey) {
      return 4;
    }
    return null;
  }

  void changeSelectedClassSection(ClassSection classSection) {
    _selectedClassSection = classSection;
    debugPrint(
        '==================== CLASS SECTION CHANGE LOG ====================');
    debugPrint('Debug Log - Class Section Changed:');
    debugPrint('ID: ${classSection.id}');
    debugPrint('Name: ${classSection.fullName}');
    debugPrint('Timestamp: ${DateTime.now()}');
    debugPrint(
        '==============================================================');
    setState(() {});
    getStudentAttendance();
  }

  void changeSelectedAttendanceStatus(String status) {
    _selectedAttendanceStatus = status;

    setState(() {});
    getStudentAttendance();
  }

  void getStudentAttendance() {
    final classSectionId = _selectedClassSection?.id ?? 0;
    final date = _selectedDateTime;

    debugPrint(
        '\n==================== ATTENDANCE REQUEST LOG ====================');
    debugPrint('Request Time: ${DateTime.now()}');
    debugPrint('Class Section Details:');
    debugPrint('- ID: $classSectionId');
    debugPrint('- Name: ${_selectedClassSection?.fullName}');
    debugPrint('\nDate Information:');
    debugPrint('- Raw Date: ${date.toString()}');
    debugPrint('- Formatted Date: ${Utils.formatDate(date)}');
    debugPrint('- Day of Week: ${date.weekday}');
    debugPrint('\nStatus Information:');
    debugPrint('- Status Code: ${getStatus()}');
    debugPrint('- Status Text: $_selectedAttendanceStatus');
    debugPrint(
        '==============================================================\n');

    context.read<StudentAttendanceForStaffCubit>().getStudentAttendance(
          classSectionId: classSectionId,
          date: date,
          status: getStatus(),
        );
  }

  void getMoreStudentAttendance() {
    context.read<StudentAttendanceForStaffCubit>().fetchMore(
          classSectionId: (_selectedClassSection?.id ?? 0),
          date: _selectedDateTime,
          status: getStatus(),
        );
  }

  Widget _buildStudentsContainer() {
    return BlocBuilder<StudentAttendanceForStaffCubit,
        StudentAttendanceForStaffState>(
      builder: (context, state) {
        if (state is StudentAttendanceForStaffFetchSuccess) {
          debugPrint(
              '\n==================== ATTENDANCE RESPONSE LOG ====================');
          debugPrint('Response Time: ${DateTime.now()}');
          debugPrint('Data Summary:');
          debugPrint('- Total Students: ${state.studentAttendances.length}');
          debugPrint('- Class: ${_selectedClassSection?.fullName}');
          debugPrint('- Date: ${Utils.formatDate(_selectedDateTime)}');
          debugPrint('\nDetailed Student Records:');
          debugPrint('----------------------------------------');
          for (var student in state.studentAttendances) {
            final studentName = student.studentDetails?.student?.fullName ??
                student.studentDetails?.fullName ??
                "No name";
            final status = student.type;
            debugPrint(
                'Student ID: ${student.studentDetails?.student?.id ?? "N/A"}');
            debugPrint('Name: $studentName');
            debugPrint('Status: $status');
            debugPrint('----------------------------------------');
          }
          debugPrint(
              '==============================================================\n');
          return Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.only(
                  top:
                      Utils.appContentTopScrollPadding(context: context) + 150),
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.all(appContentHorizontalPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: state.studentAttendances.isEmpty
                    ? const Center(
                        child: CustomTextContainer(
                          textKey: attendanceNotTakenKey,
                          style: TextStyle(fontSize: 16.0),
                        ),
                      )
                    : Column(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width,
                            height: 45,
                            decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(5.0),
                                    topLeft: Radius.circular(5.0)),
                                color: Theme.of(context).colorScheme.tertiary),
                            padding: EdgeInsets.symmetric(
                                horizontal: appContentHorizontalPadding,
                                vertical: 10),
                            child: LayoutBuilder(
                                builder: (context, boxConstraints) {
                              const titleStyle = TextStyle(
                                  fontSize: 15.0, fontWeight: FontWeight.w600);
                              return Row(
                                children: [
                                  SizedBox(
                                    width: boxConstraints.maxWidth * (0.2),
                                    child: const CustomTextContainer(
                                      textKey: rollNoKey,
                                      style: titleStyle,
                                    ),
                                  ),
                                  SizedBox(
                                    width: boxConstraints.maxWidth * (0.6),
                                    child: const CustomTextContainer(
                                      textKey: nameKey,
                                      style: titleStyle,
                                    ),
                                  ),
                                  SizedBox(
                                    width: boxConstraints.maxWidth * (0.2),
                                    child: const CustomTextContainer(
                                      textKey: statusKey,
                                      style: titleStyle,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                          ...List.generate(state.studentAttendances.length,
                              (index) {
                            final studentAttendance =
                                state.studentAttendances[index];

                            if (context
                                .read<StudentAttendanceForStaffCubit>()
                                .hasMore()) {
                              if (index ==
                                  (state.studentAttendances.length - 1)) {
                                if (state.fetchMoreError) {
                                  return Center(
                                    child: CustomTextButton(
                                        buttonTextKey: retryKey,
                                        onTapButton: () {
                                          getMoreStudentAttendance();
                                        }),
                                  );
                                }
                                return Center(
                                  child: CustomCircularProgressIndicator(
                                    indicatorColor:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                );
                              }
                            }

                            return StudentAttendanceItemContainer(
                              studentDetails: studentAttendance.studentDetails!,
                              isPresent: getStudentAttendanceStatusFromValue(
                                      studentAttendance.type ?? 0) ==
                                  StudentAttendanceStatus.present,
                              isSick: getStudentAttendanceStatusFromValue(
                                      studentAttendance.type ?? 0) ==
                                  StudentAttendanceStatus.sick,
                              isPermission: getStudentAttendanceStatusFromValue(
                                      studentAttendance.type ?? 0) ==
                                  StudentAttendanceStatus.permission,
                              isAlpa: getStudentAttendanceStatusFromValue(
                                      studentAttendance.type ?? 0) ==
                                  StudentAttendanceStatus.alpa,
                              showStatusPicker: false,
                              index: index,
                            );
                          }),
                        ],
                      ),
              ),
            ),
          );
        }

        if (state is StudentAttendanceForStaffFetchFailure) {
          debugPrint('\n==================== ERROR LOG ====================');
          debugPrint('Error Time: ${DateTime.now()}');
          debugPrint('Error Type: Fetch Failure');
          debugPrint('Error Message: ${state.errorMessage}');
          debugPrint('Context:');
          debugPrint('- Class: ${_selectedClassSection?.fullName}');
          debugPrint('- Date: ${Utils.formatDate(_selectedDateTime)}');
          debugPrint('- Status: $_selectedAttendanceStatus');
          debugPrint('================================================\n');
          return Center(
            child: ErrorContainer(
              errorMessage: state.errorMessage,
              onTapRetry: () {
                getStudentAttendance();
              },
            ),
          );
        }

        return Center(
          child: CustomCircularProgressIndicator(
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildHeaderSection() {
    return CustomFilterModernAppBar(
      title: studentAttendanceKey.tr,
      titleIcon: Icons.fact_check_rounded,
      primaryColor: maroonPrimary,
      secondaryColor: maroonLight,
      onBackPressed: () {
        Navigator.pop(context);
      },
      animationController: _animationController,
      enableAnimations: true,
      height: _headerHeight,
      firstFilterItem: FilterItemConfig(
        title: _selectedClassSection?.fullName ?? classKey.tr,
        icon: Icons.class_rounded,
        onTap: () {
          if (context.read<ClassesCubit>().state is ClassesFetchSuccess &&
              context.read<ClassesCubit>().getAllClasses().isNotEmpty) {
            Utils.showBottomSheet(
              child: FilterSelectionBottomsheet<ClassSection>(
                onSelection: (value) {
                  changeSelectedClassSection(value!);
                  Get.back();
                },
                selectedValue: _selectedClassSection!,
                titleKey: classKey,
                values: context.read<ClassesCubit>().getAllClasses(),
              ),
              context: context,
            );
          }
        },
      ),
      secondFilterItem: FilterItemConfig(
        title: _selectedAttendanceStatus.tr,
        icon: Icons.filter_list_rounded,
        onTap: () {
          Utils.showBottomSheet(
            child: FilterSelectionBottomsheet(
              onSelection: (value) {
                changeSelectedAttendanceStatus(value!);
                Get.back();
              },
              selectedValue: _selectedAttendanceStatus,
              titleKey: titleKey,
              values: const [allKey, absentKey, presentKey],
            ),
            context: context,
          );
        },
      ),
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
              if (context.read<ClassesCubit>().getAllClasses().isEmpty) {
                return const SizedBox();
              }
              return _buildStudentsContainer();
            }
            if (state is ClassesFetchFailure) {
              return Center(
                child: ErrorContainer(
                    onTapRetry: () {
                      context.read<ClassesCubit>().getClasses();
                    },
                    errorMessage: state.errorMessage),
              );
            }

            return Center(
              child: CustomCircularProgressIndicator(
                indicatorColor: Theme.of(context).colorScheme.primary,
              ),
            );
          },
        ),
        Align(
          alignment: Alignment.topCenter,
          child: BlocConsumer<ClassesCubit, ClassesState>(
            listener: (context, state) {
              if (state is ClassesFetchSuccess) {
                if (context.read<ClassesCubit>().getAllClasses().isNotEmpty) {
                  changeSelectedClassSection(
                      context.read<ClassesCubit>().getAllClasses().first);
                  getStudentAttendance();
                }
              }
            },
            builder: (context, state) {
              return Column(
                children: [
                  _buildHeaderSection(),
                  InkWell(
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                          context: context,
                          currentDate: _selectedDateTime,
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 30)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 30)));

                      if (selectedDate != null) {
                        _selectedDateTime = selectedDate;

                        setState(() {});
                        getStudentAttendance();
                      }
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 50,
                      padding: EdgeInsets.symmetric(
                          horizontal: appContentHorizontalPadding,
                          vertical: 10),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border(
                              bottom: BorderSide(
                                  color:
                                      Theme.of(context).colorScheme.tertiary))),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month),
                          const SizedBox(
                            width: 15,
                          ),
                          const CustomTextContainer(textKey: dateKey),
                          const SizedBox(
                            width: 10,
                          ),
                          CustomTextContainer(
                              textKey:
                                  "(${Utils.formatDate(_selectedDateTime)})")
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        )
      ],
    ));
  }
}
