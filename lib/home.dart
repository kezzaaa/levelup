// ignore_for_file: library_private_types_in_public_api

// Packages
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

// Files
import 'package:levelup/utils.dart';

// HomeScreen displaying the username and avatar
class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

    String srcGlb = ''; // Initialize an empty string for the GLB URL

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  // Load avatar data from SharedPreferences and update the UI
  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final ProfileData? profile = userFromPrefs(prefs);

    if (profile != null && profile.avatarUrl != null) {
      setState(() {
        srcGlb = profile.avatarUrl!; // Set the avatar URL for 3D display
      });
      // Print the avatar URL to the debug console
      debugPrint('Avatar URL: $srcGlb');
    } else {
      // Handle case where there's no avatar URL found
      debugPrint("No avatar URL found in SharedPreferences");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double appBarHeight = kToolbarHeight; // Default AppBar height
    final double avatarHeight = (screenHeight - appBarHeight) * 0.5; // 50% of remaining space

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: Text(
          "Welcome, ${widget.username}!",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // 3D Avatar taking up 50% of the screen
          SizedBox(
            height: avatarHeight,
            child: ModelViewer(
              src: srcGlb,
              alt: 'A 3D model of your avatar',
              autoRotate: true,
              disableZoom: true,
            ),
          ),
          
          // Remaining space (you can add other widgets here)
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.primary,
              child: const Center(child: Text("[Placeholder]")),
            ),
          ),
        ],
      ),
    );
  }
}