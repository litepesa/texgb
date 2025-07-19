import 'package:flutter/material.dart';

class ReactionPicker extends StatelessWidget {
  final Function(String) onReactionSelected;

  const ReactionPicker({
    Key? key,
    required this.onReactionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Common emoji reactions
    const List<String> commonEmojis = [
      '👍', '❤️', '😂', '😮', '😢', '😡'
    ];
    
    // Additional emoji categories
    const Map<String, List<String>> emojiCategories = {
      'Smileys': ['😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃', '😉', '😊'],
      'Gestures': ['👍', '👎', '👊', '✊', '🤛', '🤜', '👏', '🙌', '👐', '🤲', '🤝', '🙏'],
      'Love': ['❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '💖', '💝'],
      'Animals': ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮'],
    };
    
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick reactions bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: commonEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () => onReactionSelected(emoji),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Emoji category tabs
          Expanded(
            child: DefaultTabController(
              length: emojiCategories.length,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TabBar(
                    isScrollable: true,
                    indicatorColor: Theme.of(context).primaryColor,
                    tabs: emojiCategories.keys.map((category) {
                      return Tab(
                        text: category,
                      );
                    }).toList(),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: emojiCategories.values.map((emojiList) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: emojiList.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => onReactionSelected(emojiList[index]),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    emojiList[index],
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Custom emoji picker button
          Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            child: TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('More Emoji'),
              onPressed: () {
                // This would typically open a more comprehensive emoji picker
                // or enable custom input, but that's beyond the scope of this example
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('More emoji options coming soon')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}