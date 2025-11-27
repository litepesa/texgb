// ===============================
// Status Template Picker
// Bottom sheet for selecting text status templates
// ===============================

import 'package:flutter/material.dart';
import 'package:textgb/features/status/models/status_templates.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class StatusTemplatePicker extends StatefulWidget {
  final Function(StatusTemplate template) onTemplateSelected;

  const StatusTemplatePicker({
    super.key,
    required this.onTemplateSelected,
  });

  @override
  State<StatusTemplatePicker> createState() => _StatusTemplatePickerState();
}

class _StatusTemplatePickerState extends State<StatusTemplatePicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: StatusTemplates.categories.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Choose a Template',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Category tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
            tabs: StatusTemplates.categories
                .map((category) => Tab(text: category))
                .toList(),
          ),

          // Template list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: StatusTemplates.categories.map((category) {
                final templates = StatusTemplates.getByCategory(category);
                return _buildTemplateList(templates);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateList(List<StatusTemplate> templates) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _TemplateCard(
          template: template,
          onTap: () {
            widget.onTemplateSelected(template);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final StatusTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: template.background.colors.map((hex) => _hexToColor(hex)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (template.emoji != null) ...[
                  Text(
                    template.emoji!,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  template.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===============================
// Show Template Picker Helper
// ===============================

Future<StatusTemplate?> showStatusTemplatePicker(BuildContext context) async {
  return await showModalBottomSheet<StatusTemplate>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatusTemplatePicker(
      onTemplateSelected: (template) {},
    ),
  );
}

// Helper function to convert hex color string to Color
Color _hexToColor(String hex) {
  final hexCode = hex.replaceAll('#', '');
  return Color(int.parse('FF$hexCode', radix: 16));
}