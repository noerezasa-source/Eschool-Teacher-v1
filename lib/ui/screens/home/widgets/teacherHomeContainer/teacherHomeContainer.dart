import 'package:eschool_saas_staff/cubits/authentication/authCubit.dart';
import 'package:eschool_saas_staff/cubits/settings/appThemeCubit.dart';
import 'package:eschool_saas_staff/cubits/settings/homeScreenDataCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/teacherMyTimetableCubit.dart';
import 'package:eschool_saas_staff/cubits/userDetails/staffAllowedPermissionsAndModulesCubit.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/homeContainer/widgets/homeContainerAppbar.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/teacherHomeContainer/widgets/teacherHolidaysContainer.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/teacherHomeContainer/widgets/teacherLeavesContainer.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/teacherHomeContainer/widgets/teacherPermissionContainer.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/teacherHomeContainer/widgets/teacherTodaysTimetableContainer.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/teacherHomeContainer/widgets/teacherHomeSkeletonLoader.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/systemModulesAndPermissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherHomeContainer extends StatefulWidget {
  const TeacherHomeContainer({super.key});

  @override
  State<TeacherHomeContainer> createState() => _TeacherHomeContainerState();
}

class _TeacherHomeContainerState extends State<TeacherHomeContainer> {
  Widget _buildAppBar() {
    final profileImage =
        (context.read<AuthCubit>().getUserDetails().image ?? "");

    return HomeContainerAppbar(profileImage: profileImage);
  }

  void getHomeScreenData() {
    context.read<HomeScreenDataCubit>().getHomeScreenData(
        holidayModuleEnabled: context
            .read<StaffAllowedPermissionsAndModulesCubit>()
            .isModuleEnabled(moduleId: holidayManagementModuleId.toString()),
        staffLeaveModuleEnabled: context
            .read<StaffAllowedPermissionsAndModulesCubit>()
            .isModuleEnabled(moduleId: staffLeaveManagementModuleId.toString()),
        listTeacherTimetablePermission: false,
        isTeacher: true);
    if (context
        .read<StaffAllowedPermissionsAndModulesCubit>()
        .isModuleEnabled(moduleId: timetableManagementModuleId.toString())) {
      context
          .read<TeacherMyTimetableCubit>()
          .getTeacherMyTimetable(isRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppThemeCubit, AppThemeState>(
      builder: (context, themeState) {
        final maroonPrimary =
            AppColorPalette.getPrimaryColor(themeState.themeMode);

        return Stack(
          children: [
            BlocConsumer<StaffAllowedPermissionsAndModulesCubit,
                StaffAllowedPermissionsAndModulesState>(
              listener: (context, state) {
                if (state is StaffAllowedPermissionsAndModulesFetchSuccess) {
                  getHomeScreenData();
                }
              },
              builder: (context, state) {
                if (state is StaffAllowedPermissionsAndModulesFetchSuccess) {
                  return BlocBuilder<HomeScreenDataCubit, HomeScreenDataState>(
                    builder: (context, homeScreenDataState) {
                      if (homeScreenDataState is HomeScreenDataFetchSuccess) {
                        return RefreshIndicator(
                          color: Theme.of(context).colorScheme.primary,
                          displacement: MediaQuery.of(context).padding.top + 100,
                          onRefresh: () async {
                            getHomeScreenData();
                          },
                          child: SingleChildScrollView(
                            padding: EdgeInsets.only(
                                top: MediaQuery.of(context).padding.top + 80,
                                bottom: 100),
                            child: Column(
                              children: [
                                // TeacherHomeOverviewContainer(),
                                const SizedBox(
                                  height: 45,
                                ),
                                BlocProvider(
                                  create: (BuildContext context) {
                                    return TeacherMyTimetableCubit()
                                      ..getTeacherMyTimetable();
                                  },
                                  child:
                                      const TeacherTodaysTimetableContainer(),
                                ),
                                const TeacherPermissionContainer(),
                                const TeacherLeavesContainer(),
                                const TeacherHolidaysContainer(),
                                const SizedBox(
                                  height: 15,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      if (homeScreenDataState is HomeScreenDataFetchFailure) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.only(
                                top: MediaQuery.of(context).size.height *
                                    (0.15)),
                            child: CustomErrorWidget(
                              message: homeScreenDataState.errorMessage,
                              onRetry: () {
                                getHomeScreenData();
                              },
                              primaryColor: maroonPrimary,
                            ),
                          ),
                        );
                      }

                      // Show skeleton loader instead of circular progress indicator
                      return Stack(
                        children: [
                          const TeacherHomeSkeletonLoader(),
                          _buildAppBar(),
                        ],
                      );
                    },
                  );
                } else if (state
                    is StaffAllowedPermissionsAndModulesFetchFailure) {
                  return CustomErrorWidget(
                    message: state.errorMessage,
                    onRetry: () {
                      context
                          .read<StaffAllowedPermissionsAndModulesCubit>()
                          .getPermissionAndAllowedModules();
                    },
                    primaryColor: maroonPrimary,
                  );
                } else {
                  // Show skeleton loader for initial permission loading
                  return Stack(
                    children: [
                      const TeacherHomeSkeletonLoader(),
                      _buildAppBar(),
                    ],
                  );
                }
              },
            ),
            _buildAppBar(),
          ],
        );
      },
    );
  }
}
