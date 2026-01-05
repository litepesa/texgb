// lib/features/users/screens/additional_info_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/constants/kenya_languages.dart';
import 'package:textgb/constants/kenya_locations.dart';

class AdditionalInfoScreen extends ConsumerStatefulWidget {
  const AdditionalInfoScreen({super.key});

  @override
  ConsumerState<AdditionalInfoScreen> createState() =>
      _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends ConsumerState<AdditionalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedGender;
  String? _selectedLanguage;
  LocationData? _selectedLocation;

  bool _isSubmitting = false;

  Future<void> _showGenderSelector() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const GenderSelectorDialog(),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedGender = result;
      });
    }
  }

  Future<void> _showLanguageSelector() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const LanguageSelectorDialog(),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLanguage = result;
      });
    }
  }

  Future<void> _showLocationSelector() async {
    final result = await showDialog<LocationData>(
      context: context,
      builder: (context) => const LocationSelectorDialog(),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  void _submitForm() {
    if (_isSubmitting) {
      debugPrint('⚠️ Form already submitting');
      return;
    }

    if (_selectedGender == null) {
      _showError('Please select your gender');
      return;
    }

    if (_selectedLocation == null) {
      _showError('Please select your location');
      return;
    }

    if (_selectedLanguage == null) {
      _showError('Please select your native language');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // TODO: Update user profile with additional info
    // For now, just navigate to home
    debugPrint('🏗️ Updating user with additional info:');
    debugPrint('   - Gender: $_selectedGender');
    debugPrint('   - Location: ${_selectedLocation!.fullLocation}');
    debugPrint('   - Language: $_selectedLanguage');

    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _handleSuccess();
      }
    });
  }

  void _handleSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Information updated successfully!'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate to home
    debugPrint('🚀 Navigating to home screen');
    context.go('/home');
  }

  void _handleSkip() {
    // Allow users to skip this step
    debugPrint('⏭️ User skipped additional info');
    context.go('/home');
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE53E3E),
      ),
    );
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
          'Additional Information',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _handleSkip,
            child: Text(
              'Skip',
              style: TextStyle(
                color: _isSubmitting
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6366F1),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
                      'Personalize Your Experience',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Help us show you relevant content and connect you with the right community',
                      style: TextStyle(
                        color: Color(0xFFF3F4F6),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF93C5FD).withOpacity(0.3)),
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
                            Icons.explore,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Why We Need This',
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
                      '• Discover what\'s happening around you\n'
                      '• See trending products from your area\n'
                      '• Browse content in your native language\n'
                      '• Connect with local sellers and buyers\n'
                      '• Get personalized recommendations',
                      style: TextStyle(
                        color: Color(0xFF1E40AF),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Your Information',
                style: TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),

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

              _buildSelectionTile(
                label: 'Location (Ward)',
                value: _selectedLocation?.ward,
                hint: 'Know what is happening around you in real time',
                icon: Icons.location_on_outlined,
                onTap: _isSubmitting ? null : _showLocationSelector,
                isRequired: true,
                subtitle: _selectedLocation != null
                    ? '${_selectedLocation!.constituency}, ${_selectedLocation!.county}'
                    : 'See what\'s trending in your area',
              ),

              const SizedBox(height: 16),

              _buildSelectionTile(
                label: 'Native Content Language',
                value: _selectedLanguage,
                hint: 'Your preferred native content language',
                icon: Icons.language_outlined,
                onTap: _isSubmitting ? null : _showLanguageSelector,
                isRequired: true,
                subtitle: _selectedLanguage == null
                    ? 'Browse content in your native language'
                    : null,
              ),

              const SizedBox(height: 40),

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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Saving...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFFBBF24).withOpacity(0.3)),
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
                        'Your information is secure and helps us show you relevant content.',
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
                  style: TextStyle(color: Color(0xFFEF4444)),
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
                  color: value != null
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF9CA3AF),
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
                          color: value != null
                              ? const Color(0xFF1F2937)
                              : const Color(0xFF9CA3AF),
                          fontSize: 16,
                          fontWeight: value != null
                              ? FontWeight.w500
                              : FontWeight.normal,
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
                const Icon(Icons.arrow_forward_ios,
                    color: Color(0xFF9CA3AF), size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Dialogs
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
      title: const Text('Select Native Content Language'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search languages...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                    subtitle: group != null
                        ? Text(group, style: const TextStyle(fontSize: 12))
                        : null,
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
            const Text('County',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCounty,
              decoration: InputDecoration(
                hintText: 'Select County',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: counties
                  .map((county) =>
                      DropdownMenuItem(value: county, child: Text(county)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCounty = value;
                  _selectedConstituency = null;
                  _selectedWard = null;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Constituency',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedConstituency,
              decoration: InputDecoration(
                hintText: 'Select Constituency',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: constituencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: _selectedCounty == null
                  ? null
                  : (value) {
                      setState(() {
                        _selectedConstituency = value;
                        _selectedWard = null;
                      });
                    },
            ),
            const SizedBox(height: 16),
            const Text('Ward',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedWard,
              decoration: InputDecoration(
                hintText: 'Select Ward',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: wards
                  .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                  .toList(),
              onChanged: _selectedConstituency == null
                  ? null
                  : (value) {
                      setState(() => _selectedWard = value);
                    },
            ),
            const SizedBox(height: 24),
            if (_selectedCounty != null ||
                _selectedConstituency != null ||
                _selectedWard != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF93C5FD).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selected Location:',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Color(0xFF1E40AF))),
                    const SizedBox(height: 4),
                    Text(
                      _selectedWard != null &&
                              _selectedConstituency != null &&
                              _selectedCounty != null
                          ? '$_selectedWard, $_selectedConstituency, $_selectedCounty'
                          : 'Please select all fields',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF1E40AF)),
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
            child: const Text('Cancel')),
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
