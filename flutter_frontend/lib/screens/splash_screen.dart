import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'main_screen.dart';
import '../utils/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Small delay for splash effect while auth initializes
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      _checkAuthAndNavigate();
    }
  }

  void _checkAuthAndNavigate() {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.status == AuthStatus.loading) {
      // Still loading, wait a bit more
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _checkAuthAndNavigate();
      });
      return;
    }

    // Auth status is determined, navigate accordingly
    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Icon(
                Icons.emergency,
                size: 100,
                color: Colors.white,
              ),
              SizedBox(height: 24),

              // App Name
              Text(
                'ResQ',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),

              // Tagline
              Text(
                'Emergency Detection System',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  letterSpacing: 1,
                ),
              ),

              SizedBox(height: 48),

              // Loading Indicator
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),

              SizedBox(height: 16),

              Text(
                'Initializing...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
