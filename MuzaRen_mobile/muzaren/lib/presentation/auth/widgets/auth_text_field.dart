import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final String label;
  final String hint;
  final bool isPassword;
  final IconData? suffixIcon;
  final TextEditingController controller;
  final VoidCallback? onSuffixTap;
  final TextInputType keyboardType;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    this.isPassword = false,
    this.suffixIcon,
    required this.controller,
    this.onSuffixTap,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Sora',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 16,
              color: Color(0xFF1F2937),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              suffixIcon: suffixIcon != null
                  ? GestureDetector(
                      onTap: onSuffixTap,
                      child: Icon(
                        suffixIcon,
                        color: const Color(0xFF9CA3AF),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
