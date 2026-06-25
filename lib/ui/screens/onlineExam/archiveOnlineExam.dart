import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/cubits/onlineExam/onlineExamCubit.dart';
import 'package:eschool_saas_staff/data/models/exam/onlineExam.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:eschool_saas_staff/ui/widgets/system/errorContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';

class ArchiveOnlineExam extends StatefulWidget {
  const ArchiveOnlineExam({super.key});

  @override
  State<ArchiveOnlineExam> createState() => _ArchiveOnlineExamState();
}

class _ArchiveOnlineExamState extends State<ArchiveOnlineExam>
    with TickerProviderStateMixin {
  late final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  DateTime? _startDate; // State untuk filter tanggal
  DateTime? _endDate; // State untuk filter tanggal
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomModernAppBar(
        title: 'Arsip Ujian Online',
        icon: Icons.archive,
        fabAnimationController: _animationController,
        primaryColor: _primaryColor,
        lightColor: _accentColor,
        onBackPressed: () => Navigator.of(context).pop(),
        showFilterButton: true,
        onFilterPressed: () => _showFilterBottomSheet(context),
      ),
      body: _buildBody(),
    );
  }

  // Add these controller declarations
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Theme colors - matching onlineExamScreen
  static Color get _primaryColor => AppColorPalette.primaryMaroon; // Softer deep maroon
  static Color get _accentColor => AppColorPalette.secondaryMaroon; // Softer medium maroon
  @override
  void initState() {
    super.initState();
    _loadArchivedExams();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();

    // Start the animation loop for the app bar effect
    _animationController.repeat(reverse: true);

    // Add pulse animation controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadArchivedExams() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      context.read<OnlineExamCubit>().getArchivedExams();
    }
  }

  void _showFilterBottomSheet(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Judul
                  Text(
                    'Filter Ujian Arsip',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColorPalette.primaryMaroon,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Input Tanggal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: modalContext,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setModalState(() {
                                _startDate = picked;
                                _loadArchivedExams();
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _startDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_startDate!)
                                  : 'Dari',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[800]),
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '-',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: modalContext,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setModalState(() {
                                _endDate = picked;
                                _loadArchivedExams();
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _endDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                  : 'Sampai',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[800]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter mata pelajaran (jika diperlukan)
                  // ...

                  // Tombol Reset Filter
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        setModalState(() {
                          _startDate = null;
                          _endDate = null;
                        });
                        _loadArchivedExams();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorPalette.primaryMaroon,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text(
                        'Reset Filter',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _isSearching = _searchController.text.isNotEmpty;
        });
        await _loadArchivedExams();
      },
      child: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildExamList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return FadeInDown(
      delay: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _isSearching = value.isNotEmpty;
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari ujian arsip...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamList() {
    return BlocBuilder<OnlineExamCubit, OnlineExamState>(
      builder: (context, state) {
        if (state is OnlineExamLoading) {
          return _buildArchiveExamSkeleton();
        }
        if (state is OnlineExamFailure) {
          return Center(
            child: ErrorContainer(
              errorMessage:
                  "Tidak dapat terhubung ke server, mohon periksa koneksi internet anda dan coba lagi",
              onTapRetry: () {
                _loadArchivedExams();
              },
            ),
          );
        }
        if (state is OnlineExamSuccess) {
          final archivedExams = state.archivedExams;

          // Filter berdasarkan pencarian
          final filteredExams = _searchController.text.isEmpty
              ? archivedExams
              : archivedExams
                  .where((exam) => exam.title
                      .toLowerCase()
                      .contains(_searchController.text.toLowerCase()))
                  .toList();

          // Filter berdasarkan tanggal jika ada
          final dateFilteredExams = filteredExams.where((exam) {
            if (_startDate != null && _endDate != null) {
              return exam.startDate.isAfter(_startDate!) &&
                  exam.startDate
                      .isBefore(_endDate!.add(const Duration(days: 1)));
            } else if (_startDate != null) {
              return exam.startDate.isAfter(_startDate!);
            } else if (_endDate != null) {
              return exam.startDate
                  .isBefore(_endDate!.add(const Duration(days: 1)));
            }
            return true;
          }).toList()
            ..sort((a, b) =>
                b.startDate.compareTo(a.startDate)); // Sort terbaru dulu

          if (dateFilteredExams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSearching ? Icons.search_off : Icons.archive_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isSearching
                        ? 'Tidak ada ujian arsip yang cocok'
                        : 'Belum ada ujian yang diarsipkan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: dateFilteredExams.length,
            itemBuilder: (context, index) {
              final exam = dateFilteredExams[index];
              return _buildExamCard(exam);
            },
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildExamCard(OnlineExam exam) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          exam.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColorPalette.primaryMaroon,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Arsip',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Menu popup
                          PopupMenuButton<String>(
                            icon:
                                Icon(Icons.more_vert, color: Colors.grey[700]),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (value) {
                              if (value == 'restore') {
                                _showRestoreConfirmation(exam);
                              } else if (value == 'delete') {
                                _showPermanentDeleteConfirmation(exam);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem<String>(
                                value: 'restore',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.restore,
                                        color: Colors.blue, size: 18),
                                    SizedBox(width: 8),
                                    Text('Pulihkan'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.delete_forever,
                                        color: Colors.red, size: 18),
                                    SizedBox(width: 8),
                                    Text('Hapus'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exam.subjectName,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildInfoRow(
                          Icons.calendar_today,
                          DateFormat('dd MMMM yyyy HH:mm')
                              .format(exam.startDate),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: _buildInfoRow(
                            Icons.timer, '${exam.duration} menit'),
                      ),
                    ],
                  ),
                  // Hapus deretan tombol di sini
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamCardSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title skeleton
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 18,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 14,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Archive badge and menu skeleton
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Info rows skeleton
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            height: 13,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            height: 13,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArchiveExamSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return _buildExamCardSkeleton();
      },
    );
  }

  void _showRestoreConfirmation(OnlineExam exam) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restore_rounded,
                  color: Colors.blue[600],
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pulihkan Ujian',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Apakah Anda yakin ingin memulihkan ujian ini?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // 1. Tutup dialog pertanyaan awal terlebih dahulu
                        Get.back();
                        
                        try {
                          // Show modern loading dialog
                          Get.dialog(
                            Material(
                              color: Colors.black.withValues(alpha: 0.5),
                              child: Center(
                                child: Container(
                                  width: 320,
                                  padding: const EdgeInsets.all(40),
                                  margin: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.blue[50]!,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(32),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withValues(alpha: 0.3),
                                        blurRadius: 30,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 15),
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        blurRadius: 10,
                                        spreadRadius: -5,
                                        offset: const Offset(0, -5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue[400]!,
                                              Colors.blue[600]!,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.withValues(alpha: 0.4),
                                              blurRadius: 20,
                                              spreadRadius: 0,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SizedBox(
                                              width: 80,
                                              height: 80,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.white.withValues(alpha: 0.8),
                                                ),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.restore_rounded,
                                              color: Colors.white,
                                              size: 36,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: [
                                            Colors.blue[700]!,
                                            Colors.blue[500]!
                                          ],
                                        ).createShader(bounds),
                                        child: const Text(
                                          'Memulihkan Ujian',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Sedang memproses pemulihan data ujian',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Mohon tunggu sebentar...',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(
                                          3,
                                          (index) => Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 4),
                                            child: AnimatedBuilder(
                                              animation: _pulseAnimation,
                                              builder: (context, child) {
                                                return Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue[400]!.withValues(
                                                      alpha: 0.3 + 0.7 * (((_pulseAnimation.value + (index * 0.3)) % 1.0)),
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            barrierDismissible: false,
                          );

                          // Trigger API restore ke server
                          await context
                              .read<OnlineExamCubit>()
                              .restoreOnlineExam(exam.id);

                          if (!mounted) return;

                          // 2. Tutup dialog loading jika masih terbuka
                          if (Get.isDialogOpen ?? false) {
                            Get.back(); 
                          }

                          // 3. Tampilkan Snack sukses menggunakan ScaffoldMessenger (Lebih Aman dari Crash Overlay)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ujian berhasil dipulihkan!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );

                          // 4. Baru kembalikan rute ke halaman utama dengan membawa data result
                          Get.back(result: {
                            'action': 'restored',
                            'examId': exam.id,
                            'examTitle': exam.title,
                            'exam': exam,
                          });

                        } catch (e) {
                          if (Get.isDialogOpen ?? false) {
                            Get.back(); // Tutup loading jika gagal
                          }

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal memulihkan ujian: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Pulihkan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showPermanentDeleteConfirmation(OnlineExam exam) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.red[600],
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Hapus Permanen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Apakah Anda yakin ingin menghapus ujian ini secara permanen?\nTindakan ini tidak dapat dibatalkan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          Get.back(); // Tutup dialog konfirmasi                          // Show modern delete loading dialog
                          Get.dialog(
                            Material(
                              color: Colors.black.withValues(alpha: 0.5),
                              child: Center(
                                child: Container(
                                  width: 320,
                                  padding: const EdgeInsets.all(40),
                                  margin: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.red[50]!,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(32),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.red.withValues(alpha: 0.3),
                                        blurRadius: 30,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 15),
                                      ),
                                      BoxShadow(
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                        blurRadius: 10,
                                        spreadRadius: -5,
                                        offset: const Offset(0, -5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Animated Icon Container
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.red[400]!,
                                              Colors.red[600]!,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 20,
                                              spreadRadius: 0,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Rotating outer ring
                                            SizedBox(
                                              width: 80,
                                              height: 80,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  Colors.white
                                                      .withValues(alpha: 0.8),
                                                ),
                                              ),
                                            ),
                                            // Static icon
                                            const Icon(
                                              Icons.delete_forever_rounded,
                                              color: Colors.white,
                                              size: 36,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 32),

                                      // Title with gradient text effect
                                      ShaderMask(
                                        shaderCallback: (bounds) =>
                                            LinearGradient(
                                          colors: [
                                            Colors.red[700]!,
                                            Colors.red[500]!
                                          ],
                                        ).createShader(bounds),
                                        child: const Text(
                                          'Menghapus Ujian',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Subtitle with better styling
                                      Text(
                                        'Sedang menghapus data ujian secara permanen',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Mohon tunggu sebentar...',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),

                                      // Progress dots animation
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(
                                          3,
                                          (index) => Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 4),
                                            child: AnimatedBuilder(
                                              animation: _pulseAnimation,
                                              builder: (context, child) {
                                                return Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: Colors.red[400]!.withValues(
                                                        alpha: 0.3 +
                                                            0.7 *
                                                                (((_pulseAnimation
                                                                            .value +
                                                                        (index *
                                                                            0.3)) %
                                                                    1.0))),
                                                    shape: BoxShape.circle,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            barrierDismissible: false,
                          );

                          await context
                              .read<OnlineExamCubit>()
                              .deleteOnlineExam(
                                examId: exam.id,
                                mode: 'permanent',
                              );

                          if (!mounted) {
                            Get.back();
                            return;
                          }

                          // Tutup loading
                          Get.back();

                          // Refresh exam list is removed to preserve optimistic update
                          // _loadArchivedExams();

                          // Show auto-dismissing success snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.white),
                                    SizedBox(width: 12),
                                    Text(
                                      'Ujian berhasil dihapus!',
                                      style: TextStyle(
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
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 4,
                            ),
                          );
                        } catch (e) {
                          // Tutup loading jika masih terbuka
                          if (Get.isDialogOpen ?? false) {
                            Get.back();
                          }

                          Get.snackbar(
                            'Gagal',
                            e.toString(),
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Hapus',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
