// ignore_for_file: library_private_types_in_public_api

// Packages
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';

// Files
import 'main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _socialEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadToggleValue();
  }

  // Load the saved toggle value from SharedPreferences
  Future<void> _loadToggleValue() async {
    final prefs = await SharedPreferences.getInstance();
    bool storedValue = prefs.getBool('socialEnabled') ?? false;
    setState(() {
      _socialEnabled = storedValue;
      // When social features are enabled, disable the blur (thus setting global to false)
      blurEnabledNotifier.value = !storedValue;
    });
  }

  // Toggle the switch and persist the new value
  Future<void> _toggleSocialEnabled(bool value) async {
    setState(() {
      _socialEnabled = value;
      blurEnabledNotifier.value = !value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('socialEnabled', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      // Use Padding to position the toggle near the top
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0, left: 16.0),
        child: Row(
          children: [
            const Text(
              "Enable Social Features",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(width: 130),
            CupertinoSwitch(
              value: _socialEnabled,
              onChanged: _toggleSocialEnabled,
            ),
          ],
        ),
      ),
    );
  }
}