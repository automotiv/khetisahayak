import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kheti_sahayak_app/models/expert.dart';
import 'package:kheti_sahayak_app/screens/expert/book_consultation_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Expert Profile Screen
/// 
/// Detailed expert profile with hero header, stats, bio,
/// expertise areas, and reviews

class ExpertProfileScreen extends StatefulWidget {
  final Expert expert;

  const ExpertProfileScreen({Key? key, required this.expert}) : super(key: key);

  @override
  State<ExpertProfileScreen> createState() => _ExpertProfileScreenState();
}

class _ExpertProfileScreenState extends State<ExpertProfileScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  double _headerOpacity = 0.0;

  // Design tokens
  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _warmOrange = Color(0xFFE65100);
  static const Color _terracotta = Color(0xFFBF360C);
  static const Color _softCream = Color(0xFFFFF8E1);
  static const Color _earthBrown = Color(0xFF5D4037);
  static const Color _goldenYellow = Color(0xFFFFC107);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    setState(() {
      _headerOpacity = (offset / 200).clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softCream,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildHeroHeader(),
              SliverToBoxAdapter(child: _buildStatsRow()),
              SliverToBoxAdapter(child: _buildBioSection()),
              SliverToBoxAdapter(child: _buildExpertiseSection()),
              SliverToBoxAdapter(child: _buildLanguagesSection()),
              SliverToBoxAdapter(child: _buildAvailabilityPreview()),
              SliverToBoxAdapter(child: _buildReviewsSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          _buildAnimatedAppBar(),
          _buildBottomBookingBar(),
        ],
      ),
    );
  }

  Widget _buildAnimatedAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).padding.top + 56,
        decoration: BoxDecoration(
          color: _primaryGreen.withOpacity(_headerOpacity),
        ),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _headerOpacity < 0.5 
                        ? Colors.black.withOpacity(0.2)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Opacity(
                  opacity: _headerOpacity,
                  child: Text(
                    widget.expert.name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _headerOpacity < 0.5 
                        ? Colors.black.withOpacity(0.2)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.white),
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return SliverToBoxAdapter(
      child: Container(
        height: 320,
        child: Stack(
          children: [
            // Gradient background
            Container(
              height: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryGreen,
                    const Color(0xFF1B5E20),
                    _terracotta.withOpacity(0.8),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    right: -60,
                    top: -40,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -40,
                    bottom: 20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _warmOrange.withOpacity(0.15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Profile card
            Positioned(
              bottom: 0,
              left: 20,
              right: 20,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeOutCubic,
                )),
                child: FadeTransition(
                  opacity: _animationController,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _earthBrown.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Profile image
                        Hero(
                          tag: 'expert_${widget.expert.id}',
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  _primaryGreen.withOpacity(0.2),
                                  _warmOrange.withOpacity(0.1),
                                ],
                              ),
                              border: Border.all(
                                color: widget.expert.isOnline ? _primaryGreen : Colors.grey[300]!,
                                width: 4,
                              ),
                            ),
                            child: widget.expert.imageUrl != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: widget.expert.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => _buildInitialsAvatar(),
                                    ),
                                  )
                                : _buildInitialsAvatar(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.expert.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: _earthBrown,
                                      ),
                                    ),
                                  ),
                                  if (widget.expert.isVerified) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.verified,
                                      color: _primaryGreen,
                                      size: 22,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.expert.specialization,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: _warmOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.expert.qualification,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.expert.isOnline
                                          ? _primaryGreen.withOpacity(0.1)
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: widget.expert.isOnline
                                                ? _primaryGreen
                                                : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          widget.expert.isOnline ? 'Online' : 'Offline',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: widget.expert.isOnline
                                                ? _primaryGreen
                                                : Colors.grey,
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    final initials = widget.expert.name.split(' ').map((e) => e[0]).take(2).join();
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: _primaryGreen,
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 20),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.star_rounded,
            iconColor: _goldenYellow,
            value: widget.expert.formattedRating,
            label: 'Rating',
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.rate_review_outlined,
            iconColor: _warmOrange,
            value: '${widget.expert.reviewCount}',
            label: 'Reviews',
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.videocam_outlined,
            iconColor: _primaryGreen,
            value: '${widget.expert.totalConsultations}',
            label: 'Consults',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _earthBrown,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 60,
      width: 1,
      color: Colors.grey[200],
    );
  }

  Widget _buildBioSection() {
    if (widget.expert.bio == null || widget.expert.bio!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return _buildSection(
      title: 'About',
      icon: Icons.person_outline,
      child: Text(
        widget.expert.bio!,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.grey[700],
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildExpertiseSection() {
    return _buildSection(
      title: 'Expertise Areas',
      icon: Icons.psychology_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.expert.expertiseAreas.map((area) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryGreen.withOpacity(0.1),
                  _warmOrange.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _primaryGreen.withOpacity(0.3),
              ),
            ),
            child: Text(
              area,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _primaryGreen,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanguagesSection() {
    return _buildSection(
      title: 'Languages',
      icon: Icons.translate,
      child: Row(
        children: widget.expert.languages.map((lang) {
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language, size: 18, color: _earthBrown),
                const SizedBox(width: 8),
                Text(
                  lang,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _earthBrown,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAvailabilityPreview() {
    final now = DateTime.now();
    final nextDays = List.generate(3, (i) => now.add(Duration(days: i + 1)));
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return _buildSection(
      title: 'Availability',
      icon: Icons.calendar_today_outlined,
      trailing: TextButton(
        onPressed: () => _navigateToBooking(),
        child: Text(
          'View All',
          style: GoogleFonts.inter(
            color: _primaryGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Row(
        children: nextDays.map((day) {
          final dayName = weekdays[day.weekday - 1];
          final isToday = day.day == now.day + 1;
          
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isToday ? _primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isToday ? _primaryGreen : Colors.grey[300]!,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    dayName,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isToday ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isToday ? Colors.white : _earthBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isToday ? '5 slots' : '${3 + day.day % 4} slots',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isToday ? Colors.white70 : _primaryGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviewsSection() {
    final reviews = widget.expert.reviews ?? _getMockReviews();
    
    return _buildSection(
      title: 'Reviews',
      icon: Icons.rate_review_outlined,
      trailing: TextButton(
        onPressed: () {},
        child: Text(
          'See All',
          style: GoogleFonts.inter(
            color: _primaryGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Column(
        children: reviews.take(3).map((review) => _buildReviewCard(review)).toList(),
      ),
    );
  }

  Widget _buildReviewCard(ExpertReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _primaryGreen.withOpacity(0.1),
                child: Text(
                  review.farmerName[0],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: _primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.farmerName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: _earthBrown,
                      ),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: _goldenYellow,
                    size: 18,
                  );
                }),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                  color: _primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primaryGreen, size: 20),
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
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomBookingBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
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
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Consultation Fee',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  widget.expert.formattedFee,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _terracotta,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _navigateToBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Book Consultation',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookConsultationScreen(expert: widget.expert),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  List<ExpertReview> _getMockReviews() {
    return [
      ExpertReview(
        id: 'r1',
        farmerName: 'Ramesh Kumar',
        rating: 5,
        comment: 'Excellent advice on treating my wheat crop disease. The doctor was very patient and explained everything clearly.',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      ExpertReview(
        id: 'r2',
        farmerName: 'Suresh Patel',
        rating: 4,
        comment: 'Very helpful consultation. Got good recommendations for improving soil health.',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      ExpertReview(
        id: 'r3',
        farmerName: 'Lakshmi Devi',
        rating: 5,
        comment: 'Best agricultural expert I have consulted. My crop yield improved significantly after following the advice.',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ];
  }
}
