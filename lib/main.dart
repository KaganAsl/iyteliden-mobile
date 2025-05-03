import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:google_fonts/google_fonts.dart";
import "package:iyteliden_mobile/pages/login_page.dart";
import "package:iyteliden_mobile/pages/main_page.dart";
import "package:iyteliden_mobile/services/auth_service.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() async {
    await dotenv.load(fileName: ".env");
    runApp(MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  Future<int> _tokenVerification() async {
    // 0 -> No problem, 1 -> No token or expired, 2 -> Not verified, 3 -> Something else
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString("auth_token");
      if (jwt == null || jwt.isEmpty) return 1;
      final authService = AuthService();
      final result = await authService.userVerification(jwt);
      if (result == 204) {
        return 0;
      } else if (result == 401) {
        await prefs.remove("auth_token");
        await prefs.remove("auth_expiry");
        return 1;
      } else if (result == 403) {
        return 2;
      } else {
        await prefs.remove("auth_token");
        await prefs.remove("auth_expiry");
        return 3;
      }
    } catch (e) {
      return 1;
    }
  }

  void _showFeedbackSnackBar(BuildContext context, String message, {bool isError = false}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(10),
      action: SnackBarAction(
        label: "OK",
        textColor: Colors.white,
        onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Iyteliden",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        home: FutureBuilder<int>(
          future: _tokenVerification(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final result = snapshot.data!;
            if (result == 0) {
              return MainPage();
            } else if (result == 1) {
              return LoginPage();
            } else if (result == 2) {
              _showFeedbackSnackBar(context, "Access denied. User is not verified.", isError: true);
              return LoginPage();
            } else {
              _showFeedbackSnackBar(context, "An unknown error occurred.", isError: true);
              return LoginPage();
            }
          },
        ),
    );
  }
}
