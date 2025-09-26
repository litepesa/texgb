
// lib/features/properties/widgets/property_card.dart
import 'package:flutter/material.dart';
import 'package:textgb/features/properties/models/property_listing_model.dart';

class PropertyCard extends StatelessWidget {
  final PropertyListingModel property;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final bool showActions;

  const PropertyCard({
    super.key,
    required this.property,
    this.onTap,
    this.onLike,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Property image/thumbnail
              AspectRatio(
                aspectRatio: 16 / 20, // Vertical aspect ratio like TikTok
                child: Container(
                  decoration: BoxDecoration(
                    image: property.thumbnailUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(property.thumbnailUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: property.thumbnailUrl.isEmpty ? Colors.grey[300] : null,
                  ),
                  child: property.thumbnailUrl.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.home,
                            size: 48,
                            color: Colors.grey,
                          ),
                        )
                      : null,
                ),
              ),

              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Property info
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      property.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Location and type
                    Text(
                      '${property.location.city} • ${property.propertyTypeDisplay}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Rate and details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          property.formattedRate + '/night',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          property.fullDescription,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status badge
              if (!property.isCurrentlyAvailable)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Not Available',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // Actions
              if (showActions)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Column(
                    children: [
                      if (onLike != null)
                        GestureDetector(
                          onTap: onLike,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              property.isLiked ? Icons.favorite : Icons.favorite_border,
                              color: property.isLiked 
                                  ? const Color(0xFFFE2C55) 
                                  : Colors.white,
                              size: 18,
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
}
