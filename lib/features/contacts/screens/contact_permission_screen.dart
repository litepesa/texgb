import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:textgb/features/contacts/contacts_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class ContactPermissionScreen extends StatefulWidget {
  final VoidCallback onPermissionGranted;
  
  const ContactPermissionScreen({
    Key? key, 
    required this.onPermissionGranted
  }) : super(key: key);

  @override
  State<ContactPermissionScreen> createState() => _ContactPermissionScreenState();
}

class _ContactPermissionScreenState extends State<ContactPermissionScreen> {
  bool _isLoading = false;

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final status = await Permission.contacts.request();
      
      if (status.isGranted) {
        // Update the provider state
        final provider = Provider.of<ContactsProvider>(context, listen: false);
        provider.requestContactsPermission().then((_) {
          // Sync contacts after permission is granted
          return provider.loadContacts(context);
        }).then((_) {
          // Call the callback and pop if needed
          widget.onPermissionGranted();
          if (ModalRoute.of(context)?.isCurrent ?? false) {
            Navigator.of(context).pop();
          }
        });
      } else if (status.isPermanentlyDenied) {
        // Show dialog to open settings
        _showOpenSettingsDialog();
      } else {
        showSnackBar(context, 'Contact permission is required to sync your contacts');
      }
    } catch (e) {
      showSnackBar(context, 'Error requesting permission: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Contact permission is permanently denied. Please enable it in the app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon or illustration
              Icon(
                Icons.contacts,
                size: 120,
                color: Theme.of(context).primaryColor.withOpacity(0.7),
              ),
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Contact Access',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Explanation
              const Text(
                'TexGB needs access to your contacts to help you connect with friends who are already using the app.',
                style: TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'We only use this information to show you which of your contacts are on TexGB.',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Permission request button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestPermission,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text(
                          'Allow Contact Access',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Skip button
              TextButton(
                onPressed: () {
                  showSnackBar(context, 'You can enable contact access later in the settings');
                  Navigator.pop(context);
                },
                child: const Text('Skip for Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}