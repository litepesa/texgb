import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/utilities/assets_manager.dart';
import 'package:textgb/utilities/colors.dart';
import 'package:textgb/widgets/custom_button.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    checkAuthentication();
    super.initState();
  }

  void checkAuthentication() async {
    final authProvider = context.read<AuthenticationProvider>();
    bool isAuthenticated = await authProvider.checkAuthenticationState();

    if (isAuthenticated) {
      // Only navigate automatically if authenticated
      Navigator.pushReplacementNamed(context, Constants.homeScreen);
    }

    // Update loading state regardless
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
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              const Text(
                'Welcome to TexGB',
                style: TextStyle(
                  fontSize: 33,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              
              const Text(
                'Connect and chat securely',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(flex: 1),
              
              SizedBox(
                height: size.height * 0.35,
                width: size.width * 0.8,
                child: Lottie.asset(
                  AssetsManager.chatBubble,
                  fit: BoxFit.contain,
                ),
              ),
              
              const Spacer(flex: 1),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0),
                child: Text(
                  'Read our Privacy Policy. Tap "Agree and continue" to accept the Terms of Service.',
                  style: TextStyle(color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: size.width * 0.75,
                child: CustomButton(
                  text: 'AGREE AND CONTINUE',
                  onPressed: () => navigateToLogin(),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}