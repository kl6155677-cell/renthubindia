import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/api_constants.dart';

/// Forgot Password → Enter email → sends OTP
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.dio.post(ApiConstants.forgotPassword, data: {'email': email});
      if (mounted) {
        context.push('/verify-otp', extra: email);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data?['message'] ?? 'Something went wrong'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Forgot Password', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Reset your password',
              style: TextStyle(fontFamily: 'Sora', fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the email address associated with your account and we\'ll send you a verification code.',
              style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
            ),
            const SizedBox(height: 28),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Email address',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                  prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send Verification Code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// OTP Verification Screen
class VerifyOtpScreen extends StatefulWidget {
  final String email;
  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length != 6) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.dio.post(ApiConstants.verifyOtp, data: {
        'email': widget.email,
        'code': _otp,
      });
      if (mounted) {
        context.push('/reset-password', extra: {'email': widget.email, 'code': _otp});
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data?['message'] ?? 'Invalid code'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Verify Code', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Enter verification code',
              style: TextStyle(fontFamily: 'Sora', fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a 6-digit code to ${widget.email}',
              style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                return SizedBox(
                  width: 48,
                  height: 56,
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(fontFamily: 'Sora', fontSize: 22, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty && i < 5) {
                        _focusNodes[i + 1].requestFocus();
                      }
                      if (val.isEmpty && i > 0) {
                        _focusNodes[i - 1].requestFocus();
                      }
                      setState(() {});
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_otp.length == 6 && !_isLoading) ? _verify : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Verify'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () async {
                  try {
                    await ApiService.dio.post(ApiConstants.forgotPassword, data: {'email': widget.email.toLowerCase()});
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code resent!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to resend code. Please try again.'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
                      );
                    }
                  }
                },
                child: const Text(
                  'Didn\'t receive the code? Resend',
                  style: TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reset Password Screen
class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String code;
  const ResetPasswordScreen({super.key, required this.email, required this.code});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pw = _passwordController.text;
    if (pw.length < 6 || pw != _confirmController.text) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.dio.post(ApiConstants.resetPassword, data: {
        'email': widget.email,
        'code': widget.code,
        'newPassword': pw,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
        context.go('/auth');
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data?['message'] ?? 'Error'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = _passwordController.text == _confirmController.text;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('New Password', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text('Create new password', style: TextStyle(fontFamily: 'Sora', fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Your new password must be at least 6 characters.', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF6B7280))),
            const SizedBox(height: 28),
            _buildPasswordField(_passwordController, 'New Password', _obscure1, () => setState(() => _obscure1 = !_obscure1)),
            const SizedBox(height: 16),
            _buildPasswordField(_confirmController, 'Confirm Password', _obscure2, () => setState(() => _obscure2 = !_obscure2)),
            if (_confirmController.text.isNotEmpty && !match)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Passwords do not match', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: AppColors.error)),
              ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_passwordController.text.length >= 6 && match && !_isLoading) ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Reset Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController ctrl, String hint, bool obscure, VoidCallback toggle) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF9CA3AF)),
          suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF9CA3AF)), onPressed: toggle),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
