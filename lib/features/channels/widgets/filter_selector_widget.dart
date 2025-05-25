import 'package:flutter/material.dart';

class FilterSelectorWidget extends StatefulWidget {
  final String? selectedFilter;
  final double brightness;
  final double contrast;
  final double saturation;
  final Function(String?) onFilterChanged;
  final Function({
    double? brightness,
    double? contrast,
    double? saturation,
  }) onAdjustmentChanged;

  const FilterSelectorWidget({
    Key? key,
    this.selectedFilter,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.onFilterChanged,
    required this.onAdjustmentChanged,
  }) : super(key: key);

  @override
  State<FilterSelectorWidget> createState() => _FilterSelectorWidgetState();
}

class _FilterSelectorWidgetState extends State<FilterSelectorWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<FilterItem> _filters = [
    FilterItem('None', null, Colors.grey),
    FilterItem('Vintage', 'Vintage', Colors.orange),
    FilterItem('Cool', 'Cool', Colors.blue),
    FilterItem('Warm', 'Warm', Colors.amber),
    FilterItem('B&W', 'Black & White', Colors.black),
    FilterItem('Dramatic', 'Dramatic', Colors.deepPurple),
    FilterItem('Vivid', 'Vivid', Colors.pink),
    FilterItem('Muted', 'Muted', Colors.blueGrey),
    FilterItem('Film', 'Film', Colors.brown),
    FilterItem('Neon', 'Neon', Colors.cyan),
  ];

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
      color: Colors.black.withOpacity(0.9),
      child: Column(
        children: [
          // Tab bar for filters and adjustments
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: 'Filters'),
                Tab(text: 'Adjust'),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFiltersTab(),
                _buildAdjustmentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: _filters.length,
      itemBuilder: (context, index) {
        final filter = _filters[index];
        final isSelected = widget.selectedFilter == filter.value;
        
        return GestureDetector(
          onTap: () => widget.onFilterChanged(filter.value),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white24,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Filter preview
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        filter.color.withOpacity(0.3),
                        filter.color.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.image,
                    color: Colors.white.withOpacity(0.5),
                    size: 40,
                  ),
                ),
                
                // Filter name
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: Text(
                      filter.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                // Selected indicator
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.black,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdjustmentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAdjustmentSlider(
            label: 'Brightness',
            icon: Icons.brightness_6,
            value: widget.brightness,
            min: -1.0,
            max: 1.0,
            onChanged: (value) => widget.onAdjustmentChanged(brightness: value),
          ),
          const SizedBox(height: 24),
          
          _buildAdjustmentSlider(
            label: 'Contrast',
            icon: Icons.contrast,
            value: widget.contrast,
            min: 0.5,
            max: 2.0,
            onChanged: (value) => widget.onAdjustmentChanged(contrast: value),
          ),
          const SizedBox(height: 24),
          
          _buildAdjustmentSlider(
            label: 'Saturation',
            icon: Icons.palette,
            value: widget.saturation,
            min: 0.0,
            max: 2.0,
            onChanged: (value) => widget.onAdjustmentChanged(saturation: value),
          ),
          const SizedBox(height: 24),
          
          // Reset button
          Center(
            child: TextButton.icon(
              onPressed: () {
                widget.onAdjustmentChanged(
                  brightness: 0.0,
                  contrast: 1.0,
                  saturation: 1.0,
                );
              },
              icon: const Icon(Icons.refresh, color: Colors.white70),
              label: const Text(
                'Reset All',
                style: TextStyle(color: Colors.white70),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentSlider({
    required String label,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatValue(value, min, max),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white30,
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.3),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  String _formatValue(double value, double min, double max) {
    if (min < 0) {
      // For brightness (-1 to 1)
      final percentage = (value * 100).round();
      return percentage >= 0 ? '+$percentage%' : '$percentage%';
    } else if (max == 2.0) {
      // For contrast and saturation (0 to 2)
      final percentage = (value * 100).round();
      return '$percentage%';
    }
    return value.toStringAsFixed(1);
  }
}

class FilterItem {
  final String name;
  final String? value;
  final Color color;

  FilterItem(this.name, this.value, this.color);
}