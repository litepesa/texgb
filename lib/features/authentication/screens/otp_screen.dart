import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OtpScreen> with SingleTickerProviderStateMixin {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  String? otpCode;

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
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _resendEnabled = true;
          timer.cancel();
        }
      });
    });
  }

  void _handleResend() {
    setState(() {
      _resendEnabled = false;
      _resendTimer = 60;
    });
    _startResendTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code resent successfully'),
        backgroundColor: Color(0xFF09BB07),
      ),
    );
  }

  @override
  void dispose() {
    _resendTimerInstance?.cancel();
    controller.dispose();
    focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get route arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final verificationId = args[Constants.verificationId] as String;
    final phoneNumber = args[Constants.phoneNumber] as String;

    // Selectively watch only what we need from the auth state
    final authState = ref.watch(authenticationProvider);
    final isLoading = authState.when(
      data: (state) => state.isLoading,
      loading: () => true,
      error: (_, __) => false,
    );
    
    final isSuccessful = authState.when(
      data: (state) => state.isSuccessful,
      loading: () => false,
      error: (_, __) => false,
    );

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
            Navigator.pop(context);
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
                  _PhoneNumberDisplay(phoneNumber: phoneNumber),
                  const SizedBox(height: 36),
                  _PinInputField(
                    controller: controller,
                    focusNode: focusNode,
                    onCompleted: (pin) {
                      otpCode = pin;
                      verifyOTPCode(verificationId: verificationId, otpCode: pin);
                    },
                  ),
                  const SizedBox(height: 36),
                  _VerificationStatusIndicator(
                    isLoading: isLoading,
                    isSuccessful: isSuccessful,
                  ),
                  const SizedBox(height: 32),
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

  void verifyOTPCode({
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
          final userExists = await authNotifier.checkUserExists();
          if (userExists) {
            await authNotifier.getUserDataFromFireStore();
            await authNotifier.saveUserDataToSharedPreferences();
          }
          _navigate(userExists: userExists);
        } catch (e) {
          debugPrint('Error during OTP verification: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('An error occurred. Please try again.')),
            );
          }
        }
      },
    );
  }

  void _navigate({required bool userExists}) {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      userExists ? Constants.homeScreen : Constants.userInformationScreen,
      (route) => false,
    );
  }
}

// Extracted widget for the verification icon
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

// Extracted widget for the title
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

// Extracted widget for the subtitle
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

// Extracted widget for phone number display
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
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

// Extracted widget for pin input field
class _PinInputField extends StatelessWidget {
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
    var defaultPinTheme = PinTheme(
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

    return Pinput(
      length: 6,
      controller: controller,
      focusNode: focusNode,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: defaultPinTheme.copyWith(
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
      ),
      submittedPinTheme: defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
      ),
      errorPinTheme: defaultPinTheme.copyWith(
        height: 68,
        width: 64,
        decoration: defaultPinTheme.decoration!.copyWith(
          border: Border.all(color: Colors.red, width: 2.0),
        ),
      ),
      pinAnimationType: PinAnimationType.none,
      closeKeyboardWhenCompleted: true,
      onCompleted: onCompleted,
    );
  }
}

// Extracted widget for verification status indicator
class _VerificationStatusIndicator extends StatelessWidget {
  final bool isLoading;
  final bool isSuccessful;

  const _VerificationStatusIndicator({
    required this.isLoading,
    required this.isSuccessful,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isLoading
          ? const CircularProgressIndicator(color: Color(0xFF09BB07))
          : isSuccessful
              ? Container(
                  key: ValueKey('success'),
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.green, size: 30),
                )
              : const SizedBox.shrink(),
    );
  }
}

// Extracted widget for resend code
class _ResendCodeWidget extends StatelessWidget {
  final bool resendEnabled;
  final int resendTimer;
  final VoidCallback onResend;

  const _ResendCodeWidget({
    required this.resendEnabled,
    required this.resendTimer,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive the code?",
          style: GoogleFonts.poppins(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(width: 8),
        resendEnabled
            ? TextButton(
                onPressed: onResend,
                child: Text(
                  'Resend Code',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF09BB07),
                  ),
                ),
              )
            : Text(
                'Resend in ${resendTimer}s',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
      ],
    );
  }
}