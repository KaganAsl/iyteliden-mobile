import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/models/response/self_user_response.dart';
import 'package:iyteliden_mobile/services/user_service.dart';
import 'package:iyteliden_mobile/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {

  const ProfilePage({super.key});

  @override
  State<StatefulWidget> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  
  late Future<SelfUserResponse> _futureProfile;

  @override
  void initState() {
    super.initState();
    _futureProfile = _loadProfile();
  }

  Future<SelfUserResponse> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString("auth_token");
    if (jwt == null || jwt.isEmpty) {
      _showFeedbackSnackBar("Can't load profile", isError: true);
      throw Exception("JWT is missing");
    } else {
      final (userResponse, errorResponse) = await UserService().getSelfUserProfile(jwt);
      if (errorResponse != null) {
        _showFeedbackSnackBar(errorResponse.message, isError: true);
        throw Exception(errorResponse.message);
      } else {
        return userResponse!;
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
        title: Text(
          "Profile",
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: FutureBuilder<SelfUserResponse>(
        future: _futureProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(),);
          } else if (snapshot.hasError) {
            return const Center(child: Text("Failed to load profile."));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("User has no data."));
          }
          final user = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Id: ${user.userId}", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text("Email: ${user.mail}", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text("Username: ${user.userName}", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text("Status: ${user.status}", style: const TextStyle(fontSize: 16)),
              ],
            ),
          );
        },

      ),
    );
  }
}

