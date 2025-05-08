import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactsProvider extends ChangeNotifier {
  List<Contact> _deviceContacts = [];
  List<UserModel> _appContacts = [];
  List<UserModel> _suggestedContacts = [];
  bool _isLoading = false;
  bool _hasPermission = false;
  bool _isSyncing = false;

  List<Contact> get deviceContacts => _deviceContacts;
  List<UserModel> get appContacts => _appContacts;
  List<UserModel> get suggestedContacts => _suggestedContacts;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  bool get isSyncing => _isSyncing;

  // Request contacts permission
  Future<void> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    _hasPermission = status.isGranted;
    notifyListeners();
  }

  // Load and sync contacts
  Future<void> loadContacts(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    final authProvider = context.read<AuthenticationProvider>();
    
    try {
      // Load app contacts (users already in contact list)
      _appContacts = await authProvider.getContactsList(
        authProvider.uid!,
        [],
      );

      // Check if we have permission to access device contacts
      if (await Permission.contacts.isGranted) {
        _hasPermission = true;
        await syncContacts(context);
      }
    } catch (e) {
      debugPrint('Error loading contacts: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Sync device contacts with app users
  Future<void> syncContacts(BuildContext context) async {
    _isSyncing = true;
    notifyListeners();
    
    final authProvider = context.read<AuthenticationProvider>();
    final currentUser = authProvider.userModel!;
    
    try {
      // Load device contacts
      _deviceContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: false,
      );
      
      // Create a batch of phone numbers to check
      List<String> phoneNumbers = [];
      Set<String> processedNumbers = {};
      
      for (var contact in _deviceContacts) {
        if (contact.phones.isEmpty) continue;
        
        for (var phone in contact.phones) {
          // Normalize phone number (remove spaces, brackets, etc.)
          String normalizedNumber = _normalizePhoneNumber(phone.number);
          
          // Skip if we've already processed this number
          if (processedNumbers.contains(normalizedNumber) || 
              normalizedNumber.isEmpty) {
            continue;
          }
          
          processedNumbers.add(normalizedNumber);
          
          // Generate different formats of the number to check
          final phoneFormats = _generatePhoneFormats(normalizedNumber);
          phoneNumbers.addAll(phoneFormats);
        }
      }
      
      // Clear previous suggested contacts
      _suggestedContacts = [];
      
      // Get registered users from Firebase that match these numbers
      if (phoneNumbers.isNotEmpty) {
        // Firebase has limits on in queries, so we might need to batch
        const batchSize = 10;
        List<Future<QuerySnapshot>> queries = [];
        
        for (int i = 0; i < phoneNumbers.length; i += batchSize) {
          final endIndex = (i + batchSize < phoneNumbers.length) ? i + batchSize : phoneNumbers.length;
          final batch = phoneNumbers.sublist(i, endIndex);
          
          queries.add(
            FirebaseFirestore.instance
                .collection(Constants.users)
                .where(Constants.phoneNumber, whereIn: batch)
                .get()
          );
        }
        
        final results = await Future.wait(queries);
        
        // Process all results
        for (var snapshot in results) {
          for (var doc in snapshot.docs) {
            final userData = doc.data() as Map<String, dynamic>;
            final user = UserModel.fromMap(userData);
            
            // Skip the current user
            if (user.uid == currentUser.uid) continue;
            
            // Skip users already in contacts
            if (_appContacts.any((contact) => contact.uid == user.uid)) continue;
            
            // Skip users already in suggested contacts
            if (_suggestedContacts.any((contact) => contact.uid == user.uid)) continue;
            
            // Add to suggested contacts
            _suggestedContacts.add(user);
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing contacts: $e');
    }
    
    _isSyncing = false;
    notifyListeners();
  }

  // Normalize phone number to strip special characters and standardize format
  String _normalizePhoneNumber(String phoneNumber) {
    // Remove everything except digits
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.isEmpty) return '';
    
    // Handle different formats
    if (digitsOnly.length < 7) return ''; // Too short to be valid
    
    return digitsOnly;
  }

  // Generate different possible formats of a phone number
  List<String> _generatePhoneFormats(String phoneNumber) {
    final formats = <String>[];
    
    // Original normalized number
    formats.add(phoneNumber);
    
    // With country code (common formats)
    if (phoneNumber.length >= 10) {
      if (!phoneNumber.startsWith('+')) {
        formats.add('+$phoneNumber');
      }
      
      // Common country codes
      final countryCodes = ['+1', '+44', '+91', '+61', '+254']; // US, UK, India, Australia, Kenya
      
      for (var code in countryCodes) {
        if (!phoneNumber.startsWith(code.substring(1))) {
          formats.add('$code$phoneNumber');
        }
      }
    }
    
    return formats;
  }
  
  // Add contact from suggestions 
  Future<void> addSuggestedContact(UserModel user, BuildContext context) async {
    try {
      final authProvider = context.read<AuthenticationProvider>();
      await authProvider.addContact(contactID: user.uid);
      
      // Update local lists
      _appContacts.add(user);
      _suggestedContacts.removeWhere((contact) => contact.uid == user.uid);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding contact: $e');
    }
  }
  
  // Add all suggested contacts at once
  Future<void> addAllSuggestedContacts(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final authProvider = context.read<AuthenticationProvider>();
      
      for (var user in _suggestedContacts) {
        await authProvider.addContact(contactID: user.uid);
        _appContacts.add(user);
      }
      
      _suggestedContacts = [];
      _isLoading = false;
      notifyListeners();
      
      showSnackBar(context, 'All contacts synchronized successfully');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      showSnackBar(context, 'Error adding contacts: $e');
    }
  }
}