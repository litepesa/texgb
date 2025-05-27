// lib/features/wallet/screens/wallet_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wallet Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      modernTheme.primaryColor!,
                      modernTheme.primaryColor!.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: modernTheme.primaryColor!.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Wallet Balance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          CupertinoIcons.eye,
                          color: Colors.white.withOpacity(0.8),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'KES 12,450.00',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.arrow_up_circle,
                          color: Colors.green[300],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+5.2% from last month',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: CupertinoIcons.plus_circle,
                      title: 'Top Up',
                      subtitle: 'Add money',
                      color: Colors.green,
                      modernTheme: modernTheme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: CupertinoIcons.paperplane,
                      title: 'Send',
                      subtitle: 'Transfer money',
                      color: Colors.blue,
                      modernTheme: modernTheme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: CupertinoIcons.qrcode,
                      title: 'Receive',
                      subtitle: 'Get paid',
                      color: Colors.orange,
                      modernTheme: modernTheme,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Recent Transactions
              Text(
                'Recent Transactions',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Transaction List
              ...List.generate(5, (index) {
                final transactions = [
                  {
                    'title': 'Payment from John Doe',
                    'subtitle': 'Money received',
                    'amount': '+KES 2,500',
                    'isPositive': true,
                    'icon': CupertinoIcons.arrow_down_circle,
                  },
                  {
                    'title': 'Grocery Shopping',
                    'subtitle': 'Supermarket payment',
                    'amount': '-KES 850',
                    'isPositive': false,
                    'icon': CupertinoIcons.cart,
                  },
                  {
                    'title': 'Salary Deposit',
                    'subtitle': 'Monthly salary',
                    'amount': '+KES 65,000',
                    'isPositive': true,
                    'icon': CupertinoIcons.building_2_fill,
                  },
                  {
                    'title': 'Uber Trip',
                    'subtitle': 'Transportation',
                    'amount': '-KES 320',
                    'isPositive': false,
                    'icon': CupertinoIcons.car,
                  },
                  {
                    'title': 'Coffee Purchase',
                    'subtitle': 'Java House',
                    'amount': '-KES 450',
                    'isPositive': false,
                    'icon': CupertinoIcons.circle,
                  },
                ];

                final transaction = transactions[index];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: modernTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: modernTheme.dividerColor!.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: transaction['isPositive'] as bool
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          transaction['icon'] as IconData,
                          color: transaction['isPositive'] as bool
                              ? Colors.green
                              : Colors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction['title'] as String,
                              style: TextStyle(
                                color: modernTheme.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              transaction['subtitle'] as String,
                              style: TextStyle(
                                color: modernTheme.textSecondaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        transaction['amount'] as String,
                        style: TextStyle(
                          color: transaction['isPositive'] as bool
                              ? Colors.green
                              : Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Additional Features
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: modernTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: modernTheme.dividerColor!.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'More Services',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildServiceItem(
                            icon: CupertinoIcons.creditcard,
                            title: 'Cards',
                            modernTheme: modernTheme,
                          ),
                        ),
                        Expanded(
                          child: _buildServiceItem(
                            icon: CupertinoIcons.chart_bar,
                            title: 'Analytics',
                            modernTheme: modernTheme,
                          ),
                        ),
                        Expanded(
                          child: _buildServiceItem(
                            icon: CupertinoIcons.settings,
                            title: 'Settings',
                            modernTheme: modernTheme,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required ModernThemeExtension modernTheme,
  }) {
    return GestureDetector(
      onTap: () {
        // Handle action tap
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title feature coming soon!')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: modernTheme.dividerColor!.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String title,
    required ModernThemeExtension modernTheme,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title feature coming soon!')),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: modernTheme.primaryColor!.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: modernTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}