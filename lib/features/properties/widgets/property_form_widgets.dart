// lib/features/properties/widgets/property_form_widgets.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/features/properties/models/property_listing_model.dart';
import 'package:textgb/features/properties/constants/property_constants.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

// ===================== BASIC FORM FIELDS =====================

class PropertyFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final int maxLines;
  final int? maxLength;
  final TextInputType keyboardType;
  final String? prefixText;
  final String? suffixText;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final bool enabled;

  const PropertyFormField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.required = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.prefixText,
    this.suffixText,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<ModernThemeExtension>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme?.textColor ?? Colors.black,
            ),
            children: [
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: theme?.primaryColor ?? const Color(0xFFFE2C55),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: theme?.textTertiaryColor ?? Colors.grey[400],
            ),
            prefixText: prefixText,
            suffixText: suffixText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme?.dividerColor ?? Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme?.dividerColor ?? Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme?.primaryColor ?? const Color(0xFFFE2C55),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: enabled 
                ? (theme?.surfaceVariantColor ?? Colors.grey[50])
                : Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            counterStyle: TextStyle(
              color: theme?.textTertiaryColor ?? Colors.grey[400],
              fontSize: 12,
            ),
          ),
          style: TextStyle(
            fontSize: 16,
            color: enabled 
                ? (theme?.textColor ?? Colors.black)
                : Colors.grey[500],
          ),
        ),
      ],
    );
  }
}

// ===================== DROPDOWN FIELD =====================

class PropertyDropdownField<T> extends StatelessWidget {
  final T? value;
  final String label;
  final String? hint;
  final bool required;
  final List<T> items;
  final String Function(T)? itemLabel;
  final Function(T?)? onChanged;
  final String? Function(T?)? validator;

  const PropertyDropdownField({
    super.key,
    this.value,
    required this.label,
    this.hint,
    this.required = false,
    required this.items,
    this.itemLabel,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<ModernThemeExtension>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme?.textColor ?? Colors.black,
            ),
            children: [
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: theme?.primaryColor ?? const Color(0xFFFE2C55),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: theme?.textTertiaryColor ?? Colors.grey[400],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme?.dividerColor ?? Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme?.dividerColor ?? Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme?.primaryColor ?? const Color(0xFFFE2C55),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: theme?.surfaceVariantColor ?? Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel?.call(item) ?? item.toString(),
                style: TextStyle(
                  fontSize: 16,
                  color: theme?.textColor ?? Colors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          style: TextStyle(
            fontSize: 16,
            color: theme?.textColor ?? Colors.black,
          ),
          dropdownColor: theme?.surfaceColor ?? Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: theme?.textSecondaryColor ?? Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

// ===================== COUNTER FIELD =====================

class PropertyCounterField extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final Function(int) onChanged;

  const PropertyCounterField({
    super.key,
    required this.label,
    required this.value,
    this.min = 0,
    this.max = 99,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<ModernThemeExtension>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme?.textColor ?? Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme?.dividerColor ?? Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(12),
            color: theme?.surfaceVariantColor ?? Colors.grey[50],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: value > min ? () => onChanged(value - 1) : null,
                icon: Icon(
                  Icons.remove,
                  color: value > min 
                      ? (theme?.primaryColor ?? const Color(0xFFFE2C55))
                      : Colors.grey[400],
                ),
              ),
              Expanded(
                child: Text(
                  value.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme?.textColor ?? Colors.black,
                  ),
                ),
              ),
              IconButton(
                onPressed: value < max ? () => onChanged(value + 1) : null,
                icon: Icon(
                  Icons.add,
                  color: value < max 
                      ? (theme?.primaryColor ?? const Color(0xFFFE2C55))
                      : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===================== PROPERTY TYPE SELECTOR =====================

class PropertyTypeSelector extends StatelessWidget {
  final PropertyType selectedType;
  final Function(PropertyType) onTypeChanged;

  const PropertyTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<ModernThemeExtension>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme?.textColor ?? Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: PropertyType.values.length,
          itemBuilder: (context, index) {
            final type = PropertyType.values[index];
            final isSelected = selectedType == type;
            
            return GestureDetector(
              onTap: () => onTypeChanged(type),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected 
                        ? (theme?.primaryColor ?? const Color(0xFFFE2C55))
                        : (theme?.dividerColor ?? Colors.grey[300]!),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? (theme?.primaryColor?.withOpacity(0.1) ?? const Color(0xFFFE2C55).withOpacity(0.1))
                      : (theme?.surfaceVariantColor ?? Colors.grey[50]),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getPropertyTypeIcon(type),
                      size: 28,
                      color: isSelected
                          ? (theme?.primaryColor ?? const Color(0xFFFE2C55))
                          : (theme?.textSecondaryColor ?? Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      type.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? (theme?.primaryColor ?? const Color(0xFFFE2C55))
                            : (theme?.textColor ?? Colors.black),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  IconData _getPropertyTypeIcon(PropertyType type) {
    switch (type) {
      case PropertyType.room:
        return Icons.single_bed;
      case PropertyType.apartment:
        return Icons.apartment;
      case PropertyType.house:
        return Icons.house;
      case PropertyType.studio:
        return Icons.home_work;
      case PropertyType.villa:
        return Icons.villa;
      case PropertyType.cottage:
        return Icons.cottage;
    }
  }
}

// ===================== AMENITIES GRID =====================

class PropertyAmenitiesGrid extends StatelessWidget {
  final List<String> amenities;
  final Map<String, bool> selectedAmenities;
  final Function(String, bool) onAmenityChanged;

  const PropertyAmenitiesGrid({
    super.key,
    required this.amenities,
    required this.selectedAmenities,
    required this.onAmenityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<ModernThemeExtension>();
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: amenities.map((amenity) {
        final key = _getAmenityKey(amenity);
        final isSelected = selectedAmenities[key] ?? false;
        
        return GestureDetector(
          onTap: () => onAmenityChanged(amenity, !isSelected),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected 
                    ? (theme?.primaryColor ?? const Color(0xFFFE2C55))
                    : (theme?.dividerColor ?? Colors.grey[300]!),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(25),
              color: isSelected
                  ? (theme?.primaryColor?.withOpacity(0.1) ?? const Color(0xFFFE2C55).withOpacity(0.1))
                  : (theme?.surfaceVariantColor ?? Colors.grey[50]),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getAmenityIcon(amenity),
                  size: 18,
                  color: isSelected
                      ? (theme?.primaryColor ?? const Color(0xFFFE2C55))
                      : (theme?.textSecondaryColor ?? Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                Text(
                  amenity,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? (theme?.primaryColor ?? const Color(0xFFFE2C55))
                        : (theme?.textColor ?? Colors.black),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  String _getAmenityKey(String amenity) {
    return amenity.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
  }
  
  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'parking':
        return Icons.local_parking;
      case 'kitchen':
        return Icons.kitchen;
      case 'air conditioning':
        return Icons.ac_unit;
      case 'washing machine':
        return Icons.local_laundry_service;
      case 'tv':
        return Icons.tv;
      case 'pool':
        return Icons.pool;
      case 'gym':
        return Icons.fitness_center;
      case 'balcony':
        return Icons.balcony;
      case 'garden':
        return Icons.yard;
      default:
        return Icons.check_circle_outline;
    }
  }
}

// ===================== VIDEO UPLOADER (Video Only - No Images) =====================

class PropertyVideoUploader extends StatelessWidget {
  final File? videoFile;
  final VideoPlayerController? videoController;
  final Function(File) onVideoSelected;
  final VoidCallback onVideoRemoved;

  const PropertyVideoUploader({
    super.key,
    this.videoFile,
    this.videoController,
    required this.onVideoSelected,
    required this.onVideoRemoved,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<ModernThemeExtension>();
    
    return Column(
      children: [
        if (videoFile == null)
          _buildUploadArea(context, theme)
        else
          _buildVideoPreview(context, theme),
      ],
    );
  }
  
  Widget _buildUploadArea(BuildContext context, ModernThemeExtension? theme) {
    return GestureDetector(
      onTap: () => _pickVideo(context),
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: theme?.dividerColor ?? Colors.grey[300]!,
            style: BorderStyle.solid,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: theme?.surfaceVariantColor ?? Colors.grey[50],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme?.primaryColor?.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.videocam,
                size: 50,
                color: theme?.primaryColor ?? const Color(0xFFFE2C55),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Upload Property Video',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme?.textColor ?? Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Show your property in a 10 second to 2 minute video tour',
              style: TextStyle(
                fontSize: 16,
                color: theme?.textSecondaryColor ?? Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Maximum size: 100MB',
              style: TextStyle(
                fontSize: 14,
                color: theme?.textTertiaryColor ?? Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: theme?.primaryColor ?? const Color(0xFFFE2C55),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: (theme?.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Choose Video File',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVideoPreview(BuildContext context, ModernThemeExtension? theme) {
    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (videoController != null && videoController!.value.isInitialized)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: videoController!.value.aspectRatio,
                  child: VideoPlayer(videoController!),
                ),
              ),
            ),
          
          // Controls overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Top controls
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.videocam,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Property Video',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: onVideoRemoved,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Play button
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          if (videoController != null) {
                            if (videoController!.value.isPlaying) {
                              videoController!.pause();
                            } else {
                              videoController!.play();
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            videoController?.value.isPlaying == true 
                                ? Icons.pause 
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Bottom info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Video Ready',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _pickVideo(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            child: const Text(
                              'Change Video',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
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
        ],
      ),
    );
  }
  
  Future<void> _pickVideo(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: PropertyConstants.maxVideoDurationMinutes),
      );
      
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        // Check file size
        final fileSizeInBytes = await file.length();
        final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
        
        if (fileSizeInMB > PropertyConstants.maxVideoSizeMB) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Video file is too large (${fileSizeInMB.toStringAsFixed(1)}MB). Maximum size is ${PropertyConstants.maxVideoSizeMB}MB.',
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
          return;
        }
        
        onVideoSelected(file);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Video uploaded successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick video: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

// ===================== AVAILABILITY CALENDAR =====================

class PropertyAvailabilityCalendar extends StatefulWidget {
  final List<AvailabilityPeriod> availabilityPeriods;
  final Function(List<AvailabilityPeriod>) onAvailabilityChanged;

  const PropertyAvailabilityCalendar({
    super.key,
    required this.availabilityPeriods,
    required this.onAvailabilityChanged,
  });

  @override
  State<PropertyAvailabilityCalendar> createState() => _PropertyAvailabilityCalendarState();
}

class _PropertyAvailabilityCalendarState extends State<PropertyAvailabilityCalendar> {
  final List<AvailabilityPeriod> _periods = [];

  @override
  void initState() {
    super.initState();
    _periods.addAll(widget.availabilityPeriods);
    if (_periods.isEmpty) {
      _addDefaultPeriod();
    }
  }

  void _addDefaultPeriod() {
    final now = DateTime.now();
    _periods.add(AvailabilityPeriod(
      startDate: now,
      endDate: now.add(const Duration(days: 365)),
      isAvailable: true,
    ));
    _notifyChange();
  }

  void _notifyChange() {
    widget.onAvailabilityChanged(_periods);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<ModernThemeExtension>();
    
    return Column(
      children: [
        // Add period button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addPeriod,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: theme?.primaryColor ?? const Color(0xFFFE2C55),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: Icon(
              Icons.add,
              color: theme?.primaryColor ?? const Color(0xFFFE2C55),
            ),
            label: Text(
              'Add Availability Period',
              style: TextStyle(
                color: theme?.primaryColor ?? const Color(0xFFFE2C55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Periods list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _periods.length,
          itemBuilder: (context, index) {
            return _buildPeriodItem(context, index, theme);
          },
        ),
      ],
    );
  }
  
  Widget _buildPeriodItem(BuildContext context, int index, ModernThemeExtension? theme) {
    final period = _periods[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme?.dividerColor ?? Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(12),
        color: theme?.surfaceVariantColor ?? Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Period ${index + 1}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme?.textColor ?? Colors.black,
                ),
              ),
              if (_periods.length > 1)
                IconButton(
                  onPressed: () => _removePeriod(index),
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red[600],
                    size: 20,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Available toggle
          Row(
            children: [
              Text(
                'Available:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme?.textColor ?? Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: period.isAvailable,
                onChanged: (value) => _updatePeriod(index, period.copyWith(isAvailable: value)),
                activeColor: theme?.primaryColor ?? const Color(0xFFFE2C55),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Date range
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Start Date',
                  date: period.startDate,
                  onDateSelected: (date) => _updatePeriod(
                    index, 
                    period.copyWith(startDate: date),
                  ),
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  label: 'End Date',
                  date: period.endDate,
                  onDateSelected: (date) => _updatePeriod(
                    index, 
                    period.copyWith(endDate: date),
                  ),
                  theme: theme,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Duration info
          Text(
            '${period.durationInDays} days',
            style: TextStyle(
              fontSize: 12,
              color: theme?.textSecondaryColor ?? Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateField({
    required String label,
    required DateTime date,
    required Function(DateTime) onDateSelected,
    required ModernThemeExtension? theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme?.textColor ?? Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _selectDate(date, onDateSelected),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme?.dividerColor ?? Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(8),
              color: theme?.surfaceColor ?? Colors.white,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme?.textSecondaryColor ?? Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme?.textColor ?? Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Future<void> _selectDate(DateTime initialDate, Function(DateTime) onDateSelected) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        final theme = Theme.of(context).extension<ModernThemeExtension>();
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: theme?.primaryColor ?? const Color(0xFFFE2C55),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (selectedDate != null) {
      onDateSelected(selectedDate);
    }
  }
  
  void _addPeriod() {
    final lastPeriod = _periods.isNotEmpty ? _periods.last : null;
    final startDate = lastPeriod?.endDate.add(const Duration(days: 1)) ?? DateTime.now();
    
    _periods.add(AvailabilityPeriod(
      startDate: startDate,
      endDate: startDate.add(const Duration(days: 30)),
      isAvailable: true,
    ));
    
    setState(() {});
    _notifyChange();
  }
  
  void _removePeriod(int index) {
    if (_periods.length > 1) {
      _periods.removeAt(index);
      setState(() {});
      _notifyChange();
    }
  }
  
  void _updatePeriod(int index, AvailabilityPeriod newPeriod) {
    _periods[index] = newPeriod;
    setState(() {});
    _notifyChange();
  }
}

// ===================== HELPER WIDGETS =====================

class PropertyFormSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final EdgeInsets? padding;

  const PropertyFormSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<ModernThemeExtension>();
    
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme?.textColor ?? Colors.black,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: theme?.textSecondaryColor ?? Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class PropertyInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color? color;

  const PropertyInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<ModernThemeExtension>();
    final cardColor = color ?? theme?.primaryColor ?? const Color(0xFFFE2C55);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cardColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: cardColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme?.textColor ?? Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme?.textSecondaryColor ?? Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PropertyLoadingOverlay extends StatelessWidget {
  final String message;
  final double? progress;

  const PropertyLoadingOverlay({
    super.key,
    this.message = 'Processing...',
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (progress != null)
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFE2C55)),
                )
              else
                const CircularProgressIndicator(
                  color: Color(0xFFFE2C55),
                ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (progress != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${(progress! * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== UTILITY METHODS =====================

class PropertyFormValidators {
  static String? validateTitle(String? value) {
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
  }
  
  static String? validateDescription(String? value) {
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
  }
  
  static String? validateRate(String? value) {
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
  }
  
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return PropertyConstants.addressRequired;
    }
    return null;
  }
  
  static String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return PropertyConstants.cityRequired;
    }
    return null;
  }
  
  static String? validateCounty(String? value) {
    if (value == null || value.isEmpty) {
      return PropertyConstants.countyRequired;
    }
    return null;
  }
  
  static String? validateWhatsApp(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (!PropertyConstants.isValidWhatsAppNumber(value)) {
        return PropertyConstants.whatsappInvalid;
      }
    }
    return null;
  }
}

// Helper extension for AvailabilityPeriod
extension AvailabilityPeriodExtension on AvailabilityPeriod {
  AvailabilityPeriod copyWith({
    DateTime? startDate,
    DateTime? endDate,
    bool? isAvailable,
    String? notes,
  }) {
    return AvailabilityPeriod(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isAvailable: isAvailable ?? this.isAvailable,
      notes: notes ?? this.notes,
    );
  }
}

// Helper function to generate property ID
String generatePropertyId() {
  return 'prop_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
}