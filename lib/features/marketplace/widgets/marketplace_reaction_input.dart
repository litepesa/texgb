// lib/features/marketplace/widgets/marketplace_reaction_input.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/marketplace/models/marketplace_video_model.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class MarketplaceReactionInput extends ConsumerStatefulWidget {
  final MarketplaceVideoModel listing;
  final Function(String reaction) onSendReaction;
  final VoidCallback onCancel;

  const MarketplaceReactionInput({
    super.key,
    required this.listing,
    required this.onSendReaction,
    required this.onCancel,
  });

  @override
  ConsumerState<MarketplaceReactionInput> createState() =>
      _MarketplaceReactionInputState();
}

class _MarketplaceReactionInputState
    extends ConsumerState<MarketplaceReactionInput>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _sendReaction(String reaction) {
    if (reaction.trim().isNotEmpty) {
      widget.onSendReaction(reaction);
      _textController.clear();
      _closeWithAnimation();
    }
  }

  void _closeWithAnimation() async {
    await _fadeController.reverse();
    await _slideController.reverse();
    widget.onCancel();
  }

  String? _getBestThumbnailUrl() {
    if (widget.listing.thumbnailUrl.isNotEmpty) {
      return widget.listing.thumbnailUrl;
    }
    if (widget.listing.isMultipleImages &&
        widget.listing.imageUrls.isNotEmpty) {
      return widget.listing.imageUrls.first;
    }
    return null;
  }

  UserModel? _getListingOwner() {
    final users = ref.watch(usersProvider);
    try {
      return users.firstWhere(
        (user) => user.uid == widget.listing.userId,
        orElse: () => throw StateError('User not found'),
      );
    } catch (e) {
      return null;
    }
  }

  String _formatPrice(double price) {
    if (price == 0) return 'Free';
    return 'KSh ${price.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final currentUser = ref.watch(currentUserProvider);
    final listingOwner = _getListingOwner();
    final thumbnailUrl = _getBestThumbnailUrl();

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.only(bottom: keyboardHeight),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                modernTheme.surfaceColor?.withOpacity(0.98) ??
                    Colors.white.withOpacity(0.98),
                modernTheme.surfaceColor ?? Colors.white,
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 56,
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            modernTheme.primaryColor?.withOpacity(0.4) ??
                                Colors.grey.withOpacity(0.4),
                            modernTheme.primaryColor?.withOpacity(0.7) ??
                                Colors.grey.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.green.withOpacity(0.15),
                              Colors.green.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                CupertinoIcons.cart,
                                size: 16,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Contact Seller',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // Close button
                      Container(
                        decoration: BoxDecoration(
                          color: modernTheme.surfaceVariantColor
                                  ?.withOpacity(0.8) ??
                              Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: modernTheme.dividerColor?.withOpacity(0.4) ??
                                Colors.grey.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: _closeWithAnimation,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.close_rounded,
                                color: modernTheme.textSecondaryColor,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Listing preview card
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          modernTheme.surfaceColor ?? Colors.white,
                          modernTheme.surfaceVariantColor?.withOpacity(0.4) ??
                              Colors.grey.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: modernTheme.dividerColor?.withOpacity(0.6) ??
                            Colors.grey.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Listing thumbnail
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 88,
                                height: 88,
                                child: thumbnailUrl != null
                                    ? Image.network(
                                        thumbnailUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color:
                                                modernTheme.surfaceVariantColor,
                                            child: Icon(
                                              CupertinoIcons.photo,
                                              color: modernTheme
                                                  .textSecondaryColor,
                                              size: 32,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: modernTheme.surfaceVariantColor,
                                        child: Icon(
                                          CupertinoIcons.photo,
                                          color: modernTheme.textSecondaryColor,
                                          size: 32,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Listing info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Seller info row
                                Row(
                                  children: [
                                    // Seller avatar
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.green.withOpacity(0.4),
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                            Colors.green.withOpacity(0.1),
                                        backgroundImage: (listingOwner
                                                    ?.profileImage.isNotEmpty ==
                                                true)
                                            ? NetworkImage(
                                                listingOwner!.profileImage)
                                            : (widget.listing.userImage
                                                    .isNotEmpty
                                                ? NetworkImage(
                                                    widget.listing.userImage)
                                                : null),
                                        child: (listingOwner?.profileImage
                                                        .isEmpty !=
                                                    false &&
                                                widget
                                                    .listing.userImage.isEmpty)
                                            ? Text(
                                                (listingOwner
                                                            ?.name.isNotEmpty ==
                                                        true)
                                                    ? listingOwner!.name[0]
                                                        .toUpperCase()
                                                    : widget.listing.userName
                                                            .isNotEmpty
                                                        ? widget
                                                            .listing.userName[0]
                                                            .toUpperCase()
                                                        : 'S',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Seller name
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            listingOwner?.name ??
                                                widget.listing.userName,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: modernTheme.textColor,
                                              letterSpacing: 0.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),

                                          // Price tag
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.green
                                                      .withOpacity(0.12),
                                                  Colors.green
                                                      .withOpacity(0.06),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.green
                                                    .withOpacity(0.2),
                                                width: 0.5,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  CupertinoIcons.tag,
                                                  size: 10,
                                                  color: Colors.green,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatPrice(
                                                      widget.listing.price),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.green,
                                                    letterSpacing: 0.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Listing caption preview
                                if (widget.listing.caption.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: modernTheme.surfaceVariantColor
                                          ?.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: modernTheme.dividerColor
                                                ?.withOpacity(0.3) ??
                                            Colors.grey.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      widget.listing.caption,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: modernTheme.textSecondaryColor,
                                        fontWeight: FontWeight.w400,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Text input section header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Your message',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: modernTheme.textColor,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'to ${listingOwner?.name ?? widget.listing.userName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ask about availability, pricing, or make an offer',
                          style: TextStyle(
                            fontSize: 14,
                            color: modernTheme.textSecondaryColor
                                ?.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Text input
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          modernTheme.surfaceColor ?? Colors.white,
                          modernTheme.surfaceVariantColor?.withOpacity(0.2) ??
                              Colors.grey.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _focusNode.hasFocus
                            ? Colors.green.withOpacity(0.8)
                            : modernTheme.dividerColor?.withOpacity(0.6) ??
                                Colors.grey.withOpacity(0.3),
                        width: _focusNode.hasFocus ? 2 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                        if (_focusNode.hasFocus)
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Current user avatar
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.green.withOpacity(0.1),
                            backgroundImage:
                                currentUser?.profileImage.isNotEmpty == true
                                    ? NetworkImage(currentUser!.profileImage)
                                    : null,
                            child: currentUser?.profileImage.isEmpty != false
                                ? Text(
                                    currentUser?.name.isNotEmpty == true
                                        ? currentUser!.name[0].toUpperCase()
                                        : 'Y',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  )
                                : null,
                          ),
                        ),

                        // Text input
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            maxLines: 4,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            style: TextStyle(
                              color: modernTheme.textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.1,
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Hi, is this still available?',
                              hintStyle: TextStyle(
                                color: modernTheme.textSecondaryColor
                                    ?.withOpacity(0.6),
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.1,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            onSubmitted: _sendReaction,
                          ),
                        ),

                        // Send button
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _textController.text.trim().isNotEmpty
                                  ? [
                                      Colors.green,
                                      Colors.green.shade700,
                                    ]
                                  : [
                                      modernTheme.dividerColor
                                              ?.withOpacity(0.3) ??
                                          Colors.grey.withOpacity(0.3),
                                      modernTheme.dividerColor
                                              ?.withOpacity(0.2) ??
                                          Colors.grey.withOpacity(0.2),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _textController.text.trim().isNotEmpty
                                ? [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: _textController.text.trim().isNotEmpty
                                  ? () => _sendReaction(_textController.text)
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Icons.send_rounded,
                                  color: _textController.text.trim().isNotEmpty
                                      ? Colors.white
                                      : modernTheme.textSecondaryColor
                                          ?.withOpacity(0.5),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: keyboardHeight > 0 ? 16 : 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
