import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kheti_sahayak_app/providers/offline_provider.dart';

/// A banner widget that shows offline status
class OfflineBanner extends StatelessWidget {
  /// Child widget to show below the banner
  final Widget child;
  
  /// Whether to show the banner at the top or bottom
  final bool showAtTop;
  
  /// Background color when offline
  final Color? offlineColor;
  
  /// Background color when syncing
  final Color? syncingColor;
  
  /// Background color when there are pending changes
  final Color? pendingColor;

  const OfflineBanner({
    super.key,
    required this.child,
    this.showAtTop = true,
    this.offlineColor,
    this.syncingColor,
    this.pendingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineProvider>(
      builder: (context, provider, _) {
        final banner = _buildBanner(context, provider);
        
        if (banner == null) {
          return child;
        }
        
        return Column(
          children: showAtTop
              ? [banner, Expanded(child: child)]
              : [Expanded(child: child), banner],
        );
      },
    );
  }
  
  Widget? _buildBanner(BuildContext context, OfflineProvider provider) {
    if (provider.isOffline) {
      return _OfflineBannerContent(
        icon: Icons.cloud_off,
        message: 'You are offline',
        subMessage: provider.hasPendingSync 
            ? '${provider.pendingSyncCount} changes pending'
            : 'Changes will sync when connected',
        backgroundColor: offlineColor ?? Colors.grey.shade800,
        textColor: Colors.white,
      );
    }
    
    if (provider.isSyncing) {
      return _OfflineBannerContent(
        icon: Icons.sync,
        message: 'Syncing...',
        subMessage: provider.currentProgress?.statusMessage ?? 'Please wait',
        backgroundColor: syncingColor ?? Colors.blue.shade700,
        textColor: Colors.white,
        showProgress: true,
        progress: provider.currentProgress?.progress,
      );
    }
    
    if (provider.hasPendingSync) {
      return _OfflineBannerContent(
        icon: Icons.cloud_upload_outlined,
        message: '${provider.pendingSyncCount} pending changes',
        subMessage: 'Tap to sync now',
        backgroundColor: pendingColor ?? Colors.orange.shade700,
        textColor: Colors.white,
        onTap: () => provider.syncNow(),
      );
    }
    
    return null;
  }
}

class _OfflineBannerContent extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subMessage;
  final Color backgroundColor;
  final Color textColor;
  final bool showProgress;
  final double? progress;
  final VoidCallback? onTap;

  const _OfflineBannerContent({
    required this.icon,
    required this.message,
    this.subMessage,
    required this.backgroundColor,
    required this.textColor,
    this.showProgress = false,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (showProgress)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(textColor),
                        ),
                      )
                    else
                      Icon(icon, color: textColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (subMessage != null)
                            Text(
                              subMessage!,
                              style: TextStyle(
                                color: textColor.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.chevron_right,
                        color: textColor.withOpacity(0.7),
                      ),
                  ],
                ),
              ),
              if (showProgress && progress != null)
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor.withOpacity(0.5)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small indicator widget for showing offline status
class OfflineStatusIndicator extends StatelessWidget {
  /// Size of the indicator
  final double size;
  
  /// Whether to show text label
  final bool showLabel;

  const OfflineStatusIndicator({
    super.key,
    this.size = 24,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineProvider>(
      builder: (context, provider, _) {
        if (provider.isSyncing) {
          return _buildIndicator(
            context,
            icon: Icons.sync,
            color: Colors.blue,
            label: 'Syncing',
            isAnimating: true,
          );
        }
        
        if (provider.isOffline) {
          return _buildIndicator(
            context,
            icon: Icons.cloud_off,
            color: Colors.grey,
            label: 'Offline',
          );
        }
        
        if (provider.hasPendingSync) {
          return _buildIndicator(
            context,
            icon: Icons.cloud_upload_outlined,
            color: Colors.orange,
            label: '${provider.pendingSyncCount} pending',
            badgeCount: provider.pendingSyncCount,
          );
        }
        
        return _buildIndicator(
          context,
          icon: Icons.cloud_done,
          color: Colors.green,
          label: 'Synced',
        );
      },
    );
  }
  
  Widget _buildIndicator(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    bool isAnimating = false,
    int? badgeCount,
  }) {
    Widget iconWidget = Icon(icon, size: size, color: color);
    
    if (isAnimating) {
      iconWidget = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(seconds: 1),
        builder: (context, value, child) {
          return Transform.rotate(
            angle: value * 2 * 3.14159,
            child: child,
          );
        },
        onEnd: () {
          // This will restart the animation
        },
        child: iconWidget,
      );
    }
    
    if (badgeCount != null && badgeCount > 0) {
      iconWidget = Badge(
        label: Text(
          badgeCount > 99 ? '99+' : badgeCount.toString(),
          style: const TextStyle(fontSize: 10),
        ),
        child: iconWidget,
      );
    }
    
    if (!showLabel) {
      return iconWidget;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// A floating action button for manual sync
class SyncFAB extends StatelessWidget {
  /// Position from bottom
  final double bottom;
  
  /// Position from right
  final double right;

  const SyncFAB({
    super.key,
    this.bottom = 16,
    this.right = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineProvider>(
      builder: (context, provider, _) {
        if (!provider.hasPendingSync || provider.isOffline) {
          return const SizedBox.shrink();
        }
        
        return Positioned(
          bottom: bottom,
          right: right,
          child: FloatingActionButton.extended(
            onPressed: provider.isSyncing ? null : provider.syncNow,
            icon: provider.isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.sync),
            label: Text(
              provider.isSyncing
                  ? 'Syncing...'
                  : 'Sync (${provider.pendingSyncCount})',
            ),
          ),
        );
      },
    );
  }
}

/// A dialog showing sync status and options
class SyncStatusDialog extends StatelessWidget {
  const SyncStatusDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineProvider>(
      builder: (context, provider, _) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                provider.isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: provider.isOnline ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(provider.isOnline ? 'Online' : 'Offline'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Network', provider.networkTypeName),
              _buildInfoRow('Pending Changes', provider.pendingSyncCount.toString()),
              if (provider.lastSyncTime != null)
                _buildInfoRow('Last Sync', _formatTime(provider.lastSyncTime!)),
              if (provider.lastSyncError != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.lastSyncError!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (provider.isSyncing && provider.currentProgress != null) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: provider.currentProgress!.progress,
                ),
                const SizedBox(height: 4),
                Text(
                  provider.currentProgress!.statusMessage,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (provider.hasPendingSync && provider.isOnline && !provider.isSyncing)
              ElevatedButton(
                onPressed: () async {
                  await provider.syncNow();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Sync Now'),
              ),
            if (provider.lastSyncError != null && !provider.isSyncing)
              TextButton(
                onPressed: () async {
                  await provider.retryFailed();
                },
                child: const Text('Retry Failed'),
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
  
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SyncStatusDialog(),
    );
  }
}

/// A sliver app bar that shows offline status
class OfflineSliverAppBar extends StatelessWidget {
  final Widget title;
  final List<Widget>? actions;
  final bool pinned;
  final double expandedHeight;
  final Widget? flexibleSpace;

  const OfflineSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.pinned = true,
    this.expandedHeight = 120,
    this.flexibleSpace,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineProvider>(
      builder: (context, provider, _) {
        return SliverAppBar(
          title: title,
          pinned: pinned,
          expandedHeight: expandedHeight,
          flexibleSpace: flexibleSpace,
          actions: [
            if (actions != null) ...actions!,
            IconButton(
              icon: OfflineStatusIndicator(size: 24),
              onPressed: () => SyncStatusDialog.show(context),
              tooltip: provider.statusMessage,
            ),
          ],
          bottom: _buildBottom(context, provider),
        );
      },
    );
  }
  
  PreferredSizeWidget? _buildBottom(BuildContext context, OfflineProvider provider) {
    if (provider.isOnline && !provider.hasPendingSync && !provider.isSyncing) {
      return null;
    }
    
    Color backgroundColor;
    String message;
    
    if (provider.isOffline) {
      backgroundColor = Colors.grey.shade800;
      message = 'Offline mode - Changes will sync when connected';
    } else if (provider.isSyncing) {
      backgroundColor = Colors.blue.shade700;
      message = provider.currentProgress?.statusMessage ?? 'Syncing...';
    } else {
      backgroundColor = Colors.orange.shade700;
      message = '${provider.pendingSyncCount} changes pending';
    }
    
    return PreferredSize(
      preferredSize: const Size.fromHeight(24),
      child: Container(
        color: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            if (provider.isSyncing)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(
                provider.isOffline ? Icons.cloud_off : Icons.sync,
                color: Colors.white,
                size: 14,
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
