import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kheti_sahayak_app/models/consultation.dart';
import 'package:kheti_sahayak_app/services/consultation_service.dart';
import 'package:kheti_sahayak_app/screens/expert/add_review_screen.dart';
import 'package:kheti_sahayak_app/screens/expert/video_call_screen.dart';

/// Consultation Detail Screen
/// 
/// Shows complete consultation information including
/// expert details, scheduled time, issue description,
/// attached images, and for completed consultations:
/// expert notes and recommendations

class ConsultationDetailScreen extends StatefulWidget {
  final Consultation consultation;

  const ConsultationDetailScreen({Key? key, required this.consultation}) : super(key: key);

  @override
  State<ConsultationDetailScreen> createState() => _ConsultationDetailScreenState();
}

class _ConsultationDetailScreenState extends State<ConsultationDetailScreen> {
  late Consultation _consultation;

  // Design tokens
  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _warmOrange = Color(0xFFE65100);
  static const Color _terracotta = Color(0xFFBF360C);
  static const Color _softCream = Color(0xFFFFF8E1);
  static const Color _earthBrown = Color(0xFF5D4037);

  @override
  void initState() {
    super.initState();
    _consultation = widget.consultation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softCream,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildStatusBanner()),
          SliverToBoxAdapter(child: _buildExpertCard()),
          SliverToBoxAdapter(child: _buildScheduleInfo()),
          SliverToBoxAdapter(child: _buildIssueSection()),
          if (_consultation.attachedImages != null &&
              _consultation.attachedImages!.isNotEmpty)
            SliverToBoxAdapter(child: _buildAttachedImages()),
          if (_consultation.status == ConsultationStatus.completed) ...[
            SliverToBoxAdapter(child: _buildExpertNotes()),
            SliverToBoxAdapter(child: _buildRecommendations()),
          ],
          SliverToBoxAdapter(child: const SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: _primaryGreen,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Consultation Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryGreen,
                    const Color(0xFF1B5E20),
                    _terracotta.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -20,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'cancel') {
              _showCancelDialog();
            }
          },
          itemBuilder: (context) => [
            if (_consultation.canCancel)
              PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    const Icon(Icons.cancel_outlined, color: Colors.red),
                    const SizedBox(width: 12),
                    Text('Cancel Consultation', style: GoogleFonts.inter()),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    Color color;
    Color bgColor;
    IconData icon;
    String message;

    switch (_consultation.status) {
      case ConsultationStatus.pending:
        color = Colors.orange[700]!;
        bgColor = Colors.orange[50]!;
        icon = Icons.hourglass_empty;
        message = 'Waiting for confirmation from the expert';
        break;
      case ConsultationStatus.confirmed:
        final canJoin = _consultation.canJoin;
        color = canJoin ? Colors.blue : _primaryGreen;
        bgColor = canJoin ? Colors.blue[50]! : _primaryGreen.withOpacity(0.1);
        icon = canJoin ? Icons.videocam : Icons.check_circle;
        message = canJoin
            ? 'Your consultation is starting! Join now.'
            : 'Confirmed! The expert will be available at the scheduled time.';
        break;
      case ConsultationStatus.inProgress:
        color = Colors.blue;
        bgColor = Colors.blue[50]!;
        icon = Icons.phone_in_talk;
        message = 'Consultation is in progress';
        break;
      case ConsultationStatus.completed:
        color = _primaryGreen;
        bgColor = _primaryGreen.withOpacity(0.1);
        icon = Icons.check_circle;
        message = 'Consultation completed successfully';
        break;
      case ConsultationStatus.cancelled:
        color = Colors.red;
        bgColor = Colors.red[50]!;
        icon = Icons.cancel;
        message = 'This consultation was cancelled';
        break;
      case ConsultationStatus.noShow:
        color = Colors.grey;
        bgColor = Colors.grey[100]!;
        icon = Icons.error_outline;
        message = 'The consultation did not take place';
        break;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _consultation.status.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _earthBrown.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _primaryGreen.withOpacity(0.2),
                  _warmOrange.withOpacity(0.1),
                ],
              ),
              border: Border.all(color: _primaryGreen, width: 3),
            ),
            child: _consultation.expertImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      _consultation.expertImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildInitials(),
                    ),
                  )
                : _buildInitials(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _consultation.expertName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _earthBrown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _consultation.expertSpecialization,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: _warmOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _getTypeIcon(_consultation.type),
                      size: 16,
                      color: _primaryGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _consultation.type.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Fee Paid',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                '₹${_consultation.fee.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _terracotta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitials() {
    final initials = _consultation.expertName.split(' ').map((e) => e[0]).take(2).join();
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _primaryGreen,
        ),
      ),
    );
  }

  IconData _getTypeIcon(ConsultationType type) {
    switch (type) {
      case ConsultationType.video:
        return Icons.videocam;
      case ConsultationType.audio:
        return Icons.phone;
      case ConsultationType.chat:
        return Icons.chat;
    }
  }

  Widget _buildScheduleInfo() {
    return _buildSection(
      title: 'Schedule',
      icon: Icons.calendar_today,
      child: Row(
        children: [
          Expanded(
            child: _buildInfoCard(
              icon: Icons.calendar_month,
              label: 'Date',
              value: _formatDate(_consultation.scheduledAt),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCard(
              icon: Icons.access_time,
              label: 'Time',
              value: _formatTime(_consultation.scheduledAt),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCard(
              icon: Icons.timer,
              label: 'Duration',
              value: '${_consultation.durationMinutes} min',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: _primaryGreen, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _earthBrown,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIssueSection() {
    if (_consultation.issueDescription == null ||
        _consultation.issueDescription!.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Issue Description',
      icon: Icons.description,
      child: Text(
        _consultation.issueDescription!,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.grey[700],
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildAttachedImages() {
    return _buildSection(
      title: 'Attached Images',
      icon: Icons.photo_library,
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _consultation.attachedImages!.length,
          itemBuilder: (context, index) {
            return Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                image: DecorationImage(
                  image: NetworkImage(_consultation.attachedImages![index]),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpertNotes() {
    if (_consultation.expertNotes == null || _consultation.expertNotes!.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Expert Notes',
      icon: Icons.note_alt,
      iconColor: _warmOrange,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _warmOrange.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _warmOrange.withOpacity(0.2)),
        ),
        child: Text(
          _consultation.expertNotes!,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: _earthBrown,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    if (_consultation.recommendations == null ||
        _consultation.recommendations!.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Recommendations',
      icon: Icons.lightbulb_outline,
      iconColor: _primaryGreen,
      child: Column(
        children: _consultation.recommendations!.asMap().entries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _primaryGreen.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryGreen.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _earthBrown,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    Color? iconColor,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _earthBrown.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (iconColor ?? _primaryGreen).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor ?? _primaryGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _earthBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_consultation.status == ConsultationStatus.cancelled ||
        _consultation.status == ConsultationStatus.noShow) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: _buildActionButton(),
    );
  }

  Widget _buildActionButton() {
    switch (_consultation.status) {
      case ConsultationStatus.pending:
      case ConsultationStatus.confirmed:
        final canJoin = _consultation.canJoin;
        return Row(
          children: [
            if (_consultation.canCancel)
              Expanded(
                child: OutlinedButton(
                  onPressed: _showCancelDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            if (_consultation.canCancel) const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: canJoin ? _joinCall : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canJoin ? Colors.blue : Colors.grey[300],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(canJoin ? Icons.videocam : Icons.schedule, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      canJoin ? 'Join Call' : 'Waiting for Schedule',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case ConsultationStatus.completed:
        return _consultation.canReview
            ? ElevatedButton(
                onPressed: () => _navigateToReview(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Add Review',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: _primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      'Review Submitted',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: _primaryGreen,
                      ),
                    ),
                  ],
                ),
              );
      default:
        return const SizedBox.shrink();
    }
  }

  void _joinCall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(consultation: _consultation),
      ),
    );
  }

  void _navigateToReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReviewScreen(consultation: _consultation),
      ),
    );
  }

  Future<void> _showCancelDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel Consultation?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to cancel this consultation? This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Keep It',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Cancel Consultation',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ConsultationService.cancelConsultation(_consultation.id);
      if (mounted) Navigator.pop(context);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == DateTime(now.year, now.month, now.day)) {
      return 'Today';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow';
    }
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
