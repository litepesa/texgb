import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:textgb/features/wallet/providers/wallet_providers.dart';
import 'package:textgb/shared/services/http_client.dart';

class VirtualGiftsBottomSheet extends ConsumerStatefulWidget {
  final String? recipientId; // Required for API call
  final String? recipientName;
  final String? recipientImage;
  final Function(VirtualGift gift)? onGiftSelected;
  final VoidCallback? onClose;

  const VirtualGiftsBottomSheet({
    super.key,
    this.recipientId,
    this.recipientName,
    this.recipientImage,
    this.onGiftSelected,
    this.onClose,
  });

  @override
  ConsumerState<VirtualGiftsBottomSheet> createState() =>
      _VirtualGiftsBottomSheetState();
}

class _VirtualGiftsBottomSheetState
    extends ConsumerState<VirtualGiftsBottomSheet>
    with TickerProviderStateMixin {
  late TabController _tabController;
  VirtualGift? _selectedGift;
  bool _isProcessing = false;
  final HttpClientService _httpClient = HttpClientService();

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
        VirtualGift(
          id: 'kiss',
          name: 'Kiss',
          emoji: '💋',
          price: 35,
          color: const Color(0xFFE91E63),
          rarity: GiftRarity.uncommon,
        ),
        VirtualGift(
          id: 'muscle',
          name: 'Strong',
          emoji: '💪',
          price: 40,
          color: const Color(0xFF8BC34A),
          rarity: GiftRarity.uncommon,
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
        VirtualGift(
          id: 'crying_laugh',
          name: 'Crying Laugh',
          emoji: '🤣',
          price: 35,
          color: const Color(0xFFFFC107),
          rarity: GiftRarity.uncommon,
        ),
        VirtualGift(
          id: 'wink',
          name: 'Wink',
          emoji: '😉',
          price: 20,
          color: const Color(0xFF795548),
          rarity: GiftRarity.common,
        ),
        VirtualGift(
          id: 'angel',
          name: 'Angel',
          emoji: '😇',
          price: 45,
          color: const Color(0xFFFFFFFF),
          rarity: GiftRarity.rare,
        ),
        VirtualGift(
          id: 'devil',
          name: 'Devil',
          emoji: '😈',
          price: 45,
          color: const Color(0xFFD32F2F),
          rarity: GiftRarity.rare,
        ),
      ],
    ),
    GiftCategory(
      name: 'Animals',
      icon: CupertinoIcons.paw,
      color: const Color(0xFF4CAF50),
      gifts: [
        VirtualGift(
          id: 'cat',
          name: 'Cat',
          emoji: '🐱',
          price: 25,
          color: const Color(0xFF795548),
          rarity: GiftRarity.common,
        ),
        VirtualGift(
          id: 'dog',
          name: 'Dog',
          emoji: '🐶',
          price: 25,
          color: const Color(0xFF8D6E63),
          rarity: GiftRarity.common,
        ),
        VirtualGift(
          id: 'bear',
          name: 'Bear',
          emoji: '🐻',
          price: 40,
          color: const Color(0xFF5D4037),
          rarity: GiftRarity.uncommon,
        ),
        VirtualGift(
          id: 'lion',
          name: 'Lion',
          emoji: '🦁',
          price: 65,
          color: const Color(0xFFFF9800),
          rarity: GiftRarity.rare,
        ),
        VirtualGift(
          id: 'elephant',
          name: 'Elephant',
          emoji: '🐘',
          price: 55,
          color: const Color(0xFF607D8B),
          rarity: GiftRarity.rare,
        ),
        VirtualGift(
          id: 'eagle',
          name: 'Eagle',
          emoji: '🦅',
          price: 70,
          color: const Color(0xFF3F51B5),
          rarity: GiftRarity.rare,
        ),
        VirtualGift(
          id: 'dragon',
          name: 'Dragon',
          emoji: '🐉',
          price: 180,
          color: const Color(0xFF4CAF50),
          rarity: GiftRarity.epic,
        ),
        VirtualGift(
          id: 'phoenix',
          name: 'Phoenix',
          emoji: '🔥🦅',
          price: 350,
          color: const Color(0xFFFF5722),
          rarity: GiftRarity.legendary,
        ),
      ],
    ),
    GiftCategory(
      name: 'Luxury',
      icon: CupertinoIcons.rosette,
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
        VirtualGift(
          id: 'sports_car',
          name: 'Sports Car',
          emoji: '🏎️',
          price: 800,
          color: const Color(0xFFD32F2F),
          rarity: GiftRarity.legendary,
        ),
        VirtualGift(
          id: 'mansion',
          name: 'Mansion',
          emoji: '🏰',
          price: 1200,
          color: const Color(0xFF795548),
          rarity: GiftRarity.legendary,
        ),
        VirtualGift(
          id: 'yacht',
          name: 'Yacht',
          emoji: '🛥️',
          price: 2500,
          color: const Color(0xFF2196F3),
          rarity: GiftRarity.mythic,
        ),
        VirtualGift(
          id: 'private_jet',
          name: 'Private Jet',
          emoji: '🛩️',
          price: 5000,
          color: const Color(0xFF607D8B),
          rarity: GiftRarity.mythic,
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
        VirtualGift(
          id: 'burger',
          name: 'Burger',
          emoji: '🍔',
          price: 40,
          color: const Color(0xFF8BC34A),
          rarity: GiftRarity.uncommon,
        ),
        VirtualGift(
          id: 'sushi',
          name: 'Sushi',
          emoji: '🍣',
          price: 60,
          color: const Color(0xFF4CAF50),
          rarity: GiftRarity.rare,
        ),
        VirtualGift(
          id: 'lobster',
          name: 'Lobster',
          emoji: '🦞',
          price: 120,
          color: const Color(0xFFD32F2F),
          rarity: GiftRarity.epic,
        ),
        VirtualGift(
          id: 'caviar',
          name: 'Caviar',
          emoji: '🥄',
          price: 300,
          color: const Color(0xFF212121),
          rarity: GiftRarity.legendary,
        ),
      ],
    ),
    GiftCategory(
      name: 'Travel',
      icon: CupertinoIcons.airplane,
      color: const Color(0xFF03DAC6),
      gifts: [
        VirtualGift(
          id: 'beach',
          name: 'Beach Vacation',
          emoji: '🏖️',
          price: 400,
          color: const Color(0xFF00BCD4),
          rarity: GiftRarity.legendary,
        ),
        VirtualGift(
          id: 'mountain',
          name: 'Mountain Trip',
          emoji: '🏔️',
          price: 350,
          color: const Color(0xFF607D8B),
          rarity: GiftRarity.legendary,
        ),
        VirtualGift(
          id: 'city_break',
          name: 'City Break',
          emoji: '🏙️',
          price: 300,
          color: const Color(0xFF9C27B0),
          rarity: GiftRarity.legendary,
        ),
        VirtualGift(
          id: 'safari',
          name: 'Safari Adventure',
          emoji: '🦓',
          price: 800,
          color: const Color(0xFF8BC34A),
          rarity: GiftRarity.legendary,
        ),
        VirtualGift(
          id: 'cruise',
          name: 'Luxury Cruise',
          emoji: '🛳️',
          price: 1500,
          color: const Color(0xFF3F51B5),
          rarity: GiftRarity.mythic,
        ),
        VirtualGift(
          id: 'space_trip',
          name: 'Space Trip',
          emoji: '🚀🌌',
          price: 15000,
          color: const Color(0xFF673AB7),
          rarity: GiftRarity.ultimate,
        ),
      ],
    ),
    GiftCategory(
      name: 'Ultra Premium',
      icon: CupertinoIcons.sparkles,
      color: const Color(0xFFFFD700),
      gifts: [
        VirtualGift(
          id: 'golden_crown',
          name: 'Golden Crown',
          emoji: '👑✨',
          price: 1000,
          color: const Color(0xFFFFD700),
          rarity: GiftRarity.mythic,
        ),
        VirtualGift(
          id: 'diamond_ring',
          name: 'Diamond Ring',
          emoji: '💍',
          price: 2000,
          color: const Color(0xFF00BCD4),
          rarity: GiftRarity.mythic,
        ),
        VirtualGift(
          id: 'golden_statue',
          name: 'Golden Statue',
          emoji: '🗿✨',
          price: 3500,
          color: const Color(0xFFFFD700),
          rarity: GiftRarity.mythic,
        ),
        VirtualGift(
          id: 'treasure_chest',
          name: 'Treasure Chest',
          emoji: '💰⭐',
          price: 5000,
          color: const Color(0xFFFF9800),
          rarity: GiftRarity.ultimate,
        ),
        VirtualGift(
          id: 'palace',
          name: 'Royal Palace',
          emoji: '🏰👑',
          price: 8000,
          color: const Color(0xFF9C27B0),
          rarity: GiftRarity.ultimate,
        ),
        VirtualGift(
          id: 'island',
          name: 'Private Island',
          emoji: '🏝️🌴',
          price: 12000,
          color: const Color(0xFF00BCD4),
          rarity: GiftRarity.ultimate,
        ),
        VirtualGift(
          id: 'galaxy',
          name: 'Own a Galaxy',
          emoji: '🌌⭐',
          price: 25000,
          color: const Color(0xFF673AB7),
          rarity: GiftRarity.ultimate,
        ),
        VirtualGift(
          id: 'universe',
          name: 'The Universe',
          emoji: '🌌✨🪐',
          price: 50000,
          color: const Color(0xFF000000),
          rarity: GiftRarity.ultimate,
        ),
      ],
    ),
    GiftCategory(
      name: 'Nature',
      icon: CupertinoIcons.leaf_arrow_circlepath,
      color: const Color(0xFF4CAF50),
      gifts: [
        VirtualGift(
          id: 'flower',
          name: 'Flower',
          emoji: '🌸',
          price: 20,
          color: const Color(0xFFE91E63),
          rarity: GiftRarity.common,
        ),
        VirtualGift(
          id: 'rose',
          name: 'Rose',
          emoji: '🌹',
          price: 45,
          color: const Color(0xFFD32F2F),
          rarity: GiftRarity.uncommon,
        ),
        VirtualGift(
          id: 'bouquet',
          name: 'Bouquet',
          emoji: '💐',
          price: 85,
          color: const Color(0xFFE91E63),
          rarity: GiftRarity.rare,
        ),
        VirtualGift(
          id: 'tree',
          name: 'Tree',
          emoji: '🌳',
          price: 60,
          color: const Color(0xFF4CAF50),
          rarity: GiftRarity.rare,
        ),
        VirtualGift(
          id: 'forest',
          name: 'Forest',
          emoji: '🌲🌳',
          price: 200,
          color: const Color(0xFF2E7D32),
          rarity: GiftRarity.epic,
        ),
        VirtualGift(
          id: 'garden',
          name: 'Garden Paradise',
          emoji: '🌺🌸🌼',
          price: 400,
          color: const Color(0xFF8BC34A),
          rarity: GiftRarity.legendary,
        ),
        VirtualGift(
          id: 'aurora',
          name: 'Aurora Borealis',
          emoji: '🌌💚',
          price: 800,
          color: const Color(0xFF00E676),
          rarity: GiftRarity.legendary,
        ),
      ],
    ),
    GiftCategory(
      name: 'Sports',
      icon: CupertinoIcons.sportscourt,
      color: const Color(0xFF2196F3),
      gifts: [
        VirtualGift(
          id: 'soccer_ball',
          name: 'Soccer Ball',
          emoji: '⚽',
          price: 30,
          color: const Color(0xFF4CAF50),
          rarity: GiftRarity.uncommon,
        ),
        VirtualGift(
          id: 'basketball',
          name: 'Basketball',
          emoji: '🏀',
          price: 35,
          color: const Color(0xFFFF9800),
          rarity: GiftRarity.uncommon,
        ),
        VirtualGift(
          id: 'volleyball',
          name: 'Volleyball',
          emoji: '🏐',
          price: 25,
          color: const Color(0xFFFFC107),
          rarity: GiftRarity.common,
        ),
        VirtualGift(
          id: 'tennis',
          name: 'Tennis',
          emoji: '🎾',
          price: 40,
          color: const Color(0xFF8BC34A),
          rarity: GiftRarity.uncommon,
        ),
        VirtualGift(
          id: 'medal',
          name: 'Gold Medal',
          emoji: '🥇',
          price: 150,
          color: const Color(0xFFFFD700),
          rarity: GiftRarity.epic,
        ),
        VirtualGift(
          id: 'championship',
          name: 'Championship',
          emoji: '🏆⭐',
          price: 500,
          color: const Color(0xFFFFD700),
          rarity: GiftRarity.legendary,
        ),
        VirtualGift(
          id: 'olympics',
          name: 'Olympic Victory',
          emoji: '🥇🌟',
          price: 1000,
          color: const Color(0xFFFFD700),
          rarity: GiftRarity.mythic,
        ),
      ],
    ),
    GiftCategory(
      name: 'Celestial',
      icon: CupertinoIcons.moon_stars,
      color: const Color(0xFF673AB7),
      gifts: [
        VirtualGift(
          id: 'moon',
          name: 'Moon',
          emoji: '🌙',
          price: 100,
          color: const Color(0xFFFFFFFF),
          rarity: GiftRarity.rare,
        ),
        VirtualGift(
          id: 'sun',
          name: 'Sun',
          emoji: '☀️',
          price: 150,
          color: const Color(0xFFFFC107),
          rarity: GiftRarity.epic,
        ),
        VirtualGift(
          id: 'shooting_star',
          name: 'Shooting Star',
          emoji: '💫',
          price: 250,
          color: const Color(0xFFFFD700),
          rarity: GiftRarity.epic,
        ),
        VirtualGift(
          id: 'constellation',
          name: 'Constellation',
          emoji: '✨⭐✨',
          price: 600,
          color: const Color(0xFF3F51B5),
          rarity: GiftRarity.legendary,
        ),
        VirtualGift(
          id: 'supernova',
          name: 'Supernova',
          emoji: '💥⭐',
          price: 1500,
          color: const Color(0xFFFF5722),
          rarity: GiftRarity.mythic,
        ),
        VirtualGift(
          id: 'black_hole',
          name: 'Black Hole',
          emoji: '🕳️✨',
          price: 3000,
          color: const Color(0xFF000000),
          rarity: GiftRarity.mythic,
        ),
        VirtualGift(
          id: 'big_bang',
          name: 'Big Bang',
          emoji: '💥🌌',
          price: 10000,
          color: const Color(0xFFFF6B35),
          rarity: GiftRarity.ultimate,
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _giftCategories.length, vsync: this);

    // ✅ Debug: Log wallet state on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletAsync = ref.read(walletProvider);
      print('🎁 Gift Bottom Sheet Initialized');
      print(
          '🎁 Wallet State: ${walletAsync.value?.wallet?.coinsBalance ?? "null"}');

      walletAsync.whenData((walletState) {
        print(
            '🎁 Wallet Balance: ${walletState.wallet?.coinsBalance ?? 0} coins');
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final availableHeight = MediaQuery.of(context).size.height * 0.85;

    // ✅ Watch the wallet provider directly to handle loading state
    final walletAsync = ref.watch(walletProvider);

    return Container(
      height: availableHeight,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: walletAsync.when(
        data: (walletState) {
          final currentCoins = walletState.wallet?.coinsBalance ?? 0;

          return Column(
            children: [
              _buildHeader(currentCoins),
              _buildTabBar(),
              Expanded(
                child: _buildTabBarView(currentCoins),
              ),
              if (_selectedGift != null) _buildConfirmationBar(),
              SizedBox(height: bottomPadding),
            ],
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading wallet...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFD32F2F),
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load wallet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => ref.refresh(walletProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int currentCoins) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
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
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 20),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$currentCoins',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.stars, color: Colors.white, size: 14),
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
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
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

  Widget _buildTabBarView(int currentCoins) {
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
              final canAfford = currentCoins >= gift.price;

              return GestureDetector(
                onTap: canAfford
                    ? () {
                        setState(() {
                          _selectedGift = isSelected ? null : gift;
                        });
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? gift.color.withOpacity(0.2)
                        : Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? gift.color : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: gift.color.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      if (!canAfford)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.lock,
                                color: Colors.white54,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                                        color: _getRarityColor(gift.rarity)
                                            .withOpacity(0.5),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                ),
                              Opacity(
                                opacity: canAfford ? 1.0 : 0.5,
                                child: Text(
                                  gift.emoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            gift.name,
                            style: TextStyle(
                              color: canAfford ? Colors.white : Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  gift.color.withOpacity(canAfford ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${gift.price}',
                                  style: TextStyle(
                                    color: canAfford
                                        ? gift.color
                                        : gift.color.withOpacity(0.5),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.stars,
                                  color: canAfford
                                      ? gift.color
                                      : gift.color.withOpacity(0.5),
                                  size: 8,
                                ),
                              ],
                            ),
                          ),
                          if (gift.rarity != GiftRarity.common) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _getRarityStars(gift.rarity),
                                (index) => Container(
                                  width: 3,
                                  height: 3,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: canAfford
                                        ? _getRarityColor(gift.rarity)
                                        : _getRarityColor(gift.rarity)
                                            .withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: _selectedGift!.color.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
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
                Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_selectedGift!.price}',
                          style: TextStyle(
                            color: _selectedGift!.color,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.stars,
                          color: _selectedGift!.color,
                          size: 12,
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getRarityColor(_selectedGift!.rarity)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getRarityName(_selectedGift!.rarity),
                        style: TextStyle(
                          color: _getRarityColor(_selectedGift!.rarity),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                      : [
                          _selectedGift!.color,
                          _selectedGift!.color.withOpacity(0.8)
                        ],
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
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

  int _getRarityStars(GiftRarity rarity) {
    switch (rarity) {
      case GiftRarity.common:
        return 0;
      case GiftRarity.uncommon:
        return 1;
      case GiftRarity.rare:
        return 2;
      case GiftRarity.epic:
        return 3;
      case GiftRarity.legendary:
        return 4;
      case GiftRarity.mythic:
        return 5;
      case GiftRarity.ultimate:
        return 6;
    }
  }

  String _getRarityName(GiftRarity rarity) {
    switch (rarity) {
      case GiftRarity.common:
        return 'Common';
      case GiftRarity.uncommon:
        return 'Uncommon';
      case GiftRarity.rare:
        return 'Rare';
      case GiftRarity.epic:
        return 'Epic';
      case GiftRarity.legendary:
        return 'Legendary';
      case GiftRarity.mythic:
        return 'Mythic';
      case GiftRarity.ultimate:
        return 'Ultimate';
    }
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
      case GiftRarity.mythic:
        return const Color(0xFFE91E63);
      case GiftRarity.ultimate:
        return const Color(0xFFFFD700);
    }
  }

  // ✅ UPDATED _sendGift METHOD USING HttpClientService
  void _sendGift() async {
    if (_selectedGift == null || _isProcessing) return;

    // ✅ Get balance from wallet state directly
    final walletAsync = ref.read(walletProvider);
    final currentCoins = walletAsync.value?.wallet?.coinsBalance ?? 0;

    print('🎁 Attempting to send gift: ${_selectedGift!.name}');
    print('🎁 Gift price: ${_selectedGift!.price} coins');
    print('🎁 Current balance: $currentCoins coins');

    // Check if user has enough coins
    if (currentCoins < _selectedGift!.price) {
      print(
          '❌ Insufficient coins: need ${_selectedGift!.price}, have $currentCoins');
      _showInsufficientCoinsMessage();
      return;
    }

    // Check if recipient ID is provided
    if (widget.recipientId == null || widget.recipientId!.isEmpty) {
      print('❌ Missing recipient ID');
      _showErrorMessage('Recipient information is missing');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      print('📤 Sending gift to: ${widget.recipientId}');

      // Use HttpClientService which handles auth token and base URL automatically
      final response = await _httpClient.post('/gifts/send', body: {
        'recipientId': widget.recipientId!,
        'giftId': _selectedGift!.id,
        'message': 'Sent you a gift!',
        'context': 'profile', // Can be 'video', 'live_stream', etc.
      });

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('✅ Gift sent successfully!');
        print('✅ New sender balance: ${data['senderNewBalance']}');

        // Refresh wallet balance
        ref.refresh(walletProvider);

        // Call onGiftSelected callback if provided
        widget.onGiftSelected?.call(_selectedGift!);

        // Show success animation
        _showSuccessAnimation();

        // Close after delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        final error = jsonDecode(response.body);
        print('❌ Gift send failed: ${error['error']}');
        _showErrorMessage(error['error'] ?? 'Failed to send gift');
      }
    } catch (e) {
      print('❌ Gift send exception: $e');
      _showErrorMessage('Network error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD32F2F), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Color(0xFFD32F2F),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD32F2F), Color(0xFFE57373)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD32F2F).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'OK',
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
        ),
      ),
    );
  }

  void _showInsufficientCoinsMessage() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD32F2F), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stars_outlined,
                  color: Color(0xFFD32F2F),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Not Enough Coins',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You need ${_selectedGift!.price} coins to send this gift.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  // Navigate to coin purchase screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Redirecting to buy coins...'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Buy Coins',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey[600]!, width: 1),
                  ),
                  child: const Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => Center(
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _selectedGift!.color.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _selectedGift!.color.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _selectedGift!.emoji,
                style: const TextStyle(fontSize: 52),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gift Sent!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_selectedGift!.price}',
                    style: TextStyle(
                      color: _selectedGift!.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.stars,
                    color: _selectedGift!.color,
                    size: 12,
                  ),
                ],
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
  mythic,
  ultimate,
}

class VirtualGift {
  final String id;
  final String name;
  final String emoji;
  final int price;
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
