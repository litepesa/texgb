// ===============================
// Status Reaction Picker
// Bottom sheet for selecting emoji reactions
// ===============================

import 'package:flutter/material.dart';
import 'package:textgb/features/status/models/status_reaction_model.dart';
import 'package:textgb/features/status/theme/status_theme.dart';

class StatusReactionPicker extends StatefulWidget {
  final Function(String emoji) onReactionSelected;
  final String? currentReaction;

  const StatusReactionPicker({
    super.key,
    required this.onReactionSelected,
    this.currentReaction,
  });

  @override
  State<StatusReactionPicker> createState() => _StatusReactionPickerState();
}

class _StatusReactionPickerState extends State<StatusReactionPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'React to Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (widget.currentReaction != null)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop('remove'),
                    child: const Text('Remove'),
                  ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: StatusTheme.primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: StatusTheme.primaryBlue,
            tabs: const [
              Tab(text: 'Quick'),
              Tab(text: 'All'),
            ],
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuickReactions(),
                _buildAllReactions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReactions() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: StatusReactionEmojis.quick.length,
      itemBuilder: (context, index) {
        final emoji = StatusReactionEmojis.quick[index];
        final isSelected = widget.currentReaction == emoji;

        return _ReactionButton(
          emoji: emoji,
          label: StatusReactionEmojis.getLabel(emoji),
          isSelected: isSelected,
          onTap: () {
            widget.onReactionSelected(emoji);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Widget _buildAllReactions() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: StatusReactionEmojis.all.length,
      itemBuilder: (context, index) {
        final emoji = StatusReactionEmojis.all[index];
        final isSelected = widget.currentReaction == emoji;

        return GestureDetector(
          onTap: () {
            widget.onReactionSelected(emoji);
            Navigator.of(context).pop();
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? StatusTheme.primaryBlue.withValues(alpha: 0.1) : null,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: StatusTheme.primaryBlue, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? StatusTheme.primaryBlue.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: StatusTheme.primaryBlue, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? StatusTheme.primaryBlue : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================
// Show Reaction Picker Helper
// ===============================

Future<String?> showStatusReactionPicker({
  required BuildContext context,
  String? currentReaction,
}) async {
  return await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatusReactionPicker(
      currentReaction: currentReaction,
      onReactionSelected: (emoji) {},
    ),
  );
}
