// lib/shared/widgets/websocket_connection_status.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/providers/websocket_provider.dart';
import 'package:textgb/shared/services/websocket_service.dart';

class WebSocketConnectionStatus extends ConsumerWidget {
  final Widget child;
  final bool showConnectionBanner;

  const WebSocketConnectionStatus({
    super.key,
    required this.child,
    this.showConnectionBanner = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(websocketConnectionStateProvider);
    final wsService = ref.watch(websocketServiceProvider);

    return Stack(
      children: [
        child,
        if (showConnectionBanner)
          connectionState.when(
            data: (isConnected) {
              if (!isConnected && wsService.isConnecting) {
                return _buildConnectionBanner(
                  context,
                  'Connecting...',
                  Colors.orange,
                  showProgress: true,
                );
              } else if (!isConnected) {
                return _buildConnectionBanner(
                  context,
                  'Connection lost. Tap to retry.',
                  Colors.red,
                  onTap: () => wsService.connect(),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => _buildConnectionBanner(
              context,
              'Connecting...',
              Colors.orange,
              showProgress: true,
            ),
            error: (error, _) => _buildConnectionBanner(
              context,
              'Connection error',
              Colors.red,
              onTap: () => wsService.connect(),
            ),
          ),
      ],
    );
  }

  Widget _buildConnectionBanner(
    BuildContext context,
    String message,
    Color color, {
    bool showProgress = false,
    VoidCallback? onTap,
  }) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: color,
        child: InkWell(
          onTap: onTap,
          child: SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showProgress) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// WebSocket error listener widget
class WebSocketErrorListener extends ConsumerStatefulWidget {
  final Widget child;

  const WebSocketErrorListener({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<WebSocketErrorListener> createState() => _WebSocketErrorListenerState();
}

class _WebSocketErrorListenerState extends ConsumerState<WebSocketErrorListener> {
  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<String>>(
      websocketErrorStreamProvider,
      (previous, next) {
        next.whenData((error) {
          if (error.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Dismiss',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        });
      },
    );

    return widget.child;
  }
}

// Combined wrapper widget for WebSocket functionality
class WebSocketWrapper extends StatelessWidget {
  final Widget child;
  final bool showConnectionBanner;
  final bool showErrorMessages;

  const WebSocketWrapper({
    super.key,
    required this.child,
    this.showConnectionBanner = true,
    this.showErrorMessages = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget wrapped = child;

    if (showErrorMessages) {
      wrapped = WebSocketErrorListener(child: wrapped);
    }

    if (showConnectionBanner) {
      wrapped = WebSocketConnectionStatus(
        showConnectionBanner: showConnectionBanner,
        child: wrapped,
      );
    }

    return wrapped;
  }
}

// WebSocket connection indicator icon
class WebSocketConnectionIndicator extends ConsumerWidget {
  final double size;
  final Color? connectedColor;
  final Color? disconnectedColor;

  const WebSocketConnectionIndicator({
    super.key,
    this.size = 12,
    this.connectedColor,
    this.disconnectedColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(websocketConnectionStateProvider);
    final theme = Theme.of(context);

    return connectionState.when(
      data: (isConnected) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected
                ? (connectedColor ?? Colors.green)
                : (disconnectedColor ?? Colors.grey),
            boxShadow: isConnected
                ? [
                    BoxShadow(
                      color: (connectedColor ?? Colors.green).withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      },
      loading: () => SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            theme.colorScheme.primary,
          ),
        ),
      ),
      error: (_, __) => Icon(
        Icons.error_outline,
        size: size,
        color: disconnectedColor ?? Colors.red,
      ),
    );
  }
}

// Typing indicator widget that listens to WebSocket typing events
class TypingIndicator extends ConsumerWidget {
  final String chatId;

  const TypingIndicator({
    super.key,
    required this.chatId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typingEvents = ref.watch(typingEventsStreamProvider);

    return typingEvents.when(
      data: (message) {
        if (message.data['chatId'] == chatId && message.data['isTyping'] == true) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${message.data['userName'] ?? 'Someone'} is typing',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// WebSocket lifecycle manager
class WebSocketLifecycleManager extends ConsumerStatefulWidget {
  final Widget child;

  const WebSocketLifecycleManager({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<WebSocketLifecycleManager> createState() => _WebSocketLifecycleManagerState();
}

class _WebSocketLifecycleManagerState extends ConsumerState<WebSocketLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Connect on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wsService = ref.read(websocketServiceProvider);
      if (!wsService.isConnected && !wsService.isConnecting) {
        wsService.connect();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wsService = ref.read(websocketServiceProvider);

    switch (state) {
      case AppLifecycleState.resumed:
        // Reconnect when app comes to foreground
        if (!wsService.isConnected && !wsService.isConnecting) {
          wsService.connect();
        }
        wsService.updatePresence(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Update presence to offline when app goes to background
        wsService.updatePresence(false);
        break;
      case AppLifecycleState.detached:
        // Disconnect when app is being terminated
        wsService.disconnect();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}