import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/primary_button.dart';
import 'widgets/segmented_auth_toggle.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_event.dart';
import '../../../blocs/auth/auth_state.dart';
import '../widgets/muza_snackbar.dart';

class AuthScreen extends StatefulWidget {
  final bool initialIsLogin;
  const AuthScreen({super.key, this.initialIsLogin = true});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool isLogin;
  bool obscurePassword = true;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // Only for register

  @override
  void initState() {
    super.initState();
    isLogin = widget.initialIsLogin;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    // Unfocus keyboard
    FocusScope.of(context).unfocus();
    
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
       MuzaSnackbar.show(
        context,
        message: 'Please fill in all fields',
        type: MuzaSnackbarType.error,
      );
      return;
    }

    if (isLogin) {
      context.read<AuthBloc>().add(LoginRequested(email, password));
    } else {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        MuzaSnackbar.show(
          context,
          message: 'Please enter your name',
          type: MuzaSnackbarType.error,
        );
        return;
      }
      context.read<AuthBloc>().add(RegisterRequested(
            name: name,
            email: email,
            password: password,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthRegistrationSuccess) {
          MuzaSnackbar.show(
            context,
            message: 'Registration successful! Please log in.',
            type: MuzaSnackbarType.success,
          );
          setState(() {
            isLogin = true;
            _passwordController.clear();
            _nameController.clear();
          });
        } else if (state is AuthError) {
          // Only show if it's not a general server error (which ApiService already shows)
          if (!state.message.contains('Server error') && !state.message.contains('Something went wrong')) {
             MuzaSnackbar.show(
              context,
              message: state.message,
              type: MuzaSnackbarType.error,
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'RentHubIndia',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Color(0xFF004D40), // AppColors.primary
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  isLogin ? 'Welcome back' : 'Create Account',
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isLogin
                      ? 'Enter your credentials to continue your journey.'
                      : 'Sign up to start renting anything, anywhere.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 16,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 36),
                
                SegmentedAuthToggle(
                  isLogin: isLogin,
                  onToggle: (value) {
                    setState(() {
                      isLogin = value;
                    });
                  },
                ),
                
                const SizedBox(height: 36),

                // Dynamic Form Fields
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  firstChild: const SizedBox(width: double.infinity, height: 0), // Empty for login
                  secondChild: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: AuthTextField(
                      label: 'Full Name',
                      hint: 'John Doe',
                      controller: _nameController,
                    ),
                  ),
                  crossFadeState: isLogin ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                ),
                
                AuthTextField(
                  label: 'Email Address',
                  hint: 'hello@renthubindia.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  suffixIcon: Icons.mail_outline,
                ),
                const SizedBox(height: 24),
                
                AuthTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _passwordController,
                  isPassword: obscurePassword,
                  suffixIcon: obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  onSuffixTap: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),
                
                if (isLogin) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => context.push('/forgot-password'),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF004D40),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return PrimaryButton(
                      text: isLogin ? 'Continue' : 'Sign Up',
                      isLoading: isLoading,
                      onPressed: _submit,
                    );
                  },
                ),

                const SizedBox(height: 24),
                const SizedBox(height: 48),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      isLogin = !isLogin;
                    });
                  },
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 15,
                        color: Color(0xFF4B5563),
                      ),
                      children: [
                        TextSpan(
                          text: isLogin ? "Don't have an account? " : "Already have an account? ",
                        ),
                        TextSpan(
                          text: isLogin ? 'Sign up' : 'Log in',
                          style: const TextStyle(
                            fontFamily: 'Sora',
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF004D40),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
