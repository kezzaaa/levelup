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
  String _name = "";

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.newIndex;
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedName = prefs.getString('firstName');

    if (storedName != null && storedName.isNotEmpty) {
      setState(() {
        _name = storedName;
      });
      debugPrint("✅ First Name Loaded: $_name");
    } else {
      debugPrint("❌ No first name found in SharedPreferences");
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    Navigator.of(context).pushReplacement(_createRoute(index));
  }

  PageRouteBuilder _createRoute(int index) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          Navigation(newIndex: index),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final begin = Offset(index > _selectedIndex ? 1.0 : -1.0, 0.0);
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
    final List<Widget> pages = [
      ProfileScreen(),
      SocialScreen(),
      HomeScreen(name: _name, shouldReload: false, isEditing: false),
      MissionsScreen(),
      ProgressScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex], // ✅ Ensure the correct tab is displayed
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Social'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.check_box), label: 'Missions'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_sharp), label: 'Progress'),
        ],
      ),
    );
  }
}
