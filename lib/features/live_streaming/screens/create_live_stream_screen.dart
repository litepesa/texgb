// lib/features/live_streaming/screens/create_live_stream_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/live_streaming/models/live_stream_type_model.dart';
import 'package:textgb/features/live_streaming/routes/live_streaming_routes.dart';

class CreateLiveStreamScreen extends ConsumerWidget {
  final LiveStreamType? preselectedType;
  final String? shopId;

  const CreateLiveStreamScreen({
    super.key,
    this.preselectedType,
    this.shopId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If type is preselected, go directly to setup
    if (preselectedType != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pushToLiveStreamSetup();
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),

              const SizedBox(height: 32),

              // Title
              const Text(
                'Go Live',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Choose your stream type',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 48),

              // Gift Stream Option
              _buildStreamTypeCard(
                context: context,
                type: LiveStreamType.gift,
                icon: Icons.card_giftcard,
                title: 'Gift Stream',
                description: 'Receive virtual gifts from your viewers',
                features: [
                  'Interact with your audience',
                  'Receive gifts and earn revenue',
                  'Build your community',
                ],
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.pink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),

              const SizedBox(height: 20),

              // Shop Stream Option
              _buildStreamTypeCard(
                context: context,
                type: LiveStreamType.shop,
                icon: Icons.shopping_bag,
                title: 'Shop Stream',
                description: 'Showcase and sell your products live',
                features: [
                  'Feature products in real-time',
                  'Earn commission on sales',
                  'Engage with customers directly',
                ],
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                isDisabled: shopId == null,
                disabledMessage: shopId == null ? 'Create a shop first to start shop streams' : null,
              ),

              const Spacer(),

              // Quick tips
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Quick Tips',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTip('Good lighting and clear audio are essential'),
                    const SizedBox(height: 6),
                    _buildTip('Engage with viewers through chat'),
                    const SizedBox(height: 6),
                    _buildTip('Plan your content ahead of time'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreamTypeCard({
    required BuildContext context,
    required LiveStreamType type,
    required IconData icon,
    required String title,
    required String description,
    required List<String> features,
    required Gradient gradient,
    bool isDisabled = false,
    String? disabledMessage,
  }) {
    return GestureDetector(
      onTap: isDisabled
          ? () {
              if (disabledMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(disabledMessage),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          : () {
              context.pushToLiveStreamSetup();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: isDisabled ? null : gradient,
          color: isDisabled ? Colors.grey[900] : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDisabled
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 32,
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
                          color: isDisabled ? Colors.grey : Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: isDisabled ? Colors.grey[600] : Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isDisabled ? Colors.grey : Colors.white,
                  size: 20,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Features
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: isDisabled ? Colors.grey[600] : Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        color: isDisabled ? Colors.grey[600] : Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )),

            if (isDisabled && disabledMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        disabledMessage,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '•',
          style: TextStyle(
            color: Colors.amber,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
