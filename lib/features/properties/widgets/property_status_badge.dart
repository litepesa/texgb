// lib/features/properties/widgets/property_status_badge.dart
import 'package:flutter/material.dart';
import 'package:textgb/features/properties/models/property_listing_model.dart';

class PropertyStatusBadge extends StatelessWidget {
  final PropertyStatus status;
  final bool compact;

  const PropertyStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData? icon;

    switch (status) {
      case PropertyStatus.draft:
        backgroundColor = Colors.grey.withOpacity(0.8);
        textColor = Colors.white;
        icon = Icons.edit;
        break;
      case PropertyStatus.pending:
        backgroundColor = Colors.orange.withOpacity(0.8);
        textColor = Colors.white;
        icon = Icons.pending;
        break;
      case PropertyStatus.verified:
        backgroundColor = Colors.green.withOpacity(0.8);
        textColor = Colors.white;
        icon = Icons.verified;
        break;
      case PropertyStatus.rejected:
        backgroundColor = Colors.red.withOpacity(0.8);
        textColor = Colors.white;
        icon = Icons.cancel;
        break;
      case PropertyStatus.inactive:
        backgroundColor = Colors.grey.withOpacity(0.8);
        textColor = Colors.white;
        icon = Icons.visibility_off;
        break;
      case PropertyStatus.expired:
        backgroundColor = Colors.red[800]!.withOpacity(0.8);
        textColor = Colors.white;
        icon = Icons.schedule;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null && !compact) ...[
            Icon(
              icon,
              size: 12,
              color: textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            status.displayName,
            style: TextStyle(
              color: textColor,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}