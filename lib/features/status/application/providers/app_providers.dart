import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../../../models/user_model.dart';
import '../../../../features/authentication/authentication_provider.dart';
import '../../../../features/contacts/contacts_provider.dart';

/// Provider to get the current user
/// This is a bridge between Provider-based auth and Riverpod
final userProvider = FutureProvider<UserModel?>((ref) async {
  return null; // Placeholder - will be updated from context
});

/// Helper function to update the userProvider with the current user
/// Call this in context-aware widgets to ensure the Riverpod state stays in sync
void updateUserProvider(WidgetRef ref, BuildContext context) {
  try {
    // Get the AuthenticationProvider from the context
    final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
    final user = authProvider.userModel;
    
    // Update the userProvider state if needed
    if (user != null) {
      ref.read(userProvider.notifier).update((_) => Future.value(user));
    }
  } catch (e) {
    debugPrint('Error updating user provider: $e');
  }
}

/// Helper function to get user from Provider context
UserModel? getCurrentUser(BuildContext context) {
  try {
    // Get the AuthenticationProvider from the context
    final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
    return authProvider.userModel;
  } catch (e) {
    debugPrint('Error getting current user: $e');
    return null;
  }
}

/// ContactsProvider adapter
/// This creates a bridge between your existing contacts system
/// and the new Riverpod-based Status feature
class ContactsService {
  final BuildContext context;
  
  ContactsService(this.context);
  
  /// Get contacts for a user
  Future<List<UserModel>> getContacts(UserModel user) async {
    try {
      // Get the AuthenticationProvider from the context
      final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
      
      // Get contacts list
      return await authProvider.getContactsList(user.uid, []);
    } catch (e) {
      debugPrint('Error getting contacts: $e');
      return [];
    }
  }
  
  /// Get contacts IDs for a user
  List<String> getContactIds(UserModel user) {
    return user.contactsUIDs;
  }
  
  /// Get blocked users IDs for a user
  List<String> getBlockedUserIds(UserModel user) {
    return user.blockedUIDs;
  }
}