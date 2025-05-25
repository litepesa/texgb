import 'package:flutter/material.dart';
import 'package:textgb/features/channels/models/edited_media_model.dart';

class StickerOverlayEditor extends StatefulWidget {
  final Function(StickerOverlay) onStickerAdded;
  final Function(int, StickerOverlay) onStickerUpdated;
  final Function(int) onStickerDeleted;
  final List<StickerOverlay> existingStickers;

  const StickerOverlayEditor({
    Key? key,
    required this.onStickerAdded,
    required this.onStickerUpdated,
    required this.onStickerDeleted,
    required this.existingStickers,
  }) : super(key: key);

  @override
  State<StickerOverlayEditor> createState() => _StickerOverlayEditorState();
}

class _StickerOverlayEditorState extends State<StickerOverlayEditor>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'Trending';
  
  // Sticker categories and items
  final Map<String, List<StickerItem>> _stickerCategories = {
    'Trending': [
      StickerItem('assets/stickers/fire.png', 'Fire', animation: StickerAnimation.bounce),
      StickerItem('assets/stickers/heart.png', 'Heart', animation: StickerAnimation.scale),
      StickerItem('assets/stickers/star.png', 'Star', animation: StickerAnimation.rotate),
      StickerItem('assets/stickers/sparkles.png', 'Sparkles', animation: StickerAnimation.fadeIn),
      StickerItem('assets/stickers/100.png', '100', animation: StickerAnimation.bounce),
      StickerItem('assets/stickers/crown.png', 'Crown', animation: StickerAnimation.shake),
    ],
    'Emojis': [
      StickerItem('assets/stickers/laugh.png', 'Laugh'),
      StickerItem('assets/stickers/love_eyes.png', 'Love Eyes'),
      StickerItem('assets/stickers/cool.png', 'Cool'),
      StickerItem('assets/stickers/wink.png', 'Wink'),
      StickerItem('assets/stickers/kiss.png', 'Kiss'),
      StickerItem('assets/stickers/party.png', 'Party'),
    ],
    'Effects': [
      StickerItem('assets/stickers/lens_flare.png', 'Lens Flare'),
      StickerItem('assets/stickers/rainbow.png', 'Rainbow'),
      StickerItem('assets/stickers/smoke.png', 'Smoke'),
      StickerItem('assets/stickers/light_leak.png', 'Light Leak'),
      StickerItem('assets/stickers/bokeh.png', 'Bokeh'),
      StickerItem('assets/stickers/glitter.png', 'Glitter'),
    ],
    'Text': [
      StickerItem('assets/stickers/wow.png', 'WOW'),
      StickerItem('assets/stickers/omg.png', 'OMG'),
      StickerItem('assets/stickers/lol.png', 'LOL'),
      StickerItem('assets/stickers/love.png', 'LOVE'),
      StickerItem('assets/stickers/cute.png', 'CUTE'),
      StickerItem('assets/stickers/cool_text.png', 'COOL'),
    ],
    'Animated': [
      StickerItem('assets/stickers/neon_heart.gif', 'Neon Heart', isAnimated: true),
      StickerItem('assets/stickers/disco_ball.gif', 'Disco Ball', isAnimated: true),
      StickerItem('assets/stickers/confetti.gif', 'Confetti', isAnimated: true),
      StickerItem('assets/stickers/fireworks.gif', 'Fireworks', isAnimated: true),
      StickerItem('assets/stickers/stars.gif', 'Stars', isAnimated: true),
      StickerItem('assets/stickers/bubbles.gif', 'Bubbles', isAnimated: true),
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _stickerCategories.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addSticker(StickerItem sticker) {
    final stickerOverlay = StickerOverlay(
      stickerPath: sticker.path,
      position: const Offset(100, 200),
      animation: sticker.animation,
    );
    
    widget.onStickerAdded(stickerOverlay);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Column(
        children: [
          // Category tabs
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicator: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: _stickerCategories.keys.map((category) {
                return Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(category),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Sticker grid
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _stickerCategories.entries.map((entry) {
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: entry.value.length,
                  itemBuilder: (context, index) {
                    final sticker = entry.value[index];
                    return _buildStickerItem(sticker);
                  },
                );
              }).toList(),
            ),
          ),
          
          // Recent stickers
          if (widget.existingStickers.isNotEmpty) ...[
            Container(
              height: 1,
              color: Colors.white12,
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
            _buildRecentStickers(),
          ],
        ],
      ),
    );
  }

  Widget _buildStickerItem(StickerItem sticker) {
    return GestureDetector(
      onTap: () => _addSticker(sticker),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white12,
          ),
        ),
        child: Stack(
          children: [
            // Sticker image placeholder
            Center(
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    sticker.name.substring(0, 2).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            
            // Animated indicator
            if (sticker.isAnimated)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 12,
                    color: Colors.black,
                  ),
                ),
              ),
            
            // Animation type indicator
            if (sticker.animation != null)
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getAnimationName(sticker.animation!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentStickers() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Added Stickers',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.existingStickers.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => widget.onStickerDeleted(index),
                  child: Container(
                    width: 50,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const Center(
                          child: Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getAnimationName(StickerAnimation animation) {
    switch (animation) {
      case StickerAnimation.fadeIn:
        return 'Fade';
      case StickerAnimation.bounce:
        return 'Bounce';
      case StickerAnimation.rotate:
        return 'Spin';
      case StickerAnimation.scale:
        return 'Pulse';
      case StickerAnimation.shake:
        return 'Shake';
    }
  }
}

class StickerItem {
  final String path;
  final String name;
  final bool isAnimated;
  final StickerAnimation? animation;

  StickerItem(
    this.path,
    this.name, {
    this.isAnimated = false,
    this.animation,
  });
}