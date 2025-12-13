import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kheti_sahayak_app/providers/user_provider.dart';
import 'package:kheti_sahayak_app/widgets/loading_indicator.dart';
import 'package:kheti_sahayak_app/routes/routes.dart';
import 'package:kheti_sahayak_app/services/language_service.dart';
import 'package:kheti_sahayak_app/services/notification_preferences_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Provider.of<UserProvider>(context, listen: false).logout();
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (userProvider.isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please login to view your profile.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                child: const Text('Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context, user),
            const SizedBox(height: 16),
            _buildFarmDetailsCard(context, user),
            const SizedBox(height: 24),
            _buildNotificationSettingsCard(context),
            const SizedBox(height: 24),
            _buildAppSettingsCard(context),
            const SizedBox(height: 24),
            _buildLogoutCard(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF4CAF50).withOpacity(0.2),
              child: user.profileImageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        user.profileImageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          size: 40,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF4CAF50),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.fullName ?? user.username,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      if (user.isVerifiedFarmer)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Verified Farmer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
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

  Widget _buildFarmDetailsCard(BuildContext context, user) {
    final hasFarmDetails = user.farmSize != null ||
        user.soilType != null ||
        user.irrigationType != null ||
        (user.primaryCrops != null && user.primaryCrops!.isNotEmpty);

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.farmSize != null) ...[
              Row(
                children: [
                  Icon(Icons.agriculture, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Farm Size: ${user.farmSize} acres',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (user.soilType != null || user.irrigationType != null) ...[
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    [
                      if (user.soilType != null) 'Soil: ${user.soilType}',
                      if (user.irrigationType != null)
                        'Irrigation: ${user.irrigationType}',
                    ].join(' | '),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (user.primaryCrops != null && user.primaryCrops!.isNotEmpty) ...[
              Text(
                'Primary Crops:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.primaryCrops!
                    .map<Widget>(
                      (crop) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          crop,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (!hasFarmDetails)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.agriculture, color: Colors.grey[400], size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'No farm details added yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.editProfile);
                      },
                      child: const Text('Add Farm Details'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettingsCard(BuildContext context) {
    return Consumer<NotificationPreferencesService>(
      builder: (context, notifPrefs, _) {
        return Card(
          elevation: 2.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Notification Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              _buildSwitchTile(
                context,
                icon: Icons.wb_sunny_outlined,
                title: 'Weather Alerts',
                value: notifPrefs.weatherAlerts,
                onChanged: (value) => notifPrefs.setWeatherAlerts(value),
              ),
              _buildSwitchTile(
                context,
                icon: Icons.account_balance_outlined,
                title: 'Government Scheme Updates',
                value: notifPrefs.schemeUpdates,
                onChanged: (value) => notifPrefs.setSchemeUpdates(value),
              ),
              _buildSwitchTile(
                context,
                icon: Icons.shopping_cart_outlined,
                title: 'Marketplace Updates',
                value: notifPrefs.marketplaceUpdates,
                onChanged: (value) => notifPrefs.setMarketplaceUpdates(value),
              ),
              _buildSwitchTile(
                context,
                icon: Icons.people_outline,
                title: 'Expert Messages',
                value: notifPrefs.expertMessages,
                onChanged: (value) => notifPrefs.setExpertMessages(value),
              ),
              _buildSwitchTile(
                context,
                icon: Icons.chat_bubble_outline,
                title: 'Forum Replies',
                value: notifPrefs.forumReplies,
                onChanged: (value) => notifPrefs.setForumReplies(value),
              ),
              _buildSwitchTile(
                context,
                icon: Icons.access_time,
                title: 'Logbook Reminders',
                value: notifPrefs.logbookReminders,
                onChanged: (value) => notifPrefs.setLogbookReminders(value),
                isLast: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    return Column(
      children: [
        SwitchListTile(
          secondary: Icon(icon, color: Colors.grey[600]),
          title: Text(title),
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF4CAF50),
        ),
        if (!isLast)
          const Divider(height: 0, indent: 56, endIndent: 16),
      ],
    );
  }

  Widget _buildAppSettingsCard(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'App Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Color(0xFF4CAF50)),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.editProfile);
            },
          ),
          const Divider(height: 0, indent: 56, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Color(0xFF4CAF50)),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.changePassword);
            },
          ),
          const Divider(height: 0, indent: 56, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.language, color: Color(0xFF4CAF50)),
            title: const Text('Language'),
            subtitle: Text(languageService.currentLanguage.nativeName),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageDialog(context),
          ),
          const Divider(height: 0, indent: 56, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.shield_outlined, color: Color(0xFF4CAF50)),
            title: const Text('Privacy & Security'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showComingSoonDialog(context, 'Privacy & Security');
            },
          ),
          const Divider(height: 0, indent: 56, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Color(0xFF4CAF50)),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showComingSoonDialog(context, 'Help & Support');
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Language / भाषा चुनें'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((lang) {
            return RadioListTile<AppLanguage>(
              title: Text('${lang.nativeName} (${lang.englishName})'),
              value: lang,
              groupValue: languageService.currentLanguage,
              activeColor: const Color(0xFF4CAF50),
              onChanged: (value) {
                if (value != null) {
                  languageService.setLanguage(value);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Language changed to ${value.nativeName}'),
                      backgroundColor: const Color(0xFF4CAF50),
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(feature),
        content: const Text('This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text('Logout', style: TextStyle(color: Colors.red)),
        onTap: () => _confirmLogout(context),
      ),
    );
  }
}
