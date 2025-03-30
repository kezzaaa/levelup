// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

// Packages
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

// Files
import 'userutils.dart';
import 'avatarcreator.dart';
import 'missions.dart';

// ignore: must_be_immutable
class HomeScreen extends StatefulWidget {
  String name;
  final bool shouldReload;
  final bool isEditing;
  final Function(int)? onXPUpdate;

  HomeScreen({super.key, required this.name, required this.shouldReload, required this.isEditing, this.onXPUpdate});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  InAppWebViewController? webViewController;
  String srcGlb = '';

  bool isGaming = false;
  bool isPaused = false;
  int elapsedSeconds = 0;
  Timer? sessionTimer;
  String? _gamingTimeLimit;

  int heartsRemaining = 0;
  bool _hasLostHeartForCurrentSession = false;

  int _level = 1;
  int _xp = 0;

  @override
  void initState() {
    super.initState();

    _checkFirstTimeUser();
    _hasLevelledUp();

    _loadAvatar();
    _loadName();
    _loadGamingSession();
    _loadXPData();
    _loadHearts();

    // ✅ Automatically reload WebView when returning from Avatar Editor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.shouldReload) {
        webViewController?.reload();
        debugPrint("🔄 Auto-reloading WebView...");
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _saveCurrentLevel(); // Save level before leaving the screen
  }

  // ✅ Function to check if user has seen home tutorial before
  Future<void> _checkFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenTutorial = prefs.getBool('hasSeenHomeTutorial') ?? false;

    if (!hasSeenTutorial) {
      // ✅ Show tutorial pop-up
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showHomeTutorial(context);
      });

      // ✅ Mark tutorial as seen
      await prefs.setBool('hasSeenHomeTutorial', true);
    }
  }

  Future<void> _saveCurrentLevel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('previousUserLevel', _level); // Save old level before leaving
    debugPrint("💾 Saved Previous Level: $_level");
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

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedName = prefs.getString('firstName');

    if (storedName != null && storedName.isNotEmpty) {
      setState(() {
        widget.name = storedName;
      });
      debugPrint("✅ First Name Loaded in Home: $storedName");
    } else {
      debugPrint("❌ No first name found in SharedPreferences");
    }
  }

  Future<void> _loadXPData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _xp = prefs.getInt('userXP') ?? 0;
      _level = prefs.getInt('userLevel') ?? 1;

    });
  }

  Future<void> _loadHearts() async {
    final prefs = await SharedPreferences.getInstance();
    int storedHearts = prefs.getInt('heartsRemaining') ?? 5;
    if (storedHearts == 0) {
      storedHearts = 5;
      await prefs.setInt('heartsRemaining', storedHearts);
    }
    setState(() {
      heartsRemaining = storedHearts;
    });
  }    

  Future<void> _updateXP(int gainedXP) async {
    final prefs = await SharedPreferences.getInstance();
    
    int oldLevel = _level; // Store previous level before XP update

    setState(() {
      _xp += gainedXP;
    });

    int xpThreshold = getXpThresholdForLevel(_level);

    // 🚀 Level-up logic
    while (_xp >= xpThreshold) {
      _xp -= xpThreshold;
      _level++;
      xpThreshold = getXpThresholdForLevel(_level);

      // Restore the users hearts to full
      heartsRemaining = 5;
      await prefs.setInt('heartsRemaining', heartsRemaining);

      debugPrint("🎉 Level Up Triggered! New Level = $_level, Remaining XP = $_xp");
    }

    await prefs.setInt('userXP', _xp);
    await prefs.setInt('userLevel', _level);

    debugPrint("✅ XP Updated: Level = $_level, XP = $_xp");

    // 🔍 Confirm if we should trigger the animation
    if (_level > oldLevel) {
      debugPrint("⚡ _showLevelUpAnimation() SHOULD BE CALLED NOW!");
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint("✅ _showLevelUpAnimation() IS BEING CALLED!");
        _showLevelUpDialog(context);
      });
    } else {
      debugPrint("⛔ Level did not increase, no dialog will be shown.");
    }
  }

  Future<void> _hasLevelledUp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    int oldLevel = prefs.getInt('previousUserLevel') ?? 1; // Get last saved level
    await _loadXPData(); // Ensure `_level` is updated to the latest level
    int newLevel = _level; // Get the current level after returning

    if (oldLevel != newLevel && newLevel > 1) { // Exclude level 1 from triggering
      debugPrint("🎉 Level Up detected! Showing dialog in 500ms...");

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showLevelUpDialog(context);
      });

      // Save new level as the previous level to avoid duplicate pop-ups
      await prefs.setInt('previousUserLevel', newLevel);
    } else {
      debugPrint("✅ No Level Up detected or Level is 1 (ignored).");
    }
  }

  // ✨ Show a pop-up animation when leveling up
  void _showLevelUpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Level Up! 🎉",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "You are now Level $_level!",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 30), // Spacing for readability
              Text(
                "❤️ Your hearts have been fully restored! ❤️",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "🔃 You gained +3 refresh tokens! 🔃",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.cyan, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
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
    final ProfileData? profile = build3DAvatarUrl(prefs);

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
      context,
      MaterialPageRoute(
        builder: (context) => AvatarCreatorScreen(prefs: prefs, isEditing: true),
      ),
    ).then((shouldReload) async {
      if (shouldReload == true) {
        // ✅ Fetch updated avatar URL
        final ProfileData? updatedProfile = build3DAvatarUrl(prefs);
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
    bool sessionActive = prefs.getBool('gamingSessionActive') ?? false;
    
    // Only restore the session if it is still active.
    if (sessionActive) {
      bool gamingIsPaused = prefs.getBool('gamingIsPaused') ?? false;
      if (gamingIsPaused) {
        int storedElapsed = prefs.getInt('gamingElapsedSeconds') ?? 0;
        setState(() {
          isGaming = true;
          isPaused = true;
          elapsedSeconds = storedElapsed;
        });
        // Do NOT call _startTimer() when paused!
      } else {
        int savedStartTime = prefs.getInt('gamingStartTime') ?? 0;
        int secondsElapsed = DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(savedStartTime))
            .inSeconds;
        setState(() {
          isGaming = true;
          isPaused = false;
          elapsedSeconds = secondsElapsed;
        });
        _startTimer();
      }
    } else {
      // No active session: reset state.
      setState(() {
        isGaming = false;
        isPaused = false;
        elapsedSeconds = 0;
      });
    }
  }

  Future<void> _showTimeLimitDialog() async {
    int selectedHour = 0;
    int selectedMinute = 0;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Set Time Limit ⏳",
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            height: 150,
            child: Row(
              children: [
                // Hours picker.
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 32.0,
                    onSelectedItemChanged: (index) {
                      selectedHour = index;
                    },
                    children: List.generate(
                      24,
                      (index) => Center(
                        child: Text(
                          "$index h",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                // Minutes picker in 15-minute increments.
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 32.0,
                    onSelectedItemChanged: (index) {
                      selectedMinute = index * 15;
                    },
                    children: List.generate(
                      4,
                      (index) => Center(
                        child: Text(
                          "${index * 15} m",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                debugPrint("Time limit set to: $selectedHour h, $selectedMinute m");
                setState(() {
                  _gamingTimeLimit = "$selectedHour h $selectedMinute m";
                });
                Navigator.pop(context);
              },
              child: const Text(
                "Set",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ Start the Timer (Runs in Background)
  void _startTimer() {
    sessionTimer?.cancel();
    sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (mounted) {
        setState(() {
          elapsedSeconds++;
        });

        // Check if a time limit is set.
        if (_gamingTimeLimit != null && _gamingTimeLimit!.isNotEmpty) {
          int limitMinutes = parseGamingTimeLimit(_gamingTimeLimit!);
          int limitSeconds = limitMinutes * 60;
          if (elapsedSeconds >= limitSeconds && !_hasLostHeartForCurrentSession) {
            final prefs = await SharedPreferences.getInstance(); // <-- Obtain prefs here.
            // Lose a heart.
            if (heartsRemaining > 0) {
              setState(() {
                heartsRemaining--;
                _hasLostHeartForCurrentSession = true;
              });
              // Save the updated heartsRemaining.
              await prefs.setInt('heartsRemaining', heartsRemaining);
            }
            // Show alert dialog, then stop the session.
            stopGamingSession();
            await _showTimeLimitExceededDialog();
          }
        }
      }
    });
  }

  Future<void> _showTimeLimitExceededDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Time Limit Exceeded"),
          content: const Text(
            "You went over your allotted gaming time limit and have lost a heart.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // ✅ Start/Stop or Pause/Resume the Gaming Session
  void toggleGamingSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (!isGaming) {
      // 🟢 Start gaming session: set start time and initialize elapsedSeconds to 885 (14:45) for testing.
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt('gamingStartTime', currentTime);
      await prefs.setBool('gamingSessionActive', true);
      await prefs.setBool('gamingIsPaused', false);
      setState(() {
        isGaming = true;
        isPaused = false;
      });
      _startTimer();
    } else {
      // Toggle pause/resume.
      if (!isPaused) {
        // Pause the session.
        sessionTimer?.cancel();
        await prefs.setBool('gamingIsPaused', true);
        await prefs.setInt('gamingElapsedSeconds', elapsedSeconds);
        setState(() {
          isPaused = true;
        });
      } else {
        // Resume the session.
        int storedElapsed = prefs.getInt('gamingElapsedSeconds') ?? elapsedSeconds;
        int currentTime = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt('gamingStartTime', currentTime - storedElapsed * 1000);
        await prefs.setBool('gamingIsPaused', false);
        setState(() {
          isPaused = false;
        });
        _startTimer();
      }
    }
  }

  // ✅ Stop the Gaming Session (separate from pause/resume)
  void stopGamingSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Use elapsedSeconds as the session duration.
    int durationSeconds = elapsedSeconds;
    
    // Format the current date for display.
    DateTime now = DateTime.now();
    String dateStr = "${now.day.toString().padLeft(2, '0')}/"
        "${now.month.toString().padLeft(2, '0')}/"
        "${now.year}";
    
    // Format the duration using your formatTime function.
    String durationStr = formatTime(durationSeconds);
    
    // Create a session record string.
    String sessionRecord = "$dateStr: $durationStr";
    
    // Retrieve the existing gaming sessions list or initialize a new one.
    List<String> sessions = prefs.getStringList('gamingSessions') ?? [];
    sessions.add(sessionRecord);
    await prefs.setStringList('gamingSessions', sessions);
    
    // Mark the session as no longer active.
    await prefs.setBool('gamingSessionActive', false);
    await prefs.remove('gamingStartTime');
    
    sessionTimer?.cancel();
    setState(() {
      isGaming = false;
      isPaused = false;
      elapsedSeconds = 0;
      _hasLostHeartForCurrentSession = false;
    });
  }

  Future<void> showGamingHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = prefs.getStringList('gamingSessions') ?? [];
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Gaming History 🧾"),
          content: sessions.isEmpty
              ? const Text("No past gaming sessions.")
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      return Text(sessions[index]);
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  int parseGamingTimeLimit(String limit) {
  int hours = 0;
  int minutes = 0;
  RegExp hourExp = RegExp(r"(\d+)\s*h");
  RegExp minuteExp = RegExp(r"(\d+)\s*m");
  var hourMatch = hourExp.firstMatch(limit);
  var minuteMatch = minuteExp.firstMatch(limit);
  if (hourMatch != null) {
    hours = int.parse(hourMatch.group(1)!);
  }
  if (minuteMatch != null) {
    minutes = int.parse(minuteMatch.group(1)!);
  }
  return hours * 60 + minutes;
}

  // ✅ Format Time to HH:MM:SS
  String formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;

    List<String> parts = [];

    if (hours > 0) parts.add("$hours" "h");
    if (minutes > 0) parts.add("$minutes" "m");
    if (secs > 0 || parts.isEmpty) parts.add("$secs" "s"); // Always show seconds if no other units

    return parts.join(" ");
  }

  void _showHomeTutorial(BuildContext context) {
    final PageController pageController = PageController();
    const int totalPages = 4;
    int currentPage = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Container(
                height: 325, // adjust the height as needed
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // PageView to segment content into pages
                    Expanded(
                      child: PageView(
                        controller: pageController,
                        onPageChanged: (index) {
                          setState(() {
                            currentPage = index;
                          });
                        },
                        children: [
                          // Page 1: Home Explanation
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "Welcome to the Home Page",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Here is the hub for most of LevelUp's main features! Learn more about them by clicking the arrow below ⬇️",
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          // Page 2: Avatar Customisation
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "Your Avatar",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "View and customise the avatar you made earlier and make them do dances! 🕺",
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          // Page 3: Avatar Level
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "Avatar Level",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "See your current avatar level, this will be increased upon completing missions 🔵",
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          // Page 4: Gaming Sessions and Hearts
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "Gaming Sessions",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Track your gaming sessions, but be careful: if you go over your set limit, you'll lose a heart! 💔\n\n"
                                "Hearts can be restored upon level up! ⬆️",
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Navigation row with white arrow icons and page indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: currentPage > 0
                              ? () {
                                  setState(() {
                                    currentPage--;
                                  });
                                  pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              : null,
                        ),
                        Text(
                          "${currentPage + 1}/$totalPages",
                          style: const TextStyle(color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward, color: Colors.white),
                          onPressed: currentPage < totalPages - 1
                              ? () {
                                  setState(() {
                                    currentPage++;
                                  });
                                  pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              : null,
                        ),
                      ],
                    ),
                    // "Got it!" button to dismiss the dialog
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Got it!"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Welcome back, ${widget.name}!",
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: IconButton(
              icon: const Icon(Icons.help_center_outlined, color: Colors.white),
              onPressed: () => _showHomeTutorial(context),
            ),
          ),
        ],
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double progressValue = _xp / getXpThresholdForLevel(_level);
                        double filledWidth = constraints.maxWidth * progressValue;
                        // Format percentage value.
                        int percent = (progressValue * 100).toInt();
                        return Stack(
                          children: [
                            // Background XP Bar.
                            Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            // Conditionally render the filled progress bar.
                            progressValue > 0
                                ? AnimatedContainer(
                                    duration: const Duration(milliseconds: 1000),
                                    width: filledWidth,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.cyan,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            // Conditionally position the percentage text.
                            progressValue > 0
                                ? Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: filledWidth,
                                      alignment: Alignment.center,
                                      child: Text(
                                        "$percent%",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                : Positioned.fill(
                                    child: Center(
                                      child: Text(
                                        "$percent%",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        );
                      },
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
              5,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < heartsRemaining ? Colors.red : Colors.grey, // Grey out lost hearts.
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Left Floating Action Button
                  RawMaterialButton(
                    onPressed: () {
                      if (isGaming) {
                        toggleGamingSession(); // Toggle pause/resume
                      } else {
                        showGamingHistory(); // Show gaming history pop-up
                      }
                    },
                    constraints: const BoxConstraints.tightFor(width: 50, height: 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    fillColor: Colors.grey[700],
                    child: Icon(
                      isGaming ? (isPaused ? Icons.play_arrow : Icons.pause) : Icons.history,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Central Gaming Session Button (Larger FAB)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _gamingTimeLimit == null || _gamingTimeLimit!.isEmpty
                            ? "🚫 No gaming time limit set"
                            : "⏳ Gaming time limit: $_gamingTimeLimit",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RawMaterialButton(
                        onPressed: toggleGamingSession,
                        constraints: const BoxConstraints.tightFor(width: 220, height: 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        fillColor: isGaming ? Colors.grey[700] : Colors.green,
                        child: Text(
                          isGaming ? formatTime(elapsedSeconds) : "Start Gaming Session 🎮",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),

                  // Right Floating Action Button
                  RawMaterialButton(
                    onPressed: () {
                      if (isGaming) {
                        stopGamingSession(); // Stop session
                      } else {
                        _showTimeLimitDialog(); // Open time limit settings
                      }
                    },
                    constraints: const BoxConstraints.tightFor(width: 50, height: 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    fillColor: Colors.grey[700],
                    child: Icon(
                      isGaming ? Icons.stop : Icons.settings,
                      color: isGaming ? Colors.red : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}