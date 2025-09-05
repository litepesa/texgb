// lib/features/authentication/screens/login_screen.dart
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneNumberController = TextEditingController();
  Country selectedCountry = Country(
    phoneCode: '254',
    countryCode: 'KE',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'Kenya',
    example: 'Kenya',
    displayName: 'Kenya',
    displayNameNoCountryCode: 'KE',
    e164Key: '',
  );

  final Color wechatGreen = const Color(0xFF07C160);
  final Color wechatBlue = const Color(0xFF1A73E8); // Accent color
  final Color backgroundLight = const Color(0xFFF7F7F7);
  final Color textDark = const Color(0xFF181818);
  final Color textMedium = const Color(0xFF888888);
  final Color textLight = const Color(0xFFB2B2B2);

  String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.startsWith('0')) {
      return '+${selectedCountry.phoneCode}${phoneNumber.substring(1)}';
    }
    return '+${selectedCountry.phoneCode}$phoneNumber';
  }

  bool isPhoneNumberValid() {
    final phoneNumber = _phoneNumberController.text;
    return (phoneNumber.startsWith('0') && phoneNumber.length == 10) ||
        (!phoneNumber.startsWith('0') && phoneNumber.length == 9);
  }

  @override
  Widget build(BuildContext context) {
    // Watch the authentication state using convenience providers
    final isLoading = ref.watch(isAuthLoadingProvider);
    final authNotifier = ref.read(authenticationProvider.notifier);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: size.height * 0.15),

                // App logo with brand colors
                Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Wei',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        TextSpan(
                          text: 'Bao',
                          style: TextStyle(
                            fontSize: 45,
                            fontWeight: FontWeight.w700,
                            color: wechatGreen,
                            letterSpacing: -1.0,
                          ),
                        ),
                        TextSpan(
                          text: "微宝",
                          style: TextStyle(
                            color: const Color(0xFFFE2C55),
                            fontWeight: FontWeight.w700,
                            fontSize: 40,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.12),

                Text(
                  'Enter your phone number',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 12),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: isPhoneNumberValid()
                            ? wechatGreen.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: isPhoneNumberValid()
                          ? wechatGreen.withOpacity(0.3)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          showCountryPicker(
                            context: context,
                            showPhoneCode: true,
                            countryListTheme: CountryListThemeData(
                              backgroundColor: Colors.white,
                              textStyle: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              inputDecoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF2F2F2),
                                hintText: 'Search country',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                prefixIcon:
                                    const Icon(Icons.search, color: Colors.grey),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0, horizontal: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                              bottomSheetHeight:
                                  MediaQuery.of(context).size.height * 0.75,
                            ),
                            onSelect: (Country country) {
                              setState(() {
                                selectedCountry = country;
                                _phoneNumberController.clear();
                              });
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                  color: Colors.grey.shade100, width: 1),
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(14),
                              bottomLeft: Radius.circular(14),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                selectedCountry.flagEmoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '+${selectedCountry.phoneCode}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: textMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneNumberController,
                          maxLength: 10,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textDark,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '0XXXXXXXXX',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 16,
                              color: textLight,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 18),
                            suffixIcon: isPhoneNumberValid()
                                ? Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: wechatGreen,
                                      size: 20,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 10.0, left: 4.0),
                  child: Text(
                    'Format: 0XXXXXXXXX or XXXXXXXXX',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: textLight,
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.08),

                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: isPhoneNumberValid()
                          ? LinearGradient(
                              colors: [wechatGreen, wechatGreen.withGreen(200)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color:
                          isPhoneNumberValid() ? null : wechatGreen.withOpacity(0.6),
                    ),
                    child: ElevatedButton(
                      onPressed: isPhoneNumberValid()
                          ? () {
                              final formattedNumber =
                                  formatPhoneNumber(_phoneNumberController.text);
                              authNotifier.signInWithPhoneNumber(
                                phoneNumber: formattedNumber,
                                context: context,
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Continue',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.06),

                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: textLight,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'By continuing, you agree to our '),
                        TextSpan(
                          text: 'Terms',
                          style: TextStyle(
                            color: wechatGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: wechatGreen,
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }
}