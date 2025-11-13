import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/payment/providers/payment_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class ActivationPaymentScreen extends ConsumerStatefulWidget {
  const ActivationPaymentScreen({super.key});

  @override
  ConsumerState<ActivationPaymentScreen> createState() => _ActivationPaymentScreenState();
}

class _ActivationPaymentScreenState extends ConsumerState<ActivationPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isProcessing = false;

  static const double _activationFee = 99.0;

  @override
  void dispose() {
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

    final phone = _formatPhoneNumber(_phoneController.text);

    try {
      final checkoutRequestId = await ref.read(paymentProvider.notifier).initiateActivation(
        phoneNumber: phone,
      );

      if (!mounted) return;

      if (checkoutRequestId != null) {
        // Navigate to payment status screen
        context.push('/payment-status/$checkoutRequestId?isActivation=true');
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

  @override
  Widget build(BuildContext context) {
    final theme = _getSafeTheme(context);
    final paymentState = ref.watch(paymentProvider);

    return WillPopScope(
      onWillPop: () async {
        // Prevent going back during payment processing
        if (_isProcessing || paymentState.isLoading) {
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: AppBar(
          title: const Text('Activate Account'),
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: !_isProcessing && !paymentState.isLoading,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Welcome icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.primaryColor?.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 60,
                    color: theme.primaryColor,
                  ),
                ),

                const SizedBox(height: 24),

                // Welcome message
                Text(
                  'Welcome to WemaChat!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'To complete your registration, please pay a one-time activation fee of KES 99.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textSecondaryColor,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                // Fee info card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor ?? Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Activation Fee',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.textSecondaryColor,
                            ),
                          ),
                          Text(
                            'KES $_activationFee',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: theme.dividerColor),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: theme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This is a one-time payment. You will receive an M-Pesa prompt on your phone.',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.textSecondaryColor,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

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
                        : const Text(
                            'Pay KES 99 & Activate',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Benefits
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What you get:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildBenefit('Unlimited access to all features'),
                      _buildBenefit('Send and receive virtual gifts'),
                      _buildBenefit('Premium video content'),
                      _buildBenefit('Live streaming capabilities'),
                      _buildBenefit('No ads or interruptions'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.green[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
