// lib/features/authentication/screens/profile_setup_screen.dart (FIXED AUTO NAVIGATION)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/constants.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  File? _profileImage;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  
  bool _isSubmitting = false; // ✅ FIXED: Add loading state to prevent multiple submissions
  
  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  // Pick profile image
  Future<void> _pickProfileImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    
    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  // ✅ FIXED: Submit the form to create user profile with proper navigation handling
  void _submitForm() async {
    // Prevent multiple submissions
    if (_isSubmitting) {
      debugPrint('⚠️ Form already submitting, ignoring duplicate submission');
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      if (_profileImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a profile picture'),
            backgroundColor: Color(0xFFE53E3E),
          ),
        );
        return;
      }
      
      final authNotifier = ref.read(authenticationProvider.notifier);
      final repository = ref.read(authenticationRepositoryProvider);
      final currentUserId = repository.currentUserId;
      final phoneNumber = repository.currentUserPhoneNumber;
      
      if (currentUserId == null || phoneNumber == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication error. Please try again.'),
            backgroundColor: Color(0xFFE53E3E),
          ),
        );
        return;
      }
      
      // Set submitting state
      setState(() {
        _isSubmitting = true;
      });
      
      // Create user model using the factory method for Go backend (PHONE-ONLY)
      final userModel = UserModel.create(
        uid: currentUserId,
        name: _nameController.text.trim(),
        phoneNumber: phoneNumber,
        profileImage: '', // Will be set after upload
        bio: _aboutController.text.trim(),
      );
      
      debugPrint('🏗️ Creating profile for: ${userModel.name} (${userModel.phoneNumber})');
      
      // ✅ FIXED: Store context and navigator in variables before async operation
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      // Create user profile using the new authentication provider
      authNotifier.createUserProfile(
        user: userModel,
        profileImage: _profileImage,
        coverImage: null,
        onSuccess: () {
          debugPrint('✅ Profile created successfully - Starting navigation');
          
          // ✅ FIXED: Use stored navigator instead of context
          // This prevents the "Looking up deactivated widget's ancestor" error
          
          // Show success message using stored scaffoldMessenger
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Profile created successfully!'),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 1),
            ),
          );
          
          debugPrint('🚀 Navigating to home screen...');
          
          // ✅ FIXED: Navigate using stored navigator
          // Use pushNamedAndRemoveUntil to ensure we can't go back to profile setup
          navigator.pushNamedAndRemoveUntil(
            Constants.homeScreen,
            (route) => false, // Remove all previous routes
          ).then((_) {
            debugPrint('✅ Navigation to home screen completed');
          }).catchError((error) {
            debugPrint('❌ Navigation error: $error');
          });
        },
        onFail: () {
          debugPrint('❌ Profile creation failed');
          
          // Reset submitting state on failure
          if (mounted) {
            setState(() {
              _isSubmitting = false;
            });
            
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Failed to create profile. Please try again.'),
                backgroundColor: Color(0xFFE53E3E),
              ),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Set Up Your Profile',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm, // ✅ FIXED: Disable while submitting
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSubmitting 
                    ? const Color(0xFF6366F1).withOpacity(0.5) 
                    : const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Done',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to WeiBao Marketplace!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Set up your profile to start buying from verified sellers or showcase your products to thousands of buyers',
                      style: TextStyle(
                        color: Color(0xFFF3F4F6),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Profile image picker
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Profile Picture',
                      style: TextStyle(
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _isSubmitting ? null : _pickProfileImage, // ✅ FIXED: Disable while submitting
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _profileImage == null 
                              ? const LinearGradient(
                                  colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                )
                              : null,
                          border: Border.all(
                            color: const Color(0xFF6366F1),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          image: _profileImage != null
                              ? DecorationImage(
                                  image: FileImage(_profileImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _profileImage == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    color: Color(0xFF6366F1),
                                    size: 32,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Add Photo',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                    if (_profileImage != null) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _isSubmitting ? null : () {
                          setState(() {
                            _profileImage = null;
                          });
                        },
                        icon: const Icon(
                          Icons.refresh,
                          color: Color(0xFF6366F1),
                          size: 18,
                        ),
                        label: const Text(
                          'Change Photo',
                          style: TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Form fields
              _buildFormField(
                controller: _nameController,
                label: 'Your Name',
                hint: 'Enter your name',
                isRequired: true,
                enabled: !_isSubmitting, // ✅ FIXED: Disable while submitting
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  if (value.length > Constants.maxNameLength) {
                    return 'Name cannot exceed ${Constants.maxNameLength} characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              _buildFormField(
                controller: _aboutController,
                label: 'About You',
                hint: 'Tell people about yourself',
                maxLines: 3,
                isRequired: true,
                enabled: !_isSubmitting, // ✅ FIXED: Disable while submitting
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please tell us about yourself';
                  }
                  if (value.length < 5) {
                    return 'About must be at least 5 characters';
                  }
                  if (value.length > Constants.maxAboutLength) {
                    return 'About cannot exceed ${Constants.maxAboutLength} characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 40),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm, // ✅ FIXED: Disable while submitting
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSubmitting 
                        ? const Color(0xFF6366F1).withOpacity(0.5) 
                        : const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Creating Profile...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Create Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Footer note
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF93C5FD).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can edit your profile details anytime in settings.',
                        style: TextStyle(
                          color: Color(0xFF1E40AF),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool isRequired = false,
    bool enabled = true, // ✅ FIXED: Add enabled parameter
    String? Function(String?)? validator,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          enabled: enabled, // ✅ FIXED: Use enabled parameter
          style: TextStyle(
            color: enabled ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 16,
            ),
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF3F4F6),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            helperText: helperText,
            helperStyle: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}