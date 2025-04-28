part of 'bottom_chat_field.dart';

class MoreOptionsGrid extends StatelessWidget {
  final Color accentColor;
  final Function(bool) onSelectImage;
  final VoidCallback onSelectVideo;
  final VoidCallback onStartRecording;

  const MoreOptionsGrid({
    super.key,
    required this.accentColor,
    required this.onSelectImage,
    required this.onSelectVideo,
    required this.onStartRecording,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'icon': Icons.photo_library,
        'color': Colors.green,
        'label': 'Gallery',
        'onTap': () => onSelectImage(false),
      },
      {
        'icon': Icons.camera_alt,
        'color': Colors.blue,
        'label': 'Camera',
        'onTap': () => onSelectImage(true),
      },
      {
        'icon': Icons.videocam,
        'color': Colors.red,
        'label': 'Video',
        'onTap': onSelectVideo,
      },
      {
        'icon': Icons.location_on,
        'color': Colors.orange,
        'label': 'Location',
        'onTap': () {}, // Placeholder
      },
      {
        'icon': Icons.mic,
        'color': Colors.purple,
        'label': 'Audio',
        'onTap': onStartRecording,
      },
      {
        'icon': Icons.insert_drive_file,
        'color': Colors.indigo,
        'label': 'Documents',
        'onTap': () {}, // Placeholder
      },
      {
        'icon': Icons.contacts,
        'color': accentColor,
        'label': 'Contact',
        'onTap': () {}, // Placeholder
      },
      {
        'icon': Icons.photo,
        'color': Colors.amber,
        'label': 'Stickers',
        'onTap': () {}, // Placeholder
      },
    ];
    
    return Container(
      height: 220,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<ModernThemeExtension>()?.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Handle indicator
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.9,
              ),
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (item['onTap'] != null) {
                        (item['onTap'] as Function)();
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    splashColor: (item['color'] as Color).withOpacity(0.1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withOpacity(0.12),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (item['color'] as Color).withOpacity(0.1),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: item['color'] as Color,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          textAlign: TextAlign.center,
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
}