import 'package:flutter/material.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notification_examples.dart';

/// Screen sederhana untuk test semua jenis notifikasi
class TestNotificationsScreen extends StatelessWidget {
  const TestNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Test Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Basic Notifications'),
            const SizedBox(height: 16),
            _buildTestButton(
              'Info Notification',
              'Test general information notification',
              const Color(0xFF3B82F6),
              Icons.info_outline,
              () => NotificationExamples.showInfoNotification(),
            ),
            const SizedBox(height: 12),
            _buildTestButton(
              'Success Notification',
              'Test success notification (approval)',
              const Color(0xFF10B981),
              Icons.check_circle_outline,
              () => NotificationExamples.showSuccessNotification(),
            ),
            const SizedBox(height: 12),
            _buildTestButton(
              'Warning Notification',
              'Test warning notification (deadline)',
              const Color(0xFFF59E0B),
              Icons.warning_amber_outlined,
              () => NotificationExamples.showWarningNotification(),
            ),
            const SizedBox(height: 12),
            _buildTestButton(
              'Error Notification',
              'Test error notification (rejection)',
              const Color(0xFFEF4444),
              Icons.error_outline,
              () => NotificationExamples.showErrorNotification(),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('School Scenarios'),
            const SizedBox(height: 16),
            _buildTestButton(
              'New Assignment',
              'Teacher receives new assignment',
              AppColorPalette.secondaryMaroon,
              Icons.assignment_outlined,
              () => NotificationExamples.showNewAssignmentNotification(),
            ),
            const SizedBox(height: 12),
            _buildTestButton(
              'Attendance Recorded',
              'Attendance successfully recorded',
              const Color(0xFF06B6D4),
              Icons.check_box_outlined,
              () => NotificationExamples.showAttendanceNotification(),
            ),
            const SizedBox(height: 12),
            _buildTestButton(
              'Exam Schedule',
              'Upcoming exam notification',
              const Color(0xFFE11D48),
              Icons.schedule_outlined,
              () => NotificationExamples.showExamNotification(),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Test All'),
            const SizedBox(height: 16),
            _buildTestButton(
              'Preview All Notifications',
              'Show all notification types with delay',
              const Color(0xFF6366F1),
              Icons.play_circle_outline,
              () => NotificationExamples.previewAllNotifications(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildTestButton(
    String title,
    String description,
    Color color,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.play_arrow,
                  color: color,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
