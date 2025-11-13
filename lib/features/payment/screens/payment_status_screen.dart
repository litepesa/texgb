import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/payment/providers/payment_providers.dart';
import 'package:textgb/features/wallet/providers/wallet_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class PaymentStatusScreen extends ConsumerStatefulWidget {
  final String checkoutRequestId;
  final bool isActivation;

  const PaymentStatusScreen({
    super.key,
    required this.checkoutRequestId,
    this.isActivation = false,
  });

  @override
  ConsumerState<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends ConsumerState<PaymentStatusScreen> {
  Timer? _pollingTimer;
  int _pollCount = 0;
  static const int _maxPolls = 60; // Poll for up to 2 minutes (every 2 seconds)
  static const Duration _pollInterval = Duration(seconds: 2);

  String _statusMessage = 'Processing payment...';
  IconData _statusIcon = Icons.hourglass_empty;
  Color _statusColor = Colors.orange;
  bool _isComplete = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // Helper method to get safe theme with fallback
  ModernThemeExtension _getSafeTheme(BuildContext context) {
    return Theme.of(context).extension<ModernThemeExtension>() ??
        ModernThemeExtension(
          primaryColor: const Color(0xFF07C160), // WeChat green for Kenya
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceColor: Theme.of(context).cardColor,
          textColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          textSecondaryColor: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[600],
          dividerColor: Theme.of(context).dividerColor,
          textTertiaryColor: Colors.grey[400],
          surfaceVariantColor: Colors.grey[100],
        );
  }

  void _startPolling() {
    _pollPaymentStatus();
    _pollingTimer = Timer.periodic(_pollInterval, (_) {
      if (_pollCount >= _maxPolls) {
        _handleTimeout();
        return;
      }
      _pollPaymentStatus();
    });
  }

  Future<void> _pollPaymentStatus() async {
    _pollCount++;

    final transaction = await ref.read(paymentProvider.notifier).pollPaymentStatus(
      widget.checkoutRequestId,
    );

    if (!mounted) return;

    if (transaction != null) {
      setState(() {
        switch (transaction.status) {
          case 'completed':
            _isComplete = true;
            _isSuccess = true;
            _statusMessage = 'Payment Successful!';
            _statusIcon = Icons.check_circle;
            _statusColor = Colors.green;
            _pollingTimer?.cancel();

            // Refresh wallet to show updated balance
            ref.invalidate(walletProvider);

            break;

          case 'failed':
            _isComplete = true;
            _isSuccess = false;
            _statusMessage = transaction.resultDesc ?? 'Payment Failed';
            _statusIcon = Icons.error;
            _statusColor = Colors.red;
            _pollingTimer?.cancel();
            break;

          case 'cancelled':
            _isComplete = true;
            _isSuccess = false;
            _statusMessage = 'Payment Cancelled';
            _statusIcon = Icons.cancel;
            _statusColor = Colors.orange;
            _pollingTimer?.cancel();
            break;

          case 'timeout':
            _handleTimeout();
            break;

          case 'pending':
          default:
            _statusMessage = 'Waiting for M-Pesa confirmation...\nCheck your phone for the payment prompt.';
            _statusIcon = Icons.phone_android;
            _statusColor = Colors.blue;
            break;
        }
      });
    }
  }

  void _handleTimeout() {
    _pollingTimer?.cancel();
    if (mounted) {
      setState(() {
        _isComplete = true;
        _isSuccess = false;
        _statusMessage = 'Payment timeout. Please check your transaction history.';
        _statusIcon = Icons.access_time;
        _statusColor = Colors.grey;
      });
    }
  }

  void _navigateBack() {
    // Clear current transaction from payment provider
    ref.read(paymentProvider.notifier).clearCurrentTransaction();

    if (widget.isActivation) {
      // For activation payments, navigate to home screen
      context.go('/home');
    } else {
      // For wallet top-ups, pop back to wallet screen
      context.pop();
      context.pop(); // Pop twice to go back to wallet
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getSafeTheme(context);
    final paymentState = ref.watch(paymentProvider);
    final transaction = paymentState.currentTransaction;

    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation while polling
        if (!_isComplete) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Exit Payment'),
              content: const Text(
                'Payment is still processing. Are you sure you want to exit?\n\nYou can check the transaction status later in your transaction history.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Stay'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Exit'),
                ),
              ],
            ),
          );
          return shouldExit ?? false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: AppBar(
          title: const Text('Payment Status'),
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: _isComplete,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: _isComplete
                      ? Icon(
                          _statusIcon,
                          size: 64,
                          color: _statusColor,
                        )
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                              ),
                            ),
                            Icon(
                              _statusIcon,
                              size: 48,
                              color: _statusColor,
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 32),

                // Status message
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                    height: 1.5,
                  ),
                ),

                if (transaction != null && !_isComplete) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Amount: KES ${transaction.amount.toInt()}',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                  Text(
                    'Phone: ${transaction.phoneNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],

                if (_isComplete && _isSuccess && transaction != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Amount Paid:',
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.textSecondaryColor,
                              ),
                            ),
                            Text(
                              'KES ${transaction.amount.toInt()}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Coins Received:',
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.textSecondaryColor,
                              ),
                            ),
                            Text(
                              '${transaction.amount.toInt()} coins',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        if (transaction.mpesaReceiptNumber != null) ...[
                          const SizedBox(height: 8),
                          Divider(color: theme.dividerColor),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'M-Pesa Code:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textSecondaryColor,
                                ),
                              ),
                              Text(
                                transaction.mpesaReceiptNumber!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Action buttons
                if (_isComplete)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _navigateBack,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSuccess ? theme.primaryColor : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isSuccess ? 'Back to Wallet' : 'Close',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                if (!_isComplete) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Cancel Payment'),
                          content: const Text(
                            'Are you sure you want to cancel? You can check the transaction status later in your transaction history.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _pollingTimer?.cancel();
                                context.pop();
                                context.pop();
                              },
                              child: const Text('Yes'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.textSecondaryColor,
                      ),
                    ),
                  ),
                ],

                if (!_isComplete) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Poll ${_pollCount}/$_maxPolls',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTertiaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
