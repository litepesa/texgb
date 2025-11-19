// lib/features/channels/widgets/channel_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/theme/channels_theme.dart';

/// Facebook-quality channel card widget for lists and grids
class ChannelCard extends StatefulWidget {
  final ChannelModel channel;
  final VoidCallback? onTap;
  final VoidCallback? onSubscribe;
  final bool showSubscribeButton;

  const ChannelCard({
    super.key,
    required this.channel,
    this.onTap,
    this.onSubscribe,
    this.showSubscribeButton = true,
  });

  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<ChannelCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(
          horizontal: ChannelsTheme.spacingL,
          vertical: ChannelsTheme.spacingS,
        ),
        decoration: ChannelsTheme.cardDecoration(
          boxShadow: _isHovered ? ChannelsTheme.hoverShadow : ChannelsTheme.cardShadow,
        ),
        child: Material(
          color: ChannelsTheme.cardBackground,
          borderRadius: BorderRadius.circular(ChannelsTheme.cardRadius),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(ChannelsTheme.cardRadius),
            splashColor: ChannelsTheme.hoverColor.withOpacity(0.5),
            highlightColor: ChannelsTheme.hoverColor.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(ChannelsTheme.spacingL),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Channel Avatar
                  _buildAvatar(),
                  const SizedBox(width: ChannelsTheme.spacingM),

                  // Channel Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Channel Name + Verified Badge + Type Badge
                        _buildHeader(),
                        const SizedBox(height: ChannelsTheme.spacingXs),

                        // Description
                        _buildDescription(),
                        const SizedBox(height: ChannelsTheme.spacingM),

                        // Stats Row
                        _buildStats(),
                      ],
                    ),
                  ),

                  // Subscribe Button (if enabled)
                  if (widget.showSubscribeButton) ...[
                    const SizedBox(width: ChannelsTheme.spacingM),
                    _buildSubscribeButton(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ChannelsTheme.avatarRadius),
        color: ChannelsTheme.hoverColor,
        image: widget.channel.avatarUrl != null
            ? DecorationImage(
                image: NetworkImage(widget.channel.avatarUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: widget.channel.avatarUrl == null
          ? Icon(
              CupertinoIcons.tv_circle_fill,
              size: 32,
              color: ChannelsTheme.textTertiary,
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Channel Name
        Flexible(
          child: Text(
            widget.channel.name,
            style: ChannelsTheme.headingSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Verified Badge
        if (widget.channel.isVerified) ...[
          const SizedBox(width: ChannelsTheme.spacingXs),
          ChannelsTheme.verifiedBadge(size: 18),
        ],

        // Channel Type Badge
        const SizedBox(width: ChannelsTheme.spacingS),
        _buildTypeBadge(),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.channel.description,
      style: ChannelsTheme.bodyMedium,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        // Subscriber count
        Icon(
          CupertinoIcons.person_2_fill,
          size: 16,
          color: ChannelsTheme.textTertiary,
        ),
        const SizedBox(width: ChannelsTheme.spacingXs),
        Text(
          _formatCount(widget.channel.subscriberCount),
          style: ChannelsTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),

        // Dot separator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ChannelsTheme.spacingS),
          child: Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: ChannelsTheme.textTertiary,
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Post count
        Icon(
          CupertinoIcons.square_grid_2x2_fill,
          size: 16,
          color: ChannelsTheme.textTertiary,
        ),
        const SizedBox(width: ChannelsTheme.spacingXs),
        Text(
          '${widget.channel.postCount} ${widget.channel.postCount == 1 ? 'post' : 'posts'}',
          style: ChannelsTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeBadge() {
    Color bgColor;
    IconData icon;

    switch (widget.channel.type) {
      case ChannelType.premium:
        bgColor = ChannelsTheme.premiumChannelColor;
        icon = Icons.star;
        break;
      case ChannelType.private:
        bgColor = ChannelsTheme.privateChannelColor;
        icon = Icons.lock;
        break;
      case ChannelType.public:
      default:
        bgColor = ChannelsTheme.publicChannelColor;
        icon = Icons.public;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ChannelsTheme.spacingS,
        vertical: ChannelsTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: ChannelsTheme.white),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton() {
    final isSubscribed = widget.channel.isSubscribed ?? false;

    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: widget.onSubscribe,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSubscribed
              ? ChannelsTheme.hoverColor
              : ChannelsTheme.facebookBlue,
          foregroundColor: isSubscribed
              ? ChannelsTheme.textPrimary
              : ChannelsTheme.white,
          padding: const EdgeInsets.symmetric(
            horizontal: ChannelsTheme.spacingL,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ChannelsTheme.buttonRadius),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSubscribed)
              Icon(
                Icons.check,
                size: 16,
                color: ChannelsTheme.textPrimary,
              ),
            if (isSubscribed) const SizedBox(width: ChannelsTheme.spacingXs),
            Text(
              isSubscribed ? 'Subscribed' : 'Subscribe',
              style: ChannelsTheme.buttonText.copyWith(
                color: isSubscribed
                    ? ChannelsTheme.textPrimary
                    : ChannelsTheme.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      final millions = count / 1000000;
      return millions % 1 == 0
          ? '${millions.toInt()}M'
          : '${millions.toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      final thousands = count / 1000;
      return thousands % 1 == 0
          ? '${thousands.toInt()}K'
          : '${thousands.toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
