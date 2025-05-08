import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';
import 'package:textgb/shared/widgets/custom_button.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    checkAuthentication();
    super.initState();
  }

  void checkAuthentication() async {
    bool isAuthenticated = await ref.read(authenticationProvider.notifier).checkAuthenticationState();

    if (isAuthenticated) {
      Navigator.pushReplacementNamed(context, Constants.homeScreen);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void navigateToLogin() {
    Navigator.pushReplacementNamed(context, Constants.loginScreen);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    // Refined color palette
    const wechatGreen = Color(0xFF07C160);
    const darkBackground = Color(0xFF0F0F0F);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: darkBackground,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(wechatGreen),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            
            // Minimalist app title with elegant styling
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle green accent line
                  Positioned(
                    bottom: 0,
                    child: Container(
                      height: 3,
                      width: 40,
                      decoration: BoxDecoration(
                        color: wechatGreen,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Clean, minimalist logo text
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Wei',
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            letterSpacing: -1.0,
                          ),
                        ),
                        TextSpan(
                          text: 'Bao',
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.w700,
                            color: wechatGreen,
                            letterSpacing: -1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(flex: 1),
            
            // Featured Lottie Animation - Center of attention
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: size.height * 0.4,
                width: size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Lottie.asset(
                  AssetsManager.chatBubble,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            const Spacer(flex: 2),
            
            // Clean, minimal button with slight refinements
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () => navigateToLogin(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: wechatGreen,
                  foregroundColor: Colors.white,
                  minimumSize: Size(size.width, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Minimal legal text
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'By continuing, you accept our Terms & Privacy Policy',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}