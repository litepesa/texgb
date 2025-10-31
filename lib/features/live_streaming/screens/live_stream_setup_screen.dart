// lib/features/live_streaming/screens/live_stream_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/live_streaming/models/live_stream_model.dart';
import 'package:textgb/features/live_streaming/models/live_stream_type_model.dart';

class LiveStreamSetupScreen extends ConsumerStatefulWidget {
  final LiveStreamType? preselectedType;
  final String? shopId;

  const LiveStreamSetupScreen({
    super.key,
    this.preselectedType,
    this.shopId,
  });

  @override
  ConsumerState<LiveStreamSetupScreen> createState() => _LiveStreamSetupScreenState();
}

class _LiveStreamSetupScreenState extends ConsumerState<LiveStreamSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  LiveStreamType _streamType = LiveStreamType.gift;
  LiveStreamCategory _category = LiveStreamCategory.entertainment;
  final List<String> _selectedTags = [];
  bool _enableRecording = true;
  bool _allowComments = true;
  bool _isPrivate = false;

  // For shop streams
  final List<String> _selectedProductIds = [];

  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedType != null) {
      _streamType = widget.preselectedType!;
      if (_streamType == LiveStreamType.shop) {
        _category = LiveStreamCategory.shopping;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createStream() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      // TODO: Create stream via provider/repository
      await Future.delayed(const Duration(seconds: 2)); // Mock API call

      if (mounted) {
        // Navigate to host screen
        // context.goToLiveStreamHost(streamId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stream created! Ready to go live'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create stream: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        title: const Text(
          'Setup Live Stream',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Stream type selector
                _buildStreamTypeSelector(),

                const SizedBox(height: 24),

                // Title field
                _buildTitleField(),

                const SizedBox(height: 20),

                // Description field
                _buildDescriptionField(),

                const SizedBox(height: 24),

                // Category selector
                _buildCategorySelector(),

                const SizedBox(height: 24),

                // Tags selector
                _buildTagsSelector(),

                const SizedBox(height: 24),

                // Settings toggles
                _buildSettingsToggles(),

                const SizedBox(height: 24),

                // Product selection (for shop streams)
                if (_streamType == LiveStreamType.shop) ...[
                  _buildProductSelection(),
                  const SizedBox(height: 24),
                ],

                const SizedBox(height: 80), // Space for bottom button
              ],
            ),
          ),

          // Bottom button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomButton(),
          ),

          // Loading overlay
          if (_isCreating)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Creating your stream...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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

  Widget _buildStreamTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stream Type',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeOption(
                type: LiveStreamType.gift,
                icon: Icons.card_giftcard,
                title: 'Gift Stream',
                subtitle: 'Receive gifts from viewers',
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.pink],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeOption(
                type: LiveStreamType.shop,
                icon: Icons.shopping_bag,
                title: 'Shop Stream',
                subtitle: 'Sell products live',
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required LiveStreamType type,
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
  }) {
    final isSelected = _streamType == type;

    return GestureDetector(
      onTap: widget.preselectedType == null
          ? () {
              setState(() {
                _streamType = type;
                if (type == LiveStreamType.shop) {
                  _category = LiveStreamCategory.shopping;
                }
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stream Title',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white),
          maxLength: 100,
          decoration: InputDecoration(
            hintText: 'Enter an engaging title...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            counterStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            if (value.trim().length < 5) {
              return 'Title must be at least 5 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description (Optional)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          style: const TextStyle(color: Colors.white),
          maxLength: 500,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Tell viewers what to expect...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            counterStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LiveStreamCategory.values.map((category) {
            final isSelected = _category == category;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _category = category;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.red : Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category.displayName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTagsSelector() {
    final availableTags = [
      'Trending',
      'New',
      'Fashion',
      'Beauty',
      'Tech',
      'Gaming',
      'Music',
      'Food',
      'Travel',
      'Fitness',
      'Comedy',
      'Educational',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags (Optional)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedTags.remove(tag);
                  } else {
                    if (_selectedTags.length < 5) {
                      _selectedTags.add(tag);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Maximum 5 tags allowed'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                });
              },
              child: Chip(
                label: Text(
                  tag,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                backgroundColor: isSelected ? Colors.blue : Colors.white.withOpacity(0.05),
                side: BorderSide(
                  color: isSelected ? Colors.blue : Colors.white.withOpacity(0.2),
                ),
                deleteIcon: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
                onDeleted: isSelected ? () {} : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSettingsToggles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildToggle(
          title: 'Enable Recording',
          subtitle: 'Save stream for replay',
          icon: Icons.videocam,
          value: _enableRecording,
          onChanged: (value) {
            setState(() {
              _enableRecording = value;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildToggle(
          title: 'Allow Comments',
          subtitle: 'Viewers can chat',
          icon: Icons.chat_bubble,
          value: _allowComments,
          onChanged: (value) {
            setState(() {
              _allowComments = value;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildToggle(
          title: 'Private Stream',
          subtitle: 'Only followers can watch',
          icon: Icons.lock,
          value: _isPrivate,
          onChanged: (value) {
            setState(() {
              _isPrivate = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Featured Products',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                // TODO: Navigate to product selection
              },
              icon: const Icon(Icons.add, color: Colors.red, size: 18),
              label: const Text(
                'Add Products',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 48,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  'No products selected',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add products to showcase during your stream',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isCreating ? null : _createStream,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[800],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_fill, size: 24),
                const SizedBox(width: 12),
                Text(
                  _isCreating ? 'Creating...' : 'Start Live Stream',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
