import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kheti_sahayak_app/models/consultation.dart';
import 'package:kheti_sahayak_app/services/consultation_service.dart';
import 'package:kheti_sahayak_app/screens/expert/consultation_detail_screen.dart';
import 'package:kheti_sahayak_app/widgets/loading_indicator.dart';
import 'package:kheti_sahayak_app/widgets/empty_state.dart';

/// Consultation List Screen
/// 
/// Displays user's consultations organized by status tabs:
/// Upcoming, Completed, Cancelled

class ConsultationListScreen extends StatefulWidget {
  const ConsultationListScreen({Key? key}) : super(key: key);

  @override
  State<ConsultationListScreen> createState() => _ConsultationListScreenState();
}

class _ConsultationListScreenState extends State<ConsultationListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Consultation> _allConsultations = [];
  bool _isLoading = true;

  // Design tokens
  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _warmOrange = Color(0xFFE65100);
  static const Color _terracotta = Color(0xFFBF360C);
  static const Color _softCream = Color(0xFFFFF8E1);
  static const Color _earthBrown = Color(0xFF5D4037);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadConsultations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConsultations() async {
    setState(() => _isLoading = true);
    
    final consultations = await ConsultationService.getMyConsultations();
    
    if (mounted) {
      setState(() {
        _allConsultations = consultations;
        _isLoading = false;
      });
    }
  }

  List<Consultation> get _upcomingConsultations => _allConsultations
      .where((c) => c.status == ConsultationStatus.pending || 
                    c.status == ConsultationStatus.confirmed)
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<Consultation> get _completedConsultations => _allConsultations
      .where((c) => c.status == ConsultationStatus.completed)
      .toList()
    ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

  List<Consultation> get _cancelledConsultations => _allConsultations
      .where((c) => c.status == ConsultationStatus.cancelled || 
                    c.status == ConsultationStatus.noShow)
      .toList()
    ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softCream,
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        elevation: 0,
        title: Text(
          'My Consultations',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: _primaryGreen,
              unselectedLabelColor: Colors.white,
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: 'Upcoming (${_upcomingConsultations.length})'),
                Tab(text: 'Completed (${_completedConsultations.length})'),
                Tab(text: 'Cancelled (${_cancelledConsultations.length})'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildConsultationsList(_upcomingConsultations, 'upcoming'),
                _buildConsultationsList(_completedConsultations, 'completed'),
                _buildConsultationsList(_cancelledConsultations, 'cancelled'),
              ],
            ),
    );
  }

  Widget _buildConsultationsList(List<Consultation> consultations, String type) {
    if (consultations.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: _loadConsultations,
      color: _primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: consultations.length,
        itemBuilder: (context, index) {
          return _buildConsultationCard(consultations[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    String title;
    String subtitle;
    IconData icon;
    Color color;

    switch (type) {
      case 'upcoming':
        title = 'No Upcoming Consultations';
        subtitle = 'Book a consultation with an expert to get started';
        icon = Icons.calendar_today_outlined;
        color = _primaryGreen;
        break;
      case 'completed':
        title = 'No Completed Consultations';
        subtitle = 'Your completed consultations will appear here';
        icon = Icons.check_circle_outline;
        color = Colors.blue;
        break;
      case 'cancelled':
        title = 'No Cancelled Consultations';
        subtitle = 'Cancelled consultations will be shown here';
        icon = Icons.cancel_outlined;
        color = Colors.grey;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _earthBrown,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (type == 'upcoming') ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Find an Expert',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationCard(Consultation consultation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDetail(consultation),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with expert info and status
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            _primaryGreen.withOpacity(0.2),
                            _warmOrange.withOpacity(0.1),
                          ],
                        ),
                        border: Border.all(color: _primaryGreen, width: 2),
                      ),
                      child: consultation.expertImageUrl != null
                          ? ClipOval(
                              child: Image.network(
                                consultation.expertImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildInitials(consultation.expertName),
                              ),
                            )
                          : _buildInitials(consultation.expertName),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            consultation.expertName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _earthBrown,
                            ),
                          ),
                          Text(
                            consultation.expertSpecialization,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: _warmOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(consultation.status),
                  ],
                ),
                const SizedBox(height: 16),
                // Date, time, and type
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildInfoItem(
                        Icons.calendar_today,
                        _formatDate(consultation.scheduledAt),
                      ),
                      const SizedBox(width: 16),
                      _buildInfoItem(
                        Icons.access_time,
                        _formatTime(consultation.scheduledAt),
                      ),
                      const SizedBox(width: 16),
                      _buildInfoItem(
                        _getTypeIcon(consultation.type),
                        consultation.type.displayName,
                      ),
                    ],
                  ),
                ),
                // Issue description preview
                if (consultation.issueDescription != null &&
                    consultation.issueDescription!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    consultation.issueDescription!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Action buttons based on status
                const SizedBox(height: 16),
                _buildActionButtons(consultation),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitials(String name) {
    final initials = name.split(' ').map((e) => e[0]).take(2).join();
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _primaryGreen,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ConsultationStatus status) {
    Color color;
    Color bgColor;
    String text = status.displayName;

    switch (status) {
      case ConsultationStatus.pending:
        color = Colors.orange;
        bgColor = Colors.orange.withOpacity(0.1);
        break;
      case ConsultationStatus.confirmed:
        color = _primaryGreen;
        bgColor = _primaryGreen.withOpacity(0.1);
        break;
      case ConsultationStatus.inProgress:
        color = Colors.blue;
        bgColor = Colors.blue.withOpacity(0.1);
        break;
      case ConsultationStatus.completed:
        color = _primaryGreen;
        bgColor = _primaryGreen.withOpacity(0.1);
        break;
      case ConsultationStatus.cancelled:
        color = Colors.red;
        bgColor = Colors.red.withOpacity(0.1);
        break;
      case ConsultationStatus.noShow:
        color = Colors.grey;
        bgColor = Colors.grey.withOpacity(0.1);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _primaryGreen),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _earthBrown,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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

  Widget _buildActionButtons(Consultation consultation) {
    switch (consultation.status) {
      case ConsultationStatus.pending:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _cancelConsultation(consultation),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _navigateToDetail(consultation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'View Details',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      case ConsultationStatus.confirmed:
        final canJoin = consultation.canJoin;
        return Row(
          children: [
            if (consultation.canCancel)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rescheduleConsultation(consultation),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _warmOrange,
                    side: BorderSide(color: _warmOrange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Reschedule',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            if (consultation.canCancel) const SizedBox(width: 12),
            Expanded(
              flex: canJoin ? 2 : 1,
              child: ElevatedButton(
                onPressed: canJoin
                    ? () => _joinCall(consultation)
                    : () => _navigateToDetail(consultation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canJoin ? Colors.blue : _primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (canJoin) ...[
                      const Icon(Icons.videocam, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      canJoin ? 'Join Now' : 'View Details',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case ConsultationStatus.completed:
        return Row(
          children: [
            if (consultation.canReview)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _addReview(consultation),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber[700],
                    side: BorderSide(color: Colors.amber[700]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Add Review',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            if (consultation.canReview) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _navigateToDetail(consultation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'View Notes',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      default:
        return ElevatedButton(
          onPressed: () => _navigateToDetail(consultation),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'View Details',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        );
    }
  }

  void _navigateToDetail(Consultation consultation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsultationDetailScreen(consultation: consultation),
      ),
    );
  }

  Future<void> _cancelConsultation(Consultation consultation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel Consultation?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to cancel this consultation with ${consultation.expertName}?',
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
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ConsultationService.cancelConsultation(consultation.id);
      _loadConsultations();
    }
  }

  void _rescheduleConsultation(Consultation consultation) {
    // TODO: Navigate to reschedule screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reschedule feature coming soon', style: GoogleFonts.inter()),
        backgroundColor: _warmOrange,
      ),
    );
  }

  void _joinCall(Consultation consultation) {
    Navigator.pushNamed(context, '/video-call', arguments: consultation);
  }

  void _addReview(Consultation consultation) {
    Navigator.pushNamed(context, '/add-review', arguments: consultation);
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
    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
