import 'package:eschool_saas_staff/cubits/examStatus/examStatusCubit.dart';
import 'package:eschool_saas_staff/cubits/onlineExam/onlineExamCubit.dart';
import 'package:eschool_saas_staff/data/models/exam/onlineExam.dart';
import 'package:eschool_saas_staff/data/models/exam/studentExamStatus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:eschool_saas_staff/ui/widgets/system/no_search_results_widget.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';

class ExamStatusScreen extends StatefulWidget {
  const ExamStatusScreen({super.key});

  static Route<dynamic> route() {
    return MaterialPageRoute(builder: (_) => const ExamStatusScreen());
  }

  static Widget getRouteInstance() {
    return const ExamStatusScreen();
  }

  @override
  State<ExamStatusScreen> createState() => _ExamStatusScreenState();
}

class _ExamStatusScreenState extends State<ExamStatusScreen>
    with TickerProviderStateMixin {
  OnlineExam? selectedExam;
  late AnimationController _animationController;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomModernAppBar(
        title: 'Status Ujian',
        icon: Icons.assignment_outlined,
        fabAnimationController: _animationController,
        primaryColor: _primaryColor,
        lightColor: _glowColor,
        onBackPressed: () => Navigator.of(context).pop(),
        showAddButton: false,
        showArchiveButton: false,
        showFilterButton: false,
        showHelperButton: false,
      ),
      body: _buildAnimatedBody(),
    );
  }

  String searchQuery = "";
  String sortBy = "name"; // Default sorting
  bool isAscending = true;

  // Soft maroon color palette matching OnlineExamScreen
  static Color get _primaryColor => AppColorPalette.primaryMaroon; // Softer deep maroon
  static Color get _accentColor => AppColorPalette.secondaryMaroon; // Softer medium maroon
  static Color get _glowColor => AppColorPalette.secondaryMaroon; // Softer rich maroon

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Initial data fetch
    context.read<OnlineExamCubit>().getOnlineExams();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _refreshExamStatus() {
    if (selectedExam != null) {
      context.read<ExamStatusCubit>().getStudentExamStatus(selectedExam!.id);
    }
  }

  Future<void> _deleteStudentExamStatus(StudentExamStatus status) async {
    // Show confirmation dialog
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Hapus Status Ujian',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            content: Text(
              'Apakah Anda yakin ingin menghapus status ujian untuk ${status.name}?\nTindakan ini tidak dapat dibatalkan.',
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Batal',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[700],
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Hapus',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted) return;

    if (!confirm) return;

    // Check if exam is selected
    if (selectedExam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada ujian yang dipilih')),
      );
      return;
    }

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text('Menghapus status ujian...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    // Call delete API
    try {
      final success =
          await context.read<ExamStatusCubit>().deleteStudentExamStatus(
                selectedExam!.id,
                status.id,
              );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status ujian berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus status ujian'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Modern exam dropdown with enhanced styling
  Widget _buildExamDropdown(List<OnlineExam> exams) {
    return FadeInDown(
      delay: const Duration(milliseconds: 300),
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: _glowColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<OnlineExam>(
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: _accentColor, size: 28),
            hint: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Pilih Ujian",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
            value: selectedExam,
            items: exams.map((exam) {
              return DropdownMenuItem<OnlineExam>(
                value: exam,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    exam.title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              );
            }).toList(),
            onChanged: (exam) {
              if (exam != null) {
                HapticFeedback.lightImpact();
                setState(() {
                  selectedExam = exam;
                });
                context.read<ExamStatusCubit>().getStudentExamStatus(exam.id);
              }
            },
          ),
        ),
      ),
    );
  }

  // Enhanced search bar
  Widget _buildSearchBar() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase();
            });
          },
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.grey[800],
          ),
          decoration: InputDecoration(
            hintText: 'Cari siswa...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.grey[500],
            ),
            prefixIcon: Icon(
              Icons.search,
              color: _accentColor,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
    );
  }

  // Filter and sorting options
  Widget _buildSearchAndFilters(List<StudentExamStatus> statuses) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 12),

          // Filter options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${statuses.length} Siswa",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              InkWell(
                onTap: () {
                  _showSortOptions();
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      Text(
                        "Urutkan: ${_getSortText()}",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _accentColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: _accentColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSortText() {
    switch (sortBy) {
      case "name":
        return "Nama";
      case "time":
        return "Waktu";
      case "status":
        return "Status";
      default:
        return "Nama";
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.sort_rounded,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      "Urutkan Berdasarkan",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              _buildSortOption("Nama", "name", Icons.sort_by_alpha),
              _buildSortOption("Waktu", "time", Icons.access_time),
              _buildSortOption("Status", "status", Icons.check_circle),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, String value, IconData icon) {
    final bool isSelected = sortBy == value;

    return Material(
      color: isSelected
          ? _primaryColor.withValues(alpha: 0.08)
          : Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? _primaryColor.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected ? _primaryColor : Colors.grey[600],
            size: 20,
          ),
        ),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? _primaryColor : Colors.grey[700],
          ),
        ),
        trailing: isSelected
            ? Icon(
                isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                color: _primaryColor,
                size: 18,
              )
            : null,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            if (sortBy == value) {
              isAscending = !isAscending;
            } else {
              sortBy = value;
              isAscending = true;
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  // Modern statistics cards with animation
  Widget _buildStatisticsPanel(List<StudentExamStatus> statuses) {
    // Calculate stats
    int totalStudents = statuses.length;
    int activeStudents = statuses.where((s) => s.status == 1).length;
    int completedStudents = statuses.where((s) => s.status == 2).length;

    // New vibrant color scheme
    const Color totalColor = Color(0xFF4361EE); // Vibrant blue
    const Color activeColor = Color(0xFF06D6A0); // Fresh teal
    const Color completedColor = Color(0xFFFFBF47); // Golden yellow

    return FadeInDown(
      delay: const Duration(milliseconds: 300),
      duration: const Duration(milliseconds: 800),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            _buildStatCard(
              "Total Siswa",
              totalStudents.toString(),
              Icons.people_alt_rounded,
              totalColor,
              totalColor.withValues(alpha: 0.1),
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              "Aktif",
              activeStudents.toString(),
              Icons.play_circle_rounded,
              activeColor,
              activeColor.withValues(alpha: 0.1),
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              "Selesai",
              completedStudents.toString(),
              Icons.emoji_events_rounded,
              completedColor,
              completedColor.withValues(alpha: 0.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.7),
              color,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ]),
              child: Icon(
                icon,
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Student status list with filtering and sorting
  Widget _buildStudentStatusList(List<StudentExamStatus> statuses) {
    if (statuses.isEmpty) {
      return const _NoDataContainer(
        title: "Tidak ada data status ujian",
        message: "Belum ada siswa yang mengerjakan ujian ini",
      );
    }

    // Apply search filter
    var filteredStatuses = statuses
        .where((status) =>
            status.name.toLowerCase().contains(searchQuery) ||
            status.className.toLowerCase().contains(searchQuery))
        .toList();

    // Apply sorting
    filteredStatuses.sort((a, b) {
      int compareResult;
      switch (sortBy) {
        case "name":
          compareResult = a.name.compareTo(b.name);
          break;
        case "time":
          // Compare by start time
          final aTime = a.startTime ?? "";
          final bTime = b.startTime ?? "";
          compareResult = aTime.compareTo(bTime);
          break;
        case "status":
          compareResult = a.status.compareTo(b.status);
          break;
        default:
          compareResult = a.name.compareTo(b.name);
      }
      return isAscending ? compareResult : -compareResult;
    });

    return Column(
      children: [
        // Search dan Filter tetap ditampilkan
        _buildSearchAndFilters(statuses),
        _buildStatisticsPanel(statuses),

        // Konten berdasarkan hasil filter
        Expanded(
          child: filteredStatuses.isEmpty
              ? NoSearchResultsWidget(
                  searchQuery: searchQuery,
                  onClearSearch: () {
                    setState(() {
                      searchQuery = "";
                    });
                  },
                  primaryColor: _primaryColor,
                  accentColor: _accentColor,
                  title: 'Tidak Ada Siswa',
                  description:
                      'Tidak ditemukan siswa yang sesuai dengan pencarian Anda. Coba gunakan kata kunci yang berbeda.',
                  clearButtonText: 'Hapus Pencarian',
                  icon: Icons.people_alt_outlined,
                )
              : AnimationLimiter(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredStatuses.length,
                    itemBuilder: (context, index) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 600),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildStudentCard(filteredStatuses[index]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(StudentExamStatus status) {
    final bool isActive = status.status == 1;

    // Corrected color scheme - using golden yellow for completed
    const Color activeColor = Color(0xFF06D6A0);
    const Color completedColor = Color(0xFFFFBF47);
    final Color currentColor = isActive ? activeColor : completedColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: currentColor.withValues(alpha: 0.15),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: currentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          // Main card content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Student avatar with gradient background and 3D effect
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isActive
                              ? [
                                  const Color(0xFF06D6A0),
                                  const Color(0xFF1fc8db)
                                ]
                              : [
                                  const Color(0xFFFFBF47),
                                  const Color(0xFFf4a261)
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: currentColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(status.name),
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Student information
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  status.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildEnhancedStatusBadge(status.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.school_rounded,
                                size: 16,
                                color: currentColor.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  status.sectionName != null
                                      ? '${status.className} - ${status.sectionName}'
                                      : status.className,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Add an empty SizedBox to create vertical space
                const SizedBox(height: 40),
              ],
            ),
          ),

          // Elegant delete button as a small floating action icon
          Positioned(
            right: 16,
            bottom: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _deleteStudentExamStatus(status),
                borderRadius: BorderRadius.circular(50),
                child: Ink(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red[300]!,
                        Colors.red[700]!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        spreadRadius: 0,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return nameParts[0][0] + nameParts[1][0];
    }
    return name.length > 1 ? name.substring(0, 2) : name;
  }

  // Shimmer loading animation
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shimmer dropdown
            Container(
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
            ),

            const SizedBox(height: 20),

            // Shimmer searchbar
            Container(
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
            ),

            const SizedBox(height: 20),

            // Shimmer stat cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Shimmer student cards
            for (int i = 0; i < 5; i++) ...[
              Container(
                height: 160,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBody() {
    return RefreshIndicator(
      onRefresh: () async {
        if (selectedExam != null) {
          context
              .read<ExamStatusCubit>()
              .getStudentExamStatus(selectedExam!.id);
        } else {
          context.read<OnlineExamCubit>().getOnlineExams();
        }
      },
      color: _primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: BlocBuilder<OnlineExamCubit, OnlineExamState>(
          builder: (context, state) {
            if (state is OnlineExamSuccess) {
              if (state.exams.isEmpty) {
                return const _NoDataContainer(
                  title: "Tidak ada ujian",
                  message: "Belum ada ujian yang dibuat",
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExamDropdown(state.exams),
                  Expanded(
                    child: BlocBuilder<ExamStatusCubit, ExamStatusState>(
                      builder: (context, statusState) {
                        if (selectedExam == null) {
                          return Center(
                            child: FadeIn(
                              duration: const Duration(milliseconds: 800),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Pilih ujian untuk melihat status",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _accentColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Data siswa akan tampil setelah ujian dipilih",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (statusState is ExamStatusLoading) {
                          return _buildShimmerLoading();
                        }
                        if (statusState is ExamStatusFailure) {
                          return CustomErrorWidget(
                            message: ErrorMessageUtils.getReadableErrorMessage(
                                statusState.errorMessage),
                            onRetry: _refreshExamStatus,
                            primaryColor: _primaryColor,
                          );
                        }

                        if (statusState is ExamStatusSuccess) {
                          return _buildStudentStatusList(
                            statusState.studentExamStatuses,
                          );
                        }

                        return const SizedBox();
                      },
                    ),
                  ),
                ],
              );
            }
            if (state is OnlineExamFailure) {
              return CustomErrorWidget(
                message:
                    ErrorMessageUtils.getReadableErrorMessage(state.message),
                onRetry: () {
                  context.read<OnlineExamCubit>().getOnlineExams();
                },
                primaryColor: _primaryColor,
              );
            }

            return _buildShimmerLoading();
          },
        ),
      ),
    );
  }
}

class _NoDataContainer extends StatelessWidget {
  final String title;
  final String message;

  const _NoDataContainer({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      duration: const Duration(milliseconds: 800),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildEnhancedStatusBadge(int status) {
  final bool isActive = status == 1;
  const Color activeColor = Color(0xFF06D6A0);
  const Color completedColor =
      Color(0xFFFFBF47); // Changed to golden yellow to match statistics

  return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? [activeColor.withValues(alpha: 0.7), activeColor]
              : [completedColor.withValues(alpha: 0.7), completedColor],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? activeColor.withValues(alpha: 0.3)
                : completedColor.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.pending_rounded : Icons.check_circle_rounded,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? "Aktif" : "Selesai",
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ));
}
