// lib/features/videos/widgets/category_selection_widget.dart
import 'package:flutter/material.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class CategoryData {
  final String key;
  final String id;
  final String name;
  final String icon;
  final String color;
  final bool hasSubcategories;

  const CategoryData({
    required this.key,
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.hasSubcategories,
  });
}

class SubcategoryData {
  final String key;
  final String id;
  final String name;

  const SubcategoryData({
    required this.key,
    required this.id,
    required this.name,
  });
}

class CategorySelectionWidget extends StatefulWidget {
  final String? selectedMainCategory;
  final String? selectedSubCategory;
  final Function(String mainCategory, String mainCategoryId, String mainCategoryName, String? subCategory, String? subCategoryId, String? subCategoryName) onCategorySelected;

  const CategorySelectionWidget({
    super.key,
    this.selectedMainCategory,
    this.selectedSubCategory,
    required this.onCategorySelected,
  });

  @override
  State<CategorySelectionWidget> createState() => _CategorySelectionWidgetState();
}

class _CategorySelectionWidgetState extends State<CategorySelectionWidget> {
  String? _selectedMainCategory;
  String? _selectedSubCategory;

  // Define all categories with their data
  static const List<CategoryData> _mainCategories = [
    CategoryData(
      key: Constants.vehiclesCategory,
      id: '1',
      name: 'Vehicles',
      icon: Constants.vehiclesCategoryIcon,
      color: Constants.vehiclesCategoryColor,
      hasSubcategories: true,
    ),
    CategoryData(
      key: Constants.fashionCategory,
      id: '2',
      name: 'Fashion & Beauty',
      icon: Constants.fashionCategoryIcon,
      color: Constants.fashionCategoryColor,
      hasSubcategories: true,
    ),
    CategoryData(
      key: Constants.electronicsCategory,
      id: '3',
      name: 'Electronics',
      icon: Constants.electronicsCategoryIcon,
      color: Constants.electronicsCategoryColor,
      hasSubcategories: true,
    ),
    CategoryData(
      key: Constants.furnitureCategory,
      id: '4',
      name: 'Furniture & Home',
      icon: Constants.furnitureCategoryIcon,
      color: Constants.furnitureCategoryColor,
      hasSubcategories: true,
    ),
    CategoryData(
      key: Constants.airbnbCategory,
      id: '5',
      name: 'Airbnb',
      icon: Constants.airbnbCategoryIcon,
      color: Constants.airbnbCategoryColor,
      hasSubcategories: false,
    ),
    CategoryData(
      key: Constants.hotelsCategory,
      id: '6',
      name: 'Hotels & Restaurants',
      icon: Constants.hotelsCategoryIcon,
      color: Constants.hotelsCategoryColor,
      hasSubcategories: false,
    ),
    CategoryData(
      key: Constants.realEstateCategory,
      id: '7',
      name: 'Real Estate',
      icon: Constants.realEstateCategoryIcon,
      color: Constants.realEstateCategoryColor,
      hasSubcategories: true,
    ),
    CategoryData(
      key: Constants.servicesCategory,
      id: '8',
      name: 'Services',
      icon: Constants.servicesCategoryIcon,
      color: Constants.servicesCategoryColor,
      hasSubcategories: true,
    ),
    CategoryData(
      key: Constants.sportsCategory,
      id: '9',
      name: 'Sports & Hobbies',
      icon: Constants.sportsCategoryIcon,
      color: Constants.sportsCategoryColor,
      hasSubcategories: true,
    ),
    CategoryData(
      key: Constants.jobsCategory,
      id: '10',
      name: 'Jobs & Business',
      icon: Constants.jobsCategoryIcon,
      color: Constants.jobsCategoryColor,
      hasSubcategories: true,
    ),
  ];

  // Define subcategories for each main category
  static const Map<String, List<SubcategoryData>> _subcategories = {
    Constants.vehiclesCategory: [
      SubcategoryData(key: Constants.carsSubcategory, id: '1-1', name: 'Cars'),
      SubcategoryData(key: Constants.vehiclePartsSubcategory, id: '1-2', name: 'Vehicle Parts & Accessories'),
      SubcategoryData(key: Constants.trucksSubcategory, id: '1-3', name: 'Trucks & Trailers'),
      SubcategoryData(key: Constants.busesSubcategory, id: '1-4', name: 'Buses & Microbuses'),
      SubcategoryData(key: Constants.motorcyclesSubcategory, id: '1-5', name: 'Motorcycles & Scooters'),
      SubcategoryData(key: Constants.heavyMachinerySubcategory, id: '1-6', name: 'Construction & Heavy Machinery'),
      SubcategoryData(key: Constants.bicyclesSubcategory, id: '1-7', name: 'Bicycles'),
      SubcategoryData(key: Constants.boatsSubcategory, id: '1-8', name: 'Boats & Watercraft'),
    ],
    Constants.fashionCategory: [
      SubcategoryData(key: Constants.menFashionSubcategory, id: '2-1', name: "Men's Fashion"),
      SubcategoryData(key: Constants.womenFashionSubcategory, id: '2-2', name: "Women's Fashion"),
      SubcategoryData(key: Constants.childrenFashionSubcategory, id: '2-3', name: "Children's Fashion"),
      SubcategoryData(key: Constants.shoesSubcategory, id: '2-4', name: 'Shoes'),
      SubcategoryData(key: Constants.bagsAccessoriesSubcategory, id: '2-5', name: 'Bags & Accessories'),
      SubcategoryData(key: Constants.jewelryWatchesSubcategory, id: '2-6', name: 'Jewelry & Watches'),
      SubcategoryData(key: Constants.beautyCosmeticsSubcategory, id: '2-7', name: 'Beauty & Cosmetics'),
      SubcategoryData(key: Constants.traditionalWearSubcategory, id: '2-8', name: 'Traditional Wear'),
    ],
    Constants.electronicsCategory: [
      SubcategoryData(key: Constants.smartphonesSubcategory, id: '3-1', name: 'Smartphones'),
      SubcategoryData(key: Constants.computersLaptopsSubcategory, id: '3-2', name: 'Computers & Laptops'),
      SubcategoryData(key: Constants.tabletsSubcategory, id: '3-3', name: 'Tablets'),
      SubcategoryData(key: Constants.tvAudioSubcategory, id: '3-4', name: 'TV & Audio Systems'),
      SubcategoryData(key: Constants.gamingSubcategory, id: '3-5', name: 'Gaming Consoles & Accessories'),
      SubcategoryData(key: Constants.camerasSubcategory, id: '3-6', name: 'Cameras & Photography'),
      SubcategoryData(key: Constants.homeAppliancesSubcategory, id: '3-7', name: 'Home Appliances'),
      SubcategoryData(key: Constants.electronicsAccessoriesSubcategory, id: '3-8', name: 'Electronics Accessories'),
    ],
    Constants.furnitureCategory: [
      SubcategoryData(key: Constants.livingRoomSubcategory, id: '4-1', name: 'Living Room Furniture'),
      SubcategoryData(key: Constants.bedroomSubcategory, id: '4-2', name: 'Bedroom Furniture'),
      SubcategoryData(key: Constants.kitchenDiningSubcategory, id: '4-3', name: 'Kitchen & Dining'),
      SubcategoryData(key: Constants.officeFurnitureSubcategory, id: '4-4', name: 'Office Furniture'),
      SubcategoryData(key: Constants.homeDecorSubcategory, id: '4-5', name: 'Home Decor'),
      SubcategoryData(key: Constants.gardenOutdoorSubcategory, id: '4-6', name: 'Garden & Outdoor'),
      SubcategoryData(key: Constants.lightingSubcategory, id: '4-7', name: 'Lighting'),
      SubcategoryData(key: Constants.storageOrganizationSubcategory, id: '4-8', name: 'Storage & Organization'),
    ],
    Constants.realEstateCategory: [
      SubcategoryData(key: Constants.apartmentsRentSubcategory, id: '7-1', name: 'Apartments for Rent'),
      SubcategoryData(key: Constants.apartmentsSaleSubcategory, id: '7-2', name: 'Apartments for Sale'),
      SubcategoryData(key: Constants.housesRentSubcategory, id: '7-3', name: 'Houses for Rent'),
      SubcategoryData(key: Constants.housesSaleSubcategory, id: '7-4', name: 'Houses for Sale'),
      SubcategoryData(key: Constants.commercialSubcategory, id: '7-5', name: 'Commercial Properties'),
      SubcategoryData(key: Constants.landSubcategory, id: '7-6', name: 'Land & Plots'),
      SubcategoryData(key: Constants.roommatesSubcategory, id: '7-7', name: 'Roommates & Shared Housing'),
    ],
    Constants.servicesCategory: [
      SubcategoryData(key: Constants.homeServicesSubcategory, id: '8-1', name: 'Home Services'),
      SubcategoryData(key: Constants.beautyWellnessSubcategory, id: '8-2', name: 'Beauty & Wellness'),
      SubcategoryData(key: Constants.automotiveServicesSubcategory, id: '8-3', name: 'Automotive Services'),
      SubcategoryData(key: Constants.tutoringClassesSubcategory, id: '8-4', name: 'Tutoring & Classes'),
      SubcategoryData(key: Constants.eventServicesSubcategory, id: '8-5', name: 'Event Services'),
      SubcategoryData(key: Constants.businessServicesSubcategory, id: '8-6', name: 'Business Services'),
      SubcategoryData(key: Constants.healthMedicalSubcategory, id: '8-7', name: 'Health & Medical'),
      SubcategoryData(key: Constants.freelanceDigitalSubcategory, id: '8-8', name: 'Freelance & Digital Services'),
    ],
    Constants.sportsCategory: [
      SubcategoryData(key: Constants.gymFitnessSubcategory, id: '9-1', name: 'Gym & Fitness Equipment'),
      SubcategoryData(key: Constants.outdoorSportsSubcategory, id: '9-2', name: 'Outdoor Sports'),
      SubcategoryData(key: Constants.indoorGamesSubcategory, id: '9-3', name: 'Indoor Games & Toys'),
      SubcategoryData(key: Constants.musicalInstrumentsSubcategory, id: '9-4', name: 'Musical Instruments'),
      SubcategoryData(key: Constants.booksMediaSubcategory, id: '9-5', name: 'Books & Media'),
      SubcategoryData(key: Constants.artCraftsSubcategory, id: '9-6', name: 'Art & Crafts'),
      SubcategoryData(key: Constants.collectiblesSubcategory, id: '9-7', name: 'Collectibles & Antiques'),
      SubcategoryData(key: Constants.partyEventsSubcategory, id: '9-8', name: 'Party & Event Supplies'),
    ],
    Constants.jobsCategory: [
      SubcategoryData(key: Constants.fullTimeJobsSubcategory, id: '10-1', name: 'Full-time Jobs'),
      SubcategoryData(key: Constants.partTimeJobsSubcategory, id: '10-2', name: 'Part-time Jobs'),
      SubcategoryData(key: Constants.internshipsSubcategory, id: '10-3', name: 'Internships'),
      SubcategoryData(key: Constants.freelanceGigsSubcategory, id: '10-4', name: 'Freelance & Gigs'),
      SubcategoryData(key: Constants.businessForSaleSubcategory, id: '10-5', name: 'Businesses for Sale'),
      SubcategoryData(key: Constants.franchiseOpportunitiesSubcategory, id: '10-6', name: 'Franchise Opportunities'),
      SubcategoryData(key: Constants.partnershipsSubcategory, id: '10-7', name: 'Business Partnerships'),
      SubcategoryData(key: Constants.investmentsSubcategory, id: '10-8', name: 'Investment Opportunities'),
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedMainCategory = widget.selectedMainCategory;
    _selectedSubCategory = widget.selectedSubCategory;
  }

  void _onMainCategorySelected(CategoryData category) {
    setState(() {
      _selectedMainCategory = category.key;
      // Reset subcategory when main category changes
      _selectedSubCategory = null;
    });

    if (!category.hasSubcategories) {
      // Independent category - notify immediately
      widget.onCategorySelected(
        category.key,
        category.id,
        category.name,
        null,
        null,
        null,
      );
    }
  }

  void _onSubCategorySelected(SubcategoryData subcategory) {
    setState(() {
      _selectedSubCategory = subcategory.key;
    });

    // Get main category data
    final mainCategory = _mainCategories.firstWhere(
      (cat) => cat.key == _selectedMainCategory,
    );

    // Notify with both main and sub category
    widget.onCategorySelected(
      mainCategory.key,
      mainCategory.id,
      mainCategory.name,
      subcategory.key,
      subcategory.id,
      subcategory.name,
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'car_icon':
      case 'vehicle_icon':
        return Icons.directions_car;
      case 'fashion_icon':
        return Icons.checkroom;
      case 'electronics_icon':
        return Icons.devices;
      case 'furniture_icon':
        return Icons.chair;
      case 'airbnb_icon':
        return Icons.home;
      case 'hotel_restaurant_icon':
        return Icons.restaurant;
      case 'real_estate_icon':
        return Icons.location_city;
      case 'services_icon':
        return Icons.build;
      case 'sports_icon':
        return Icons.sports_soccer;
      case 'jobs_icon':
        return Icons.work;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Categories
        Text(
          'Select Category *',
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Categories Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _mainCategories.length,
          itemBuilder: (context, index) {
            final category = _mainCategories[index];
            final isSelected = _selectedMainCategory == category.key;
            final categoryColor = _parseColor(category.color);
            
            return GestureDetector(
              onTap: () => _onMainCategorySelected(category),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected 
                      ? categoryColor.withOpacity(0.15)
                      : modernTheme.surfaceColor?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? categoryColor
                        : modernTheme.borderColor ?? Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCategoryIcon(category.icon),
                      color: isSelected ? categoryColor : modernTheme.textSecondaryColor,
                      size: 20,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category.name,
                      style: TextStyle(
                        color: isSelected ? categoryColor : modernTheme.textColor,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        
        // Subcategories (if applicable)
        if (_selectedMainCategory != null && 
            _mainCategories.any((cat) => cat.key == _selectedMainCategory && cat.hasSubcategories)) ...[
          const SizedBox(height: 24),
          Text(
            'Select Subcategory *',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // Subcategories Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _subcategories[_selectedMainCategory]!.map((subcategory) {
              final isSelected = _selectedSubCategory == subcategory.key;
              final mainCategory = _mainCategories.firstWhere(
                (cat) => cat.key == _selectedMainCategory,
              );
              final categoryColor = _parseColor(mainCategory.color);
              
              return GestureDetector(
                onTap: () => _onSubCategorySelected(subcategory),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? categoryColor.withOpacity(0.15)
                        : modernTheme.surfaceColor?.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? categoryColor
                          : modernTheme.borderColor ?? Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    subcategory.name,
                    style: TextStyle(
                      color: isSelected ? categoryColor : modernTheme.textColor,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        
        // Selected Category Display
        if (_selectedMainCategory != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: modernTheme.primaryColor!.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: modernTheme.primaryColor!.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: modernTheme.primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _buildSelectedCategoryText(),
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _buildSelectedCategoryText() {
    if (_selectedMainCategory == null) return '';
    
    final mainCategory = _mainCategories.firstWhere(
      (cat) => cat.key == _selectedMainCategory,
    );
    
    if (!mainCategory.hasSubcategories || _selectedSubCategory == null) {
      return 'Selected: ${mainCategory.name}';
    }
    
    final subcategory = _subcategories[_selectedMainCategory]!.firstWhere(
      (sub) => sub.key == _selectedSubCategory,
    );
    
    return 'Selected: ${mainCategory.name} > ${subcategory.name}';
  }
}