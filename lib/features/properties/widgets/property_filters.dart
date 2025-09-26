
// lib/features/properties/widgets/property_filters.dart
import 'package:flutter/material.dart';
import 'package:textgb/features/properties/models/property_listing_model.dart';

class PropertyFilters extends StatelessWidget {
  final PropertyType? selectedType;
  final String? selectedCity;
  final double? minRate;
  final double? maxRate;
  final ValueChanged<PropertyType?> onTypeChanged;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<double?> onMinRateChanged;
  final ValueChanged<double?> onMaxRateChanged;
  final VoidCallback onClearFilters;
  final List<String> availableCities;

  const PropertyFilters({
    super.key,
    this.selectedType,
    this.selectedCity,
    this.minRate,
    this.maxRate,
    required this.onTypeChanged,
    required this.onCityChanged,
    required this.onMinRateChanged,
    required this.onMaxRateChanged,
    required this.onClearFilters,
    this.availableCities = const [],
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = selectedType != null || 
                       selectedCity != null || 
                       minRate != null || 
                       maxRate != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasFilters)
                TextButton(
                  onPressed: onClearFilters,
                  child: const Text('Clear All'),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Property Type Filter
          const Text(
            'Property Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTypeChip(null, 'All Types'),
              ...PropertyType.values.map(
                (type) => _buildTypeChip(type, type.displayName),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // City Filter
          const Text(
            'City',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: selectedCity,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintText: 'Select city',
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Cities'),
              ),
              ...availableCities.map(
                (city) => DropdownMenuItem<String?>(
                  value: city,
                  child: Text(city),
                ),
              ),
            ],
            onChanged: onCityChanged,
          ),

          const SizedBox(height: 24),

          // Price Range Filter
          const Text(
            'Price Range (KES per night)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Min price',
                    prefixText: 'KES ',
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: minRate?.toStringAsFixed(0),
                  onChanged: (value) {
                    final rate = double.tryParse(value);
                    onMinRateChanged(rate);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Max price',
                    prefixText: 'KES ',
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: maxRate?.toStringAsFixed(0),
                  onChanged: (value) {
                    final rate = double.tryParse(value);
                    onMaxRateChanged(rate);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Apply Filters Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFE2C55),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTypeChip(PropertyType? type, String label) {
    final isSelected = selectedType == type;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTypeChanged(type),
      selectedColor: const Color(0xFFFE2C55).withOpacity(0.2),
      checkmarkColor: const Color(0xFFFE2C55),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFFE2C55) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected 
              ? const Color(0xFFFE2C55) 
              : Colors.grey[300]!,
        ),
      ),
    );
  }
}

