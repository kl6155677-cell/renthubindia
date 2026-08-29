import 'package:flutter/material.dart';

class SegmentedAuthToggle extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onToggle;

  const SegmentedAuthToggle({
    super.key,
    required this.isLogin,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6), // Light grey background
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          // Animated white pill background
          AnimatedAlign(
            alignment: isLogin ? Alignment.centerLeft : Alignment.centerRight,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onToggle(true),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isLogin ? const Color(0xFF004D40) : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onToggle(false),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Register',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: !isLogin ? const Color(0xFF004D40) : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
