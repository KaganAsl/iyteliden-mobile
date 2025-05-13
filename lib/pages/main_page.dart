import 'package:flutter/material.dart';
import 'package:iyteliden_mobile/pages/create_product_page.dart';
import 'package:iyteliden_mobile/pages/profile_page.dart';
import 'package:iyteliden_mobile/pages/search_page.dart';
import 'package:iyteliden_mobile/pages/tabs/favorite_tab.dart';
import 'package:iyteliden_mobile/pages/tabs/home_tab.dart';
import 'package:iyteliden_mobile/pages/tabs/messages_tab.dart';
import 'package:iyteliden_mobile/utils/app_colors.dart';

class MainPage extends StatefulWidget {

  const MainPage({super.key});

  @override
  State<StatefulWidget> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late List<Widget> _tabs;
  
  @override
  void initState() {
    super.initState();
    // Initialize tabs
    _refreshAllTabs();
    
    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);
  }
  
  // Helper method to refresh all tabs
  void _refreshAllTabs() {
    _tabs = [
      const HomeTab(),
      const MessagesTab(),
      const Placeholder(),
      const FavoriteTab(),
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes, refresh all tabs
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _refreshAllTabs();
      });
    }
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CreateProductPage(),
        ),
      ).then((_) {
        // Refresh tabs when returning from CreateProductPage
        if (mounted) {
          setState(() {
            _refreshAllTabs();
          });
        }
      });
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfilePage(),
        ),
      ).then((_) {
        // Refresh tabs when returning from ProfilePage
        if (mounted) {
          setState(() {
            _refreshAllTabs();
          });
        }
      });
    } else if (_selectedIndex != index) {
      setState(() {
        // If changing tabs, refresh the destination tab
        if (index == 0 || index == 3) {
          if (index == 0) {
            _tabs[0] = const HomeTab();
          } else {
            _tabs[3] = const FavoriteTab();
          }
        }
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Iyteliden"),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final favoritesChanged = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchPage(),
                ),
              );
              
              // Only refresh tabs if favorites changed or we need to ensure fresh data
              if (mounted && (favoritesChanged == true)) {
                setState(() {
                  // Recreate all tabs to ensure fresh data
                  _refreshAllTabs();
                });
              }
            },
          ),
        ],
      ),
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
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Messages"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline_rounded), label: "Create"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favourites"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}