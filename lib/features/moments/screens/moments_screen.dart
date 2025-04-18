import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/features/moments/screens/create_moment_screen.dart';
import 'package:textgb/features/moments/screens/user_moments_screen.dart';
import 'package:textgb/features/moments/widgets/moment_card.dart';
import 'package:textgb/models/moment_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/moments_provider.dart';
import 'package:textgb/utilities/global_methods.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({Key? key}) : super(key: key);

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  @override
  void initState() {
    super.initState();
    _loadMoments();
  }

  Future<void> _loadMoments() async {
    final authProvider = context.read<AuthenticationProvider>();
    final momentsProvider = context.read<MomentsProvider>();
    
    final currentUser = authProvider.userModel!;
    final contactIds = currentUser.contactsUIDs;
    
    await momentsProvider.fetchMoments(
      currentUserId: currentUser.uid,
      contactIds: contactIds,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final backgroundColor = themeExtension?.backgroundColor ?? Colors.white;
    final accentColor = themeExtension?.accentColor ?? Colors.green;
    
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Moments'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Navigate to user's moments screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserMomentsScreen(userId: currentUser.uid),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<MomentsProvider>(
        builder: (context, momentsProvider, child) {
          if (momentsProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }
          
          final moments = [
            ...momentsProvider.userMoments,
            ...momentsProvider.contactsMoments,
          ]..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Ensure chronological order
          
          if (moments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_album_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No moments yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share your first moment or add more contacts',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToCreateMoment(context),
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Create Moment'),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: _loadMoments,
            color: accentColor,
            child: ListView.builder(
              itemCount: moments.length,
              itemBuilder: (context, index) {
                final moment = moments[index];
                
                // Mark moment as viewed if it's not the current user's
                if (moment.uid != currentUser.uid && !moment.viewedBy.contains(currentUser.uid)) {
                  momentsProvider.markMomentAsViewed(
                    momentId: moment.momentId,
                    userId: currentUser.uid,
                  );
                }
                
                return MomentCard(
                  moment: moment,
                  currentUserId: currentUser.uid,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateMoment(context),
        backgroundColor: accentColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToCreateMoment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateMomentScreen(),
      ),
    ).then((_) => _loadMoments());
  }
}