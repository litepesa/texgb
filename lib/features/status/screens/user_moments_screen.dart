import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/features/status/widgets/moment_card.dart';
import 'package:textgb/models/moment_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/utilities/global_methods.dart';

class UserMomentsScreen extends StatefulWidget {
  final String userId;
  
  const UserMomentsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserMomentsScreen> createState() => _UserMomentsScreenState();
}

class _UserMomentsScreenState extends State<UserMomentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final backgroundColor = themeExtension?.backgroundColor ?? Colors.white;
    final accentColor = themeExtension?.accentColor ?? Colors.green;
    
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final isCurrentUser = widget.userId == currentUser.uid;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(isCurrentUser ? 'My Moments' : 'User Moments'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('moments')
            .where('uid', isEqualTo: widget.userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: accentColor,
              ),
            );
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isCurrentUser ? 'You haven\'t shared any moments yet' : 'No moments to show',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isCurrentUser) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Create Moment'),
                    ),
                  ],
                ],
              ),
            );
          }
          
          // Convert the snapshot documents to MomentModel objects
          final moments = snapshot.data!.docs.map((doc) {
            return MomentModel.fromMap(doc.data() as Map<String, dynamic>);
          }).toList();
          
          return ListView.builder(
            itemCount: moments.length,
            itemBuilder: (context, index) {
              final moment = moments[index];
              
              // Mark as viewed if it's not the current user's
              if (!isCurrentUser && !moment.viewedBy.contains(currentUser.uid)) {
                _markAsViewed(moment.momentId, currentUser.uid);
              }
              
              return MomentCard(
                moment: moment,
                currentUserId: currentUser.uid,
                showDeleteOption: isCurrentUser,
                onDelete: isCurrentUser ? () => _deleteMoment(moment.momentId) : null,
              );
            },
          );
        },
      ),
    );
  }
  
  // Mark a moment as viewed
  Future<void> _markAsViewed(String momentId, String userId) async {
    try {
      final doc = await _firestore.collection('moments').doc(momentId).get();
      if (!doc.exists) return;
      
      final viewedBy = List<String>.from(doc.get('viewedBy') ?? []);
      if (viewedBy.contains(userId)) return;
      
      viewedBy.add(userId);
      await _firestore.collection('moments').doc(momentId).update({
        'viewedBy': viewedBy,
      });
    } catch (e) {
      print('Error marking moment as viewed: $e');
    }
  }
  
  // Delete a moment
  Future<void> _deleteMoment(String momentId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get the moment to find media URLs that need to be deleted
      final doc = await _firestore.collection('moments').doc(momentId).get();
      if (!doc.exists) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Delete the moment from Firestore
      await _firestore.collection('moments').doc(momentId).delete();
      
      // Note: In a full implementation, we would also delete the media files from Firebase Storage
      // But for simplicity in this example, we'll skip that part
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        showSnackBar(context, 'Moment deleted successfully');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        showSnackBar(context, 'Error deleting moment: $e');
      }
    }
  }
}