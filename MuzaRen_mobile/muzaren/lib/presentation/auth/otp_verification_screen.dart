import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/primary_button.dart';
import '../widgets/muza_snackbar.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_event.dart';
import '../../../blocs/auth/auth_state.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  const OtpVerificationScreen({super.key, required this.verificationId});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() async {
    FocusScope.of(context).unfocus();
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length < 6) {
      MuzaSnackbar.show(
        context,
        message: 'Please enter a valid 6-digit OTP',
        type: MuzaSnackbarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      String? idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        // Send idToken to our backend to login/signup
        context.read<AuthBloc>().add(FirebaseLoginRequested(idToken));
      } else {
        throw Exception("Failed to get ID token");
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      MuzaSnackbar.show(
        context,
        message: e.message ?? 'Invalid OTP',
        type: MuzaSnackbarType.error,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      MuzaSnackbar.show(
        context,
        message: 'An error occurred during verification',
        type: MuzaSnackbarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthError) {
          setState(() {
            _isLoading = false;
          });
          MuzaSnackbar.show(
            context,
            message: state.message,
            type: MuzaSnackbarType.error,
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Verify OTP',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enter the 6-digit code sent to your mobile number',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 16,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 48),
                
                AuthTextField(
                  label: 'OTP Code',
                  hint: '123456',
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                
                const SizedBox(height: 40),

                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return PrimaryButton(
                      text: 'Verify & Login',
                      isLoading: _isLoading || state is AuthLoading,
                      onPressed: _verifyOtp,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
