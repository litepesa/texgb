import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/theme/theme_manager.dart';

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authenticationProvider);
    
    // Handle loading/error states
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (authState.hasError) {
      return Scaffold(
        body: Center(child: Text('Error: ${authState.error}')),
      );
    }
    
    // Check if we have valid authentication state data
    if (authState.value == null || authState.value!.userModel == null) {
      return const Scaffold(
        body: Center(child: Text('User data not available')),
      );
    }
    
    final currentUser = authState.value!.userModel!;
    
    // Get theme state from the ThemeManagerNotifier
    final themeStateAsync = ref.watch(themeManagerNotifierProvider);
    final isDarkMode = themeStateAsync.hasValue ? themeStateAsync.value!.isDarkMode : false;
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          userImageWidget(
                            imageUrl: currentUser.image,
                            radius: 50,
                            onTap: () {},
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentUser.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentUser.phoneNumber,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: currentUser.isOnline ? Colors.green : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      currentUser.isOnline ? 'Online' : 'Offline',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        color: Colors.grey,
                        thickness: 1,
                        height: 32,
                      ),
                      const Text(
                        'About Me',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser.aboutMe.isEmpty ? 'No about information provided' : currentUser.aboutMe,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Theme settings section
              Card(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                      leading: Container(
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            isDarkMode
                                ? Icons.nightlight_round
                                : Icons.wb_sunny_rounded,
                            color: isDarkMode ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                      title: const Text('Dark Mode'),
                      trailing: Switch(
                        value: isDarkMode,
                        onChanged: (_) {
                          // Toggle theme using the ThemeManagerNotifier
                          ref.read(themeManagerNotifierProvider.notifier).toggleTheme();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Additional settings
              Card(
                child: Column(
                  children: [
                    _buildSettingsTile(
                      title: 'Edit Profile',
                      icon: Icons.edit,
                      iconColor: Colors.blue,
                      onTap: () {
                        // Navigate to edit profile screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit Profile feature is under development'),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      title: 'Privacy Settings',
                      icon: Icons.privacy_tip,
                      iconColor: Colors.teal,
                      onTap: () {
                        // Navigate to privacy settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Privacy Settings feature is under development'),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      title: 'Notifications',
                      icon: Icons.notifications,
                      iconColor: Colors.amber,
                      onTap: () {
                        // Navigate to notifications
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notifications feature is under development'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Logout button
              Card(
                child: _buildSettingsTile(
                  title: 'Logout',
                  icon: Icons.logout_outlined,
                  iconColor: Colors.red,
                  onTap: () async {
                    // Show confirmation dialog
                    bool confirm = await _showLogoutConfirmation(context);
                    if (confirm) {
                      await ref.read(authenticationProvider.notifier)
                        .logout()
                        .whenComplete(() {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            Constants.loginScreen,
                            (route) => false,
                          );
                        });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        decoration: BoxDecoration(
          color: iconColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<bool> _showLogoutConfirmation(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    ) ?? false;
  }
}