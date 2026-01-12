import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/user_progress.dart';

/// Widget displaying a badge with animation
class BadgeWidget extends StatelessWidget {
  final Badge badge;
  final bool showDetails;
  final VoidCallback? onTap;

  const BadgeWidget({
    Key? key,
    required this.badge,
    this.showDetails = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _showBadgeDialog(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _getBadgeColor().withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: _getBadgeColor().withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge icon with glow effect
            _buildBadgeIcon(),

            const SizedBox(height: 12),

            // Badge name
            Text(
              badge.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            if (showDetails) ...[
              const SizedBox(height: 4),
              // Points value
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                      '+${badge.pointsValue}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeIcon() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            _getBadgeColor().withOpacity(0.2),
            _getBadgeColor().withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _getBadgeColor().withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          _getBadgeIcon(),
          size: 36,
          color: _getBadgeColor(),
        ),
      ),
    );
  }

  void _showBadgeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BadgeDetailDialog(badge: badge),
    );
  }

  Color _getBadgeColor() {
    switch (badge.type) {
      case BadgeType.achievement:
        return Colors.blue;
      case BadgeType.milestone:
        return Colors.purple;
      case BadgeType.streak:
        return Colors.orange;
      case BadgeType.quiz:
        return Colors.green;
      case BadgeType.special:
        return Colors.amber[700]!;
    }
  }

  IconData _getBadgeIcon() {
    switch (badge.type) {
      case BadgeType.achievement:
        return Icons.emoji_events;
      case BadgeType.milestone:
        return Icons.flag;
      case BadgeType.streak:
        return Icons.local_fire_department;
      case BadgeType.quiz:
        return Icons.quiz;
      case BadgeType.special:
        return Icons.star;
    }
  }
}

/// Dialog showing badge details
class BadgeDetailDialog extends StatelessWidget {
  final Badge badge;

  const BadgeDetailDialog({Key? key, required this.badge}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge icon with animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          _getBadgeColor().withOpacity(0.8),
                          _getBadgeColor(),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getBadgeColor().withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getBadgeIcon(),
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Badge name
            Text(
              badge.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Type chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getBadgeColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getTypeLabel(),
                style: TextStyle(
                  color: _getBadgeColor(),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              badge.description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Points and date
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Icon(Icons.star, color: Colors.amber[600]),
                      const SizedBox(height: 4),
                      Text(
                        '+${badge.pointsValue}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                      Text(
                        'Points',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(badge.earnedAt),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Earned',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getBadgeColor(),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Awesome!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBadgeColor() {
    switch (badge.type) {
      case BadgeType.achievement:
        return Colors.blue;
      case BadgeType.milestone:
        return Colors.purple;
      case BadgeType.streak:
        return Colors.orange;
      case BadgeType.quiz:
        return Colors.green;
      case BadgeType.special:
        return Colors.amber[700]!;
    }
  }

  IconData _getBadgeIcon() {
    switch (badge.type) {
      case BadgeType.achievement:
        return Icons.emoji_events;
      case BadgeType.milestone:
        return Icons.flag;
      case BadgeType.streak:
        return Icons.local_fire_department;
      case BadgeType.quiz:
        return Icons.quiz;
      case BadgeType.special:
        return Icons.star;
    }
  }

  String _getTypeLabel() {
    switch (badge.type) {
      case BadgeType.achievement:
        return 'Achievement';
      case BadgeType.milestone:
        return 'Milestone';
      case BadgeType.streak:
        return 'Streak Badge';
      case BadgeType.quiz:
        return 'Quiz Master';
      case BadgeType.special:
        return 'Special Badge';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Locked badge placeholder widget
class LockedBadgeWidget extends StatelessWidget {
  final String name;
  final String hint;

  const LockedBadgeWidget({
    Key? key,
    required this.name,
    required this.hint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
            child: Icon(
              Icons.lock,
              size: 32,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

/// Badge showcase row (for profile/home screens)
class BadgeShowcase extends StatelessWidget {
  final List<Badge> badges;
  final int maxDisplay;
  final VoidCallback? onViewAll;

  const BadgeShowcase({
    Key? key,
    required this.badges,
    this.maxDisplay = 5,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayBadges = badges.take(maxDisplay).toList();
    final remaining = badges.length - maxDisplay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium, color: Colors.amber[600]),
                const SizedBox(width: 8),
                const Text(
                  'Badges',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
                  child: Text(
                    '${badges.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayBadges.length + (remaining > 0 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == displayBadges.length && remaining > 0) {
                return GestureDetector(
                  onTap: onViewAll,
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '+$remaining',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              }

              final badge = displayBadges[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 8,
                ),
                child: _MinioBadge(badge: badge),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MinioBadge extends StatelessWidget {
  final Badge badge;

  const _MinioBadge({required this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => BadgeDetailDialog(badge: badge),
      ),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              _getBadgeColor().withOpacity(0.2),
              _getBadgeColor().withOpacity(0.1),
            ],
          ),
          border: Border.all(
            color: _getBadgeColor().withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Icon(
          _getBadgeIcon(),
          size: 32,
          color: _getBadgeColor(),
        ),
      ),
    );
  }

  Color _getBadgeColor() {
    switch (badge.type) {
      case BadgeType.achievement:
        return Colors.blue;
      case BadgeType.milestone:
        return Colors.purple;
      case BadgeType.streak:
        return Colors.orange;
      case BadgeType.quiz:
        return Colors.green;
      case BadgeType.special:
        return Colors.amber[700]!;
    }
  }

  IconData _getBadgeIcon() {
    switch (badge.type) {
      case BadgeType.achievement:
        return Icons.emoji_events;
      case BadgeType.milestone:
        return Icons.flag;
      case BadgeType.streak:
        return Icons.local_fire_department;
      case BadgeType.quiz:
        return Icons.quiz;
      case BadgeType.special:
        return Icons.star;
    }
  }
}
