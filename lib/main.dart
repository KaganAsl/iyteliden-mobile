import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:google_fonts/google_fonts.dart";
import "package:iyteliden_mobile/pages/login_page.dart";
import "package:iyteliden_mobile/pages/main_page.dart";
import "package:iyteliden_mobile/services/auth_service.dart";
import "package:iyteliden_mobile/pages/landing_page.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() async {
    await dotenv.load(fileName: ".env");
    runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Iyteliden",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        home: const LandingPage(),
    );
  }
}
