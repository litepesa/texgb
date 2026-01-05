// lib/features/wallet/widgets/escrow_funding_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class EscrowFundingWidget extends ConsumerStatefulWidget {
  const EscrowFundingWidget({super.key});

  @override
  ConsumerState<EscrowFundingWidget> createState() =>
      _EscrowFundingWidgetState();

  /// Show the gift coins purchase widget as a modal bottom sheet
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

  // Helper method to get safe theme with fallback
  ModernThemeExtension _getSafeTheme(BuildContext context) {
    return Theme.of(context).extension<ModernThemeExtension>() ??
        ModernThemeExtension(
          primaryColor: const Color(0xFFFE2C55),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceColor: Theme.of(context).cardColor,
          textColor:
              Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          textSecondaryColor:
              Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[600],
          dividerColor: Theme.of(context).dividerColor,
          textTertiaryColor: Colors.grey[400],
          surfaceVariantColor: Colors.grey[100],
        );
  }

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
    final theme = _getSafeTheme(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final currentUser = ref.watch(currentUserProvider);

    return Container(
      height: screenHeight * 0.9,
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(
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
                  color: theme.textTertiaryColor ?? Colors.grey[400],
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
                                gradient: LinearGradient(
                                  colors: [
                                    theme.primaryColor ??
                                        const Color(0xFFFE2C55),
                                    (theme.primaryColor ??
                                            const Color(0xFFFE2C55))
                                        .withOpacity(0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (theme.primaryColor ??
                                            const Color(0xFFFE2C55))
                                        .withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.card_giftcard,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Buy Gift Coins',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor ?? Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Send virtual gifts to your favorite creators\nMinimum purchase: KES 100',
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.textSecondaryColor ??
                                    Colors.grey[600],
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (currentUser != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (theme.surfaceVariantColor ??
                                          Colors.grey[100]!)
                                      .withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (theme.dividerColor ??
                                            Colors.grey[300]!)
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: theme.primaryColor ??
                                          const Color(0xFFFE2C55),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Account: ${currentUser.phoneNumber}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              theme.textColor ?? Colors.black,
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
                        padding:
                            EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enter Amount',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor ?? Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Amount Input Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    (theme.primaryColor ??
                                            const Color(0xFFFE2C55))
                                        .withOpacity(0.1),
                                    (theme.primaryColor ??
                                            const Color(0xFFFE2C55))
                                        .withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: (theme.primaryColor ??
                                          const Color(0xFFFE2C55))
                                      .withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Amount Input
                                  Row(
                                    children: [
                                      Text(
                                        'KES',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: theme.textSecondaryColor ??
                                              Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _amountController,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w700,
                                            color: theme.primaryColor ??
                                                const Color(0xFFFE2C55),
                                          ),
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: '100',
                                            hintStyle: TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w700,
                                              color: (theme.textTertiaryColor ??
                                                      Colors.grey[400])
                                                  ?.withOpacity(0.5),
                                            ),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedAmount =
                                                  double.tryParse(value) ??
                                                      100.0;
                                            });
                                          },
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                                RegExp(r'^\d+\.?\d{0,2}')),
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
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.monetization_on,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'You\'ll receive ${_selectedAmount.toStringAsFixed(0)} gift coins',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green,
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
                            Text(
                              'Quick Select',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.textSecondaryColor ??
                                    Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Responsive Quick Select Buttons
                            LayoutBuilder(
                              builder: (context, buttonConstraints) {
                                final availableWidth =
                                    buttonConstraints.maxWidth;
                                final buttonSpacing = 8.0;
                                final buttonsPerRow = isSmallScreen ? 2 : 3;
                                final buttonWidth = (availableWidth -
                                        (buttonSpacing * (buttonsPerRow - 1))) /
                                    buttonsPerRow;

                                return Wrap(
                                  spacing: buttonSpacing,
                                  runSpacing: buttonSpacing,
                                  children: [100, 500, 1000, 2000, 5000, 10000]
                                      .map((amount) {
                                    final isSelected =
                                        _selectedAmount == amount.toDouble();
                                    return SizedBox(
                                      width: buttonWidth,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedAmount = amount.toDouble();
                                            _amountController.text =
                                                amount.toString();
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? theme.primaryColor ??
                                                    const Color(0xFFFE2C55)
                                                : (theme.surfaceVariantColor ??
                                                        Colors.grey[100]!)
                                                    .withOpacity(0.5),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isSelected
                                                  ? theme.primaryColor ??
                                                      const Color(0xFFFE2C55)
                                                  : (theme.dividerColor ??
                                                          Colors.grey[300]!)
                                                      .withOpacity(0.3),
                                              width: 1,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color:
                                                          (theme.primaryColor ??
                                                                  const Color(
                                                                      0xFFFE2C55))
                                                              .withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Text(
                                            'KES $amount',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 11 : 12,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? Colors.white
                                                  : theme.textSecondaryColor ??
                                                      Colors.grey[600],
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

                            // Buy Coins Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _selectedAmount >= 100
                                    ? () => _showPaymentInstructions(context)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor ??
                                      const Color(0xFFFE2C55),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  disabledBackgroundColor:
                                      (theme.textTertiaryColor ??
                                              Colors.grey[400])
                                          ?.withOpacity(0.3),
                                  elevation: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.card_giftcard, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedAmount >= 100
                                          ? 'Buy ${_selectedAmount.toStringAsFixed(0)} Coins for KES ${_selectedAmount.toStringAsFixed(0)}'
                                          : 'Minimum amount is KES 100',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // How gifting works section
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'How Gift Coins Work',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '1. Buy gift coins (1 coin = KES 1)\n'
                                    '2. Pay securely via M-Pesa\n'
                                    '3. Send virtual gifts to creators you love\n'
                                    '4. Creators can convert gifts to real cash',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.textSecondaryColor ??
                                          Colors.grey[600],
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
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textSecondaryColor ?? Colors.grey[600],
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
    final theme = _getSafeTheme(context);
    final currentUser = ref.read(currentUserProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: theme.surfaceColor,
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
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor ?? const Color(0xFFFE2C55),
                            (theme.primaryColor ?? const Color(0xFFFE2C55))
                                .withOpacity(0.7),
                          ],
                        ),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                      ),
                      child: const Icon(
                        Icons.card_giftcard,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Buy ${_selectedAmount.toStringAsFixed(0)} Gift Coins',
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.textColor ?? Colors.black,
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
                      // Purchase summary
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
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
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  'KES ${_selectedAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Gift Coins:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  '+${_selectedAmount.toStringAsFixed(0)} coins',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
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
                          color: (theme.primaryColor ?? const Color(0xFFFE2C55))
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                (theme.primaryColor ?? const Color(0xFFFE2C55))
                                    .withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_android,
                                  color: theme.primaryColor ??
                                      const Color(0xFFFE2C55),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'M-Pesa Payment Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: theme.textColor ?? Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildPaymentDetail(
                                theme, 'Business Name:', 'Pomasoft Limited'),
                            const SizedBox(height: 8),
                            _buildCopyableDetail(
                                context, theme, 'Paybill Number:', '4146499'),
                            const SizedBox(height: 4),
                            _buildPaymentDetail(
                                theme,
                                'Account Number:',
                                currentUser?.phoneNumber ??
                                    'Your registered phone number'),
                            const SizedBox(height: 8),
                            _buildPaymentDetail(theme, 'Amount:',
                                'KES ${_selectedAmount.toStringAsFixed(0)}'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Payment steps
                      Text(
                        'Payment Steps:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.textColor ?? Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStep(theme, '1', 'Go to M-Pesa menu on your phone'),
                      _buildStep(theme, '2', 'Select "Pay Bill"'),
                      _buildStep(theme, '3', 'Enter business number: 4146499'),
                      _buildStep(theme, '4',
                          'Enter your phone number: ${currentUser?.phoneNumber ?? "[Your Phone Number]"}'),
                      _buildStep(theme, '5',
                          'Enter amount: KES ${_selectedAmount.toStringAsFixed(0)}'),
                      _buildStep(
                          theme, '6', 'Enter your M-Pesa PIN and confirm'),
                      _buildStep(theme, '7', 'Save the confirmation SMS'),
                      _buildStep(
                          theme, '8', 'Coins will be added within 10 minutes'),

                      const SizedBox(height: 16),

                      // Important note
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.card_giftcard,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Use your coins to send virtual gifts to creators and show your support. Creators can convert gifts to real cash!',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.textSecondaryColor ??
                                      Colors.grey[600],
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
                        color: Colors.green,
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

  Widget _buildPaymentDetail(
      ModernThemeExtension theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: theme.textSecondaryColor ?? Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textColor ?? Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableDetail(BuildContext context, ModernThemeExtension theme,
      String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: theme.textSecondaryColor ?? Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () =>
                _copyToClipboard(context, value, label.replaceAll(':', '')),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (theme.surfaceVariantColor ?? Colors.grey[100]!)
                    .withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (theme.dividerColor ?? Colors.grey[300]!)
                      .withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryColor ?? const Color(0xFFFE2C55),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.copy,
                    size: 14,
                    color: theme.textSecondaryColor ?? Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(
      ModernThemeExtension theme, String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: theme.primaryColor ?? const Color(0xFFFE2C55),
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
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondaryColor ?? Colors.grey[600],
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
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
