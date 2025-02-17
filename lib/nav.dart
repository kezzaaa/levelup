// ignore_for_file: library_private_types_in_public_api

// Packages
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Files
import 'package:levelup/profile.dart';
import 'package:levelup/social.dart';
import 'package:levelup/home.dart';
import 'package:levelup/missions.dart';
import 'package:levelup/progress.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  _NavigationState createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {

  // List of screens corresponding to the tabs
  final List<Widget> _pages = [];

  @override
  Widget build(BuildContext context) {
    // Update _pages after the username has been loaded
    _pages.clear();
    _pages.addAll([
      ProfileScreen(),
      SocialScreen(),
      HomeScreen(username: _username), // Pass the actual username here
      MissionsScreen(),
      ProgressScreen(),
    ]);

    return Scaffold(
      body: _pages[_selectedIndex], // Display selected page based on index
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex, // Ensure it highlights the selected tab
        onTap: _onItemTapped, // Handle tab selection
        backgroundColor: Theme.of(context).colorScheme.secondary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Social'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.check_box), label: 'Missions'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_sharp), label: 'Progress'),
        ],
      ),
    );
  }

  String _username = ""; // Default is an empty string
  int _selectedIndex = 2; // Default to 'Home' tab

  @override
  void initState() {
    super.initState();
    _loadUsername(); // Load the username when the screen is initialized
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? "User"; // Default to "User" if null
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}