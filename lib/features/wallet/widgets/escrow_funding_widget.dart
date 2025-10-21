// lib/features/wallet/widgets/escrow_funding_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';

class EscrowFundingWidget extends ConsumerStatefulWidget {
  const EscrowFundingWidget({super.key});

  @override
  ConsumerState<EscrowFundingWidget> createState() => _EscrowFundingWidgetState();

  /// Show the escrow funding widget as a modal bottom sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const EscrowFundingWidget(),
    );
  }
}

class _EscrowFundingWidgetState extends ConsumerState<EscrowFundingWidget> {
  final TextEditingController _amountController = TextEditingController();
  double _selectedAmount = 100.0;

  // Escrow-focused Professional Colors
  static const _escrowPrimary = Color(0xFF1E88E5);
  static const _escrowSecondary = Color(0xFF42A5F5);
  static const _escrowLight = Color(0xFF90CAF9);
  static const _escrowSuccess = Color(0xFF4CAF50);
  static const _escrowWarning = Color(0xFFFF9800);
  static const _escrowCardBg = Color(0xFF263238);
  static const _escrowCardBgLight = Color(0xFF37474F);

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
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final currentUser = ref.watch(currentUserProvider);
    
    return Container(
      height: screenHeight * 0.9,
      decoration: const BoxDecoration(
        color: _escrowCardBg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 350;
          final horizontalPadding = isSmallScreen ? 16.0 : 24.0;
          
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _escrowLight.withOpacity(0.3),
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
                        padding: EdgeInsets.all(horizontalPadding),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_escrowSecondary, _escrowPrimary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.security,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Add Funds to Escrow',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _escrowPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Secure funds for marketplace transactions\nMinimum deposit: KES 100',
                              style: TextStyle(
                                fontSize: 16,
                                color: _escrowSecondary,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (currentUser != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _escrowCardBgLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _escrowLight.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      color: _escrowLight,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Account: ${currentUser.phoneNumber}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _escrowLight,
                                        ),
                                        overflow: TextOverflow.ellipsis,
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
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enter Amount',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _escrowPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Amount Input Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: _escrowCardBgLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _escrowLight.withOpacity(0.3),
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
                                          color: _escrowSecondary,
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
                                            color: _escrowPrimary,
                                          ),
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            hintText: '100',
                                            hintStyle: TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w700,
                                              color: _escrowLight,
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
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _escrowSuccess.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _escrowSuccess.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.security,
                                          color: _escrowSuccess,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'KES ${_selectedAmount.toStringAsFixed(0)} will be secured in escrow',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: _escrowSuccess,
                                            ),
                                            textAlign: TextAlign.center,
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
                                color: _escrowSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Responsive Quick Select Buttons
                            LayoutBuilder(
                              builder: (context, buttonConstraints) {
                                final availableWidth = buttonConstraints.maxWidth;
                                final buttonSpacing = 8.0;
                                final buttonsPerRow = isSmallScreen ? 2 : 3;
                                final buttonWidth = (availableWidth - (buttonSpacing * (buttonsPerRow - 1))) / buttonsPerRow;
                                
                                return Wrap(
                                  spacing: buttonSpacing,
                                  runSpacing: buttonSpacing,
                                  children: [100, 500, 1000, 2000, 5000, 10000].map((amount) {
                                    final isSelected = _selectedAmount == amount.toDouble();
                                    return SizedBox(
                                      width: buttonWidth,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedAmount = amount.toDouble();
                                            _amountController.text = amount.toString();
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isSelected ? _escrowSecondary : _escrowCardBgLight,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isSelected ? _escrowSecondary : _escrowLight.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            'KES $amount',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 11 : 12,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected ? Colors.white : _escrowLight,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Add Funds Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _selectedAmount >= 100 
                                  ? () => _showPaymentInstructions(context) 
                                  : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _escrowPrimary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  disabledBackgroundColor: _escrowLight.withOpacity(0.3),
                                ),
                                child: Text(
                                  _selectedAmount >= 100 
                                    ? 'Add KES ${_selectedAmount.toStringAsFixed(0)} to Escrow'
                                    : 'Minimum amount is KES 100',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),

                            // How escrow works section
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _escrowWarning.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _escrowWarning.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: _escrowWarning,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'How Escrow Works',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _escrowWarning,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    '1. Add funds to your escrow wallet (minimum KES 100)\n'
                                    '2. Pay via M-Pesa using the provided details\n'
                                    '3. Funds are securely held until transaction completion\n'
                                    '4. Use escrow for safe marketplace purchases and sales',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _escrowWarning,
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
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _escrowCardBgLight,
                        foregroundColor: _escrowLight,
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
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPaymentInstructions(BuildContext context) {
    final currentUser = ref.read(currentUserProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _escrowCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: screenWidth * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_escrowSecondary, _escrowPrimary],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: const Icon(
                        Icons.security,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add KES ${_selectedAmount.toStringAsFixed(0)} to Escrow',
                        style: const TextStyle(
                          fontSize: 18,
                          color: _escrowPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Funding summary
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _escrowSuccess.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _escrowSuccess.withOpacity(0.3),
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
                                    color: _escrowSuccess,
                                  ),
                                ),
                                Text(
                                  'KES ${_selectedAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _escrowSuccess,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Escrow Balance:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: _escrowSuccess,
                                  ),
                                ),
                                Text(
                                  '+KES ${_selectedAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _escrowSuccess,
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
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _escrowPrimary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _escrowPrimary.withOpacity(0.3),
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
                                  color: _escrowPrimary,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'M-Pesa Payment Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _escrowPrimary,
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
                          color: _escrowPrimary,
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
                      _buildStep('8', 'Funds will be added to escrow within 10 minutes'),
                      
                      const SizedBox(height: 16),
                      
                      // Important note
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _escrowWarning.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _escrowWarning.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.security,
                              color: _escrowWarning,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your funds will be securely held in escrow and can be used for safe marketplace transactions, purchases, and payments.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _escrowWarning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              
              // Action button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        color: _escrowSuccess,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
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
              color: _escrowLight,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: _escrowPrimary,
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
              color: _escrowLight,
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _copyToClipboard(context, value, label.replaceAll(':', '')),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _escrowCardBgLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _escrowLight.withOpacity(0.3),
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
                      color: _escrowPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.copy,
                    size: 14,
                    color: _escrowLight,
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
              color: _escrowSecondary,
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
                color: _escrowLight,
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
        backgroundColor: _escrowSuccess,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}