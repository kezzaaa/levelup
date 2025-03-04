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
  final int newIndex; // ✅ Correct parameter

  const Navigation({super.key, this.newIndex = 2}); // ✅ Default to home tab

  @override
  _NavigationState createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  late int _selectedIndex;
  String _username = "User"; // ✅ Ensure default value

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.newIndex; // ✅ Assign selected index from constructor
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? "User"; // ✅ Load stored username
    });
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return; // ✅ Prevent redundant navigation

    Navigator.of(context).pushReplacement(_createRoute(index));
  }

  PageRouteBuilder _createRoute(int index) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          Navigation(newIndex: index), // ✅ Pass index correctly
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final begin = Offset(index > _selectedIndex ? 1.0 : -1.0, 0.0); // ✅ Slide Left/Right
        final end = Offset.zero;
        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      ProfileScreen(),
      SocialScreen(),
      HomeScreen(username: _username, shouldReload: false, isEditing: false),
      MissionsScreen(),
      ProgressScreen(),
    ];

    return Scaffold(
      body: _pages[_selectedIndex], // ✅ Ensure the correct tab is displayed
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
}
