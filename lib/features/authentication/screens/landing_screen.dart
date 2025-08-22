import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';

// State provider for loading state
final landingLoadingProvider = StateProvider.autoDispose<bool>((ref) => true);

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  // Pre-load Lottie animation
  late Future<LottieComposition> _lottieComposition;

  @override
  void initState() {
    _lottieComposition = AssetLottie(AssetsManager.chatBubble).load();
    // Fire and forget authentication check
    _checkAuthentication();
    super.initState();
  }

  Future<void> _checkAuthentication() async {
    try {
      final authNotifier = ref.read(authenticationProvider.notifier);
      final isAuthenticated = await authNotifier.checkAuthenticationState();

      if (isAuthenticated && mounted) {
        Navigator.pushReplacementNamed(context, Constants.homeScreen);
      }
    } catch (e) {
      debugPrint('Authentication check error: $e');
    } finally {
      // Update loading state only if still mounted
      if (mounted) {
        ref.read(landingLoadingProvider.notifier).state = false;
      }
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, Constants.loginScreen);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(landingLoadingProvider);
    final size = MediaQuery.of(context).size;
    
    // Refined color palette - extracted as constants to avoid recreation
    const wechatGreen = Color(0xFF07C160);
    const darkBackground = Color(0xFF0F0F0F);
    
    if (isLoading) {
      return const _LoadingScreen();
    }
    
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            
            // Extracted to a separate widget for better tree optimization
            const _AppLogo(),
            
            const Spacer(flex: 1),
            
            // Featured Lottie Animation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: size.height * 0.4,
                width: size.width,
                child: FutureBuilder<LottieComposition>(
                  future: _lottieComposition,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Lottie(
                        composition: snapshot.data!,
                        frameRate: FrameRate.max,
                        fit: BoxFit.contain,
                      );
                    }
                    // Show a placeholder while loading
                    return const Center(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(wechatGreen),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const Spacer(flex: 2),
            
            // Get Started Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: _navigateToLogin,
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
            
            // Legal text
            const _LegalText(),
            
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}

// Extracted widgets for better tree optimization

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    const wechatGreen = Color(0xFF07C160);
    const darkBackground = Color(0xFF0F0F0F);
    
    return const Scaffold(
      backgroundColor: darkBackground,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(wechatGreen),
        ),
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    const wechatGreen = Color(0xFF07C160);
    
    return Padding(
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
        ],
      ),
    );
  }
}

class _LegalText extends StatelessWidget {
  const _LegalText();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.0),
      child: Text(
        'By continuing, you accept our Terms & Privacy Policy',
        style: TextStyle(
          color: Colors.white38,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}