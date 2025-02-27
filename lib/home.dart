// ignore_for_file: library_private_types_in_public_api

// Packages
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

// Files
import 'package:levelup/utils.dart';

// HomeScreen displaying the username and avatar
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.username});

  final String username;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? chosenAnimation;
  String srcGlb = '';

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
      debugPrint('Avatar URL: $srcGlb');
    } else {
      debugPrint("No avatar URL found in SharedPreferences");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double avatarHeight = screenHeight * 0.4;

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

          // XP bar on top of avatar
          Padding(
            padding: const EdgeInsets.only(top: 60.0), // Fixed spacing
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 10, // XP Bar height
              child: Stack(
                children: [
                  // Background Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800, // Dark background
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  // XP Fill (50% full)
                  FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green, // XP fill color
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3D Avatar with podium underneath using Stack
          SizedBox(
            height: avatarHeight + 100, // Increase height to fit podium
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 0, // Set to 0 to ensure podium is fully visible
                  child: Image.asset(
                    'assets/images/podium.png',
                    width: 125,
                    height: 125,
                  ),
                ),
                // 3D Avatar (Placed after so it's on top of the podium)
                SizedBox(
                  height: avatarHeight,
                  child: ModelViewer(
                    src: srcGlb,
                    alt: 'A 3D model of your avatar',
                    autoRotate: true,
                    disableZoom: true,
                    cameraControls: true,
                    maxCameraOrbit: "Infinity 0deg auto",
                    minCameraOrbit: "-Infinity 80deg auto",
                  ),
                ),
              ],
            ),
          ),

          // Remaining space for other widgets
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