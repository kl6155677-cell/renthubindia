import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../blocs/location/location_bloc.dart';
import '../../../blocs/location/location_state.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.go('/home');
            } else if (state is AuthUnauthenticated || state is AuthError) {
              context.go('/auth'); // Unified Auth Screen
            }
          },
        ),
        BlocListener<LocationBloc, LocationState>(
          listener: (context, state) {
            if (state is LocationNotServiceable) {
              context.go('/not-serviceable', extra: state.city);
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Stack(
          children: [
            // Geometric background painter
            Positioned.fill(
              child: CustomPaint(
                painter: _GeometricBackgroundPainter(),
              ),
            ),
            // Center Logo
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // RentHubIndia Text
                  const Text(
                    'RentHubIndia',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Rent Anything. Anywhere.',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 16,
                      color: Color(0xFFB2DFDB), // Lighter teal/mint matches image
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeometricBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Top right circle
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.15), 180, paint);
    
    // Bottom left circle
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.75), 220, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
