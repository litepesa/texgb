// lib/features/properties/widgets/property_actions_sidebar.dart
import 'package:flutter/material.dart';
import 'package:textgb/features/properties/models/property_listing_model.dart';

class PropertyActionsSidebar extends StatelessWidget {
  final PropertyListingModel property;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onContact;

  const PropertyActionsSidebar({
    super.key,
    required this.property,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like button
        _buildActionButton(
          icon: property.isLiked ? Icons.favorite : Icons.favorite_border,
          count: property.likesCount,
          onTap: onLike,
          color: property.isLiked ? const Color(0xFFFE2C55) : Colors.white,
        ),
        
        const SizedBox(height: 20),
        
        // Comment button
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          count: property.commentsCount,
          onTap: onComment,
          color: Colors.white,
        ),
        
        const SizedBox(height: 20),
        
        // Views count (non-interactive)
        _buildActionButton(
          icon: Icons.visibility_outlined,
          count: property.viewsCount,
          onTap: null,
          color: Colors.white70,
        ),
        
        const SizedBox(height: 20),
        
        // Share button
        _buildActionButton(
          icon: Icons.share_outlined,
          count: null,
          onTap: onShare,
          color: Colors.white,
        ),
        
        const SizedBox(height: 32),
        
        // Contact Host button (prominent)
        _buildContactButton(),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int? count,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            if (count != null && count > 0) ...[
              const SizedBox(height: 4),
              Text(
                _formatCount(count),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton() {
    return GestureDetector(
      onTap: onContact,
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF25D366), // WhatsApp green
              Color(0xFF1DA851),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF25D366).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 6),
            const Text(
              'Contact',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (property.inquiriesCount > 0) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${property.inquiriesCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}m';
    }
  }
}
