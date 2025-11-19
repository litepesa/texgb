// lib/features/channels/screens/create_channel_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/core/router/app_router.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/theme/channels_theme.dart';

/// Screen for creating a new channel
class CreateChannelScreen extends ConsumerStatefulWidget {
  const CreateChannelScreen({super.key});

  @override
  ConsumerState<CreateChannelScreen> createState() => _CreateChannelScreenState();
}

class _CreateChannelScreenState extends ConsumerState<CreateChannelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  ChannelType _selectedType = ChannelType.public;
  int? _subscriptionPrice;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChannelsTheme.screenBackground,
      appBar: AppBar(
        title: const Text('Create Channel'),
        actions: [
          if (_isCreating)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _createChannel,
              child: Text(
                'Create',
                style: ChannelsTheme.headingSmall.copyWith(
                  fontSize: 16,
                  color: ChannelsTheme.facebookBlue,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Channel Name
            TextFormField(
              controller: _nameController,
              decoration: ChannelsTheme.inputDecoration(
                labelText: 'Channel Name',
                hintText: 'Enter channel name',
                prefixIcon: const Icon(Icons.tv),
              ).copyWith(
                border: const OutlineInputBorder(),
              ),
              maxLength: 50,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a channel name';
                }
                if (value.trim().length < 3) {
                  return 'Name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: ChannelsTheme.inputDecoration(
                labelText: 'Description',
                hintText: 'Describe what your channel is about',
                prefixIcon: const Icon(Icons.description),
              ).copyWith(
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 500,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                if (value.trim().length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Channel Type
            Text(
              'Channel Type',
              style: ChannelsTheme.headingSmall,
            ),
            const SizedBox(height: 12),

            // Public Option
            _buildTypeOption(
              type: ChannelType.public,
              icon: Icons.public,
              title: 'Public',
              description: 'Anyone can discover and subscribe to your channel',
              color: ChannelsTheme.publicChannelColor,
            ),
            const SizedBox(height: 12),

            // Private Option
            _buildTypeOption(
              type: ChannelType.private,
              icon: Icons.lock,
              title: 'Private',
              description: 'Only people you invite can see and subscribe',
              color: ChannelsTheme.privateChannelColor,
            ),
            const SizedBox(height: 12),

            // Premium Option
            _buildTypeOption(
              type: ChannelType.premium,
              icon: Icons.star,
              title: 'Premium',
              description: 'Subscribers pay to access your content',
              color: ChannelsTheme.premiumChannelColor,
            ),

            // Premium Subscription Price
            if (_selectedType == ChannelType.premium) ...[
              const SizedBox(height: 16),
              Card(
                color: ChannelsTheme.warning.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: ChannelsTheme.warning),
                          const SizedBox(width: 8),
                          Text(
                            'Premium Channel Settings',
                            style: ChannelsTheme.headingSmall.copyWith(
                              color: ChannelsTheme.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: ChannelsTheme.inputDecoration(
                          labelText: 'Subscription Price (Coins)',
                          hintText: 'e.g., 100',
                          prefixIcon: const Icon(Icons.attach_money),
                        ).copyWith(
                          border: const OutlineInputBorder(),
                          fillColor: ChannelsTheme.cardBackground,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_selectedType == ChannelType.premium) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter subscription price';
                            }
                            final price = int.tryParse(value);
                            if (price == null || price <= 0) {
                              return 'Please enter a valid price';
                            }
                            if (price < 10) {
                              return 'Minimum price is 10 coins';
                            }
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _subscriptionPrice = int.tryParse(value);
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Note: Platform takes 20% of subscription fees',
                        style: ChannelsTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Guidelines
            Card(
              color: ChannelsTheme.facebookBlue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, color: ChannelsTheme.facebookBlue),
                        const SizedBox(width: 8),
                        Text(
                          'Channel Guidelines',
                          style: ChannelsTheme.headingSmall.copyWith(
                            color: ChannelsTheme.facebookBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildGuideline('You can add up to 8 admins/moderators'),
                    _buildGuideline('Regular posts: ≤5 minutes or ≤100MB'),
                    _buildGuideline('Premium posts: up to 2GB supported'),
                    _buildGuideline('Multi-threaded comments enabled'),
                    _buildGuideline('All notifications are silent by default'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required ChannelType type,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : ChannelsTheme.hoverColor,
          border: Border.all(
            color: isSelected ? color : ChannelsTheme.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(ChannelsTheme.cardRadius),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : ChannelsTheme.textTertiary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: ChannelsTheme.white,
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
                    style: ChannelsTheme.headingSmall.copyWith(
                      color: isSelected ? color : ChannelsTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: ChannelsTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideline(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: ChannelsTheme.facebookBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: ChannelsTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createChannel() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isCreating = true);

    try {
      final actionsNotifier = ref.read(channelActionsProvider.notifier);
      final channel = await actionsNotifier.createChannel(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        subscriptionPriceCoins: _selectedType == ChannelType.premium
            ? _subscriptionPrice
            : null,
      );

      if (mounted) {
        if (channel != null) {
          // Success - navigate to the new channel
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${channel.name} created successfully!'),
              backgroundColor: ChannelsTheme.success,
            ),
          );
          // Navigate to channel detail
          context.goToChannelDetail(channel.id);
        } else {
          // Failed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create channel. Please try again.'),
              backgroundColor: ChannelsTheme.error,
            ),
          );
          setState(() => _isCreating = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: ChannelsTheme.error,
          ),
        );
        setState(() => _isCreating = false);
      }
    }
  }
}
