// lib/features/properties/models/property_listing_model.dart

// Property status enum
enum PropertyStatus {
  draft('draft'),           // Created but not submitted for verification
  pending('pending'),       // Submitted for admin verification
  verified('verified'),     // Admin verified and active
  rejected('rejected'),     // Admin rejected
  inactive('inactive'),     // Admin deactivated
  expired('expired');       // Subscription expired

  const PropertyStatus(this.value);
  final String value;

  static PropertyStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'draft':
        return PropertyStatus.draft;
      case 'pending':
        return PropertyStatus.pending;
      case 'verified':
        return PropertyStatus.verified;
      case 'rejected':
        return PropertyStatus.rejected;
      case 'inactive':
        return PropertyStatus.inactive;
      case 'expired':
        return PropertyStatus.expired;
      default:
        return PropertyStatus.draft;
    }
  }

  String get displayName {
    switch (this) {
      case PropertyStatus.draft:
        return 'Draft';
      case PropertyStatus.pending:
        return 'Pending Review';
      case PropertyStatus.verified:
        return 'Active';
      case PropertyStatus.rejected:
        return 'Rejected';
      case PropertyStatus.inactive:
        return 'Inactive';
      case PropertyStatus.expired:
        return 'Expired';
    }
  }

  bool get isVisible => this == PropertyStatus.verified;
  bool get canBeEdited => this == PropertyStatus.draft || this == PropertyStatus.rejected;
}

// Property type enum
enum PropertyType {
  apartment('apartment'),
  house('house'),
  room('room'),
  studio('studio'),
  villa('villa'),
  cottage('cottage');

  const PropertyType(this.value);
  final String value;

  static PropertyType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'apartment':
        return PropertyType.apartment;
      case 'house':
        return PropertyType.house;
      case 'room':
        return PropertyType.room;
      case 'studio':
        return PropertyType.studio;
      case 'villa':
        return PropertyType.villa;
      case 'cottage':
        return PropertyType.cottage;
      default:
        return PropertyType.room;
    }
  }

  String get displayName {
    switch (this) {
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.house:
        return 'House';
      case PropertyType.room:
        return 'Room';
      case PropertyType.studio:
        return 'Studio';
      case PropertyType.villa:
        return 'Villa';
      case PropertyType.cottage:
        return 'Cottage';
    }
  }
}

// Property amenities
class PropertyAmenities {
  final bool wifi;
  final bool parking;
  final bool kitchen;
  final bool airConditioning;
  final bool washingMachine;
  final bool tv;
  final bool pool;
  final bool gym;
  final bool balcony;
  final bool garden;
  final List<String> customAmenities;

  const PropertyAmenities({
    this.wifi = false,
    this.parking = false,
    this.kitchen = false,
    this.airConditioning = false,
    this.washingMachine = false,
    this.tv = false,
    this.pool = false,
    this.gym = false,
    this.balcony = false,
    this.garden = false,
    this.customAmenities = const [],
  });

  factory PropertyAmenities.fromMap(Map<String, dynamic> map) {
    return PropertyAmenities(
      wifi: map['wifi'] ?? false,
      parking: map['parking'] ?? false,
      kitchen: map['kitchen'] ?? false,
      airConditioning: map['airConditioning'] ?? map['air_conditioning'] ?? false,
      washingMachine: map['washingMachine'] ?? map['washing_machine'] ?? false,
      tv: map['tv'] ?? false,
      pool: map['pool'] ?? false,
      gym: map['gym'] ?? false,
      balcony: map['balcony'] ?? false,
      garden: map['garden'] ?? false,
      customAmenities: _parseStringArray(map['customAmenities'] ?? map['custom_amenities']),
    );
  }

  static List<String> _parseStringArray(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    if (value is String) {
      if (value.isEmpty || value == '{}' || value == '[]') return [];
      return value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  Map<String, dynamic> toMap() {
    return {
      'wifi': wifi,
      'parking': parking,
      'kitchen': kitchen,
      'airConditioning': airConditioning,
      'washingMachine': washingMachine,
      'tv': tv,
      'pool': pool,
      'gym': gym,
      'balcony': balcony,
      'garden': garden,
      'customAmenities': customAmenities,
    };
  }

  PropertyAmenities copyWith({
    bool? wifi,
    bool? parking,
    bool? kitchen,
    bool? airConditioning,
    bool? washingMachine,
    bool? tv,
    bool? pool,
    bool? gym,
    bool? balcony,
    bool? garden,
    List<String>? customAmenities,
  }) {
    return PropertyAmenities(
      wifi: wifi ?? this.wifi,
      parking: parking ?? this.parking,
      kitchen: kitchen ?? this.kitchen,
      airConditioning: airConditioning ?? this.airConditioning,
      washingMachine: washingMachine ?? this.washingMachine,
      tv: tv ?? this.tv,
      pool: pool ?? this.pool,
      gym: gym ?? this.gym,
      balcony: balcony ?? this.balcony,
      garden: garden ?? this.garden,
      customAmenities: customAmenities ?? this.customAmenities,
    );
  }

  List<String> get enabledAmenities {
    List<String> amenities = [];
    if (wifi) amenities.add('WiFi');
    if (parking) amenities.add('Parking');
    if (kitchen) amenities.add('Kitchen');
    if (airConditioning) amenities.add('Air Conditioning');
    if (washingMachine) amenities.add('Washing Machine');
    if (tv) amenities.add('TV');
    if (pool) amenities.add('Pool');
    if (gym) amenities.add('Gym');
    if (balcony) amenities.add('Balcony');
    if (garden) amenities.add('Garden');
    amenities.addAll(customAmenities);
    return amenities;
  }
}

// Property location
class PropertyLocation {
  final String address;
  final String city;
  final String county;
  final String country;
  final double? latitude;
  final double? longitude;
  final String? nearbyLandmarks;

  const PropertyLocation({
    required this.address,
    required this.city,
    required this.county,
    this.country = 'Kenya',
    this.latitude,
    this.longitude,
    this.nearbyLandmarks,
  });

  factory PropertyLocation.fromMap(Map<String, dynamic> map) {
    return PropertyLocation(
      address: map['address']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      county: map['county']?.toString() ?? '',
      country: map['country']?.toString() ?? 'Kenya',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      nearbyLandmarks: map['nearbyLandmarks']?.toString() ?? map['nearby_landmarks']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'city': city,
      'county': county,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'nearbyLandmarks': nearbyLandmarks,
    };
  }

  PropertyLocation copyWith({
    String? address,
    String? city,
    String? county,
    String? country,
    double? latitude,
    double? longitude,
    String? nearbyLandmarks,
  }) {
    return PropertyLocation(
      address: address ?? this.address,
      city: city ?? this.city,
      county: county ?? this.county,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      nearbyLandmarks: nearbyLandmarks ?? this.nearbyLandmarks,
    );
  }

  String get fullAddress => '$address, $city, $county';
  String get shortAddress => '$city, $county';
  bool get hasCoordinates => latitude != null && longitude != null;
}

// Property availability period
class AvailabilityPeriod {
  final DateTime startDate;
  final DateTime endDate;
  final bool isAvailable;
  final String? notes;

  const AvailabilityPeriod({
    required this.startDate,
    required this.endDate,
    required this.isAvailable,
    this.notes,
  });

  factory AvailabilityPeriod.fromMap(Map<String, dynamic> map) {
    return AvailabilityPeriod(
      startDate: DateTime.parse(map['startDate'] ?? map['start_date']),
      endDate: DateTime.parse(map['endDate'] ?? map['end_date']),
      isAvailable: map['isAvailable'] ?? map['is_available'] ?? true,
      notes: map['notes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isAvailable': isAvailable,
      'notes': notes,
    };
  }

  bool isAvailableOn(DateTime date) {
    return isAvailable && 
           date.isAfter(startDate.subtract(const Duration(days: 1))) && 
           date.isBefore(endDate.add(const Duration(days: 1)));
  }

  int get durationInDays => endDate.difference(startDate).inDays + 1;
}

// Main Property Listing Model
class PropertyListingModel {
  final String id;
  final String hostId;
  final String hostName;
  final String hostImage;
  final String hostPhoneNumber;
  final String? hostWhatsappNumber;
  
  // Property details
  final String title;
  final String description;
  final PropertyType propertyType;
  final PropertyLocation location;
  final PropertyAmenities amenities;
  final int bedrooms;
  final int bathrooms;
  final int maxGuests;
  final double ratePerNightKES;
  
  // Media
  final String videoUrl;
  final String thumbnailUrl;
  final List<String> imageUrls;
  
  // Availability
  final List<AvailabilityPeriod> availabilityPeriods;
  final DateTime? nextAvailableDate;
  final bool isCurrentlyAvailable;
  
  // Status and admin
  final PropertyStatus status;
  final String? adminNotes;
  final DateTime? verifiedAt;
  final String? verifiedByAdmin;
  final DateTime subscriptionExpiresAt;
  final bool subscriptionActive;
  
  // Engagement (independent system)
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final int inquiriesCount;
  final bool isLiked; // Current user's like status
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastInquiryAt;
  final bool isFeatured;
  final List<String> tags;
  
  const PropertyListingModel({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.hostImage,
    required this.hostPhoneNumber,
    this.hostWhatsappNumber,
    required this.title,
    required this.description,
    required this.propertyType,
    required this.location,
    required this.amenities,
    required this.bedrooms,
    required this.bathrooms,
    required this.maxGuests,
    required this.ratePerNightKES,
    required this.videoUrl,
    required this.thumbnailUrl,
    this.imageUrls = const [],
    this.availabilityPeriods = const [],
    this.nextAvailableDate,
    this.isCurrentlyAvailable = false,
    this.status = PropertyStatus.draft,
    this.adminNotes,
    this.verifiedAt,
    this.verifiedByAdmin,
    required this.subscriptionExpiresAt,
    this.subscriptionActive = true,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    this.inquiriesCount = 0,
    this.isLiked = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastInquiryAt,
    this.isFeatured = false,
    this.tags = const [],
  });

  factory PropertyListingModel.fromMap(Map<String, dynamic> map) {
    return PropertyListingModel(
      id: map['id']?.toString() ?? '',
      hostId: map['hostId']?.toString() ?? map['host_id']?.toString() ?? '',
      hostName: map['hostName']?.toString() ?? map['host_name']?.toString() ?? '',
      hostImage: map['hostImage']?.toString() ?? map['host_image']?.toString() ?? '',
      hostPhoneNumber: map['hostPhoneNumber']?.toString() ?? map['host_phone_number']?.toString() ?? '',
      hostWhatsappNumber: map['hostWhatsappNumber']?.toString() ?? map['host_whatsapp_number']?.toString(),
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      propertyType: PropertyType.fromString(map['propertyType'] ?? map['property_type']),
      location: PropertyLocation.fromMap((map['location'] ?? {}) as Map<String, dynamic>),
      amenities: PropertyAmenities.fromMap((map['amenities'] ?? {}) as Map<String, dynamic>),
      bedrooms: (map['bedrooms'] ?? 1).toInt(),
      bathrooms: (map['bathrooms'] ?? 1).toInt(),
      maxGuests: (map['maxGuests'] ?? map['max_guests'] ?? 2).toInt(),
      ratePerNightKES: (map['ratePerNightKES'] ?? map['rate_per_night_kes'] ?? 0.0).toDouble(),
      videoUrl: map['videoUrl']?.toString() ?? map['video_url']?.toString() ?? '',
      thumbnailUrl: map['thumbnailUrl']?.toString() ?? map['thumbnail_url']?.toString() ?? '',
      imageUrls: _parseStringArray(map['imageUrls'] ?? map['image_urls']),
      availabilityPeriods: _parseAvailabilityPeriods(map['availabilityPeriods'] ?? map['availability_periods']),
      nextAvailableDate: map['nextAvailableDate'] != null || map['next_available_date'] != null
          ? DateTime.parse(map['nextAvailableDate'] ?? map['next_available_date'])
          : null,
      isCurrentlyAvailable: map['isCurrentlyAvailable'] ?? map['is_currently_available'] ?? false,
      status: PropertyStatus.fromString(map['status']),
      adminNotes: map['adminNotes']?.toString() ?? map['admin_notes']?.toString(),
      verifiedAt: map['verifiedAt'] != null || map['verified_at'] != null
          ? DateTime.parse(map['verifiedAt'] ?? map['verified_at'])
          : null,
      verifiedByAdmin: map['verifiedByAdmin']?.toString() ?? map['verified_by_admin']?.toString(),
      subscriptionExpiresAt: DateTime.parse(
        map['subscriptionExpiresAt'] ?? map['subscription_expires_at'] ?? DateTime.now().add(const Duration(days: 365)).toIso8601String()
      ),
      subscriptionActive: map['subscriptionActive'] ?? map['subscription_active'] ?? true,
      likesCount: (map['likesCount'] ?? map['likes_count'] ?? 0).toInt(),
      commentsCount: (map['commentsCount'] ?? map['comments_count'] ?? 0).toInt(),
      viewsCount: (map['viewsCount'] ?? map['views_count'] ?? 0).toInt(),
      inquiriesCount: (map['inquiriesCount'] ?? map['inquiries_count'] ?? 0).toInt(),
      isLiked: map['isLiked'] ?? map['is_liked'] ?? false,
      createdAt: DateTime.parse(map['createdAt'] ?? map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? map['updated_at'] ?? DateTime.now().toIso8601String()),
      lastInquiryAt: map['lastInquiryAt'] != null || map['last_inquiry_at'] != null
          ? DateTime.parse(map['lastInquiryAt'] ?? map['last_inquiry_at'])
          : null,
      isFeatured: map['isFeatured'] ?? map['is_featured'] ?? false,
      tags: _parseStringArray(map['tags']),
    );
  }

  // Helper methods for parsing
  static List<String> _parseStringArray(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    if (value is String) {
      if (value.isEmpty || value == '{}' || value == '[]') return [];
      return value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  static List<AvailabilityPeriod> _parseAvailabilityPeriods(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => e is Map<String, dynamic> ? AvailabilityPeriod.fromMap(e) : null)
          .where((e) => e != null)
          .cast<AvailabilityPeriod>()
          .toList();
    }
    return [];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hostId': hostId,
      'hostName': hostName,
      'hostImage': hostImage,
      'hostPhoneNumber': hostPhoneNumber,
      'hostWhatsappNumber': hostWhatsappNumber,
      'title': title,
      'description': description,
      'propertyType': propertyType.value,
      'location': location.toMap(),
      'amenities': amenities.toMap(),
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'maxGuests': maxGuests,
      'ratePerNightKES': ratePerNightKES,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'imageUrls': imageUrls,
      'availabilityPeriods': availabilityPeriods.map((period) => period.toMap()).toList(),
      'nextAvailableDate': nextAvailableDate?.toIso8601String(),
      'isCurrentlyAvailable': isCurrentlyAvailable,
      'status': status.value,
      'adminNotes': adminNotes,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verifiedByAdmin': verifiedByAdmin,
      'subscriptionExpiresAt': subscriptionExpiresAt.toIso8601String(),
      'subscriptionActive': subscriptionActive,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'viewsCount': viewsCount,
      'inquiriesCount': inquiriesCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastInquiryAt': lastInquiryAt?.toIso8601String(),
      'isFeatured': isFeatured,
      'tags': tags,
    };
  }

  PropertyListingModel copyWith({
    String? id,
    String? hostId,
    String? hostName,
    String? hostImage,
    String? hostPhoneNumber,
    String? hostWhatsappNumber,
    String? title,
    String? description,
    PropertyType? propertyType,
    PropertyLocation? location,
    PropertyAmenities? amenities,
    int? bedrooms,
    int? bathrooms,
    int? maxGuests,
    double? ratePerNightKES,
    String? videoUrl,
    String? thumbnailUrl,
    List<String>? imageUrls,
    List<AvailabilityPeriod>? availabilityPeriods,
    DateTime? nextAvailableDate,
    bool? isCurrentlyAvailable,
    PropertyStatus? status,
    String? adminNotes,
    DateTime? verifiedAt,
    String? verifiedByAdmin,
    DateTime? subscriptionExpiresAt,
    bool? subscriptionActive,
    int? likesCount,
    int? commentsCount,
    int? viewsCount,
    int? inquiriesCount,
    bool? isLiked,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastInquiryAt,
    bool? isFeatured,
    List<String>? tags,
  }) {
    return PropertyListingModel(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostImage: hostImage ?? this.hostImage,
      hostPhoneNumber: hostPhoneNumber ?? this.hostPhoneNumber,
      hostWhatsappNumber: hostWhatsappNumber ?? this.hostWhatsappNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      propertyType: propertyType ?? this.propertyType,
      location: location ?? this.location,
      amenities: amenities ?? this.amenities,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      maxGuests: maxGuests ?? this.maxGuests,
      ratePerNightKES: ratePerNightKES ?? this.ratePerNightKES,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      availabilityPeriods: availabilityPeriods ?? this.availabilityPeriods,
      nextAvailableDate: nextAvailableDate ?? this.nextAvailableDate,
      isCurrentlyAvailable: isCurrentlyAvailable ?? this.isCurrentlyAvailable,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedByAdmin: verifiedByAdmin ?? this.verifiedByAdmin,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      subscriptionActive: subscriptionActive ?? this.subscriptionActive,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      inquiriesCount: inquiriesCount ?? this.inquiriesCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastInquiryAt: lastInquiryAt ?? this.lastInquiryAt,
      isFeatured: isFeatured ?? this.isFeatured,
      tags: tags ?? this.tags,
    );
  }

  // Helper methods
  String get formattedRate => 'KES ${ratePerNightKES.toStringAsFixed(0)}';
  String get propertyTypeDisplay => propertyType.displayName;
  String get statusDisplay => status.displayName;
  bool get canBeEdited => status.canBeEdited;
  bool get isActive => status.isVisible && subscriptionActive;
  bool get isExpired => subscriptionExpiresAt.isBefore(DateTime.now());
  
  String get guestsText {
    if (maxGuests == 1) return '1 guest';
    return '$maxGuests guests';
  }
  
  String get bedroomsText {
    if (bedrooms == 0) return 'Studio';
    if (bedrooms == 1) return '1 bedroom';
    return '$bedrooms bedrooms';
  }
  
  String get bathroomsText {
    if (bathrooms == 1) return '1 bathroom';
    return '$bathrooms bathrooms';
  }
  
  String get fullDescription => '$bedroomsText • $bathroomsText • $guestsText';
  
  // WhatsApp integration
  String? get whatsappLink {
    if (hostWhatsappNumber == null || hostWhatsappNumber!.isEmpty) return null;
    return 'https://wa.me/$hostWhatsappNumber';
  }
  
  String? get whatsappLinkWithMessage {
    if (hostWhatsappNumber == null || hostWhatsappNumber!.isEmpty) return null;
    String message = Uri.encodeComponent(
      'Hi $hostName! I\'m interested in your property "$title" listed on the app. Is it available?'
    );
    return 'https://wa.me/$hostWhatsappNumber?text=$message';
  }
  
  bool get hasWhatsApp => hostWhatsappNumber != null && hostWhatsappNumber!.isNotEmpty;
  
  // Availability helpers
  bool isAvailableOn(DateTime date) {
    if (!isActive) return false;
    return availabilityPeriods.any((period) => period.isAvailableOn(date));
  }
  
  DateTime? get earliestAvailableDate {
    final now = DateTime.now();
    final availablePeriods = availabilityPeriods
        .where((period) => period.isAvailable && period.endDate.isAfter(now))
        .toList();
    
    if (availablePeriods.isEmpty) return null;
    
    availablePeriods.sort((a, b) => a.startDate.compareTo(b.startDate));
    return availablePeriods.first.startDate.isAfter(now) 
        ? availablePeriods.first.startDate 
        : now;
  }
  
  // Validation
  List<String> validate() {
    List<String> errors = [];
    
    if (title.isEmpty) errors.add('Title cannot be empty');
    if (description.isEmpty) errors.add('Description cannot be empty');
    if (title.length > 100) errors.add('Title cannot exceed 100 characters');
    if (description.length > 1000) errors.add('Description cannot exceed 1000 characters');
    if (ratePerNightKES <= 0) errors.add('Rate per night must be greater than 0');
    if (bedrooms < 0) errors.add('Bedrooms cannot be negative');
    if (bathrooms < 0) errors.add('Bathrooms cannot be negative');
    if (maxGuests <= 0) errors.add('Max guests must be at least 1');
    if (location.address.isEmpty) errors.add('Address is required');
    if (location.city.isEmpty) errors.add('City is required');
    if (location.county.isEmpty) errors.add('County is required');
    
    return errors;
  }
  
  bool get isValid => validate().isEmpty;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PropertyListingModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PropertyListingModel(id: $id, title: $title, host: $hostName, status: ${status.value}, rate: $formattedRate)';
  }
}