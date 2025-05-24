import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/pages/login_page.dart';
import 'package:iyteliden_mobile/pages/register_page.dart';
import 'package:iyteliden_mobile/pages/main_page.dart';
import 'package:iyteliden_mobile/services/auth_service.dart';
import 'package:iyteliden_mobile/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _isCheckingToken = true; // Added state variable

  @override
  void initState() {
    super.initState();
    _checkTokenAndNavigate();
  }

  Future<void> _checkTokenAndNavigate() async {
    // 0 -> No problem, 1 -> No token or expired, 2 -> Not verified, 3 -> Something else
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString("auth_token");

      if (jwt == null || jwt.isEmpty) {
        if (mounted) {
          setState(() {
            _isCheckingToken = false;
          });
        }
        return;
      }

      final authService = AuthService();
      final result = await authService.userVerification(jwt);

      if (!mounted) return;

      if (result == 204) { // HTTP 204 No Content usually means success for verification
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      } else if (result == 401) { // Unauthorized (token expired or invalid)
        await prefs.remove("auth_token");
        await prefs.remove("auth_expiry");
        if (mounted) {
          setState(() {
            _isCheckingToken = false;
          });
        }
      } else if (result == 403) { // Forbidden (user not verified, e.g., email not confirmed)
        if (mounted) {
          setState(() {
            _isCheckingToken = false;
          });
        }
      } else {
        // Other errors, potentially remove token and stay
        await prefs.remove("auth_token");
        await prefs.remove("auth_expiry");
        if (mounted) {
          setState(() {
            _isCheckingToken = false;
          });
        }
      }
    } catch (e) {
      // Exception during token check, stay on LandingPage
      if (mounted) {
        setState(() {
          _isCheckingToken = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingToken) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // App Logo
              Image.asset(
                'assets/logo.png', // Assuming logo.png is in the assets folder
                height: 150,
              ),
              const SizedBox(height: 20),
              // App Name
              const Text(
                'iyteliden', // Replace with your actual app name if different
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text, // Or your primary text color
                ),
              ),
              const SizedBox(height: 48),
              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B0A1A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Register Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF414143), // Or another distinct color
                     shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    );
                  },
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 