// ignore_for_file: library_private_types_in_public_api

// Packages
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

// Files
import 'userutils.dart';
import 'avatarcreator.dart';
import 'missions.dart';

// ignore: must_be_immutable
class HomeScreen extends StatefulWidget {
  String username;
  final bool shouldReload;
  final bool isEditing;
  final Function(int)? onXPUpdate;

  HomeScreen({super.key, required this.username, required this.shouldReload, required this.isEditing, this.onXPUpdate});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  InAppWebViewController? webViewController;
  String srcGlb = '';

  bool isGaming = false;
  int elapsedSeconds = 0;
  Timer? sessionTimer;

  int _level = 1;
  int _xp = 0;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
    _loadUsername();
    _loadGamingSession();
    _loadXPData();

    // ✅ Automatically reload WebView when returning from Avatar Editor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.shouldReload) {
        webViewController?.reload();
        debugPrint("🔄 Auto-reloading WebView...");
      }
    });
  }

  void openMissionsScreen() async {
    final int? xpReward = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MissionsScreen()),
    );

    if (xpReward != null) {
      _updateXP(xpReward);
    }
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedUsername = prefs.getString('username');

    if (storedUsername != null && storedUsername.isNotEmpty) {
      setState(() {
        widget.username = storedUsername; // ✅ Update UI with correct username
      });
      debugPrint('✅ Username Loaded: $storedUsername');
    } else {
      debugPrint("❌ No username found in SharedPreferences");
    }
  }

  Future<void> _loadXPData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _xp = prefs.getInt('userXP') ?? 0;
      _level = prefs.getInt('userLevel') ?? 1;
    });
  }

  Future<void> _updateXP(int gainedXP) async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _xp += gainedXP; // Add the XP gained
    });

    int xpThreshold = getXpThresholdForLevel(_level);

    // 🚀 Level-up logic
    while (_xp >= xpThreshold) {
      _xp -= xpThreshold; // Deduct XP needed for leveling up
      _level++; // Increase level
      xpThreshold = getXpThresholdForLevel(_level); // Update threshold for next level

      // 🎉 Animate level-up effect (optional)
      _showLevelUpAnimation();
    }

    // Save XP and Level persistently
    await prefs.setInt('userXP', _xp);
    await prefs.setInt('userLevel', _level);

    debugPrint("✅ XP Updated: $_xp | Level: $_level");
  }

  // ✨ Optional: Show a pop-up animation when leveling up
  void _showLevelUpAnimation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: const Center(
            child: Text(
              "🎉 Level Up! 🎉",
              style: TextStyle(color: Colors.yellow, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          content: Center(
            child: Text(
              "You are now Level $_level!",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Awesome!", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ✅ Load avatar data from SharedPreferences and update the UI
  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final ProfileData? profile = userFromPrefs(prefs);

    if (profile != null && profile.avatarUrl != null) {
      setState(() {
        srcGlb = profile.avatarUrl!;
      });
      debugPrint('✅ Avatar URL Loaded: $srcGlb');
    } else {
      debugPrint("❌ No avatar URL found in SharedPreferences");
    }
  }

  // ✅ Helper function to get correct MIME type for assets
  String _getMimeType(String path) {
    if (path.endsWith(".html")) return "text/html";
    if (path.endsWith(".js")) return "application/javascript";
    if (path.endsWith(".css")) return "text/css";
    if (path.endsWith(".glb")) return "model/gltf-binary";
    if (path.endsWith(".fbx")) return "application/octet-stream";
    return "text/plain";
  }

  // ✅ Open Fullscreen Avatar Creator
  void openAvatarEditor() async {
    final prefs = await SharedPreferences.getInstance();
    Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(
        builder: (context) => AvatarCreatorScreen(prefs: prefs, isEditing: true),
      ),
    ).then((shouldReload) async {
      if (shouldReload == true) {
        // ✅ Fetch updated avatar URL
        final ProfileData? updatedProfile = userFromPrefs(prefs);
        if (updatedProfile != null && updatedProfile.avatarUrl != null) {
          setState(() {
            srcGlb = updatedProfile.avatarUrl!;
          });
          debugPrint("✅ Updated Avatar URL Loaded: $srcGlb");
        } else {
          debugPrint("❌ Failed to load updated avatar URL");
        }

        // ✅ Reload WebView with updated model
        webViewController?.reload();
        debugPrint("🔄 WebView reloaded after avatar edit.");
      }
    });
  }

  Future<void> _loadGamingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final int? savedStartTime = prefs.getInt('gamingStartTime');

    if (savedStartTime != null) {
      int secondsElapsed = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(savedStartTime))
          .inSeconds;

      setState(() {
        isGaming = true;
        elapsedSeconds = secondsElapsed; // ✅ Restore elapsed time
      });

      _startTimer(); // ✅ Restart the timer when reloading the screen
    }
  }

  // ✅ Start/Stop the Gaming Session
  void toggleGamingSession() async {
    final prefs = await SharedPreferences.getInstance();

    if (!isGaming) {
      // 🟢 Start gaming session & save start time
      final int currentTime = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt('gamingStartTime', currentTime);
      setState(() {
        isGaming = true;
        elapsedSeconds = 0;
      });
      _startTimer();
    } else {
      // 🔴 Stop gaming session & remove start time
      await prefs.remove('gamingStartTime');
      sessionTimer?.cancel();
      setState(() {
        isGaming = false;
        elapsedSeconds = 0;
      });
    }
  }

  // ✅ Start the Timer (Runs in Background)
  void _startTimer() {
    sessionTimer?.cancel();
    sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => elapsedSeconds++);
      }
    });
  }

  // ✅ Format Time to HH:MM:SS
  String formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return "${hours.toString().padLeft(2, '0')}:"
           "${minutes.toString().padLeft(2, '0')}:"
           "${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
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
          SizedBox(height: 20),

          // 🔹 Row 1: Top Section (XP Bar + Level Indicator)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.050,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🔵 Level Indicator (Cyan Circle with White Number)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.cyan,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '$_level',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // 🌟 XP Bar (Cyan progress with white border)
                  Expanded(
                    child: Stack(
                      children: [
                        // Background XP Bar
                        Container(
                          height: 15,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        // XP Progress (Cyan Fill)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            double progress = _xp / getXpThresholdForLevel(_level);
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: constraints.maxWidth * progress,
                              height: 15,
                              decoration: BoxDecoration(
                                color: Colors.cyan,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ❤️ Hearts Row (Health Indicator)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 🔹 Row 2: Avatar Section (WebView + Edit Icon)
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 🌍 WebView Displaying Avatar
                InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri("https://localhost/assets/viewer.html"),
                  ),
                  initialSettings: InAppWebViewSettings(
                    transparentBackground: true,
                    allowFileAccess: true,
                    allowUniversalAccessFromFileURLs: true,
                    allowFileAccessFromFileURLs: true,
                    clearCache: true,
                    disableVerticalScroll: true,
                  ),
                  onWebViewCreated: (controller) {
                    if (webViewController == null) {
                      webViewController = controller;

                      // ✅ Add JavaScript handler to listen for messages from JavaScript
                      webViewController!.addJavaScriptHandler(
                        handlerName: 'danceTriggered',
                        callback: (args) {
                          debugPrint("💃 Dance event received from WebView!");
                        },
                      );
                    }
                  },
                  shouldInterceptRequest: (controller, request) async {
                    if (request.url.toString().startsWith("https://localhost/assets/")) {
                      String assetPath = request.url.toString().replaceFirst(
                          "https://localhost/assets/", "assets/");
                      try {
                        ByteData data = await rootBundle.load(assetPath);
                        return WebResourceResponse(
                          data: data.buffer.asUint8List(),
                          contentType: _getMimeType(assetPath),
                        );
                      } catch (e) {
                        debugPrint("❌ Error loading asset: $e");
                        return null;
                      }
                    }
                    return null;
                  },
                  onLoadStop: (controller, url) async {
                    final prefs = await SharedPreferences.getInstance();
                    final String? userGender = prefs.getString('userGender');

                    // ✅ Set user gender in JavaScript
                    if (userGender != null) {
                      await webViewController!.evaluateJavascript(
                        source: "window.setUserGender('$userGender');",
                      );
                      debugPrint("✅ Sent user gender to WebView: $userGender");
                    }

                    // ✅ Load GLB model in JavaScript
                    if (srcGlb.isNotEmpty) {
                      await webViewController!.evaluateJavascript(
                        source: "loadGLBModel('$srcGlb');",
                      );
                      debugPrint("✅ Passed GLB URL to WebView: $srcGlb");
                    }
                  },
                ),

                // ✏️ Floating Edit & Dance Buttons
                Positioned(
                  top: 75,
                  right: 20,
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_square, color: Colors.white, size: 30),
                        onPressed: openAvatarEditor,
                      ),
                      const SizedBox(height: 10),
                      IconButton(
                        icon: const Icon(Icons.music_note, color: Colors.white, size: 30),
                        onPressed: () async {
                          if (webViewController != null) {
                            await webViewController!.evaluateJavascript(
                              source: "playRandomDanceAnimation();",
                            );
                            debugPrint("✅ Called playRandomDanceAnimation() in WebView");
                          } else {
                            debugPrint("❌ WebViewController is null!");
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Row 3: Bottom Section (Start Gaming Session Button)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.16,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: toggleGamingSession,
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 50,
                    width: 220,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isGaming ? Colors.grey[800] : Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isGaming ? formatTime(elapsedSeconds) : "Start Gaming Session 🎮",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}