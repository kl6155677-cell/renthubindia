import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/primary_button.dart';
import '../widgets/muza_snackbar.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    FocusScope.of(context).unfocus();
    final phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length < 10) {
      MuzaSnackbar.show(
        context,
        message: 'Please enter a valid phone number',
        type: MuzaSnackbarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phone', // Assuming India for RentHubIndia, can be made dynamic
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (rare on iOS, common on Android)
          // We can handle auto-signin here if needed, but usually we just let the user enter the code
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
          });
          MuzaSnackbar.show(
            context,
            message: e.message ?? 'Verification failed',
            type: MuzaSnackbarType.error,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isLoading = false;
          });
          // Navigate to OTP screen with verificationId
          context.push('/otp-verification', extra: verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Timeout
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      MuzaSnackbar.show(
        context,
        message: 'Failed to send OTP. Try again.',
        type: MuzaSnackbarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                'RentHubIndia',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF004D40),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Login or Sign Up',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter your mobile number to get an OTP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 16,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 48),
              
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Text(
                      '+91',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AuthTextField(
                      label: '', // No label above to align perfectly
                      hint: '9876543210',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),

              PrimaryButton(
                text: 'Send OTP',
                isLoading: _isLoading,
                onPressed: _sendOtp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
