import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/request/auth_entity.dart';
import 'package:iyteliden_mobile/pages/main_page.dart';
import 'package:iyteliden_mobile/pages/register_page.dart';
import 'package:iyteliden_mobile/services/auth_service.dart';
import 'package:iyteliden_mobile/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {

  const LoginPage({super.key});

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showFeedbackSnackBar("Email or password can't be empty", isError: true);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final authData = AuthEntity(mail: email, password: password);

    try {
      final (authResponse, errorResponse) = await _authService.login(authData);
      if (!mounted) return;
      if (errorResponse != null) {
        _showFeedbackSnackBar(errorResponse.message, isError: true);
        setState(() {
          _isLoading = false;
        });
      } else if (authResponse != null) {
        int verifyResponse = await _authService.userVerification(authResponse.authorization);
        if (verifyResponse == 403) {
          _showFeedbackSnackBar("User not verified yet", isError: true);
          setState(() {
            _isLoading = false;
          });
          return;
        }
        _showFeedbackSnackBar("Sucessfully logged in.");
        setState(() {
          _isLoading = false;
        });
        _saveJwt(authResponse.authorization, authResponse.expireSeconds);
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MainPage()));
      } else {
        _showFeedbackSnackBar("Unknown error occured.", isError: true);
        _isLoading = false;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }    
    }
  }

  void _showFeedbackSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(10),
      action: SnackBarAction(
        label: "OK",
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _saveJwt(String token, int expireSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    final expiry = DateTime.now().add(Duration(seconds: expireSeconds));

    await prefs.setString("auth_token", token);
    await prefs.setString("auth_expiry", expiry.toIso8601String());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/logo.png",
              height: 200,
            ),
            const SizedBox(height: 32,),
            const Text(
              "Welcome Back",
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32,),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.secondary),
                ),
              ),
            ),
            const SizedBox(height: 32,),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                labelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.secondary),
                ),
              ),
            ),
            const SizedBox(height: 32,),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll<Color>(AppColors.primary),
                ),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading ?
                  const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.background,
                      strokeWidth: 3,
                    ),
                  )
                  :
                  const Text(
                    "Login",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.background,
                    ),
                  ),
              ),
            ),
            const SizedBox(height: 16,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't you have account? ",
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    );
                  },
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
