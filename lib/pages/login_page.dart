import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/request/auth_entity.dart';
import 'package:iyteliden_mobile/pages/register_page.dart';
import 'package:iyteliden_mobile/services/auth_service.dart';
import 'package:iyteliden_mobile/utils/app_colors.dart';

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
      _showErrorDialog("Email and password can not be empty");
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
        _showErrorDialog(errorResponse.message);
        setState(() {
          _isLoading = false;
        });
      } else if (authResponse != null) {
        _showSuccessDialog();
        setState(() {
          _isLoading = false;
        });
      } else {
        _showErrorDialog("Unexpected error occured");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }    
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Login Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      }
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Login Success'),
          content: const Text('You have logged in successfully!'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                 Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
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
              "logo.png",
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
