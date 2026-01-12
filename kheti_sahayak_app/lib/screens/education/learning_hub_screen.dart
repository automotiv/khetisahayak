import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kheti_sahayak_app/models/learning_module.dart';
import 'package:kheti_sahayak_app/providers/learning_provider.dart';
import 'package:kheti_sahayak_app/screens/education/module_detail_screen.dart';
import 'package:kheti_sahayak_app/screens/education/progress_screen.dart';
import 'package:kheti_sahayak_app/widgets/education/progress_indicator_widget.dart';

/// Main learning hub screen with module discovery and progress
class LearningHubScreen extends StatefulWidget {
  const LearningHubScreen({Key? key}) : super(key: key);

  @override
  State<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends State<LearningHubScreen> {
  String? _selectedCategory;
  String? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<LearningProvider>();
    await provider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Consumer<LearningProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.modules.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: CustomScrollView(
              slivers: [
                // Header with progress summary
                _buildHeader(provider),

                // Continue learning section
                if (provider.getRecommendedModules().isNotEmpty)
                  _buildContinueLearningSection(provider),

                // Categories
                _buildCategoriesSection(provider),

                // Filter chips
                SliverToBoxAdapter(
                  child: _buildFilterChips(),
                ),

                // All modules grid
                _buildModulesGrid(provider),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(LearningProvider provider) {
    final progress = provider.userProgress;

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[700]!, Colors.green[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with title and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learning Hub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Expand your farming knowledge',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.person, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProgressScreen(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Progress summary card
            if (progress != null) _buildProgressCard(progress, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    dynamic progress,
    LearningProvider provider,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProgressScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Level badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber[400]!, Colors.amber[700]!],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${progress.currentLevel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Level ${progress.currentLevel}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 12, color: Colors.amber[700]),
                            const SizedBox(width: 2),
                            Text(
                              '${progress.totalPoints}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.levelProgress,
                      backgroundColor: Colors.grey[200],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.amber[600]!),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Streak
            Column(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: progress.streak.currentStreak > 0
                      ? Colors.orange
                      : Colors.grey,
                  size: 28,
                ),
                Text(
                  '${progress.streak.currentStreak}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progress.streak.currentStreak > 0
                        ? Colors.orange[800]
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueLearningSection(LearningProvider provider) {
    final recommended = provider.getRecommendedModules(limit: 3);

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Continue Learning',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Show all in-progress modules
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recommended.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 12,
                  ),
                  child: _buildContinueCard(recommended[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueCard(LearningModule module) {
    return GestureDetector(
      onTap: () => _navigateToModule(module),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with progress overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: module.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: module.thumbnailUrl!,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 100,
                          color: Colors.green[200],
                          child: const Center(
                            child: Icon(Icons.school, size: 40),
                          ),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: module.progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${(module.progress * 100).toInt()}% complete',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
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
    );
  }

  Widget _buildCategoriesSection(LearningProvider provider) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              'Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: provider.categories.length,
              itemBuilder: (context, index) {
                final category = provider.categories[index];
                final isSelected = _selectedCategory == category.id;

                return Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory =
                            isSelected ? null : category.id;
                      });
                      provider.loadModules(category: _selectedCategory);
                    },
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.green[700]
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Colors.green[700]!
                              : Colors.grey[300]!,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getCategoryIcon(category.id),
                            color: isSelected ? Colors.white : Colors.green[700],
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          const Text(
            'All Modules',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Difficulty filter
          PopupMenuButton<String>(
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
                  Text(
                    _selectedDifficulty?.capitalize() ?? 'All Levels',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                ],
              ),
            ),
            onSelected: (value) {
              setState(() {
                _selectedDifficulty = value == 'all' ? null : value;
              });
              context.read<LearningProvider>().loadModules(
                    category: _selectedCategory,
                    difficulty: _selectedDifficulty,
                  );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Levels')),
              const PopupMenuItem(value: 'beginner', child: Text('Beginner')),
              const PopupMenuItem(
                  value: 'intermediate', child: Text('Intermediate')),
              const PopupMenuItem(value: 'advanced', child: Text('Advanced')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModulesGrid(LearningProvider provider) {
    final modules = provider.getFilteredModules(
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
    );

    if (modules.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.school_outlined, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No modules found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildModuleCard(modules[index]),
          childCount: modules.length,
        ),
      ),
    );
  }

  Widget _buildModuleCard(LearningModule module) {
    return GestureDetector(
      onTap: () => _navigateToModule(module),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: module.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: module.thumbnailUrl!,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: Colors.grey[200]),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.green[100],
                            child: const Icon(Icons.school),
                          ),
                        )
                      : Container(
                          height: 100,
                          color: Colors.green[100],
                          child: const Center(
                            child: Icon(Icons.school, size: 40),
                          ),
                        ),
                ),
                // Difficulty badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(module.difficulty),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      module.difficulty.capitalize(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Downloaded indicator
                if (module.isDownloaded)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.download_done,
                        size: 16,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
              ],
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Bottom info
                    Row(
                      children: [
                        Icon(Icons.timer, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${module.estimatedDuration} min',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.star, size: 14, color: Colors.amber[600]),
                        const SizedBox(width: 2),
                        Text(
                          '${module.pointsReward}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Progress bar if started
                    if (module.progress > 0) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: module.progress,
                          backgroundColor: Colors.grey[200],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToModule(LearningModule module) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModuleDetailScreen(moduleId: module.id),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'organic_farming':
        return Icons.eco;
      case 'pest_management':
        return Icons.bug_report;
      case 'soil_health':
        return Icons.grass;
      case 'irrigation':
        return Icons.water_drop;
      case 'crop_management':
        return Icons.agriculture;
      case 'post_harvest':
        return Icons.inventory_2;
      default:
        return Icons.school;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

extension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
