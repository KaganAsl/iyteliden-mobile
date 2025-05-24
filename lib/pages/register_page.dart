import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/request/auth_entity.dart';
import 'package:iyteliden_mobile/pages/login_page.dart';
import 'package:iyteliden_mobile/services/auth_service.dart';
import 'package:iyteliden_mobile/utils/app_colors.dart';

class RegisterPage extends StatefulWidget {

  const RegisterPage({super.key});

  @override
  State<StatefulWidget> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  
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

  Future<void> _handleRegister() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final mail = _emailController.text;
    final password = _passwordController.text;

    if (mail.isEmpty || password.isEmpty) {
      _showFeedbackSnackBar("Email or password can't be empty", isError: true);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final authData = AuthEntity(mail: mail, password: password);

    try {
      final (authResponse, errorResponse) = await _authService.register(authData);
      if (!mounted) return;
      if (errorResponse != null) {
        _showFeedbackSnackBar(errorResponse.message, isError: true);
        setState(() {
          _isLoading = false;
        });
      } else if (authResponse != null) {
        _showFeedbackSnackBar("Verification mail send.");
        setState(() {
          _isLoading = false;
        });
        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()),);
      } else {
        _showFeedbackSnackBar("Unknown error occured.", isError: true);
        setState(() {
          _isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.text),
        titleTextStyle: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.bold),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
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
              "Create Account",
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
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading ?
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                )
                :
                const Text(
                  "Register",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.background,
                  ),
                )
              ),
            ),
            const SizedBox(height: 16,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Already have account? ",
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  child: const Text(
                    "Log In",
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