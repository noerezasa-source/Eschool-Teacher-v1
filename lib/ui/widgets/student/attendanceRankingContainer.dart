import 'package:eschool_saas_staff/data/models/student/attendanceRanking.dart';
import 'package:eschool_saas_staff/ui/widgets/student/attendenceRankingItemContainer.dart';
import 'package:flutter/material.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';

class AttendanceRankingContainer extends StatefulWidget {
  final AttendanceRanking attendanceRankings;
  final bool showAllStudents;
  final String searchQuery;

  const AttendanceRankingContainer({
    super.key,
    required this.attendanceRankings,
    required this.showAllStudents,
    this.searchQuery = "",
  });

  @override
  State<AttendanceRankingContainer> createState() =>
      _AttendanceRankingContainerState();
}

class BackgroundPainter extends CustomPainter {
  final Color color;

  BackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Create a pattern of circles or dots
    for (double x = 0; x < size.width; x += 20) {
      for (double y = 0; y < size.height; y += 20) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _AttendanceRankingContainerState extends State<AttendanceRankingContainer>
    with SingleTickerProviderStateMixin {
  bool _showWarning = true;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    // Memulai animasi segera setelah widget dibuat
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print received data
    debugPrint("AttendanceRankingContainer DEBUG:");
    debugPrint("  - showAllStudents: ${widget.showAllStudents}");
    debugPrint(
        "  - allStudents count: ${widget.attendanceRankings.allStudents?.length ?? 0}");
    debugPrint(
        "  - groupedByClassLevel count: ${widget.attendanceRankings.groupedByClassLevel?.length ?? 0}");
    debugPrint("  - searchQuery: '${widget.searchQuery}'");

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Background Pattern
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundPainter(
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
            // Main Content
            NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                // Memastikan konten tetap terlihat saat di-scroll
                if (scrollNotification is ScrollStartNotification) {
                  if (!_animationController.isCompleted) {
                    _animationController.forward();
                  }
                }
                return true;
              },
              child: Container(
                margin: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 16),
                      _buildLeaderboard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorPalette.primaryMaroon,
            AppColorPalette.secondaryMaroon,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        boxShadow: [
          BoxShadow(
            color: AppColorPalette.primaryMaroon.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Icon
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.school,
              size: 100,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),

          // Content
          Column(
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.emoji_events_rounded,
                            color: Colors.amber, size: 24),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Data Ketidakhadiran Siswa",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "Berdasarkan tingkat kehadiran siswa",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 8),
                    _buildTopThreeItem(
                        widget.showAllStudents
                            ? ((widget.attendanceRankings.allStudents?.length ??
                                        0) >
                                    1
                                ? widget.attendanceRankings.allStudents![1]
                                : null)
                            : _getTopStudent(2),
                        2),
                    _buildTopThreeItem(
                        widget.showAllStudents
                            ? ((widget.attendanceRankings.allStudents
                                        ?.isNotEmpty ??
                                    false)
                                ? widget.attendanceRankings.allStudents![0]
                                : null)
                            : _getTopStudent(1),
                        1),
                    _buildTopThreeItem(
                        widget.showAllStudents
                            ? ((widget.attendanceRankings.allStudents?.length ??
                                        0) >
                                    2
                                ? widget.attendanceRankings.allStudents![2]
                                : null)
                            : _getTopStudent(3),
                        3),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: _showWarning
                    ? Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "⚠️ Peringkat 1-3 adalah siswa dengan pelanggaran tertinggi!",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white, size: 18),
                              padding: const EdgeInsets.all(0),
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  _showWarning = false;
                                });
                              },
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  dynamic _getTopStudent(int position) {
    return widget.attendanceRankings.groupedByClassLevel
        ?.expand((e) => e.topStudents ?? [])
        .where((student) => student.rank == position)
        .firstOrNull;
  }

  Widget _buildTopThreeItem(dynamic student, int position) {
    final scale = position == 1 ? 1.1 : 1.0;
    final verticalPadding = position == 1 ? 0.0 : 20.0;

    return Container(
      width: MediaQuery.of(context).size.width * 0.27, // Slightly wider
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: verticalPadding),
      child: Transform.scale(
        scale: scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Position indicator circle
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _getPositionColors(position),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  "#$position",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: position == 1 ? 20 : 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Rank number

            // Student name - improved layout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              constraints: const BoxConstraints(minHeight: 36),
              child: SingleChildScrollView(
                child: Text(
                  student?.studentName ?? '-',
                  style: TextStyle(
                    color: position <= 3
                        ? const Color.fromARGB(255, 255, 255, 255)
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: position == 1 ? 12 : 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Alpha count - improved layout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                'Alpha: ${student?.alphaCount ?? 0}',
                style: const TextStyle(
                  color: Color.fromARGB(255, 228, 227, 227),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getPositionColors(int position) {
    switch (position) {
      case 1:
        return [
          Colors.red.shade800, // Merah tua (peringatan)
          Colors.red.shade600,
        ];
      case 2:
        return [
          Colors.deepOrange.shade800, // Oranye tua (waspada)
          Colors.deepOrange.shade600,
        ];
      case 3:
        return [
          Colors.orange.shade800, // Oranye terang (waspada)
          Colors.orange.shade600,
        ];
      default:
        return [
          const Color(0xFFE2E8F0),
          const Color(0xFFCBD5E1),
        ];
    }
  }

  Widget _buildLeaderboard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.showAllStudents
            ? _buildAllStudentsList()
            : _buildTopStudentsList(),
      ),
    );
  }

  List<Widget> _buildAllStudentsList() {
    return (widget.attendanceRankings.allStudents ?? [])
        .where((student) => (student.studentName?.toLowerCase() ?? '')
            .contains(widget.searchQuery.toLowerCase()))
        .map((student) {
      return AttendanceRankingItemContainer(
        topStudents: TopStudents(
          rank: widget.attendanceRankings.allStudents!.indexOf(student) + 1,
          className: student.className,
          studentName: student.studentName,
          studentId: student.studentId,
          jumlahJpSum: student.jumlahJpSum,
          point: student.point,
          alphaCount: student.alphaCount,
        ),
        index: widget.attendanceRankings.allStudents!.indexOf(student),
      );
    }).toList();
  }

  List<Widget> _buildTopStudentsList() {
    return (widget.attendanceRankings.groupedByClassLevel ?? [])
        .expand((classLevel) => (classLevel.topStudents ?? []))
        .where((student) => student.studentName
            .toLowerCase()
            .contains(widget.searchQuery.toLowerCase()))
        .map((student) => AttendanceRankingItemContainer(
              topStudents: student,
              index: student.rank ?? 0,
            ))
        .toList();
  }
}

