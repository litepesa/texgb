// lib/features/moments/widgets/my_moments_header.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class MyMomentsHeader extends ConsumerWidget {
  final List<MomentModel> myMoments;
  final VoidCallback onCreateMoment;
  final VoidCallback onViewMyMoments;

  const MyMomentsHeader({
    super.key,
    required this.myMoments,
    required this.onCreateMoment,
    required this.onViewMyMoments,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authenticationProvider);
    final currentUser = authState.value?.userModel;

    if (currentUser == null) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Profile picture with camera overlay
              GestureDetector(
                onTap: onCreateMoment,
                child: Stack(
                  children: [
                    userImageWidget(
                      imageUrl: currentUser.image,
                      radius: 32,
                      onTap: onCreateMoment,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.camera,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // User info and create button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUser.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onCreateMoment,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Share what\'s on your mind...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // My recent moments preview
          if (myMoments.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildMyMomentsPreview(context),
          ],
        ],
      ),
    );
  }

  Widget _buildMyMomentsPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Moments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            GestureDetector(
              onTap: onViewMyMoments,
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF007AFF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Horizontal scrollable moments preview
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: myMoments.take(10).length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final moment = myMoments[index];
              return _buildMomentPreviewItem(context, moment);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMomentPreviewItem(BuildContext context, MomentModel moment) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to moment detail
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFF2F2F7),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (moment.hasMedia)
                CachedNetworkImage(
                  imageUrl: moment.mediaUrls.first,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFFF2F2F7),
                    child: const Center(
                      child: CupertinoActivityIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => _buildTextPreview(moment),
                )
              else
                _buildTextPreview(moment),
              
              // Video indicator
              if (moment.hasVideo)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    CupertinoIcons.videocam_fill,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              
              // Multiple media indicator
              if (moment.hasMultipleMedia)
                const Positioned(
                  bottom: 4,
                  right: 4,
                  child: Icon(
                    CupertinoIcons.rectangle_stack,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextPreview(MomentModel moment) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF007AFF).withOpacity(0.8),
            const Color(0xFF5856D6).withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Text(
          moment.content.isEmpty ? '📝' : moment.content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}