import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/payment/providers/payment_providers.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';

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
  final List<double> _quickAmounts = [75, 150, 300, 450, 750, 1500];
  double? _selectedAmount;
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
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
        // Check if this is a first-time activation payment
        final currentUser = ref.read(currentUserProvider);
        final isActivation = currentUser?.hasPaid == false;

        // Navigate to payment status screen with isActivation parameter
        context.push('/payment-status/$checkoutRequestId?isActivation=$isActivation');
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
    final paymentState = ref.watch(paymentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1F2937),
        title: const Text(
          'Top Up Wallet',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section with gradient (matches profile setup)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Top Up Your Wallet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Add coins to unlock premium content, send gifts, and boost your videos',
                      style: TextStyle(
                        color: Color(0xFFF3F4F6),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.payments_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Conversion Rate: ',
                            style: TextStyle(
                              color: Color(0xFFF3F4F6),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '1.5 KES = 1 Coin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // What you can do with coins (matches profile setup blue info box)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF93C5FD).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.stars_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'What You Can Do With Coins',
                            style: TextStyle(
                              color: Color(0xFF1E40AF),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Send virtual gifts to your favorite creators\n'
                      '• Unlock exclusive premium videos and content\n'
                      '• Boost your videos to reach more viewers\n'
                      '• Support the WemaChat creator community\n'
                      '• Access special features and perks',
                      style: TextStyle(
                        color: Color(0xFF1E40AF),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick amounts
              const Text(
                'Quick Select',
                style: TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAmounts.map((amount) {
                  final isSelected = _selectedAmount == amount;
                  final coins = (amount / 1.5).round(); // Calculate coins: 1 coin = 1.5 KES
                  return InkWell(
                    onTap: () => _selectQuickAmount(amount),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'KES ${amount.toInt()}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$coins coins',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white.withOpacity(0.9) : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Custom amount
              const Text(
                'Or Enter Custom Amount',
                style: TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                enabled: _selectedAmount == null,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: TextStyle(
                  color: _selectedAmount == null ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount (KES)',
                  hintText: 'Enter amount (min KES 10)',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
                  prefixText: 'KES ',
                  filled: true,
                  fillColor: _selectedAmount != null ? const Color(0xFFF3F4F6) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
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
              const Text(
                'M-Pesa Phone Number',
                style: TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '0712345678 or 254712345678',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF6366F1)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                ),
                validator: _validatePhone,
              ),

              const SizedBox(height: 40),

              // Pay button (matches profile setup button)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isProcessing || paymentState.isLoading)
                      ? null
                      : _initiatePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_isProcessing || paymentState.isLoading)
                        ? const Color(0xFF6366F1).withOpacity(0.5)
                        : const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing || paymentState.isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Processing Payment...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Pay KES ${_selectedAmount?.toInt() ?? (_amountController.text.isEmpty ? '---' : _amountController.text)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Security notice (matches profile setup style)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.security,
                      color: Color(0xFF92400E),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Secure M-Pesa Payment',
                            style: TextStyle(
                              color: Color(0xFF92400E),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your payment is processed securely through Safaricom M-Pesa. You will receive a prompt on your phone.',
                            style: TextStyle(
                              color: Color(0xFF92400E),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Cancel button
              Center(
                child: TextButton(
                  onPressed: _isProcessing ? null : () => context.pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
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
