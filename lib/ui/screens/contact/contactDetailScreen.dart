import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/contact/contactDetailCubit.dart';
import 'package:eschool_saas_staff/cubits/authentication/authCubit.dart';
import 'package:eschool_saas_staff/models/contact.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';

class ContactDetailScreen extends StatefulWidget {
  final int contactId;

  const ContactDetailScreen({super.key, required this.contactId});

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late TextEditingController _replyController;
  late ScrollController _scrollController;
  bool _hasReplied = false; // Track if user has sent a reply

  Color get _primaryColor => AppColorPalette.primaryMaroon;
  Color get _lightColor => AppColorPalette.secondaryMaroon;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _replyController = TextEditingController();
    _scrollController = ScrollController();

    // Load contact detail
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactDetailCubit>().getContactDetail(widget.contactId);
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          CustomModernAppBar(
            title: 'Detail Kontak',
            icon: Icons.contact_page_rounded,
            fabAnimationController: _fabAnimationController,
            primaryColor: _primaryColor,
            lightColor: _lightColor,
            onBackPressed: () {
              // Pass back true if user has sent a reply
              Get.back(result: _hasReplied);
            },
          ),
          Expanded(
            child: BlocBuilder<ContactDetailCubit, ContactDetailState>(
              builder: (context, state) {
                if (state is ContactDetailLoading) {
                  return const SkeletonContactDetailScreen();
                } else if (state is ContactDetailSuccess) {
                  return _buildContactDetail(state.contact);
                } else if (state is ContactDetailFailure) {
                  return _buildErrorState(state.errorMessage);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactDetail(Contact contact) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contact Info Card
                _buildContactInfoCard(contact),

                const SizedBox(height: 16),

                // Message Card
                _buildMessageCard(contact),

                const SizedBox(height: 16),

                // Replies Section
                if (contact.replies != null && contact.replies!.isNotEmpty)
                  _buildRepliesSection(contact.replies!),

                const SizedBox(height: 100), // Space for reply input
              ],
            ),
          ),
        ),

        // Reply Input (for staff/admin only, not teachers)
        if (!context.read<AuthCubit>().isTeacher()) _buildReplyInput(contact),
      ],
    );
  }

  Widget _buildContactInfoCard(Contact contact) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: contact.isInquiry
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  contact.isInquiry
                      ? Icons.help_outline_rounded
                      : Icons.report_problem_outlined,
                  color: contact.isInquiry ? Colors.blue : Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.typeDisplayName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: contact.isInquiry ? Colors.blue : Colors.red,
                      ),
                    ),
                    Text(
                      contact.subject,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(contact.status),
            ],
          ),

          const SizedBox(height: 20),

          // Contact Details
          _buildDetailRow(Icons.person_rounded, 'Nama', contact.name),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.email_rounded, 'Email', contact.email),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.access_time_rounded,
            'Waktu',
            _formatDateTime(contact.createdAt),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageCard(Contact contact) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.message_rounded,
                color: _primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Pesan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            contact.message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    )
        .animate(delay: 100.ms)
        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildRepliesSection(List<ContactReply> replies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.reply_rounded,
              color: _primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Balasan (${replies.length})',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...replies.asMap().entries.map((entry) {
          final index = entry.key;
          final reply = entry.value;
          return _buildReplyItem(reply, index);
        }),
      ],
    );
  }

  Widget _buildReplyItem(ContactReply reply, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.green,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply.adminName ?? 'Admin',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      _formatDateTime(reply.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reply.reply,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    )
        .animate(delay: (index * 100).ms)
        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
        .slideX(begin: 0.3, end: 0);
  }

  Widget _buildReplyInput(Contact contact) {
    // Only show for staff/admin (not for teachers) and if contact is not closed
    final isTeacher = context.read<AuthCubit>().isTeacher();

    if (isTeacher) {
      // Teachers cannot reply to contacts
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border(
            top: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Text(
              'Hanya admin/staff yang dapat membalas pesan',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (contact.isClosed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border(
            top: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_rounded, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Text(
              'Kontak ini sudah ditutup',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _replyController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tulis balasan untuk ${contact.name}...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _sendReply(contact),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    'Kirim Balasan',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                onSelected: (value) => _updateStatus(contact, value),
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: Colors.grey[600],
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'replied',
                    child: Text('Tandai Sudah Dibalas'),
                  ),
                  const PopupMenuItem(
                    value: 'closed',
                    child: Text('Tutup Kontak'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'new':
        color = Colors.orange;
        text = 'Baru';
        break;
      case 'replied':
        color = Colors.green;
        text = 'Dibalas';
        break;
      case 'closed':
        color = Colors.grey;
        text = 'Ditutup';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Terjadi Kesalahan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context
                .read<ContactDetailCubit>()
                .getContactDetail(widget.contactId),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  void _sendReply(Contact contact) async {
    final reply = _replyController.text.trim();
    if (reply.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Balasan tidak boleh kosong')),
      );
      return;
    }

    try {
      await context
          .read<ContactDetailCubit>()
          .replyToContact(contact.id, reply);
      _replyController.clear();

      // Mark that user has sent a reply
      setState(() {
        _hasReplied = true;
      });

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Balasan berhasil dikirim'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Refresh contact detail to show new reply
      if (!mounted) return;
      await context.read<ContactDetailCubit>().getContactDetail(contact.id);

      // Scroll to bottom to show the new reply
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim balasan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateStatus(Contact contact, String status) {
    context.read<ContactDetailCubit>().updateContactStatus(contact.id, status);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Status kontak berhasil diperbarui'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      // Try to parse as ISO 8601 format first
      final dateTime = DateTime.parse(dateTimeString);
      return Utils.formatDateAndTime(dateTime);
    } catch (e) {
      // If parsing fails, assume it's already formatted
      // Check if it's already in the expected format
      if (dateTimeString.contains('/')) {
        return dateTimeString;
      }
      // If not, return as is
      return dateTimeString;
    }
  }
}
