import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';
import 'package:textgb/shared/theme/theme_manager.dart';
import 'package:textgb/widgets/settings_list_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isDarkMode = false;

  // get the saved theme mode
  void getThemeMode() async {
    // get the theme manager
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    // check if the saved theme mode is dark
    setState(() {
      isDarkMode = themeManager.isDarkMode;
    });
  }

  @override
  void initState() {
    getThemeMode();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // get user data from arguments
    final uid = ModalRoute.of(context)!.settings.arguments as String;
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final bool isCurrentUser = uid == currentUser.uid;
    
    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text('Profile'),
        actions: [
          if (!isCurrentUser) PopupMenuButton<String>(
            onSelected: (value) async {
              final authProvider = context.read<AuthenticationProvider>();
              if (value == 'block') {
                // Show confirmation dialog
                bool confirmed = await _showBlockConfirmation(context);
                if (confirmed) {
                  await authProvider.blockContact(contactID: uid);
                  showSnackBar(context, 'User has been blocked');
                  Navigator.pop(context);
                }
              } else if (value == 'remove') {
                // Show confirmation dialog
                bool confirmed = await _showRemoveConfirmation(context);
                if (confirmed) {
                  await authProvider.removeContact(contactID: uid);
                  showSnackBar(context, 'Contact has been removed');
                }
              } else if (value == 'unblock') {
                await authProvider.unblockContact(contactID: uid);
                showSnackBar(context, 'User has been unblocked');
              }
            },
            itemBuilder: (BuildContext context) {
              final isBlocked = currentUser.blockedUIDs.contains(uid);
              final isContact = currentUser.contactsUIDs.contains(uid);
              
              return <PopupMenuEntry<String>>[
                if (isBlocked)
                  const PopupMenuItem<String>(
                    value: 'unblock',
                    child: Text('Unblock user'),
                  )
                else ...[
                  if (isContact)
                    const PopupMenuItem<String>(
                      value: 'remove',
                      child: Text('Remove from contacts'),
                    ),
                  const PopupMenuItem<String>(
                    value: 'block',
                    child: Text('Block user'),
                  ),
                ],
              ];
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: context.read<AuthenticationProvider>().userStream(userID: uid),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userModel =
              UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);

          // Check relationship status
          final bool isBlocked = currentUser.blockedUIDs.contains(uid);
          final bool isContact = currentUser.contactsUIDs.contains(uid);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(userModel),
                  if (isBlocked) 
                    _buildBlockedBanner(),
                  
                  if (!isCurrentUser && !isBlocked) 
                    _buildActionButtons(context, userModel, isContact),
                  
                  const SizedBox(height: 24),
                  
                  if (isCurrentUser) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        'Settings',
                        style: GoogleFonts.openSans(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSettingsCards(context),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(UserModel userModel) {
    return Card(
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
                  imageUrl: userModel.image,
                  radius: 50,
                  onTap: () {},
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userModel.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userModel.phoneNumber,
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
                              color: userModel.isOnline ? Colors.green : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            userModel.isOnline ? 'Online' : 'Offline',
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
              userModel.aboutMe.isEmpty ? 'No about information provided' : userModel.aboutMe,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.block, color: Colors.red),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'You have blocked this user',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = context.read<AuthenticationProvider>();
              final uid = ModalRoute.of(context)!.settings.arguments as String;
              await authProvider.unblockContact(contactID: uid);
              showSnackBar(context, 'User has been unblocked');
            },
            child: Text('Unblock'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, UserModel userModel, bool isContact) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, Constants.chatScreen, arguments: {
                  Constants.contactUID: userModel.uid,
                  Constants.contactName: userModel.name,
                  Constants.contactImage: userModel.image,
                  Constants.groupId: '',
                });
              },
              icon: const Icon(Icons.message),
              label: const Text('Message'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final authProvider = context.read<AuthenticationProvider>();
                if (isContact) {
                  // Show confirmation dialog
                  bool confirmed = await _showRemoveConfirmation(context);
                  if (confirmed) {
                    await authProvider.removeContact(contactID: userModel.uid);
                    showSnackBar(context, 'Contact has been removed');
                  }
                } else {
                  // Add contact
                  await authProvider.addContact(contactID: userModel.uid);
                  showSnackBar(context, '${userModel.name} added to your contacts');
                }
              },
              icon: Icon(isContact ? Icons.person_remove : Icons.person_add),
              label: Text(isContact ? 'Remove' : 'Add Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isContact ? Colors.red : null,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCards(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    
    return Column(
      children: [
        Card(
          child: Column(
            children: [
              SettingsListTile(
                title: 'Account',
                icon: Icons.person,
                iconContainerColor: Colors.deepPurple,
                onTap: () {
                  // navigate to account settings
                },
              ),
              SettingsListTile(
                title: 'My Media',
                icon: Icons.image,
                iconContainerColor: Colors.green,
                onTap: () {
                  // navigate to account settings
                },
              ),
              SettingsListTile(
                title: 'Notifications',
                icon: Icons.notifications,
                iconContainerColor: Colors.red,
                onTap: () {
                  // navigate to account settings
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              SettingsListTile(
                title: 'Contacts',
                icon: Icons.contacts,
                iconContainerColor: Colors.blue,
                onTap: () {
                  Navigator.pushNamed(context, Constants.contactsScreen);
                },
              ),
              SettingsListTile(
                title: 'Blocked Contacts',
                icon: Icons.block,
                iconContainerColor: Colors.red,
                onTap: () {
                  Navigator.pushNamed(context, Constants.blockedContactsScreen);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              SettingsListTile(
                title: 'Help',
                icon: Icons.help,
                iconContainerColor: Colors.yellow,
                onTap: () {
                  // navigate to account settings
                },
              ),
              SettingsListTile(
                title: 'Share',
                icon: Icons.share,
                iconContainerColor: Colors.blue,
                onTap: () {
                  // navigate to account settings
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
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
            title: const Text('Change theme'),
            trailing: Switch(
                value: isDarkMode,
                onChanged: (value) {
                  // set the isDarkMode to the value
                  setState(() {
                    isDarkMode = value;
                  });
                  // check if the value is true
                  if (value) {
                    // set the theme mode to dark
                    themeManager.setDarkMode();
                  } else {
                    // set the theme mode to light
                    themeManager.setLightMode();
                  }
                }),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              SettingsListTile(
                title: 'Logout',
                icon: Icons.logout_outlined,
                iconContainerColor: Colors.red,
                onTap: () {
                  showMyAnimatedDialog(
                    context: context,
                    title: 'Logout',
                    content: 'Are you sure you want to logout?',
                    textAction: 'Logout',
                    onActionTap: (value) {
                      if (value) {
                        // logout
                        context
                            .read<AuthenticationProvider>()
                            .logout()
                            .whenComplete(() {
                          Navigator.pop(context);
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            Constants.loginScreen,
                            (route) => false,
                          );
                        });
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _showBlockConfirmation(BuildContext context) async {
    bool result = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text(
          'When you block someone, they won\'t be able to message you or see your status updates. Are you sure you want to block this user?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              result = true;
              Navigator.pop(context);
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result;
  }

  Future<bool> _showRemoveConfirmation(BuildContext context) async {
    bool result = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Contact'),
        content: const Text(
          'Are you sure you want to remove this person from your contacts?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              result = true;
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result;
  }
}