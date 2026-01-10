import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kheti_sahayak_app/models/expert.dart';
import 'package:kheti_sahayak_app/services/consultation_service.dart';
import 'package:kheti_sahayak_app/screens/expert/expert_profile_screen.dart';
import 'package:kheti_sahayak_app/widgets/loading_indicator.dart';
import 'package:kheti_sahayak_app/widgets/empty_state.dart';

/// Expert List Screen
/// 
/// Displays a searchable, filterable list of agricultural experts
/// with a stunning terracotta-inspired design

class ExpertListScreen extends StatefulWidget {
  const ExpertListScreen({Key? key}) : super(key: key);

  @override
  State<ExpertListScreen> createState() => _ExpertListScreenState();
}

class _ExpertListScreenState extends State<ExpertListScreen>
    with SingleTickerProviderStateMixin {
  List<Expert> _experts = [];
  List<Expert> _filteredExperts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedSpecialization = 'All';
  String _sortBy = 'rating';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _specializations = [
    'All',
    'Crop Disease',
    'Soil Health',
    'Irrigation',
    'Organic Farming',
    'Crop Planning',
    'Pest Control',
  ];

  // Design tokens - Earthy, warm palette
  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _warmOrange = Color(0xFFE65100);
  static const Color _terracotta = Color(0xFFBF360C);
  static const Color _softCream = Color(0xFFFFF8E1);
  static const Color _earthBrown = Color(0xFF5D4037);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _loadExperts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExperts() async {
    setState(() => _isLoading = true);
    
    final experts = await ConsultationService.getExperts();
    
    if (mounted) {
      setState(() {
        _experts = experts;
        _filteredExperts = experts;
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  void _filterExperts() {
    setState(() {
      _filteredExperts = _experts.where((expert) {
        final matchesSearch = _searchQuery.isEmpty ||
            expert.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            expert.specialization.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesSpecialization = _selectedSpecialization == 'All' ||
            expert.specialization == _selectedSpecialization ||
            expert.expertiseAreas.contains(_selectedSpecialization);
        
        return matchesSearch && matchesSpecialization;
      }).toList();

      // Sort
      switch (_sortBy) {
        case 'rating':
          _filteredExperts.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'price_low':
          _filteredExperts.sort((a, b) => a.consultationFee.compareTo(b.consultationFee));
          break;
        case 'price_high':
          _filteredExperts.sort((a, b) => b.consultationFee.compareTo(a.consultationFee));
          break;
        case 'experience':
          _filteredExperts.sort((a, b) => b.experienceYears.compareTo(a.experienceYears));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softCream,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildFilterChips()),
          SliverToBoxAdapter(child: _buildSortRow()),
          _buildExpertList(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: _primaryGreen,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Expert Consultants',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryGreen,
                    const Color(0xFF1B5E20),
                    _terracotta.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Pattern overlay
            Positioned(
              right: -50,
              top: -30,
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
              left: -30,
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
            // Content
            Positioned(
              left: 20,
              bottom: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.agriculture,
                        color: Colors.white.withOpacity(0.9),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Connect with Agricultural Experts',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
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
      actions: [
        IconButton(
          icon: const Icon(Icons.history, color: Colors.white),
          onPressed: () {
            Navigator.pushNamed(context, '/consultation-history');
          },
          tooltip: 'Consultation History',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _earthBrown.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          _searchQuery = value;
          _filterExperts();
        },
        decoration: InputDecoration(
          hintText: 'Search experts by name or specialty...',
          hintStyle: GoogleFonts.inter(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Icon(Icons.search, color: _primaryGreen),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[400]),
                  onPressed: () {
                    _searchController.clear();
                    _searchQuery = '';
                    _filterExperts();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _specializations.length,
        itemBuilder: (context, index) {
          final spec = _specializations[index];
          final isSelected = spec == _selectedSpecialization;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(
                spec,
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : _earthBrown,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedSpecialization = spec;
                  _filterExperts();
                });
              },
              backgroundColor: Colors.white,
              selectedColor: _primaryGreen,
              checkmarkColor: Colors.white,
              elevation: 0,
              pressElevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? _primaryGreen : Colors.grey[300]!,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_filteredExperts.length} experts found',
            style: GoogleFonts.inter(
              color: _earthBrown,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _filterExperts();
              });
            },
            itemBuilder: (context) => [
              _buildSortMenuItem('rating', 'Highest Rating', Icons.star),
              _buildSortMenuItem('price_low', 'Price: Low to High', Icons.arrow_upward),
              _buildSortMenuItem('price_high', 'Price: High to Low', Icons.arrow_downward),
              _buildSortMenuItem('experience', 'Most Experienced', Icons.work_history),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort, size: 18, color: _primaryGreen),
                  const SizedBox(width: 4),
                  Text(
                    'Sort',
                    style: GoogleFonts.inter(
                      color: _earthBrown,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: _earthBrown),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(String value, String label, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: _sortBy == value ? _primaryGreen : Colors.grey),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              color: _sortBy == value ? _primaryGreen : _earthBrown,
              fontWeight: _sortBy == value ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: LoadingIndicator(),
      );
    }

    if (_filteredExperts.isEmpty) {
      return SliverFillRemaining(
        child: EmptyStateWidget(
          type: EmptyStateType.noSearchResults,
          customTitle: 'No Experts Found',
          customSubtitle: 'Try adjusting your search or filters',
          buttonText: 'Clear Filters',
          onButtonPressed: () {
            setState(() {
              _searchController.clear();
              _searchQuery = '';
              _selectedSpecialization = 'All';
              _filterExperts();
            });
          },
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (index / _filteredExperts.length) * 0.5,
                    ((index + 1) / _filteredExperts.length) * 0.5 + 0.5,
                    curve: Curves.easeOutCubic,
                  ),
                )),
                child: _buildExpertCard(_filteredExperts[index]),
              ),
            );
          },
          childCount: _filteredExperts.length,
        ),
      ),
    );
  }

  Widget _buildExpertCard(Expert expert) {
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
          onTap: () => _navigateToProfile(expert),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image with online indicator
                    Stack(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                _primaryGreen.withOpacity(0.2),
                                _warmOrange.withOpacity(0.1),
                              ],
                            ),
                            border: Border.all(
                              color: expert.isOnline ? _primaryGreen : Colors.grey[300]!,
                              width: 3,
                            ),
                          ),
                          child: expert.imageUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    expert.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildInitialsAvatar(expert),
                                  ),
                                )
                              : _buildInitialsAvatar(expert),
                        ),
                        if (expert.isOnline)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: _primaryGreen,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Expert Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  expert.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: _earthBrown,
                                  ),
                                ),
                              ),
                              if (expert.isVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified, size: 14, color: _primaryGreen),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Verified',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _primaryGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            expert.specialization,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: _warmOrange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Rating and stats
                          Row(
                            children: [
                              _buildStatChip(
                                Icons.star_rounded,
                                expert.formattedRating,
                                Colors.amber,
                              ),
                              const SizedBox(width: 12),
                              _buildStatChip(
                                Icons.work_outline,
                                '${expert.experienceYears}y',
                                _primaryGreen,
                              ),
                              const SizedBox(width: 12),
                              _buildStatChip(
                                Icons.people_outline,
                                '${expert.totalConsultations}',
                                Colors.blue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Languages
                Row(
                  children: [
                    Icon(Icons.translate, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        expert.languagesText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Bottom row with price and button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consultation Fee',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          expert.formattedFee,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _terracotta,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _navigateToProfile(expert),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Book Now',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(Expert expert) {
    final initials = expert.name.split(' ').map((e) => e[0]).take(2).join();
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

  Widget _buildStatChip(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _earthBrown,
          ),
        ),
      ],
    );
  }

  void _navigateToProfile(Expert expert) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ExpertProfileScreen(expert: expert),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}
