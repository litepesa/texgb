// lib/features/authentication/screens/profile_setup_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/constants/kenya_languages.dart';
import 'package:textgb/constants/kenya_locations.dart';

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
  
  // Additional profile fields
  String? _selectedGender;
  String? _selectedLanguage;
  LocationData? _selectedLocation;
  
  bool _isSubmitting = false;
  
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

  // Show gender selection dialog
  Future<void> _showGenderSelector() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const GenderSelectorDialog(),
    );
    
    if (result != null) {
      setState(() {
        _selectedGender = result;
      });
    }
  }

  // Show language/tribe selection dialog
  Future<void> _showLanguageSelector() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const LanguageSelectorDialog(),
    );
    
    if (result != null) {
      setState(() {
        _selectedLanguage = result;
      });
    }
  }

  // Show location selection dialog
  Future<void> _showLocationSelector() async {
    final result = await showDialog<LocationData>(
      context: context,
      builder: (context) => const LocationSelectorDialog(),
    );
    
    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  // Submit the form to create user profile
  void _submitForm() async {
    if (_isSubmitting) {
      debugPrint('Warning: Form already submitting, ignoring duplicate submission');
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

      // Validate additional fields
      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your gender'),
            backgroundColor: Color(0xFFE53E3E),
          ),
        );
        return;
      }

      if (_selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your location'),
            backgroundColor: Color(0xFFE53E3E),
          ),
        );
        return;
      }

      if (_selectedLanguage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your native language'),
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
      
      setState(() {
        _isSubmitting = true;
      });
      
      // Create user model with new fields
      final userModel = UserModel.create(
        uid: currentUserId,
        name: _nameController.text.trim(),
        phoneNumber: phoneNumber,
        profileImage: '',
        bio: _aboutController.text.trim(),
        gender: _selectedGender,
        location: _selectedLocation!.fullLocation,
        language: _selectedLanguage,
      );
      
      debugPrint('Creating profile with enhanced data:');
      debugPrint('   - Name: ${userModel.name}');
      debugPrint('   - Gender: ${userModel.gender}');
      debugPrint('   - Location: ${userModel.location}');
      debugPrint('   - Language: ${userModel.language}');
      
      // CRITICAL FIX: Store context and navigator in variables before async operation
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      authNotifier.createUserProfile(
        user: userModel,
        profileImage: _profileImage,
        coverImage: null,
        onSuccess: () {
          debugPrint('Profile created successfully - Starting navigation');
          
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Profile created successfully!'),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 1),
            ),
          );
          
          debugPrint('Navigating to home screen...');
          
          navigator.pushNamedAndRemoveUntil(
            Constants.homeScreen,
            (route) => false,
          ).then((_) {
            debugPrint('Navigation to home screen completed');
          }).catchError((error) {
            debugPrint('Navigation error: $error');
          });
        },
        onFail: () {
          debugPrint('Profile creation failed');
          
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
              onPressed: _isSubmitting ? null : _submitForm,
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
                      onTap: _isSubmitting ? null : _pickProfileImage,
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
              
              // Basic Info Section
              const Text(
                'Basic Information',
                style: TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildFormField(
                controller: _nameController,
                label: 'Your Name',
                hint: 'Enter your name',
                isRequired: true,
                enabled: !_isSubmitting,
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
                enabled: !_isSubmitting,
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
              
              const SizedBox(height: 32),
              
              // Additional Info Section with explanation
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF93C5FD).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_city,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Why We Need This Information',
                            style: TextStyle(
                              color: Color(0xFF1E40AF),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Connect you with nearby creators, sellers and buyers\n'
                      '• Show products, content relevant to your location\n'
                      '• Reduce delivery costs and time\n'
                      '• Build a trusted local community',
                      style: TextStyle(
                        color: Color(0xFF1E40AF),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Additional Information',
                style: TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              
              // Gender Selection
              _buildSelectionTile(
                label: 'Gender',
                value: _selectedGender != null 
                    ? (_selectedGender == 'male' ? 'Male' : 'Female')
                    : null,
                hint: 'Select your gender',
                icon: Icons.person_outline,
                onTap: _isSubmitting ? null : _showGenderSelector,
                isRequired: true,
              ),
              
              const SizedBox(height: 16),
              
              // Location Selection
              _buildSelectionTile(
                label: 'Location (Ward)',
                value: _selectedLocation?.ward,
                hint: 'Select your ward',
                icon: Icons.location_on_outlined,
                onTap: _isSubmitting ? null : _showLocationSelector,
                isRequired: true,
                subtitle: _selectedLocation != null 
                    ? '${_selectedLocation!.constituency}, ${_selectedLocation!.county}'
                    : null,
              ),
              
              const SizedBox(height: 16),
              
              // Native Language/Tribe Selection
              _buildSelectionTile(
                label: 'Native Language',
                value: _selectedLanguage,
                hint: 'Select your preferred native language',
                icon: Icons.language_outlined,
                onTap: _isSubmitting ? null : _showLanguageSelector,
                isRequired: true,
              ),
              
              const SizedBox(height: 40),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
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
              
              // Privacy note
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: Color(0xFF92400E),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your information helps us provide you with a better experience.',
                        style: TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
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
    bool enabled = true,
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
          enabled: enabled,
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

  Widget _buildSelectionTile({
    required String label,
    required String? value,
    required String hint,
    required IconData icon,
    required VoidCallback? onTap,
    bool isRequired = false,
    String? subtitle,
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
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: value != null ? const Color(0xFF6366F1) : const Color(0xFF9CA3AF),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value ?? hint,
                        style: TextStyle(
                          color: value != null ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
                          fontSize: 16,
                          fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: const Color(0xFF9CA3AF),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Gender Selector Dialog
class GenderSelectorDialog extends StatelessWidget {
  const GenderSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Gender'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.male, color: Color(0xFF3B82F6)),
            title: const Text('Male'),
            onTap: () => Navigator.pop(context, 'male'),
          ),
          ListTile(
            leading: const Icon(Icons.female, color: Color(0xFFEC4899)),
            title: const Text('Female'),
            onTap: () => Navigator.pop(context, 'female'),
          ),
        ],
      ),
    );
  }
}

// Language/Tribe Selector Dialog
class LanguageSelectorDialog extends StatefulWidget {
  const LanguageSelectorDialog({super.key});

  @override
  State<LanguageSelectorDialog> createState() => _LanguageSelectorDialogState();
}

class _LanguageSelectorDialogState extends State<LanguageSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredTribes = KenyaLanguages.allTribes;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTribes(String query) {
    setState(() {
      _filteredTribes = KenyaLanguages.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Preferred Native Language'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _filterTribes,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredTribes.length,
                itemBuilder: (context, index) {
                  final tribe = _filteredTribes[index];
                  final group = KenyaLanguages.getGroup(tribe);
                  return ListTile(
                    title: Text(tribe),
                    subtitle: group != null ? Text(group, style: const TextStyle(fontSize: 12)) : null,
                    onTap: () => Navigator.pop(context, tribe),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Location Selector Dialog
class LocationSelectorDialog extends StatefulWidget {
  const LocationSelectorDialog({super.key});

  @override
  State<LocationSelectorDialog> createState() => _LocationSelectorDialogState();
}

class _LocationSelectorDialogState extends State<LocationSelectorDialog> {
  String? _selectedCounty;
  String? _selectedConstituency;
  String? _selectedWard;

  @override
  Widget build(BuildContext context) {
    final counties = KenyaLocations.allCounties;
    final constituencies = _selectedCounty != null 
        ? KenyaLocations.getConstituencies(_selectedCounty!)
        : <String>[];
    final wards = _selectedCounty != null && _selectedConstituency != null
        ? KenyaLocations.getWards(_selectedCounty!, _selectedConstituency!)
        : <String>[];

    return AlertDialog(
      title: const Text('Select Location'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // County Dropdown
            const Text(
              'County',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCounty,
              decoration: InputDecoration(
                hintText: 'Select County',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: counties.map((county) {
                return DropdownMenuItem(
                  value: county,
                  child: Text(county),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCounty = value;
                  _selectedConstituency = null;
                  _selectedWard = null;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Constituency Dropdown
            const Text(
              'Constituency',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedConstituency,
              decoration: InputDecoration(
                hintText: 'Select Constituency',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: constituencies.map((constituency) {
                return DropdownMenuItem(
                  value: constituency,
                  child: Text(constituency),
                );
              }).toList(),
              onChanged: _selectedCounty == null ? null : (value) {
                setState(() {
                  _selectedConstituency = value;
                  _selectedWard = null;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Ward Dropdown
            const Text(
              'Ward',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedWard,
              decoration: InputDecoration(
                hintText: 'Select Ward',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: wards.map((ward) {
                return DropdownMenuItem(
                  value: ward,
                  child: Text(ward),
                );
              }).toList(),
              onChanged: _selectedConstituency == null ? null : (value) {
                setState(() {
                  _selectedWard = value;
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Summary
            if (_selectedCounty != null || _selectedConstituency != null || _selectedWard != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF93C5FD).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Location:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedWard != null && _selectedConstituency != null && _selectedCounty != null
                          ? '$_selectedWard, $_selectedConstituency, $_selectedCounty'
                          : 'Please select all fields',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedCounty != null && 
                     _selectedConstituency != null && 
                     _selectedWard != null
              ? () {
                  final location = LocationData(
                    ward: _selectedWard!,
                    constituency: _selectedConstituency!,
                    county: _selectedCounty!,
                  );
                  Navigator.pop(context, location);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}