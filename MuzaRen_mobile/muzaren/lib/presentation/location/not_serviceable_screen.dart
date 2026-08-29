import 'package:flutter/material.dart';

class NotServiceableScreen extends StatelessWidget {
  final String city;

  const NotServiceableScreen({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_off,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                'Not Serviceable',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sorry, RentHubIndia is not currently available in $city.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 16,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 48),
              // We could add a button to select a different city manually if we implement that feature
              // For now, they are just blocked.
            ],
          ),
        ),
      ),
    );
  }
}
