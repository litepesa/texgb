// lib/features/live_streaming/widgets/gift_selection_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/live_streaming/models/live_gift_model.dart';

class GiftSelectionSheet extends ConsumerStatefulWidget {
  final double userBalance;
  final Function(GiftType gift, int quantity) onSendGift;

  const GiftSelectionSheet({
    super.key,
    required this.userBalance,
    required this.onSendGift,
  });

  @override
  ConsumerState<GiftSelectionSheet> createState() => _GiftSelectionSheetState();
}

class _GiftSelectionSheetState extends ConsumerState<GiftSelectionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GiftType? _selectedGift;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF0D0D0D),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Tier tabs
          _buildTierTabs(),

          // Gift grid
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGiftGrid(_getGiftsByTier(GiftTier.basic)),
                _buildGiftGrid(_getGiftsByTier(GiftTier.popular)),
                _buildGiftGrid(_getGiftsByTier(GiftTier.premium)),
                _buildGiftGrid(_getGiftsByTier(GiftTier.luxury)),
              ],
            ),
          ),

          // Send button
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Send Gift',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'KES ${widget.userBalance.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.red,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Basic'),
          Tab(text: 'Popular'),
          Tab(text: 'Premium'),
          Tab(text: 'Luxury'),
        ],
      ),
    );
  }

  Widget _buildGiftGrid(List<GiftType> gifts) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: gifts.length,
      itemBuilder: (context, index) {
        final gift = gifts[index];
        final isSelected = _selectedGift?.id == gift.id;
        final canAfford = widget.userBalance >= gift.price;

        return GestureDetector(
          onTap: canAfford
              ? () {
                  setState(() {
                    _selectedGift = gift;
                    _quantity = 1;
                  });
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.red.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.red : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gift emoji
                Text(
                  gift.emoji,
                  style: TextStyle(
                    fontSize: 36,
                    color: canAfford ? null : Colors.white.withOpacity(0.3),
                  ),
                ),
                const SizedBox(height: 4),

                // Gift name
                Text(
                  gift.name,
                  style: TextStyle(
                    color: canAfford ? Colors.white : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),

                // Price
                Text(
                  '${gift.price.toStringAsFixed(0)} KES',
                  style: TextStyle(
                    color: canAfford ? Colors.amber : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Lock icon if can't afford
                if (!canAfford) ...[
                  const SizedBox(height: 2),
                  Icon(
                    Icons.lock,
                    color: Colors.grey.withOpacity(0.5),
                    size: 12,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSendButton() {
    final canSend = _selectedGift != null &&
        widget.userBalance >= (_selectedGift!.price * _quantity);
    final totalCost = _selectedGift != null ? _selectedGift!.price * _quantity : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Quantity selector
            if (_selectedGift != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Quantity:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildQuantityButton(
                    icon: Icons.remove,
                    onTap: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildQuantityButton(
                    icon: Icons.add,
                    onTap: _quantity < 99
                        ? () => setState(() => _quantity++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Send button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: canSend
                    ? () {
                        widget.onSendGift(_selectedGift!, _quantity);
                        Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_selectedGift != null) ...[
                      Text(
                        _selectedGift!.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      _selectedGift != null
                          ? 'Send (${totalCost.toStringAsFixed(0)} KES)'
                          : 'Select a Gift',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onTap != null
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: onTap != null ? Colors.white : Colors.grey,
          size: 20,
        ),
      ),
    );
  }

  List<GiftType> _getGiftsByTier(GiftTier tier) {
    return GiftType.defaultGifts.where((gift) => gift.tier == tier).toList();
  }
}

// Usage example:
// showModalBottomSheet(
//   context: context,
//   backgroundColor: Colors.transparent,
//   isScrollControlled: true,
//   builder: (context) => GiftSelectionSheet(
//     userBalance: 5000.0,
//     onSendGift: (gift, quantity) {
//       // Handle gift sending
//     },
//   ),
// );
