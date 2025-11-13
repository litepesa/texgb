import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/payment/providers/payment_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class WalletTopUpScreen extends ConsumerStatefulWidget {
  const WalletTopUpScreen({super.key});

  @override
  ConsumerState<WalletTopUpScreen> createState() => _WalletTopUpScreenState();
}

class _WalletTopUpScreenState extends ConsumerState<WalletTopUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();

  // Predefined amounts in KES
  final List<double> _quickAmounts = [100, 250, 500, 1000, 2000, 5000];
  double? _selectedAmount;
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
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

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove any non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    // Check if it's a valid Kenyan phone number
    if (digitsOnly.length < 9 || digitsOnly.length > 12) {
      return 'Invalid phone number';
    }

    // Must start with 254, 0, or 7
    if (!digitsOnly.startsWith('254') &&
        !digitsOnly.startsWith('0') &&
        !digitsOnly.startsWith('7')) {
      return 'Phone number must be Kenyan (start with 254, 0, or 7)';
    }

    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Invalid amount';
    }

    if (amount < 10) {
      return 'Minimum amount is KES 10';
    }

    if (amount > 150000) {
      return 'Maximum amount is KES 150,000';
    }

    return null;
  }

  String _formatPhoneNumber(String phone) {
    // Remove any non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');

    // Format to 254XXXXXXXXX
    if (digitsOnly.startsWith('254')) {
      return digitsOnly;
    } else if (digitsOnly.startsWith('0')) {
      return '254${digitsOnly.substring(1)}';
    } else if (digitsOnly.startsWith('7')) {
      return '254$digitsOnly';
    }

    return digitsOnly;
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final amount = _selectedAmount ?? double.parse(_amountController.text);
    final phone = _formatPhoneNumber(_phoneController.text);

    try {
      final checkoutRequestId = await ref.read(paymentProvider.notifier).initiateTopUp(
        amount: amount,
        phoneNumber: phone,
      );

      if (!mounted) return;

      if (checkoutRequestId != null) {
        // Navigate to payment status screen
        context.push('/payment-status/$checkoutRequestId');
      } else {
        // Show error from provider state
        final error = ref.read(paymentProvider).error;
        _showErrorDialog(error ?? 'Failed to initiate payment');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _selectQuickAmount(double amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getSafeTheme(context);
    final paymentState = ref.watch(paymentProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text('Top Up Wallet'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor ?? Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: theme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'M-Pesa Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1 KES = 1 Coin\nYou will receive an M-Pesa prompt on your phone to complete the payment.',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textSecondaryColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick amounts
              Text(
                'Quick Select',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAmounts.map((amount) {
                  final isSelected = _selectedAmount == amount;
                  return InkWell(
                    onTap: () => _selectQuickAmount(amount),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.primaryColor : theme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? theme.primaryColor! : (theme.dividerColor ?? Colors.grey[300]!),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'KES ${amount.toInt()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : theme.textColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Custom amount
              Text(
                'Or Enter Custom Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                enabled: _selectedAmount == null,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: 'Amount (KES)',
                  hintText: 'Enter amount (min KES 10)',
                  prefixText: 'KES ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: _selectedAmount != null
                      ? Colors.grey[100]
                      : theme.surfaceColor,
                ),
                validator: _selectedAmount != null ? null : _validateAmount,
                onChanged: (_) {
                  setState(() {
                    _selectedAmount = null;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Phone number
              Text(
                'M-Pesa Phone Number',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '0712345678 or 254712345678',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: theme.surfaceColor,
                ),
                validator: _validatePhone,
              ),

              const SizedBox(height: 32),

              // Pay button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isProcessing || paymentState.isLoading)
                      ? null
                      : _initiatePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessing || paymentState.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Pay KES ${_selectedAmount?.toInt() ?? (_amountController.text.isEmpty ? '---' : _amountController.text)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel button
              TextButton(
                onPressed: _isProcessing ? null : () => context.pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
