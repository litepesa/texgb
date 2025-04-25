import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class ChannelSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final bool showResults;
  final String searchQuery;
  final Function(String) onChanged;
  final VoidCallback onClear;

  const ChannelSearchBar({
    Key? key,
    required this.controller,
    required this.placeholder,
    required this.showResults,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: modernTheme.dividerColor!,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Search Field
          CupertinoSearchTextField(
            controller: controller,
            placeholder: placeholder,
            onChanged: onChanged,
            onSuffixTap: onClear,
            style: TextStyle(color: modernTheme.textColor),
            backgroundColor: modernTheme.surfaceVariantColor,
            placeholderStyle: TextStyle(color: modernTheme.textSecondaryColor),
            prefixIcon: Icon(CupertinoIcons.search, color: modernTheme.textSecondaryColor),
            suffixIcon: showResults 
                ? Icon(CupertinoIcons.clear, color: modernTheme.textSecondaryColor) 
                : Icon(CupertinoIcons.search, color: Colors.transparent),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          ),
          
          // Search Results Indicator
          if (showResults)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.search,
                    size: 14,
                    color: modernTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Results for "$searchQuery"',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: modernTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onClear,
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: modernTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}