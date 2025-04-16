import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:textgb/providers/authentication_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

  // Format phone number by removing leading zero if present
  String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.startsWith('0')) {
      return '+${selectedCountry.phoneCode}${phoneNumber.substring(1)}';
    }
    return '+${selectedCountry.phoneCode}$phoneNumber';
  }

  // Simple validation - either 10 digits with leading 0 or 9 digits without it
  bool isPhoneNumberValid() {
    final phoneNumber = _phoneNumberController.text;
    return (phoneNumber.startsWith('0') && phoneNumber.length == 10) || 
           (!phoneNumber.startsWith('0') && phoneNumber.length == 9);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthenticationProvider>();
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: size.height * 0.15),
                
                // App Title
                Text(
                  'TexGB',
                  style: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                    letterSpacing: -1,
                  ),
                ),
                
                SizedBox(height: size.height * 0.02),
                
                Text(
                  'Connect with a simple tap',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                  ),
                ),
                
                SizedBox(height: size.height * 0.08),
                
                // Phone label
                Text(
                  'Enter your phone number',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Phone input field
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      // Country code selector
                      InkWell(
                        onTap: () {
                          showCountryPicker(
                            context: context,
                            showPhoneCode: true,
                            onSelect: (Country country) {
                              setState(() {
                                selectedCountry = country;
                                _phoneNumberController.clear();
                              });
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.grey.shade200, width: 1),
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
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Phone number field
                      Expanded(
                        child: TextFormField(
                          controller: _phoneNumberController,
                          maxLength: 10,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
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
                              color: Colors.grey.shade400,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Phone formatting hint
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Text(
                    'Enter 10 digits (0XXXXXXXXX) or 9 digits (XXXXXXXXX)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                
                SizedBox(height: size.height * 0.08),
                
                // Continue button
                AnimatedOpacity(
                  opacity: isPhoneNumberValid() ? 1.0 : 0.6,
                  duration: const Duration(milliseconds: 200),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isPhoneNumberValid()
                          ? () {
                              final formattedNumber = formatPhoneNumber(
                                _phoneNumberController.text,
                              );
                              
                              authProvider.signInWithPhoneNumber(
                                phoneNumber: formattedNumber,
                                context: context,
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
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
                
                SizedBox(height: size.height * 0.04),
                
                // Terms text
                Center(
                  child: Text(
                    'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.5,
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