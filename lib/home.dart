// ignore_for_file: library_private_types_in_public_api

// Packages
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

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
  Flutter3DController controller = Flutter3DController();
  String? chosenAnimation;
  String srcGlb = '';

  @override
  void initState() {
    super.initState();
    _loadAvatar();

    // Listen for when the model loads
    controller.onModelLoaded.addListener(() async {
      debugPrint('Model loaded: ${controller.onModelLoaded.value}');
      
      // Fetch available animations
      List<String> animations = await controller.getAvailableAnimations();
      debugPrint('Available animations: $animations');

      if (animations.isNotEmpty) {
        setState(() {
          chosenAnimation = animations.first; // Select first animation as default
        });

        // Play the selected animation
        controller.playAnimation(animationName: chosenAnimation);
      }
    });
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
          // 3D Avatar with podium underneath using Stack
          SizedBox(
            height: avatarHeight,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  bottom: -25,
                  child: Image.asset(
                    'assets/images/podium.png',
                    width: 100,
                    height: 100,
                  ),
                ),
                // 3D Avatar (Placed After so it's On Top of the podium)
                SizedBox(
                  height: avatarHeight * 0.8,
                  child: Flutter3DViewer(
                    controller: controller,
                    src: srcGlb,
                    onLoad: (String modelAddress) {
                      debugPrint('Model successfully loaded: $modelAddress');
                    },
                    onError: (String error) {
                      debugPrint('Model failed to load: $error');
                    },
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