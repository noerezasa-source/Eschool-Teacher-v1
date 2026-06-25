import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';

class RecapAttendanceContainer extends StatelessWidget {
  final List<ClassSection> classSections;
  final Function(ClassSection, int) onDownload;
  final int selectedYear;
  final int? selectedMonth;
  final String? email;
  final int? schoolId; // Tambahkan parameter schoolId

  const RecapAttendanceContainer({
    super.key,
    required this.classSections,
    required this.onDownload,
    required this.selectedYear,
    this.selectedMonth,
    this.email,
    this.schoolId, // Tambahkan ini
  });

  // Update the _previewRecap method
  void _previewRecap(
      BuildContext context, ClassSection section, int month) async {
    // Check if class is in PKL
    if (section.pkl == 1) {
      _showPKLNotification(context, section.name ?? 'Kelas ini');
      return;
    }

    if (schoolId == null) {
      debugPrint('School ID is null');
      return;
    }

    final url = Uri.parse('https://eschool.ac.id/recap-download'
        '?school_id=$schoolId' // Gunakan schoolId yang diterima dari parameter
        '&class_id=${section.classDetails?.id}'
        '&class_section_id=${section.id}'
        '&month=$month'
        '&year=$selectedYear'
        '&email=${Uri.encodeComponent(email ?? "")}'
        '&gm=naowndoianwodinaiwondaoiwnd'
        '&download=false');

    debugPrint('Preview URL: $url'); // Debug log

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.inAppWebView);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching preview URL: $e');
    }
  }

  // Add this new method to show PKL notification
  void _showPKLNotification(BuildContext context, String className) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Kelas Sedang PKL',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            '$className sedang melaksanakan PKL (Praktik Kerja Lapangan). '
            'Rekap absensi tidak tersedia selama periode PKL.',
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Tutup',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final availableMonths = selectedYear < now.year
        ? 12
        : selectedYear > now.year
            ? 0
            : now.month;

    if (availableMonths == 0) {
      return FadeIn(
        duration: const Duration(milliseconds: 800),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColorPalette.warmBeige,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColorPalette.primaryMaroon.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: AppColorPalette.primaryMaroon.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 20),
                Text(
                  'Data Rekap Belum Tersedia',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColorPalette.primaryMaroon,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tahun $selectedYear',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColorPalette.secondaryMaroon,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show message if no month is selected
    if (selectedMonth == null) {
      return FadeIn(
        duration: const Duration(milliseconds: 800),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColorPalette.warmBeige,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColorPalette.primaryMaroon.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  size: 64,
                  color: AppColorPalette.primaryMaroon.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 20),
                Text(
                  'Pilih Bulan dan Tahun',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColorPalette.primaryMaroon,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Silakan pilih bulan dan tahun untuk melihat rekap absensi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColorPalette.secondaryMaroon,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Check if selected month is available
    if (selectedMonth! > availableMonths) {
      return FadeIn(
        duration: const Duration(milliseconds: 800),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColorPalette.warmBeige,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColorPalette.primaryMaroon.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.orange[700],
                ),
                const SizedBox(height: 20),
                Text(
                  'Data Belum Tersedia',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColorPalette.primaryMaroon,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rekap absensi untuk ${_getMonthName(selectedMonth!)} $selectedYear belum tersedia',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColorPalette.secondaryMaroon,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        color: AppColorPalette.warmBeige.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            // Show only the selected month
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColorPalette.primaryMaroon.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMonthHeader(
                        selectedMonth! - 1), // Convert to 0-based index
                    _buildClassList(selectedMonth! - 1,
                        context), // Convert to 0-based index
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader(int monthIndex) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorPalette.primaryMaroon,
            AppColorPalette.secondaryMaroon,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getMonthName(monthIndex + 1),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$selectedYear',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassList(int monthIndex, BuildContext context) {
    // Tampilkan semua kelas yang tersedia
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header kolom diubah menjadi lebih sesuai dengan layout baru
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kelas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColorPalette.primaryMaroon,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Divider(
            color: AppColorPalette.lightMaroon,
            thickness: 1,
            height: 32,
          ),
          // Menampilkan daftar kelas yang kosong
          if (classSections.isEmpty)
            _buildNoClassesMessage()
          // Menampilkan semua kelas yang tersedia
          else
            ...classSections
                .map((section) => _buildClassItem(section, monthIndex, context))
                ,
        ],
      ),
    );
  }

  // Widget untuk menampilkan pesan ketika tidak ada kelas
  Widget _buildNoClassesMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 40,
              color: Colors.orange[700],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada kelas ditemukan',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassItem(
      ClassSection section, int monthIndex, BuildContext context) {
    return SlideInRight(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: section.pkl == 1
              ? Colors.grey.shade100
              : AppColorPalette.warmBeige.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: section.pkl == 1
                ? Colors.grey.shade300
                : AppColorPalette.lightMaroon,
            width: 1,
          ),
        ),
        // Gunakan Column untuk memisahkan nama kelas dan tombol aksi
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian nama kelas
            Row(
              children: [
                Icon(
                  section.pkl == 1
                      ? Icons.business_center_rounded
                      : Icons.school_rounded,
                  color: section.pkl == 1
                      ? Colors.grey
                      : AppColorPalette.secondaryMaroon,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.name ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: section.pkl == 1
                          ? Colors.grey.shade700
                          : AppColorPalette.primaryMaroon,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),

            // Separator
            const SizedBox(height: 16),

            // Bagian tombol aksi dalam row terpisah
            Align(
              alignment: Alignment.centerRight,
              child: _buildActionButtons(section, monthIndex, context),
            ),
          ],
        ),
      ),
    );
  }

  // Update the existing _buildActionButtons method with new styling
  Widget _buildActionButtons(
      ClassSection section, int monthIndex, BuildContext context) {
    final bool isPKL = section.pkl == 1;

    return Wrap(
      spacing: 8, // Jarak horizontal antara tombol
      runSpacing: 8, // Jarak vertikal jika tombol wrap ke baris baru
      children: [
        _buildActionButton(
          icon:
              isPKL ? Icons.business_center_rounded : Icons.visibility_rounded,
          label: 'Preview',
          onPressed: () => _previewRecap(context, section, monthIndex + 1),
          isPrimary: true,
          isPKL: isPKL,
        ),
        _buildActionButton(
          icon: isPKL ? Icons.business_center_rounded : Icons.download_rounded,
          label: 'Unduh',
          onPressed: () => isPKL
              ? _showPKLNotification(context, section.name ?? 'Kelas ini')
              : onDownload(section, monthIndex + 1),
          isPrimary: false,
          isPKL: isPKL,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
    required bool isPKL,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isPKL
                ? Colors.grey.shade300
                : isPrimary
                    ? AppColorPalette.primaryMaroon
                    : AppColorPalette.secondaryMaroon,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isPKL
                    ? Colors.grey.withValues(alpha: 0.2)
                    : AppColorPalette.primaryMaroon.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}
