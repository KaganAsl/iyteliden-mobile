import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/pages/create_product_page.dart';
import 'package:iyteliden_mobile/pages/profile_page.dart';
import 'package:iyteliden_mobile/pages/tabs/home_tab.dart';
import 'package:iyteliden_mobile/utils/app_colors.dart';

class MainPage extends StatefulWidget {

  const MainPage({super.key});

  @override
  State<StatefulWidget> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const Center(child: Text("Categories"),),
    const Placeholder(),
    const Center(child: Text("Favourites"),),
  ];

  void _onTabTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CreateProductPage(),
        ),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfilePage(),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: AppColors.primary,
        //unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: "Categories"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline_rounded), label: "Create"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favourites"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}