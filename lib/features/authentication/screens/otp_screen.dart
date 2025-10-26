// lib/features/authentication/screens/otp_screen.dart (go_router VERSION)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/core/router/route_paths.dart';
import 'package:textgb/core/router/app_router.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OtpScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _otpCode;
  String? _verificationId;
  String? _phoneNumber;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _resendEnabled = false;
  int _resendTimer = 60;
  Timer? _resendTimerInstance;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startResendTimer();
    
    // Request focus after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get arguments from go_router
    // go_router passes arguments via state.extra
    if (_verificationId == null || _phoneNumber == null) {
      final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
      if (extra != null) {
        _verificationId = extra['verificationId'] as String?;
        _phoneNumber = extra['phoneNumber'] as String?;
      }
    }
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  void _startResendTimer() {
    _resendTimerInstance?.cancel();
    _resendTimerInstance = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        setState(() {
          _resendEnabled = true;
        });
        timer.cancel();
      }
    });
  }

  void _handleResend() {
    setState(() {
      _resendEnabled = false;
      _resendTimer = 60;
    });
    _startResendTimer();
    
    // Optimized snackbar with shorter duration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code resent successfully'),
        backgroundColor: Color(0xFF09BB07),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _verifyOTPCode({
    required String verificationId,
    required String otpCode,
  }) async {
    final authNotifier = ref.read(authenticationProvider.notifier);
    
    authNotifier.verifyOTPCode(
      verificationId: verificationId,
      otpCode: otpCode,
      context: context,
      onSuccess: () async {
        if (!mounted) return;
        
        try {
          // Check if user exists in Go backend
          final userExists = await authNotifier.checkUserExists();
          
          bool hasCompleteProfile = false;
          
          if (userExists) {
            // Get user data from backend
            final userData = await authNotifier.getUserDataFromBackend();
            
            // Check if user has complete profile
            if (userData != null && 
                userData.name.isNotEmpty && 
                userData.name.trim().isNotEmpty) {
              // User has complete profile, save to shared preferences
              await authNotifier.saveUserDataToSharedPreferences();
              hasCompleteProfile = true;
            }
          }
          
          // Navigate based on profile completeness using go_router
          _navigate(hasCompleteProfile: hasCompleteProfile);
          
        } catch (e) {
          debugPrint('Error during OTP verification: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('An error occurred. Please try again.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      },
    );
  }

  void _navigate({required bool hasCompleteProfile}) {
    if (!mounted) return;
    
    // THE MAGIC: Use go_router for navigation
    if (hasCompleteProfile) {
      // User has profile, go to home
      context.goToHome();
    } else {
      // User needs to create profile
      context.goToCreateProfile();
    }
  }

  @override
  void dispose() {
    _resendTimerInstance?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Return loading if arguments not provided
    if (_verificationId == null || _phoneNumber == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            _animationController.stop();
            _resendTimerInstance?.cancel();
            // THE MAGIC: Use go_router to go back
            context.pop();
          },
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const _VerificationIcon(),
                  const SizedBox(height: 32),
                  const _VerificationTitle(),
                  const SizedBox(height: 12),
                  const _VerificationSubtitle(),
                  const SizedBox(height: 8),
                  _PhoneNumberDisplay(phoneNumber: _phoneNumber!),
                  const SizedBox(height: 36),
                  _PinInputField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onCompleted: (pin) {
                      _otpCode = pin;
                      _verifyOTPCode(verificationId: _verificationId!, otpCode: pin);
                    },
                  ),
                  const SizedBox(height: 36),
                  
                  // Using Consumer for localized rebuilds
                  Consumer(
                    builder: (context, ref, _) {
                      final authState = ref.watch(authenticationProvider);
                      final isLoading = authState.maybeWhen(
                        data: (data) => data.isLoading,
                        orElse: () => false,
                      );
                      final isSuccessful = authState.maybeWhen(
                        data: (data) => data.isSuccessful,
                        orElse: () => false,
                      );
                      return _VerificationStatusIndicator(
                        isLoading: isLoading,
                        isSuccessful: isSuccessful,
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Using Consumer for the timer to isolate rebuilds
                  _ResendCodeWidget(
                    resendEnabled: _resendEnabled,
                    resendTimer: _resendTimer,
                    onResend: _handleResend,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Optimized widget for the verification icon
class _VerificationIcon extends StatelessWidget {
  const _VerificationIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF09BB07).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.lock_outline, size: 50, color: Color(0xFF09BB07)),
    );
  }
}

// Using cached Poppins style approach
class _VerificationTitle extends StatelessWidget {
  const _VerificationTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Verification',
      style: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }
}

class _VerificationSubtitle extends StatelessWidget {
  const _VerificationSubtitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Enter the 6-digit code sent to your phone number',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.black54,
      ),
    );
  }
}

class _PhoneNumberDisplay extends StatelessWidget {
  final String phoneNumber;

  const _PhoneNumberDisplay({required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          phoneNumber,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 16, color: Color(0xFF09BB07)),
          onPressed: () => context.pop(), // Use go_router pop
        ),
      ],
    );
  }
}

// Using static constant for default theme
class _PinInputField extends StatelessWidget {
  // Static constants to avoid recreating on each build
  static var defaultPinTheme = PinTheme(
    width: 56,
    height: 60,
    textStyle: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey, width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Colors.grey,
          blurRadius: 5,
          spreadRadius: 1,
        ),
      ],
    ),
  );

  // Pre-computed themes for better performance
  static final focusedPinTheme = defaultPinTheme.copyWith(
    height: 68,
    width: 64,
    decoration: defaultPinTheme.decoration!.copyWith(
      border: Border.all(color: const Color(0xFF09BB07), width: 2.0),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF09BB07).withOpacity(0.1),
          blurRadius: 8,
          spreadRadius: 2,
        ),
      ],
    ),
  );

  static final submittedPinTheme = defaultPinTheme.copyWith(
    decoration: defaultPinTheme.decoration!.copyWith(
      color: Colors.grey.shade100,
      border: Border.all(color: Colors.grey.shade300, width: 1.5),
    ),
  );

  static final errorPinTheme = defaultPinTheme.copyWith(
    height: 68,
    width: 64,
    decoration: defaultPinTheme.decoration!.copyWith(
      border: Border.all(color: Colors.red, width: 2.0),
    ),
  );

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onCompleted;

  const _PinInputField({
    required this.controller,
    required this.focusNode,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Pinput(
      length: 6,
      controller: controller,
      focusNode: focusNode,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      submittedPinTheme: submittedPinTheme,
      errorPinTheme: errorPinTheme,
      pinAnimationType: PinAnimationType.none, // Disable animations for performance
      closeKeyboardWhenCompleted: true,
      onCompleted: onCompleted,
    );
  }
}

// Optimized verification status indicator
class _VerificationStatusIndicator extends StatelessWidget {
  final bool isLoading;
  final bool isSuccessful;

  // Using a const constructor for better optimization
  const _VerificationStatusIndicator({
    required this.isLoading,
    required this.isSuccessful,
  });

  @override
  Widget build(BuildContext context) {
    // Cache widgets to avoid recreating them
    const loadingWidget = CircularProgressIndicator(color: Color(0xFF09BB07));
    
    final successWidget = Container(
      key: const ValueKey('success'),
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, color: Colors.green, size: 30),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isLoading
          ? loadingWidget
          : isSuccessful
              ? successWidget
              : const SizedBox.shrink(),
    );
  }
}

// Optimized resend code widget
class _ResendCodeWidget extends StatelessWidget {
  final bool resendEnabled;
  final int resendTimer;
  final VoidCallback onResend;

  // Using a const constructor for better optimization
  const _ResendCodeWidget({
    required this.resendEnabled,
    required this.resendTimer,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    // Cache text styles 
    final regularStyle = GoogleFonts.poppins(
      fontSize: 15, 
      color: Colors.black54
    );
    
    final resendStyle = GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF09BB07),
    );
    
    final timerStyle = GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: Colors.grey,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Didn't receive the code?", style: regularStyle),
        const SizedBox(width: 8),
        if (resendEnabled)
          TextButton(
            onPressed: onResend,
            // Optimized button properties
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size.zero,
            ),
            child: Text('Resend Code', style: resendStyle),
          )
        else
          Text('Resend in ${resendTimer}s', style: timerStyle),
      ],
    );
  }
}