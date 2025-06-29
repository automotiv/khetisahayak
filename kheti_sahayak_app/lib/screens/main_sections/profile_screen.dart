import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/user.dart'; // Assuming you have a User model
// import 'package:kheti_sahayak_app/services/user_service.dart'; // You might need a UserService later

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Placeholder for user data. In a real app, this would come from authentication state.
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    // TODO: Fetch actual user data from AuthService or a dedicated UserService
    // For now, using a dummy user
    setState(() {
      _currentUser = User(
        id: 'dummy_user_id_123',
        username: 'JohnDoe',
        email: 'john.doe@example.com',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'User Profile',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          if (_currentUser != null)
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Username: ${_currentUser!.username}',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8.0),
                    Text('Email: ${_currentUser!.email}'),
                    const SizedBox(height: 8.0),
                    Text(
                        'Member Since: ${_currentUser!.createdAt.toLocal().toString().split(' ')[0]}'),
                    // Add more user details as needed
                  ],
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 20),
          Text(
            'Account Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16.0),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            onTap: () {
              // TODO: Navigate to Edit Profile screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit Profile clicked')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            onTap: () {
              // TODO: Navigate to Change Password screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Change Password clicked')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              // TODO: Implement logout logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logout clicked')),
              );
            },
          ),
        ],
      ),
    );
  }
}