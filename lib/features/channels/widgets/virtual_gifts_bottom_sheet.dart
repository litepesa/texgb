import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class VirtualGiftsBottomSheet extends StatefulWidget {
  final String? recipientName;
  final String? recipientImage;
  final Function(VirtualGift gift)? onGiftSelected;
  final VoidCallback? onClose;

  const VirtualGiftsBottomSheet({
    Key? key,
    this.recipientName,
    this.recipientImage,
    this.onGiftSelected,
    this.onClose,
  }) : super(key: key);

  @override
  State<VirtualGiftsBottomSheet> createState() => _VirtualGiftsBottomSheetState();
}

class _VirtualGiftsBottomSheetState extends State<VirtualGiftsBottomSheet>
    with TickerProviderStateMixin {
  late TabController _tabController;
  VirtualGift? _selectedGift;
  bool _isProcessing = false;

  final List<GiftCategory> _giftCategories = [
    GiftCategory(
      name: 'Popular',
      icon: CupertinoIcons.flame_fill,
      color: const Color(0xFFFF6B35),
      gifts: [
        VirtualGift(
          id: 'heart',
          name: 'Heart',
          emoji: '❤️',
          price: 10,
          color: const Color(0xFFE91E63),
          rarity: GiftRarity.common,
        ),
        VirtualGift(
          id: 'thumbs_up',
          name: 'Thumbs Up',
          emoji: '👍',
          price: 15,
          color: const Color(0xFF2196F3),
          rarity: GiftRarity.common,
        ),
        VirtualGift(
          id: 'clap',
          name: 'Applause',
          emoji: '👏',
          price: 25,
          color: const Color(0xFFFFC107),
          rarity: GiftRarity.uncommon,
        ),
        VirtualGift(
          id: 'fire',
          name: 'Fire',
          emoji: '🔥',
          price: 50,
          color: const Color(0xFFFF5722),
          rarity: GiftRarity.rare,
        ),
        VirtualGift(
          id: 'star',
          name: 'Star',
          emoji: '⭐',
          price: 75,
          color: const Color(0xFFFFD700),
          rarity: GiftRarity.rare,
        ),
        VirtualGift(
          id: 'crown',
          name: 'Crown',
          emoji: '👑',
          price: 150,
          color: const Color(0xFFFFD700),
          rarity: GiftRarity.epic,
        ),
      ],
    ),
    GiftCategory(
      name: 'Emotions',
      icon: CupertinoIcons.smiley_fill,
      color: const Color(0xFFFF9800),
      gifts: [
        VirtualGift(
          id: 'love_eyes',
          name: 'Love Eyes',
          emoji: '😍',
          price: 20,
          color: const Color(0xFFE91E63),
          rarity: GiftRarity.common,
        ),
        VirtualGift(
          id: 'laugh',
          name: 'Laughing',
          emoji: '😂',
          price: 15,
          color: const Color(0xFFFFC107),
          rarity: GiftRarity.common,
        ),
        VirtualGift(
          id: 'cool',
          name: 'Cool',
          emoji: '😎',
          price: 30,
          color: const Color(0xFF607D8B),
          rarity: GiftRarity.uncommon,
        ),
        VirtualGift(
          id: 'shocked',
          name: 'Shocked',
          emoji: '😱',
          price: 25,
          color: const Color(0xFF9C27B0),
          rarity: GiftRarity.uncommon,
        ),
        VirtualGift(
          id: 'party',
          name: 'Party',
          emoji: '🥳',
          price: 40,
          color: const Color(0xFF4CAF50),
          rarity: GiftRarity.rare,
        ),
        VirtualGift(
          id: 'mind_blown',
          name: 'Mind Blown',
          emoji: '🤯',
          price: 60,
          color: const Color(0xFFFF5722),
          rarity: GiftRarity.rare,
        ),
      ],
    ),
    GiftCategory(
      name: 'Luxury',
      icon: CupertinoIcons.pen,
      color: const Color(0xFF9C27B0),
      gifts: [
        VirtualGift(
          id: 'diamond',
          name: 'Diamond',
          emoji: '💎',
          price: 200,
          color: const Color(0xFF00BCD4),
          rarity: GiftRarity.epic,
        ),
        VirtualGift(
          id: 'trophy',
          name: 'Trophy',
          emoji: '🏆',
          price: 100,
          color: const Color(0xFFFFD700),
          rarity: GiftRarity.rare,
        ),
        VirtualGift(
          id: 'rocket',
          name: 'Rocket',
          emoji: '🚀',
          price: 120,
          color: const Color(0xFF2196F3),
          rarity: GiftRarity.epic,
        ),
        VirtualGift(
          id: 'money_bag',
          name: 'Money Bag',
          emoji: '💰',
          price: 250,
          color: const Color(0xFF4CAF50),
          rarity: GiftRarity.epic,
        ),
        VirtualGift(
          id: 'unicorn',
          name: 'Unicorn',
          emoji: '🦄',
          price: 300,
          color: const Color(0xFF9C27B0),
          rarity: GiftRarity.legendary,
        ),
        VirtualGift(
          id: 'rainbow',
          name: 'Rainbow',
          emoji: '🌈',
          price: 500,
          color: const Color(0xFFFF6B35),
          rarity: GiftRarity.legendary,
        ),
      ],
    ),
    GiftCategory(
      name: 'Food',
      icon: CupertinoIcons.heart_circle_fill,
      color: const Color(0xFFFF5722),
      gifts: [
        VirtualGift(
          id: 'coffee',
          name: 'Coffee',
          emoji: '☕',
          price: 35,
          color: const Color(0xFF8D6E63),
          rarity: GiftRarity.uncommon,
        ),
        VirtualGift(
          id: 'pizza',
          name: 'Pizza',
          emoji: '🍕',
          price: 45,
          color: const Color(0xFFFF5722),
          rarity: GiftRarity.uncommon,
        ),
        VirtualGift(
          id: 'cake',
          name: 'Birthday Cake',
          emoji: '🎂',
          price: 55,
          color: const Color(0xFFE91E63),
          rarity: GiftRarity.rare,
        ),
        VirtualGift(
          id: 'champagne',
          name: 'Champagne',
          emoji: '🍾',
          price: 80,
          color: const Color(0xFFFFD700),
          rarity: GiftRarity.rare,
        ),
        VirtualGift(
          id: 'donut',
          name: 'Donut',
          emoji: '🍩',
          price: 25,
          color: const Color(0xFFFF9800),
          rarity: GiftRarity.common,
        ),
        VirtualGift(
          id: 'ice_cream',
          name: 'Ice Cream',
          emoji: '🍦',
          price: 30,
          color: const Color(0xFF00BCD4),
          rarity: GiftRarity.uncommon,
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _giftCategories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: _buildTabBarView(),
          ),
          if (_selectedGift != null) _buildConfirmationBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: () {
              widget.onClose?.call();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Recipient info
          if (widget.recipientImage != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF6B35), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  widget.recipientImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[700],
                      child: const Icon(Icons.person, color: Colors.white, size: 20),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send Gift',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.recipientName != null)
                  Text(
                    'to ${widget.recipientName}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          
          // Balance display (placeholder)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'KES 1,250',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.account_balance_wallet, color: Colors.white, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFFFF6B35),
        indicatorWeight: 3,
        labelColor: const Color(0xFFFF6B35),
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
        tabs: _giftCategories.map((category) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(category.icon, size: 16),
                const SizedBox(width: 6),
                Text(category.name),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: _giftCategories.map((category) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: category.gifts.length,
            itemBuilder: (context, index) {
              final gift = category.gifts[index];
              final isSelected = _selectedGift?.id == gift.id;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGift = isSelected ? null : gift;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? gift.color.withOpacity(0.2) : Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? gift.color : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: gift.color.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Gift emoji with rarity glow
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (gift.rarity != GiftRarity.common)
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _getRarityColor(gift.rarity).withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            gift.emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Gift name
                      Text(
                        gift.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Price with currency
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: gift.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'KES ${gift.price}',
                          style: TextStyle(
                            color: gift.color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      // Rarity indicator
                      if (gift.rarity != GiftRarity.common) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _getRarityColor(gift.rarity),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfirmationBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Selected gift preview
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _selectedGift!.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _selectedGift!.color, width: 1),
            ),
            child: Center(
              child: Text(
                _selectedGift!.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedGift!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'KES ${_selectedGift!.price}',
                  style: TextStyle(
                    color: _selectedGift!.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Send button
          GestureDetector(
            onTap: _isProcessing ? null : _sendGift,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 100,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isProcessing 
                    ? [Colors.grey, Colors.grey[600]!]
                    : [_selectedGift!.color, _selectedGift!.color.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: _selectedGift!.color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: _isProcessing 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Send',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(GiftRarity rarity) {
    switch (rarity) {
      case GiftRarity.common:
        return Colors.grey;
      case GiftRarity.uncommon:
        return Colors.green;
      case GiftRarity.rare:
        return Colors.blue;
      case GiftRarity.epic:
        return Colors.purple;
      case GiftRarity.legendary:
        return Colors.orange;
    }
  }

  void _sendGift() async {
    if (_selectedGift == null || _isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      // Call the callback
      widget.onGiftSelected?.call(_selectedGift!);
      
      // Show success animation
      _showSuccessAnimation();
      
      // Close after delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          widget.onClose?.call();
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _selectedGift!.emoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gift Sent!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Data models
enum GiftRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

class VirtualGift {
  final String id;
  final String name;
  final String emoji;
  final int price; // Price in KES
  final Color color;
  final GiftRarity rarity;

  VirtualGift({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
    required this.color,
    required this.rarity,
  });
}

class GiftCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<VirtualGift> gifts;

  GiftCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.gifts,
  });
}