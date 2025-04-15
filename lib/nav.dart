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
  late int _previousIndex;
  String _name = "";

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.newIndex;
    _previousIndex = _selectedIndex;
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
    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });
    if (index == 4) {
      progressKey.currentState?.refreshHabits();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      ProfileScreen(),
      SocialScreen(),
      HomeScreen(name: _name, shouldReload: false, isEditing: false),
      MissionsScreen(),
      ProgressScreen(key: progressKey),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) {
          // Determine slide direction based on index difference.
          final bool slideFromRight = _selectedIndex > _previousIndex;
          final Offset beginOffset =
              slideFromRight ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
          return SlideTransition(
            position: animation.drive(
              Tween<Offset>(begin: beginOffset, end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          );
        },
        child: Container(
          // Key the container with the selected index so AnimatedSwitcher knows when to animate.
          key: ValueKey<int>(_selectedIndex),
          child: pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFF1C1C1C),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
