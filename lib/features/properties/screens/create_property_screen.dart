// lib/features/properties/screens/create_property_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/features/properties/models/property_listing_model.dart';
import 'package:textgb/features/properties/providers/property_providers.dart';
import 'package:textgb/features/properties/constants/property_constants.dart';
import 'package:textgb/features/properties/widgets/property_form_widgets.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class CreatePropertyScreen extends ConsumerStatefulWidget {
  final PropertyListingModel? existingProperty; // For editing
  final bool isEditing;

  const CreatePropertyScreen({
    super.key,
    this.existingProperty,
    this.isEditing = false,
  });

  @override
  ConsumerState<CreatePropertyScreen> createState() => _CreatePropertyScreenState();
}

class _CreatePropertyScreenState extends ConsumerState<CreatePropertyScreen>
    with TickerProviderStateMixin {
  
  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  late TabController _tabController;
  
  // Text Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rateController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countyController = TextEditingController();
  final _nearbyLandmarksController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _customAmenitiesController = TextEditingController();
  
  // Form State
  PropertyType _selectedPropertyType = PropertyType.room;
  int _bedrooms = 1;
  int _bathrooms = 1;
  int _maxGuests = 2;
  
  // Location
  double? _latitude;
  double? _longitude;
  
  // Amenities
  final Map<String, bool> _amenities = {
    'wifi': false,
    'parking': false,
    'kitchen': false,
    'airConditioning': false,
    'washingMachine': false,
    'tv': false,
    'pool': false,
    'gym': false,
    'balcony': false,
    'garden': false,
  };
  final List<String> _customAmenities = [];
  
  // Media
  File? _videoFile;
  VideoPlayerController? _videoController;
  final ImagePicker _picker = ImagePicker();
  
  // Availability
  final List<AvailabilityPeriod> _availabilityPeriods = [];
  bool _isCurrentlyAvailable = true;
  
  // UI State
  int _currentStep = 0;
  bool _isLoading = false;
  bool _showPreview = false;
  
  static const int _totalSteps = 5;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _totalSteps, vsync: this);
    _initializeFromExisting();
    _addDefaultAvailability();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rateController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countyController.dispose();
    _nearbyLandmarksController.dispose();
    _whatsappController.dispose();
    _customAmenitiesController.dispose();
    _pageController.dispose();
    _tabController.dispose();
    _videoController?.dispose();
    super.dispose();
  }
  
  void _initializeFromExisting() {
    if (widget.existingProperty != null) {
      final property = widget.existingProperty!;
      _titleController.text = property.title;
      _descriptionController.text = property.description;
      _rateController.text = property.ratePerNightKES.toStringAsFixed(0);
      _selectedPropertyType = property.propertyType;
      _bedrooms = property.bedrooms;
      _bathrooms = property.bathrooms;
      _maxGuests = property.maxGuests;
      _addressController.text = property.location.address;
      _cityController.text = property.location.city;
      _countyController.text = property.location.county;
      _nearbyLandmarksController.text = property.location.nearbyLandmarks ?? '';
      _whatsappController.text = property.hostWhatsappNumber ?? '';
      _latitude = property.location.latitude;
      _longitude = property.location.longitude;
      _isCurrentlyAvailable = property.isCurrentlyAvailable;
      
      // Initialize amenities
      final amenities = property.amenities;
      _amenities['wifi'] = amenities.wifi;
      _amenities['parking'] = amenities.parking;
      _amenities['kitchen'] = amenities.kitchen;
      _amenities['airConditioning'] = amenities.airConditioning;
      _amenities['washingMachine'] = amenities.washingMachine;
      _amenities['tv'] = amenities.tv;
      _amenities['pool'] = amenities.pool;
      _amenities['gym'] = amenities.gym;
      _amenities['balcony'] = amenities.balcony;
      _amenities['garden'] = amenities.garden;
      _customAmenities.addAll(amenities.customAmenities);
      
      // Initialize availability periods
      _availabilityPeriods.addAll(property.availabilityPeriods);
    }
  }
  
  void _addDefaultAvailability() {
    if (_availabilityPeriods.isEmpty) {
      final now = DateTime.now();
      _availabilityPeriods.add(AvailabilityPeriod(
        startDate: now,
        endDate: now.add(const Duration(days: 365)),
        isAvailable: true,
      ));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<ModernThemeExtension>();
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser == null || !currentUser.isHost) {
      return _buildAccessDeniedScreen(theme);
    }
    
    return Scaffold(
      backgroundColor: theme?.backgroundColor ?? Colors.white,
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          _buildProgressIndicator(theme),
          Expanded(
            child: _showPreview 
                ? _buildPreviewSection(theme)
                : _buildFormContent(theme),
          ),
          _buildBottomActions(theme),
        ],
      ),
    );
  }
  
  Widget _buildAccessDeniedScreen(ModernThemeExtension? theme) {
    return Scaffold(
      backgroundColor: theme?.backgroundColor ?? Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Access Denied',
          style: TextStyle(
            color: theme?.textColor ?? Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 80,
                color: Colors.red[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Host Access Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme?.textColor ?? Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Only verified hosts can create property listings. Please contact support to become a host.',
                style: TextStyle(
                  fontSize: 16,
                  color: theme?.textSecondaryColor ?? Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme?.primaryColor ?? const Color(0xFFFE2C55),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar(ModernThemeExtension? theme) {
    return AppBar(
      backgroundColor: theme?.surfaceColor ?? Colors.white,
      elevation: 1,
      title: Text(
        widget.isEditing ? 'Edit Property' : 'Create Property Listing',
        style: TextStyle(
          color: theme?.textColor ?? Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        onPressed: () => _showExitConfirmation(),
        icon: Icon(
          Icons.close,
          color: theme?.textColor ?? Colors.black,
        ),
      ),
      actions: [
        if (!_showPreview)
          TextButton(
            onPressed: _canShowPreview() ? () => setState(() => _showPreview = true) : null,
            child: Text(
              'Preview',
              style: TextStyle(
                color: _canShowPreview() 
                    ? (theme?.primaryColor ?? const Color(0xFFFE2C55))
                    : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (_showPreview)
          TextButton(
            onPressed: () => setState(() => _showPreview = false),
            child: Text(
              'Edit',
              style: TextStyle(
                color: theme?.primaryColor ?? const Color(0xFFFE2C55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }
  
  Widget _buildProgressIndicator(ModernThemeExtension? theme) {
    if (_showPreview) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme?.surfaceColor ?? Colors.white,
        border: Border(
          bottom: BorderSide(
            color: theme?.dividerColor ?? Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: TextStyle(
                  color: theme?.textSecondaryColor ?? Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${((_currentStep + 1) / _totalSteps * 100).toInt()}%',
                style: TextStyle(
                  color: theme?.primaryColor ?? const Color(0xFFFE2C55),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: theme?.dividerColor ?? Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(
              theme?.primaryColor ?? const Color(0xFFFE2C55),
            ),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
  
  Widget _buildFormContent(ModernThemeExtension? theme) {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentStep = index),
      children: [
        _buildBasicInfoStep(theme),
        _buildLocationStep(theme),
        _buildAmenitiesStep(theme),
        _buildMediaStep(theme),
        _buildAvailabilityStep(theme),
      ],
    );
  }
  
  Widget _buildBasicInfoStep(ModernThemeExtension? theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme?.textColor ?? Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us about your property',
              style: TextStyle(
                fontSize: 16,
                color: theme?.textSecondaryColor ?? Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            
            // Property Title
            PropertyFormField(
              controller: _titleController,
              label: 'Property Title',
              hint: 'e.g., Cozy 2-bedroom apartment in Westlands',
              required: true,
              maxLength: PropertyConstants.maxTitleLength,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return PropertyConstants.titleRequired;
                }
                if (value.trim().length < PropertyConstants.minTitleLength) {
                  return PropertyConstants.titleTooShort;
                }
                if (value.length > PropertyConstants.maxTitleLength) {
                  return PropertyConstants.titleTooLong;
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Property Type
            PropertyTypeSelector(
              selectedType: _selectedPropertyType,
              onTypeChanged: (type) => setState(() => _selectedPropertyType = type),
            ),
            
            const SizedBox(height: 24),
            
            // Property Details Row
            Row(
              children: [
                Expanded(
                  child: PropertyCounterField(
                    label: 'Bedrooms',
                    value: _bedrooms,
                    min: 0,
                    max: PropertyConstants.maxBedroomsLimit,
                    onChanged: (value) => setState(() => _bedrooms = value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PropertyCounterField(
                    label: 'Bathrooms',
                    value: _bathrooms,
                    min: 1,
                    max: PropertyConstants.maxBathroomsLimit,
                    onChanged: (value) => setState(() => _bathrooms = value),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: PropertyCounterField(
                    label: 'Max Guests',
                    value: _maxGuests,
                    min: 1,
                    max: PropertyConstants.maxGuestsLimit,
                    onChanged: (value) => setState(() => _maxGuests = value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PropertyFormField(
                    controller: _rateController,
                    label: 'Rate per Night (KES)',
                    hint: '5000',
                    keyboardType: TextInputType.number,
                    required: true,
                    prefixText: 'KES ',
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return PropertyConstants.rateRequired;
                      }
                      final rate = double.tryParse(value);
                      if (rate == null || 
                          rate < PropertyConstants.minRatePerNightKES || 
                          rate > PropertyConstants.maxRatePerNightKES) {
                        return PropertyConstants.rateInvalid;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Description
            PropertyFormField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Describe your property, its features, and what makes it special...',
              maxLines: 5,
              maxLength: PropertyConstants.maxDescriptionLength,
              required: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return PropertyConstants.descriptionRequired;
                }
                if (value.trim().length < PropertyConstants.minDescriptionLength) {
                  return PropertyConstants.descriptionTooShort;
                }
                if (value.length > PropertyConstants.maxDescriptionLength) {
                  return PropertyConstants.descriptionTooLong;
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // WhatsApp Contact
            PropertyFormField(
              controller: _whatsappController,
              label: 'WhatsApp Number (Optional)',
              hint: '254712345678',
              keyboardType: TextInputType.phone,
              prefixText: '+',
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (!PropertyConstants.isValidWhatsAppNumber(value)) {
                    return PropertyConstants.whatsappInvalid;
                  }
                }
                return null;
              },
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLocationStep(ModernThemeExtension? theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location Details',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme?.textColor ?? Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help guests find your property',
            style: TextStyle(
              fontSize: 16,
              color: theme?.textSecondaryColor ?? Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Address
          PropertyFormField(
            controller: _addressController,
            label: 'Street Address',
            hint: 'e.g., Waiyaki Way, ABC Apartments, House No. 123',
            required: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return PropertyConstants.addressRequired;
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          // City and County
          Row(
            children: [
              Expanded(
                child: PropertyDropdownField<String>(
                  value: _cityController.text.isEmpty ? null : _cityController.text,
                  label: 'City',
                  hint: 'Select city',
                  items: PropertyConstants.majorKenyanCities,
                  onChanged: (value) {
                    setState(() {
                      _cityController.text = value ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return PropertyConstants.cityRequired;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PropertyDropdownField<String>(
                  value: _countyController.text.isEmpty ? null : _countyController.text,
                  label: 'County',
                  hint: 'Select county',
                  items: PropertyConstants.kenyanCounties,
                  onChanged: (value) {
                    setState(() {
                      _countyController.text = value ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return PropertyConstants.countyRequired;
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Nearby Landmarks
          PropertyFormField(
            controller: _nearbyLandmarksController,
            label: 'Nearby Landmarks (Optional)',
            hint: 'e.g., Near Sarit Centre, 5 minutes from Junction Mall',
            maxLines: 2,
          ),
          
          const SizedBox(height: 32),
          
          // Map Section (Placeholder)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme?.dividerColor ?? Colors.grey[300]!,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Pin Location on Map',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildAmenitiesStep(ModernThemeExtension? theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities & Features',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme?.textColor ?? Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What does your property offer?',
            style: TextStyle(
              fontSize: 16,
              color: theme?.textSecondaryColor ?? Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Basic Amenities
          Text(
            'Basic Amenities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme?.textColor ?? Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          PropertyAmenitiesGrid(
            amenities: PropertyConstants.basicAmenities,
            selectedAmenities: _amenities,
            onAmenityChanged: (amenity, selected) {
              setState(() {
                _amenities[amenity.toLowerCase().replaceAll(' ', '')] = selected;
              });
            },
          ),
          
          const SizedBox(height: 32),
          
          // Luxury Amenities
          Text(
            'Luxury Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme?.textColor ?? Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          PropertyAmenitiesGrid(
            amenities: PropertyConstants.luxuryAmenities,
            selectedAmenities: _amenities,
            onAmenityChanged: (amenity, selected) {
              setState(() {
                String key = amenity.toLowerCase().replaceAll(' ', '');
                if (key == 'airconditioner') key = 'airConditioning';
                if (key == 'washingmachine') key = 'washingMachine';
                _amenities[key] = selected;
              });
            },
          ),
          
          const SizedBox(height: 32),
          
          // Custom Amenities
          Text(
            'Additional Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme?.textColor ?? Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          PropertyFormField(
            controller: _customAmenitiesController,
            label: 'Other amenities (separate with commas)',
            hint: 'e.g., Rooftop terrace, Pet-friendly, 24/7 security',
            maxLines: 2,
            onChanged: (value) {
              _customAmenities.clear();
              if (value.isNotEmpty) {
                _customAmenities.addAll(
                  value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
                );
              }
            },
          ),
          
          if (_customAmenities.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _customAmenities.map((amenity) {
                return Chip(
                  label: Text(amenity),
                  backgroundColor: theme?.primaryColor?.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: theme?.primaryColor ?? const Color(0xFFFE2C55),
                  ),
                  deleteIcon: Icon(
                    Icons.close,
                    size: 18,
                    color: theme?.primaryColor ?? const Color(0xFFFE2C55),
                  ),
                  onDeleted: () {
                    setState(() {
                      _customAmenities.remove(amenity);
                      _customAmenitiesController.text = _customAmenities.join(', ');
                    });
                  },
                );
              }).toList(),
            ),
          ],
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildMediaStep(ModernThemeExtension? theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photos & Video',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme?.textColor ?? Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Show off your property with a video tour',
            style: TextStyle(
              fontSize: 16,
              color: theme?.textSecondaryColor ?? Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Video Section
          Text(
            'Property Video (Required)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme?.textColor ?? Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a 10 second to 2 minute video tour of your property',
            style: TextStyle(
              fontSize: 14,
              color: theme?.textSecondaryColor ?? Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          
          PropertyVideoUploader(
            videoFile: _videoFile,
            videoController: _videoController,
            onVideoSelected: _handleVideoSelection,
            onVideoRemoved: _handleVideoRemoval,
          ),
          
          const SizedBox(height: 24),
          
          // Video Tips
          PropertyInfoCard(
            icon: Icons.videocam,
            title: 'Video Tips',
            description: 'Show all rooms, highlight unique features, good lighting, steady shots',
            color: Colors.blue,
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildAvailabilityStep(ModernThemeExtension? theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Availability',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme?.textColor ?? Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set when your property is available for booking',
            style: TextStyle(
              fontSize: 16,
              color: theme?.textSecondaryColor ?? Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Current Status
          Row(
            children: [
              Text(
                'Currently Available:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme?.textColor ?? Colors.black,
                ),
              ),
              const SizedBox(width: 16),
              Switch(
                value: _isCurrentlyAvailable,
                onChanged: (value) => setState(() => _isCurrentlyAvailable = value),
                activeColor: theme?.primaryColor ?? const Color(0xFFFE2C55),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Availability Periods
          Text(
            'Availability Periods',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme?.textColor ?? Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          PropertyAvailabilityCalendar(
            availabilityPeriods: _availabilityPeriods,
            onAvailabilityChanged: (periods) {
              setState(() {
                _availabilityPeriods.clear();
                _availabilityPeriods.addAll(periods);
              });
            },
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildPreviewSection(ModernThemeExtension? theme) {
    final property = _buildPropertyModel();
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Preview
          if (_videoFile != null && _videoController != null)
            AspectRatio(
              aspectRatio: PropertyConstants.propertyVideoAspectRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: VideoPlayer(_videoController!),
                    ),
                    // Property Info Overlay (from feed screen)
                    Positioned(
                      left: 16,
                      right: 80,
                      bottom: 100,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              property.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${property.propertyTypeDisplay} • ${property.fullDescription}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    property.location.shortAddress,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFE2C55).withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${property.formattedRate}/night',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Play button overlay
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Property Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFFE2C55),
                      child: Text(
                        property.hostName.isNotEmpty
                            ? property.hostName[0].toUpperCase()
                            : 'H',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.hostName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: theme?.textColor ?? Colors.black,
                            ),
                          ),
                          Text(
                            'Host',
                            style: TextStyle(
                              color: theme?.textSecondaryColor ?? Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme?.textColor ?? Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  property.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme?.textColor ?? Colors.black,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'Amenities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme?.textColor ?? Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: property.amenities.enabledAmenities.map((amenity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme?.primaryColor?.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme?.primaryColor ?? const Color(0xFFFE2C55),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        amenity,
                        style: TextStyle(
                          color: theme?.primaryColor ?? const Color(0xFFFE2C55),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme?.textColor ?? Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  property.location.fullAddress,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme?.textColor ?? Colors.black,
                  ),
                ),
                
                if (property.location.nearbyLandmarks?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Near: ${property.location.nearbyLandmarks}',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme?.textSecondaryColor ?? Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomActions(ModernThemeExtension? theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme?.surfaceColor ?? Colors.white,
        border: Border(
          top: BorderSide(
            color: theme?.dividerColor ?? Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: _showPreview ? _buildPreviewActions(theme) : _buildFormActions(theme),
    );
  }
  
  Widget _buildPreviewActions(ModernThemeExtension? theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => setState(() => _showPreview = false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: theme?.primaryColor ?? const Color(0xFFFE2C55),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Back to Edit',
              style: TextStyle(
                color: theme?.primaryColor ?? const Color(0xFFFE2C55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme?.primaryColor ?? const Color(0xFFFE2C55),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.isEditing ? 'Update Property' : 'Create Property',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFormActions(ModernThemeExtension? theme) {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: theme?.dividerColor ?? Colors.grey[300]!,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Back',
                style: TextStyle(
                  color: theme?.textColor ?? Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          flex: _currentStep == 0 ? 1 : 2,
          child: ElevatedButton(
            onPressed: _canProceed() ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme?.primaryColor ?? const Color(0xFFFE2C55),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              _currentStep == _totalSteps - 1 ? 'Review' : 'Next',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Helper Methods
  bool _canProceed() {
    switch (_currentStep) {
      case 0: // Basic Info
        return _titleController.text.trim().isNotEmpty &&
               _descriptionController.text.trim().isNotEmpty &&
               _rateController.text.trim().isNotEmpty;
      case 1: // Location
        return _addressController.text.trim().isNotEmpty &&
               _cityController.text.trim().isNotEmpty &&
               _countyController.text.trim().isNotEmpty;
      case 2: // Amenities
        return true; // Amenities are optional
      case 3: // Media
        return _videoFile != null; // Video is required
      case 4: // Availability
        return _availabilityPeriods.isNotEmpty;
      default:
        return false;
    }
  }
  
  bool _canShowPreview() {
    return _titleController.text.trim().isNotEmpty &&
           _descriptionController.text.trim().isNotEmpty &&
           _rateController.text.trim().isNotEmpty &&
           _addressController.text.trim().isNotEmpty &&
           _cityController.text.trim().isNotEmpty &&
           _countyController.text.trim().isNotEmpty &&
           _videoFile != null;
  }
  
  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  Future<void> _handleVideoSelection(File videoFile) async {
    setState(() {
      _videoFile = videoFile;
    });
    
    _videoController = VideoPlayerController.file(videoFile);
    await _videoController!.initialize();
    setState(() {});
  }
  
  void _handleVideoRemoval() {
    setState(() {
      _videoFile = null;
      _videoController?.dispose();
      _videoController = null;
    });
  }
  
  PropertyListingModel _buildPropertyModel() {
    final currentUser = ref.read(currentUserProvider)!;
    final now = DateTime.now();
    
    return PropertyListingModel(
      id: widget.existingProperty?.id ?? generatePropertyId(),
      hostId: currentUser.uid,
      hostName: currentUser.name,
      hostImage: currentUser.profileImage,
      hostPhoneNumber: currentUser.phoneNumber,
      hostWhatsappNumber: _whatsappController.text.trim().isNotEmpty
          ? PropertyConstants.formatWhatsAppNumber(_whatsappController.text.trim())
          : null,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      propertyType: _selectedPropertyType,
      location: PropertyLocation(
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        county: _countyController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        nearbyLandmarks: _nearbyLandmarksController.text.trim().isNotEmpty
            ? _nearbyLandmarksController.text.trim()
            : null,
      ),
      amenities: PropertyAmenities(
        wifi: _amenities['wifi'] ?? false,
        parking: _amenities['parking'] ?? false,
        kitchen: _amenities['kitchen'] ?? false,
        airConditioning: _amenities['airConditioning'] ?? false,
        washingMachine: _amenities['washingMachine'] ?? false,
        tv: _amenities['tv'] ?? false,
        pool: _amenities['pool'] ?? false,
        gym: _amenities['gym'] ?? false,
        balcony: _amenities['balcony'] ?? false,
        garden: _amenities['garden'] ?? false,
        customAmenities: _customAmenities,
      ),
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
      maxGuests: _maxGuests,
      ratePerNightKES: double.tryParse(_rateController.text) ?? 0.0,
      videoUrl: '', // Will be set after upload
      thumbnailUrl: '', // Will be set after upload
      availabilityPeriods: _availabilityPeriods,
      isCurrentlyAvailable: _isCurrentlyAvailable,
      status: widget.existingProperty?.status ?? PropertyStatus.draft,
      subscriptionExpiresAt: widget.existingProperty?.subscriptionExpiresAt ??
          now.add(const Duration(days: PropertyConstants.subscriptionDurationDays)),
      createdAt: widget.existingProperty?.createdAt ?? now,
      updatedAt: now,
    );
  }
  
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in the form'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(PropertyConstants.videoRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final property = _buildPropertyModel();
      
      if (widget.isEditing && widget.existingProperty != null) {
        await ref.read(hostPropertiesProvider.notifier).updateProperty(
          property: property,
          newVideoFile: _videoFile,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(PropertyConstants.propertyUpdated),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await ref.read(hostPropertiesProvider.notifier).createProperty(
          property: property,
          videoFile: _videoFile!,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(PropertyConstants.propertyCreated),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'Are you sure you want to leave? Your changes will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close screen
            },
            child: const Text(
              'Discard',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}