import 'package:flutter/material.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';

class CreateStatusButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CreateStatusButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? const Color(0xFF07C160);
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        onPressed: onPressed,
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
        tooltip: 'Create Status',
      ),
    );
  }
}