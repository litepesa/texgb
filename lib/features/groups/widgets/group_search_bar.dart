import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:textgb/shared/theme/wechat_theme_extension.dart';

class GroupSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final String placeholder;
  final bool showResults;
  final String? searchQuery;

  const GroupSearchBar({
    Key? key,
    required this.controller,
    required this.onChanged,
    this.onClear,
    this.placeholder = 'Search groups',
    this.showResults = false,
    this.searchQuery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top space after app bar/tabs
        const SizedBox(height: 12),
        
        // Search bar with enhanced styling
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey.shade800 
                : Colors.grey.shade200,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: CupertinoSearchTextField(
            controller: controller,
            backgroundColor: Colors.transparent,
            prefixInsets: const EdgeInsets.only(left: 12),
            suffixInsets: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            placeholder: placeholder,
            placeholderStyle: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium!.color?.withOpacity(0.6),
              fontSize: 15,
            ),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium!.color,
              fontSize: 15,
            ),
            onChanged: onChanged,
            onSuffixTap: () {
              controller.clear();
              if (onClear != null) {
                onClear!();
              }
              FocusScope.of(context).unfocus();
            },
          ),
        ),
        
        // Results indicator when searching
        if (showResults && searchQuery != null && searchQuery!.isNotEmpty) 
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 0),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 16,
                  color: themeExtension?.greyColor ?? Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Search results for "$searchQuery"',
                  style: TextStyle(
                    fontSize: 13,
                    color: themeExtension?.greyColor ?? Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
        // Divider for better section separation
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: themeExtension?.dividerColor ?? Colors.grey.withOpacity(0.2),
          ),
        ),
      ],
    );
  }
}