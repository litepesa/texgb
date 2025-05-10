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
  final controller = TextEditingController();
  final focusNode = FocusNode();
  String? otpCode;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _resendEnabled = false;
  int _resendTimer = 60;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
            _startResendTimer();
          } else {
            _resendEnabled = true;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final verificationId = args[Constants.verificationId] as String;
    final phoneNumber = args[Constants.phoneNumber] as String;

    final authState = ref.watch(authenticationProvider);

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
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

    final errorPinTheme = defaultPinTheme.copyWith(
      height: 68,
      width: 64,
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: Colors.red, width: 2.0),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF09BB07).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline, size: 50, color: Color(0xFF09BB07)),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Verification',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Enter the 6-digit code sent to your phone number',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
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
                  ),
                  const SizedBox(height: 36),

                  Pinput(
                    length: 6,
                    controller: controller,
                    focusNode: focusNode,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    submittedPinTheme: submittedPinTheme,
                    errorPinTheme: errorPinTheme,
                    pinAnimationType: PinAnimationType.scale,
                    closeKeyboardWhenCompleted: true,
                    onCompleted: (pin) {
                      setState(() {
                        otpCode = pin;
                      });
                      verifyOTPCode(verificationId: verificationId, otpCode: pin);
                    },
                  ),
                  const SizedBox(height: 36),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: authState.when(
                      data: (data) => data.isLoading
                          ? const CircularProgressIndicator(color: Color(0xFF09BB07))
                          : data.isSuccessful
                              ? Container(
                                  key: const ValueKey('success'),
                                  height: 60,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, color: Colors.green, size: 30),
                                )
                              : const SizedBox.shrink(),
                      loading: () => const CircularProgressIndicator(color: Color(0xFF09BB07)),
                      error: (error, stack) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive the code?",
                        style: GoogleFonts.poppins(fontSize: 15, color: Colors.black54),
                      ),
                      const SizedBox(width: 8),
                      _resendEnabled
                          ? TextButton(
                              onPressed: () {
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
                              },
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
                              'Resend in ${_resendTimer}s',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                    ],
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
        bool userExists = await authNotifier.checkUserExists();

        if (userExists) {
          await authNotifier.getUserDataFromFireStore();
          await authNotifier.saveUserDataToSharedPreferences();
          navigate(userExits: true);
        } else {
          navigate(userExits: false);
        }
      },
    );
  }

  void navigate({required bool userExits}) {
    if (userExits) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        Constants.homeScreen,
        (route) => false,
      );
    } else {
      Navigator.pushReplacementNamed(
        context,
        Constants.userInformationScreen,
      );
    }
  }
}