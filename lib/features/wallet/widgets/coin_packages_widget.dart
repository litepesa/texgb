// lib/features/wallet/widgets/coin_packages_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';

class CoinPackagesWidget extends ConsumerStatefulWidget {
  const CoinPackagesWidget({super.key});

  @override
  ConsumerState<CoinPackagesWidget> createState() => _CoinPackagesWidgetState();

  /// Show the KEST purchase widget as a modal bottom sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const CoinPackagesWidget(),
    );
  }
}

class _CoinPackagesWidgetState extends ConsumerState<CoinPackagesWidget> {
  final TextEditingController _amountController = TextEditingController();
  double _selectedAmount = 100.0;

  // Custom Blue Fintech Colors
  static const _fintechPrimary = Color(0xFF64B5F6);
  static const _fintechSecondary = Color(0xFF42A5F5);
  static const _fintechLight = Color(0xFF90CAF9);
  static const _fintechSuccess = Color(0xFF81C784);
  static const _fintechWarning = Color(0xFFFFB74D);
  static const _fintechCardBg = Color(0xFF263238);
  static const _fintechCardBgLight = Color(0xFF37474F);

  @override
  void initState() {
    super.initState();
    _amountController.text = '100';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final currentUser = ref.watch(currentUserProvider);
    
    return Container(
      height: screenHeight * 0.9,
      decoration: const BoxDecoration(
        color: _fintechCardBg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _fintechLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomPadding + 20),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_fintechSecondary, _fintechPrimary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Buy KEST',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _fintechPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Load any amount from KES 100 minimum\n1 KES = 1 KEST',
                          style: TextStyle(
                            fontSize: 16,
                            color: _fintechSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (currentUser != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _fintechCardBgLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _fintechLight.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.person,
                                  color: _fintechLight,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Account: ${currentUser.phoneNumber}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _fintechLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Amount Input Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enter Amount',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _fintechPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Amount Input Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _fintechCardBgLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _fintechLight.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Amount Input
                              Row(
                                children: [
                                  const Text(
                                    'KES',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: _fintechSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _amountController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color: _fintechPrimary,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '100',
                                        hintStyle: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w700,
                                          color: _fintechLight,
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedAmount = double.tryParse(value) ?? 100.0;
                                        });
                                      },
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Conversion Display
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _fintechSuccess.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _fintechSuccess.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.swap_horiz,
                                      color: _fintechSuccess,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'You will receive ${_selectedAmount.toStringAsFixed(0)} KEST',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _fintechSuccess,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Quick Amount Buttons
                        const Text(
                          'Quick Select',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _fintechSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [100, 500, 1000, 2000, 5000, 10000].map((amount) {
                            final isSelected = _selectedAmount == amount.toDouble();
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedAmount = amount.toDouble();
                                  _amountController.text = amount.toString();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? _fintechSecondary : _fintechCardBgLight,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? _fintechSecondary : _fintechLight.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'KES $amount',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : _fintechLight,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Buy Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _selectedAmount >= 100 
                              ? () => _showPurchaseInstructions(context) 
                              : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _fintechPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: _fintechLight.withOpacity(0.3),
                            ),
                            child: Text(
                              _selectedAmount >= 100 
                                ? 'Buy ${_selectedAmount.toStringAsFixed(0)} KEST'
                                : 'Minimum amount is KES 100',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),

                        // How it works section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _fintechWarning.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _fintechWarning.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: _fintechWarning,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'How It Works',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _fintechWarning,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '1. Enter the amount you want to load (minimum KES 100)\n'
                                '2. Pay via M-Pesa using the provided details\n'
                                '3. KEST will be added to your wallet within 10 minutes\n'
                                '4. Use KEST for transactions, payments, and transfers',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _fintechWarning,
                                  height: 1.5,
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
            ),
          ),
          
          // Close button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _fintechCardBgLight,
                  foregroundColor: _fintechLight,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseInstructions(BuildContext context) {
    final currentUser = ref.read(currentUserProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _fintechCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_fintechSecondary, _fintechPrimary],
                ),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Buy ${_selectedAmount.toStringAsFixed(0)} KEST',
              style: const TextStyle(
                fontSize: 18,
                color: _fintechPrimary,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Purchase summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _fintechSuccess.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _fintechSuccess.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Amount:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _fintechSuccess,
                          ),
                        ),
                        Text(
                          'KES ${_selectedAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _fintechSuccess,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'You receive:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _fintechSuccess,
                          ),
                        ),
                        Text(
                          '${_selectedAmount.toStringAsFixed(0)} KEST',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _fintechSuccess,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // M-Pesa payment details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _fintechPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _fintechPrimary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.phone_android,
                          color: _fintechPrimary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'M-Pesa Payment Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _fintechPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentDetail('Business Name:', 'Pomasoft Limited'),
                    const SizedBox(height: 8),
                    _buildCopyableDetail(context, 'Paybill Number:', '4146499'),
                    const SizedBox(height: 4),
                    _buildPaymentDetail('Account Number:', currentUser?.phoneNumber ?? 'Your registered phone number'),
                    const SizedBox(height: 8),
                    _buildPaymentDetail('Amount:', 'KES ${_selectedAmount.toStringAsFixed(0)}'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Payment steps
              const Text(
                'Payment Steps:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _fintechPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildStep('1', 'Go to M-Pesa menu on your phone'),
              _buildStep('2', 'Select "Pay Bill"'),
              _buildStep('3', 'Enter business number: 4146499'),
              _buildStep('4', 'Enter your phone number: ${currentUser?.phoneNumber ?? "[Your Phone Number]"}'),
              _buildStep('5', 'Enter amount: KES ${_selectedAmount.toStringAsFixed(0)}'),
              _buildStep('6', 'Enter your M-Pesa PIN and confirm'),
              _buildStep('7', 'Save the confirmation SMS'),
              _buildStep('8', 'KEST will be added within 10 minutes'),
              
              const SizedBox(height: 16),
              
              // Important note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _fintechWarning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _fintechWarning.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: _fintechWarning,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'After payment, you can use your KEST tokens for various transactions, P2P transfers, and payments within the platform!',
                        style: TextStyle(
                          fontSize: 13,
                          color: _fintechWarning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(
                color: _fintechSuccess,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetail(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: _fintechLight,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: _fintechPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableDetail(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: _fintechLight,
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _copyToClipboard(context, value, label.replaceAll(':', '')),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _fintechCardBgLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _fintechLight.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _fintechPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.copy,
                    size: 14,
                    color: _fintechLight,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: _fintechSecondary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(
                fontSize: 14,
                color: _fintechLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: _fintechSuccess,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}