// lib/features/contacts/screens/add_contact_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class AddContactScreen extends ConsumerStatefulWidget {
  const AddContactScreen({super.key});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  final TextEditingController _phoneController = TextEditingController();
  UserModel? _foundUser;
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _searchContact() async {
    if (_phoneController.text.isEmpty) {
      setState(() {
        _error = 'Please enter a phone number';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
      _foundUser = null;
    });

    try {
      final contactsNotifier = ref.read(contactsNotifierProvider.notifier);

      // Ensure phone number is in international format
      String phoneNumber = _phoneController.text.trim();
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+$phoneNumber'; // Add + if missing
      }

      final user = await contactsNotifier.searchUserByPhoneNumber(phoneNumber);

      setState(() {
        _isSearching = false;
        _foundUser = user;
        if (user == null) {
          _error = 'No user found with this phone number';
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _error = 'Error searching for user: ${e.toString()}';
      });
    }
  }

  Future<void> _addContact() async {
    if (_foundUser == null) return;

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
      await contactsNotifier.addContact(_foundUser!);

      if (mounted) {
        showSnackBar(context, 'Contact added successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _error = 'Error adding contact: ${e.toString()}';
      });
    }
  }

  // Navigate to contact profile
  void _viewContactProfile() {
    if (_foundUser == null) return;

    Navigator.pushNamed(
      context,
      Constants.contactProfileScreen,
      arguments: _foundUser!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;

    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced Custom App Bar matching contacts screen style
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: modernTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: modernTheme.dividerColor!.withOpacity(0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: modernTheme.primaryColor!.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Enhanced Back Button
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: modernTheme.primaryColor!.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: modernTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  // Enhanced Title
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Text(
                            'Add New Contact',
                            style: TextStyle(
                              color: modernTheme.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            height: 2,
                            width: 60,
                            decoration: BoxDecoration(
                              color: modernTheme.primaryColor!.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Placeholder for symmetry
                  const SizedBox(width: 44),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Phone number input with enhanced design
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: modernTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: modernTheme.dividerColor!.withOpacity(0.15),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: modernTheme.primaryColor!.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                            spreadRadius: -4,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter phone number with country code',
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.phone_rounded,
                              color: primaryColor,
                              size: 20,
                            ),
                          ),
                          suffixIcon: _phoneController.text.isNotEmpty
                              ? Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _phoneController.clear();
                                        _foundUser = null;
                                        _error = null;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      margin: const EdgeInsets.all(8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.clear_rounded,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          labelStyle:
                              TextStyle(color: modernTheme.textSecondaryColor),
                          hintStyle:
                              TextStyle(color: modernTheme.textTertiaryColor),
                        ),
                        style: TextStyle(color: modernTheme.textColor),
                        keyboardType: TextInputType.phone,
                        onChanged: (value) {
                          setState(() {
                            // Reset search when phone number changes
                            _foundUser = null;
                            _error = null;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Enhanced Search button
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: _isSearching ? null : _searchContact,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _isSearching
                                ? primaryColor.withOpacity(0.5)
                                : primaryColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isSearching
                                ? null
                                : [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isSearching)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.search_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Text(
                                _isSearching ? 'Searching...' : 'Search',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Error message with enhanced design
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.error_outline_rounded,
                                color: Colors.red,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Found user with enhanced design
                    if (_foundUser != null)
                      Container(
                        margin: const EdgeInsets.only(top: 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: modernTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: modernTheme.dividerColor!.withOpacity(0.15),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  modernTheme.primaryColor!.withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 6),
                              spreadRadius: -6,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                              spreadRadius: -3,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Enhanced user avatar
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.3),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _foundUser!.profileImage.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        _foundUser!.profileImage,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _buildFallbackAvatar(),
                                      ),
                                    )
                                  : _buildFallbackAvatar(),
                            ),

                            const SizedBox(height: 16),

                            // User name
                            Text(
                              _foundUser!.name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: modernTheme.textColor,
                                letterSpacing: -0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 8),

                            // Phone number badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.phone_rounded,
                                    size: 14,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _foundUser!.phoneNumber,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Bio if available
                            if (_foundUser!.bio.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: modernTheme.surfaceVariantColor!
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: modernTheme.dividerColor!
                                        .withOpacity(0.15),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _foundUser!.bio,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    color: modernTheme.textSecondaryColor,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    child: InkWell(
                                      onTap: _isSearching ? null : _addContact,
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        decoration: BoxDecoration(
                                          color: _isSearching
                                              ? primaryColor.withOpacity(0.5)
                                              : primaryColor,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          boxShadow: _isSearching
                                              ? null
                                              : [
                                                  BoxShadow(
                                                    color: primaryColor
                                                        .withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                              child: const Icon(
                                                Icons.person_add_rounded,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _isSearching
                                                  ? 'Adding...'
                                                  : 'Add Contact',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    child: InkWell(
                                      onTap: _isSearching
                                          ? null
                                          : _viewContactProfile,
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        decoration: BoxDecoration(
                                          color:
                                              modernTheme.surfaceVariantColor,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: modernTheme.dividerColor!
                                                .withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: modernTheme
                                                    .textSecondaryColor!
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                              child: Icon(
                                                Icons.info_outline_rounded,
                                                color: modernTheme
                                                    .textSecondaryColor,
                                                size: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'View Profile',
                                              style: TextStyle(
                                                color: modernTheme
                                                    .textSecondaryColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // Information about adding contacts when no user found
                    if (_foundUser == null && !_isSearching && _error == null)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: modernTheme.primaryColor!
                                      .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  CupertinoIcons.person_add,
                                  size: 60,
                                  color: modernTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Find Your Friends',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: modernTheme.textColor,
                                  letterSpacing: -0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter a phone number to find contacts',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: modernTheme.textSecondaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: modernTheme.surfaceVariantColor!
                                      .withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Include country code (e.g., +1)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: modernTheme.textTertiaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          _foundUser?.name.isNotEmpty == true
              ? _foundUser!.name[0].toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
