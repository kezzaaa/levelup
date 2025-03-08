// ignore_for_file: library_private_types_in_public_api

// Packages
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Files
import 'userutils.dart';

// Missions Screen
class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  _MissionsScreenState createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  List<Map<String, dynamic>> _allMissions = []; // Store ALL missions
  final List<Map<String, dynamic>> _systemMissions = []; // Store only active missions
  final List<Map<String, dynamic>> _userMissions = [];

  int _dailyResetTime = 0;
  int _weeklyResetTime = 0;
  int _monthlyResetTime = 0;

  String _userFilter = '';
  String _systemFilter = '';
  int _refreshTokens = 99;

  final ScrollController _userScrollController = ScrollController();

  late Timer _countdownTimer;

  @override
  void initState() {
    super.initState();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!mounted) return;

        final now = DateTime.now().millisecondsSinceEpoch;

        if (now >= _dailyResetTime) {
            debugPrint("🔄 Daily Missions Reset Triggered");
            _resetMissions('daily');
            _dailyResetTime = now + Duration(days: 1).inMilliseconds; // Reset for next day
            await _loadMissionTimers(); // Save the new reset time
        }
        if (now >= _weeklyResetTime) {
            debugPrint("🔄 Weekly Missions Reset Triggered");
            _resetMissions('weekly');
            _weeklyResetTime = now + Duration(days: 7).inMilliseconds; // Reset for next week
            await _loadMissionTimers();
        }
        if (now >= _monthlyResetTime) {
            debugPrint("🔄 Monthly Missions Reset Triggered");
            _resetMissions('monthly');
            _monthlyResetTime = now + Duration(days: DateTime(now).month == 2 ? 28 : 30).inMilliseconds; // Auto-detect month length
            await _loadMissionTimers();
        }

        setState(() {}); // Update countdown every second
    });

    _checkFirstTimeUser();

    // ✅ Load missions first, then create if necessary
    _loadMissions().then((_) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // ✅ Load saved filters, if available
      _userFilter = prefs.getString('userFilter') ?? 'daily';
      _systemFilter = prefs.getString('systemFilter') ?? 'daily';

      List<String>? savedSystemMissions = prefs.getStringList('activeSystemMissions');
      if (savedSystemMissions == null || savedSystemMissions.isEmpty) {
          debugPrint("🛑 No active system missions found, creating new ones...");
          _createMissions("daily", 3);
          _createMissions("weekly", 3);
          _createMissions("monthly", 3);
      }

      setState(() {}); // ✅ Update UI with loaded filters
    });

    _loadMissionTimers();
    _loadRefreshTokens();
  }

  @override
  void dispose() {
    _saveActiveMissions();
    _countdownTimer.cancel();
    super.dispose();
  }

  // ✅ Function to check if user has seen mission tutorial before
  Future<void> _checkFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenTutorial = prefs.getBool('hasSeenMissionTutorial') ?? false;

    if (!hasSeenTutorial) {
      // ✅ Show tutorial pop-up
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showMissionTutorialTip(context);
      });

      // ✅ Mark tutorial as seen
      await prefs.setBool('hasSeenMissionTutorial', true);
    }
  }

  Future<List<Map<String, dynamic>>> _createMissions(String type, int count,
      {bool clearExisting = true, bool addToList = true, List<String> excludeNames = const []}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get user-selected focuses from SharedPreferences
    List<String> selectedAreas = prefs.getStringList('userFocuses') ?? [];

    // Normalize selected areas to match lowercase skillsector values
    List<String> normalizedSelectedAreas = selectedAreas
        .map((area) => area.replaceAll(RegExp(r'\[.*?\]'), '').trim().toLowerCase())
        .toList();

    // Optionally remove old missions of the same type
    if (clearExisting) {
      setState(() {
        _systemMissions.removeWhere((m) => m['type'] == type);
      });
    }

    // Filter available missions:
    // - mission must meet the completed/repeatable criteria
    // - match the mission type and selected areas
    // - and not be in the excludeNames list (based on their 'title' field)
    List<Map<String, dynamic>> availableMissions = _allMissions
        .where((m) =>
            ((!m['completed']) || (m['completed'] && m['repeatable'] == true)) &&
            m['type'] == type &&
            normalizedSelectedAreas.contains(m['skillsector']) &&
            !excludeNames.contains(m['title']))
        .toList();

    availableMissions.shuffle();

    // Clone and select exactly 'count' missions
    List<Map<String, dynamic>> selectedMissions = availableMissions
        .take(count)
        .map((mission) => Map<String, dynamic>.from(mission))
        .toList();

    // Assign unique IDs and reset mission state
    for (var mission in selectedMissions) {
      mission['id'] = _generateUniqueId();
      mission['progress'] = 0;
      mission['completed'] = false;
      mission['removing'] = false;
    }

    // Optionally add the new missions to the global list
    if (addToList) {
      setState(() {
        _systemMissions.addAll(selectedMissions);
      });
    }

    return selectedMissions;
  }

  // ✅ Function to generate a unique ID
  int _generateUniqueId() {
      return DateTime.now().millisecondsSinceEpoch * 1000 + Random().nextInt(1000);
  }

  Future<void> _saveActiveMissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // ✅ Save system missions
    List<String> systemMissionsJson = _systemMissions.map((m) => json.encode(m)).toList();
    await prefs.setStringList('activeSystemMissions', systemMissionsJson);

    // ✅ Save user-created missions
    List<String> userMissionsJson = _userMissions.map((m) => json.encode(m)).toList();
    await prefs.setStringList('activeUserMissions', userMissionsJson);

    debugPrint("💾 Saved Active Missions: System(${_systemMissions.length}), User(${_userMissions.length})");
  }

  Future<void> _loadMissions() async {
    try {
        final prefs = await SharedPreferences.getInstance();
        final List<String> completedMissions = prefs.getStringList('completedMissions') ?? [];
        final List<String>? savedSystemMissionsJson = prefs.getStringList('activeSystemMissions');
        final List<String>? savedUserMissionsJson = prefs.getStringList('activeUserMissions');

        final String jsonString = await rootBundle.loadString('assets/missions.json');
        List<dynamic> jsonResponse = json.decode(jsonString);

        debugPrint("📌 Detected ${jsonResponse.length} missions in JSON.");

        List<Map<String, dynamic>> allMissions = jsonResponse.map((mission) {
            String missionTitle = mission['title'];
            int storedProgress = prefs.getInt('progress_$missionTitle') ?? 0;
            bool isCompleted = completedMissions.contains(missionTitle);

            mission['progress'] = storedProgress;
            mission['completed'] = isCompleted;
            mission['id'] = mission.containsKey('id') && mission['id'] != null ? mission['id'] : _generateUniqueId();
            return mission as Map<String, dynamic>;
        }).toList();

        List<Map<String, dynamic>> systemMissions = [];
        if (savedSystemMissionsJson != null && savedSystemMissionsJson.isNotEmpty) {
            systemMissions = savedSystemMissionsJson.map((m) => json.decode(m) as Map<String, dynamic>).toList();
        }

        List<Map<String, dynamic>> userMissions = [];
        if (savedUserMissionsJson != null && savedUserMissionsJson.isNotEmpty) {
            userMissions = savedUserMissionsJson.map((m) => json.decode(m) as Map<String, dynamic>).toList();
        }

        setState(() {
            _allMissions = allMissions;
            _systemMissions.clear();
            _systemMissions.addAll(systemMissions);
            _userMissions.clear();
            _userMissions.addAll(userMissions);
        });

        // 🔄 Only create new missions if no saved missions exist
        if (_systemMissions.isEmpty) {
            debugPrint("🛠️ No active system missions found. Creating new ones...");
            await _createMissions("daily", 3);
            await _createMissions("weekly", 3);
            await _createMissions("monthly", 3);
        }

        debugPrint("📌 Active Missions Reloaded: System(${_systemMissions.length}), User(${_userMissions.length})");
    } catch (e) {
        debugPrint("❌ Error loading missions from JSON: $e");
    }
  }

  Future<void> _loadMissionTimers() async {
    final prefs = await SharedPreferences.getInstance();
    int now = DateTime.now().millisecondsSinceEpoch;

    _dailyResetTime = prefs.getInt('dailyResetTime') ?? _getNextResetTime('daily');
    _weeklyResetTime = prefs.getInt('weeklyResetTime') ?? _getNextResetTime('weekly');
    _monthlyResetTime = prefs.getInt('monthlyResetTime') ?? _getNextResetTime('monthly');

    if (now >= _dailyResetTime) {
      debugPrint("🔄 Daily Missions Reset Triggered");
      _resetMissions('daily');
    }
    if (now >= _weeklyResetTime) {
      debugPrint("🔄 Weekly Missions Reset Triggered");
      _resetMissions('weekly');
    }
    if (now >= _monthlyResetTime) {
      debugPrint("🔄 Monthly Missions Reset Triggered");
      _resetMissions('monthly');
    }
  }

  // Calculate next reset time based on type
  int _getNextResetTime(String type) {
    DateTime now = DateTime.now();
    DateTime nextReset;

    if (type == 'daily') {
      nextReset = now.add(Duration(days: 1));
    } else if (type == 'weekly') {
      nextReset = now.add(Duration(days: 7 - now.weekday)); // Next Monday
    } else if (type == 'monthly') {
      nextReset = DateTime(now.year, now.month + 1, 1, 0, 0, 0); // First day of next month
    } else {
      return now.millisecondsSinceEpoch;
    }

    return nextReset.millisecondsSinceEpoch;
  }

  void _resetMissions(String type) async {
    final prefs = await SharedPreferences.getInstance();

    // 🛠️ Step 1: Remove old missions for this type
    setState(() {
        _systemMissions.removeWhere((m) => m['type'] == type);
    });

    await Future.delayed(Duration(milliseconds: 100)); // Let Flutter process state update

    // 🆕 Step 2: Create new missions for this type
    List<Map<String, dynamic>> newMissions = await _createMissions(type, 3, clearExisting: false);

    if (newMissions.isEmpty) {
        debugPrint("⚠️ No new missions available for $type!");
        return;
    }

    // ✅ Step 3: Ensure unique IDs and add them to the mission list
    Set<int> existingIds = _systemMissions.map((m) => m['id'] as int).toSet();
    newMissions.removeWhere((m) => existingIds.contains(m['id']));

    setState(() {
        _systemMissions.addAll(newMissions);
    });

    // ✅ Step 4: Save updated mission list
    await prefs.setStringList(
        'activeSystemMissions',
        _systemMissions.map((m) => json.encode(m)).toList(),
    );

    // ✅ Step 5: Update reset time
    int newResetTime = _getNextResetTime(type);
    await prefs.setInt('${type}ResetTime', newResetTime);

    debugPrint("✅ $type missions reset! New reset time: $newResetTime");
  }

  // ✅ Load refresh tokens from SharedPreferences
  Future<void> _loadRefreshTokens() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _refreshTokens = prefs.getInt('refreshTokens') ?? 3; // Default to 3 if not set
    });
  }

  // ✅ Save refresh token count
  Future<void> _updateRefreshTokens(int amount) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _refreshTokens = (_refreshTokens + amount).clamp(0, 99); // Prevents negative values
    });
    await prefs.setInt('refreshTokens', _refreshTokens);
  }

  // ✅ Function to show missions tutorial pop-up
  void _showMissionTutorialTip(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // ✅ Rounded corners
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF212121), // ✅ Dialog background
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 1), // ✅ White border
            ),
            padding: const EdgeInsets.all(16), // ✅ Adds spacing inside the box
            child: Column(
              mainAxisSize: MainAxisSize.min, // ✅ Ensures dialog wraps content
              children: [
                const Text(
                  "How to Use Missions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "• Complete daily, weekly, and monthly missions to earn rewards.\n"
                  "• Tap a mission to expand details and track progress.\n"
                  "• Swipe left on user-created missions to delete them.\n"
                  "• Press the '+ Add' button to create custom missions!\n\n"
                  "Start your journey now!",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
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
  }

  // ✅ Function to add new mission
  void _addMission() {
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    int selectedDifficulty = 1;
    int selectedSegments = 1;
    String selectedType = 'daily'; // Default to daily
    String selectedSkillSector = 'fitness'; // Default skill sector
    List<String> skillSectors = [
      'fitness',
      'diet',
      'mindfulness',
      'productivity',
      'creativity'
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: const Text('Add New Mission', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title Input
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Mission Title"),
              ),
              // Description Input
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Mission Description"),
              ),
              const SizedBox(height: 10),
              // Mission Type Dropdown
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF1C1C1C),
                value: selectedType,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Mission Type"),
                items: ['daily', 'weekly', 'monthly'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  selectedType = value!;
                },
              ),
              // Skill Sector Dropdown
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF1C1C1C),
                value: selectedSkillSector,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Skill Sector"),
                items: skillSectors.map((sector) {
                  return DropdownMenuItem(
                    value: sector,
                    child: Text(sector.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedSkillSector = value!;
                },
              ),
              // Difficulty Selector
              DropdownButtonFormField<int>(
                dropdownColor: const Color(0xFF1C1C1C),
                value: selectedDifficulty,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Difficulty"),
                items: List.generate(3, (i) => i + 1).map((diff) {
                  return DropdownMenuItem(value: diff, child: Text("⭐" * diff));
                }).toList(),
                onChanged: (value) {
                  selectedDifficulty = value!;
                },
              ),
              // Segments Selector (Max 10)
              DropdownButtonFormField<int>(
                dropdownColor: const Color(0xFF1C1C1C),
                value: selectedSegments,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Segments"),
                items: List.generate(10, (i) => i + 1).map((seg) {
                  return DropdownMenuItem(value: seg, child: Text("$seg"));
                }).toList(),
                onChanged: (value) {
                  selectedSegments = value!;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  setState(() {
                    _userMissions.add({
                      "id": DateTime.now().millisecondsSinceEpoch + Random().nextInt(1000),
                      'title': titleController.text,
                      'description': descriptionController.text,
                      'type': selectedType,
                      'skillsector': selectedSkillSector, // Added skillsector
                      'difficulty': selectedDifficulty,
                      'segments': selectedSegments,
                      'progress': 0,
                      'completed': false,
                      'removing': false,
                      'expanded': false,
                    });
                  });
                  debugPrint("📌 New Mission Added: ${_userMissions.last}");
                }
                Navigator.pop(context);
              },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _interactedWithMission(int index, bool isUserMission) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> completedMissions = prefs.getStringList('completedMissions') ?? [];

    if (isUserMission) {
        String missionTitle = _userMissions[index]['title'];
        int segments = _userMissions[index]['segments'] ?? 1;
        int currentProgress = _userMissions[index]['progress'] ?? 0;

        debugPrint("🟡 Interacting with User Mission: $missionTitle (Current Progress: $currentProgress / $segments)");

        if (currentProgress < segments) {
            setState(() {
                _userMissions[index]['progress']++;  // ✅ Increment progress
            });

            await prefs.setInt('progress_$missionTitle', _userMissions[index]['progress']);
        }

        // ✅ Delay marking as completed so the UI updates properly
        if (_userMissions[index]['progress'] >= segments) {
            Future.delayed(const Duration(milliseconds: 0), () { // ✅ Short delay to allow UI to update
                if (mounted) {
                    setState(() {
                        _userMissions[index]['completed'] = true;
                        _userMissions[index]['removing'] = true;
                    });

                    debugPrint("✅ User Mission Completed: $missionTitle");
                }
            });

            // ✅ Ensure full fade-out before removing
            Future.delayed(const Duration(milliseconds: 1000), () { // 🔥 Forces full 1.5s fade-out
                if (mounted && index < _userMissions.length) {
                    setState(() {
                        _userMissions.removeAt(index);
                    });
                }
            });
        }

    } else {
        String missionTitle = _systemMissions[index]['title'];
        int segments = _systemMissions[index]['segments'] ?? 1;
        int currentProgress = _systemMissions[index]['progress'] ?? 0;

        debugPrint("🟡 Interacting with System Mission: $missionTitle (Current Progress: $currentProgress / $segments)");

        if (currentProgress < segments) {
            setState(() {
                _systemMissions[index]['progress']++;  // ✅ Increment progress
            });

            await prefs.setInt('progress_$missionTitle', _systemMissions[index]['progress']);
        }

        // ✅ Delay marking as completed so the UI updates properly
        if (_systemMissions[index]['progress'] >= segments) {
            Future.delayed(const Duration(milliseconds: 0), () { // ✅ Short delay to allow UI to update
                if (mounted) {
                    setState(() {
                        _systemMissions[index]['completed'] = true;
                        _systemMissions[index]['removing'] = true;
                    });

                    debugPrint("✅ System Mission Completed: $missionTitle");

                    if (!completedMissions.contains(missionTitle)) {
                        completedMissions.add(missionTitle);
                        prefs.setStringList('completedMissions', completedMissions);
                    }

                    int xpReward = _systemMissions[index]['experience'];
                    completeMission(xpReward);
                }
            });

            // ✅ Ensure full fade-out before removing
            Future.delayed(const Duration(milliseconds: 1000), () { // 🔥 Forces full 1.5s fade-out
                if (mounted && index < _systemMissions.length) {
                    setState(() {
                        _systemMissions.removeAt(index);
                    });
                }
            });
        }
    }
  }

  // ✅ Show confirmation popup before refreshing a mission
  Future<bool?> _showRefreshConfirmation(int index) async {
    if (_refreshTokens <= 0) {
      return showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("No Refresh Tokens Left"),
            content: const Text(
              "You're out of refresh tokens! Complete missions or wait for the daily reset to earn more.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }

    // ✅ Show Confirmation Dialog if User Has Tokens
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Use a Refresh Token?"),
          content: const Text(
            "Do you want to use a refresh token to replace this mission with a new one?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // ❌ Cancel
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true), // ✅ Confirm Refresh
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  // ✅ Refresh a mission
  void _deductRefreshToken(int index) async {
    if (_refreshTokens <= 0) return; // Stop if no tokens left
    await _updateRefreshTokens(-1); // Deduct a refresh token
  }

  // ✅ Complete a mission and reward XP
  void completeMission(int xpReward) async {
    final prefs = await SharedPreferences.getInstance();
    
    int currentXP = prefs.getInt('userXP') ?? 0;
    int currentLevel = prefs.getInt('userLevel') ?? 1;

    currentXP += xpReward;
    int xpThreshold = getXpThresholdForLevel(currentLevel);

    while (currentXP >= xpThreshold) {
      currentXP -= xpThreshold;
      currentLevel++;
      xpThreshold = getXpThresholdForLevel(currentLevel);
    }

    await prefs.setInt('userXP', currentXP);
    await prefs.setInt('userLevel', currentLevel);

    // ✅ Notify `home.dart` to update XP bar
    // ignore: use_build_context_synchronously
    if (Navigator.canPop(context)) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context, xpReward); // Send XP reward back to HomeScreen
    }
  }

  Future<void> _setUserFilter(String filter) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userFilter', filter); // ✅ Save filter selection
    setState(() {
        _userFilter = filter;
    });
  }

  Future<void> _setSystemFilter(String filter) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('systemFilter', filter); // ✅ Save filter selection
      setState(() {
          _systemFilter = filter;
      });
  }

  Widget _buildFilterButton(String text, String type, bool isUserFilter, Future<void> Function(String) onFilterChange) {
    bool isActive = isUserFilter ? (_userFilter == type) : (_systemFilter == type);

    return SizedBox(
      width: 60,
      height: 25,
      child: TextButton(
        onPressed: () async {
          await onFilterChange(type); // ✅ Calls the correct filter function
          setState(() {}); // ✅ Triggers UI update
        },
        style: TextButton.styleFrom(
          backgroundColor: isActive ? Colors.white : Colors.transparent,
          foregroundColor: isActive ? Colors.black : Colors.white,
          side: const BorderSide(color: Colors.white),
          padding: const EdgeInsets.all(2),
        ),
        child: Text(text, style: const TextStyle(fontSize: 10)),
      ),
    );
  }

  Widget _buildMissionTimer(String type) {
    int remainingTime = _getRemainingTime(type);
    String formattedTime = _formatCountdown(remainingTime);

    return Text(
      "⏳ $formattedTime",
      style: TextStyle(fontSize: 12, color: Colors.white),
    );
  }

  // Get remaining time for countdown
  int _getRemainingTime(String type) {
    int now = DateTime.now().millisecondsSinceEpoch;
    if (type == 'daily') return _dailyResetTime - now;
    if (type == 'weekly') return _weeklyResetTime - now;
    if (type == 'monthly') return _monthlyResetTime - now;
    return 0;
  }

  // Format milliseconds to HH:MM:SS
  String _formatCountdown(int millis) {
    if (millis <= 0) return "00:00:00";
    Duration duration = Duration(milliseconds: millis);
    String hours = duration.inHours.toString().padLeft(2, '0');
    String minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  void _showCompletedMissions(BuildContext context) {
    List<Map<String, dynamic>> completedMissions = [
      ..._userMissions.where((m) => m['completed']),
      ..._systemMissions.where((m) => m['completed']),
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Completed Missions'),
          content: completedMissions.isEmpty
              ? const Text("No missions completed yet. Keep going!")
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: completedMissions.length,
                    itemBuilder: (context, index) {
                      final mission = completedMissions[index];
                      return ListTile(
                        title: Text(mission['title']),
                        subtitle: Text(mission['description']),
                        leading: const Icon(Icons.check_circle, color: Colors.green), // Completed icon
                      );
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

  Widget _buildMissionTile(
    Map<String, dynamic> mission,
    int index,
    bool isUserMission,
  ) {
    int xp = isUserMission
        ? 0
        : (mission.containsKey('experience') ? mission['experience'] : 0);
    int skillPoints = isUserMission
        ? 0
        : (mission.containsKey('skillpoints') ? mission['skillpoints'] : 0);
    String skillSector = mission.containsKey('skillsector') 
        ? mission['skillsector'] 
        : '';

    int segments = mission.containsKey('segments') ? mission['segments'] : 1;
    int progress = mission.containsKey('progress') ? mission['progress'] : 0;
    bool isMultiStep = segments > 1;
    bool isCompleted = mission['completed'];

    // Define skill sector colors
    Map<String, Color> skillColors = {
      'fitness': Colors.red,
      'finances': Colors.green,
      'diet': Colors.blue,
      'productivity': Colors.orange,
      'creativity': Colors.purple,
      'mindfulness': Colors.yellow,
      'education': Colors.indigo,
      'sleep': Colors.grey,
      'hobbies': Colors.cyan,
      'social': Colors.pink,
      'career': Colors.brown,
      'confidence': Colors.lime,
      'relationships': Colors.amber,
      'dating': Colors.teal,
      'screentime': Colors.blueGrey,
      'skills': Colors.deepOrange,
    };
    Color skillColor = skillColors[skillSector] ?? Colors.grey;

    return Dismissible(
      key: ValueKey(mission['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        color: isUserMission ? Colors.red : Colors.green,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: isUserMission
            ? const Icon(Icons.delete_sweep_rounded, color: Colors.white)
            : const Icon(Icons.refresh, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (isUserMission) {
          return Future.value(true); // Allow normal deletion of user missions
        } else {
          return _showRefreshConfirmation(index); // Ask the user first
        }
      },
      onDismissed: (_) async {
        if (isUserMission) {
          // For user missions, just remove immediately.
          setState(() {
            _userMissions.removeAt(index);
          });
        } else {
          // Capture the dismissed mission's type and name.
          String type = _systemMissions[index]['type'];
          String dismissedName = _systemMissions[index]['title'];

          // Immediately remove the dismissed mission.
          setState(() {
            _systemMissions.removeAt(index);
          });

          // Deduct refresh token or perform any side effects.
          _deductRefreshToken(index);

          // Build exclusion list: include names of all currently active missions 
          // and the dismissed mission.
          List<String> activeMissionNames =
          _systemMissions.map((m) => m['title'] as String).toList();
          activeMissionNames.add(dismissedName);

          // Create a new mission excluding those names.
          List<Map<String, dynamic>> newMissions = await _createMissions(
            type,
            1,
            clearExisting: false,
            addToList: false,
            excludeNames: activeMissionNames,
          );

          if (mounted && newMissions.isNotEmpty) {
            // Insert the new mission at the same index.
            setState(() {
              _systemMissions.insert(index, newMissions.first);
            });
            debugPrint(
                "🆕 Inserted new mission at index $index with ID: ${newMissions.first['id']}");
          } else {
            debugPrint(
                "⚠️ No new mission found for type: $type that isn't already active. The list now has one less item.");
          }
        }
      },
      child: AnimatedOpacity(
        key: ValueKey(mission['id']),
        duration: const Duration(milliseconds: 1000),
        opacity: mission['completed'] ? 0.0 : 1.0,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 8), // Spacing between tiles
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center, // Vertically center items
                children: [
                  // Colored label on the left
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 30),
                    decoration: BoxDecoration(
                      color: skillColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Icon or Checkbox
                  isMultiStep
                      ? IconButton(
                          icon: Icon(
                            mission['completed']
                                ? Icons.check_circle
                                : Icons.add_circle_outline_rounded,
                            color: mission['completed'] ? Colors.green : Colors.white,
                            size: 30,
                          ),
                          onPressed: () {
                            if (mission['progress'] < mission['segments']) {
                              _interactedWithMission(index, isUserMission);
                            }
                          },
                        )
                      : Checkbox(
                          value: isCompleted,
                          onChanged: (_) => _interactedWithMission(index, isUserMission),
                        ),
                  const SizedBox(width: 10),

                  // Main text & progress bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mission title
                        Text(
                          mission['title'],
                          style: TextStyle(
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),

                        // Multi-step progress bar (if applicable)
                        if (isMultiStep)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: List.generate(segments, (i) {
                                final bool isFilled = i < progress;
                                return Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    height: 7.5,
                                    decoration: BoxDecoration(
                                      color: isFilled ? Colors.green : Colors.grey[700],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Expand/collapse arrow (white)
                  IconButton(
                    icon: Icon(
                      mission['expanded'] ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        mission['expanded'] = !mission['expanded'];
                      });
                    },
                  ),
                ],
              ),
            ),
            // 🔽 EXPANDED CONTENT (Only visible when expanded)
            if (mission['expanded'])
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.symmetric(
                    horizontal: 0, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ⭐ Difficulty Rating System (Now works for both User & System Missions)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(3, (i) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.star_outline_rounded,
                                  color: Colors.white,
                                  size: 44,
                                ),
                                Icon(
                                  i < (mission['difficulty'] ?? 0)
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: i < (mission['difficulty'] ?? 0)
                                      ? const Color.fromARGB(
                                          255, 239, 215, 0)
                                      : Colors.transparent,
                                  size: 35,
                                ),
                              ],
                            );
                          }),
                        ),
                        if (!isUserMission)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // XP Indicator (Blue Circle)
                              Container(
                                width: 33, // Fixed width
                                height: 33, // Fixed height
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.cyan,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                                child: Text(
                                  "$xp",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5), // Spacing between XP and triangle
                              // 🔺 Triangle and Number Wrapped in Stack
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Move triangle left
                                  Transform.translate(
                                    offset: const Offset(0, 2),
                                    child: CustomPaint(
                                      size: const Size(40, 40),
                                      painter: RoundedTrianglePainter(
                                        fillColor: skillColor,
                                        borderColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  // Skill points number
                                  Text(
                                    "$skillPoints",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      mission['description'],
                      style: const TextStyle(
                          fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        leading: IconButton(
          icon: const Icon(Icons.help_outline), // Question mark icon
          tooltip: "Mission Tutorial",
          onPressed: () => _showMissionTutorialTip(context),
        ),
        title: Center(
          child: Text(
            "🔄 $_refreshTokens", // Display refresh tokens in the center
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events), // Trophy icon
            tooltip: "View Completed Missions",
            onPressed: () => _showCompletedMissions(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LevelUp Missions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distributes elements evenly
              children: [
                Row(
                  children: [
                    _buildFilterButton('Daily', 'daily', false, _setSystemFilter),
                    const SizedBox(width: 8),
                    _buildFilterButton('Weekly', 'weekly', false, _setSystemFilter),
                    const SizedBox(width: 8),
                    _buildFilterButton('Monthly', 'monthly', false, _setSystemFilter),
                  ],
                ),
                const Spacer(), // Pushes the timer to the right
                _buildMissionTimer(_systemFilter), // Timer aligned to the right
              ],
            ),
            const SizedBox(height: 20),  
            Column(
              children: _systemMissions.where((m) => m['type'] == _systemFilter).isEmpty
                  ? [
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          "No missions currently available, come back later.",
                          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      ),
                    ]
                  : _systemMissions.where((m) => m['type'] == _systemFilter).map((mission) {
                      return Container(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildMissionTile(mission, _systemMissions.indexOf(mission), false),
                      );
                    }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Your Missions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildFilterButton('Daily', 'daily', true, _setUserFilter),
                const SizedBox(width: 8),
                _buildFilterButton('Weekly', 'weekly', true, _setUserFilter),
                const SizedBox(width: 8),
                _buildFilterButton('Monthly', 'monthly', true, _setUserFilter),
              ],
            ),
            const SizedBox(height: 20),  
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                controller: _userScrollController,
                child: _userMissions.where((m) => m['type'] == _userFilter).isEmpty
                    ? ListView(
                        controller: _userScrollController,
                        children: const [
                          SizedBox(height: 10),
                          Center(
                            child: Text(
                              "Out of missions? Make your own!",
                              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
                            ),
                          ),
                        ],
                      )
                  : ListView.builder(
                  controller: _userScrollController,
                  itemCount:
                      _userMissions.where((m) => m['type'] == _userFilter).length,
                  itemBuilder: (context, index) {
                    final filteredMissions =
                        _userMissions.where((m) => m['type'] == _userFilter).toList();
                    if (index >= filteredMissions.length) return const SizedBox();

                    final mission = filteredMissions[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: _buildMissionTile(mission, index, true),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: _addMission, // Calls _addMission() when tapped
        backgroundColor: Colors.green, // Green background
        child: const Icon(
          Icons.add, // White plus icon
          color: Colors.white,
          ),
        ),
    );
  }
}
  
class RoundedTrianglePainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final double cornerRadius;

  RoundedTrianglePainter({
    required this.fillColor,
    this.borderColor = Colors.white,
    this.borderWidth = 4.0, // Outline thickness
    this.cornerRadius = 4.0, // Adjust this for roundness
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeJoin = StrokeJoin.round;

    final Paint fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    // 🔺 Equilateral Triangle Size Calculation
    double baseWidth = size.width * 1;
    double height = (sqrt(3) / 2) * baseWidth;

    // Define triangle points
    Offset topPoint = Offset(baseWidth / 2, 0);
    Offset bottomLeft = Offset(0, height);
    Offset bottomRight = Offset(baseWidth, height);

    Path trianglePath = Path()
      ..moveTo(topPoint.dx, topPoint.dy + cornerRadius)
      ..lineTo(bottomRight.dx - cornerRadius, bottomRight.dy - cornerRadius)
      ..lineTo(bottomLeft.dx + cornerRadius, bottomLeft.dy - cornerRadius)
      ..close();

    // 🔲 **Draw White Border First**
    canvas.drawPath(trianglePath, borderPaint);

    // 🔺 **Draw Filled Triangle Slightly Smaller**
    Path fillTrianglePath = Path()
      ..moveTo(topPoint.dx, topPoint.dy + borderWidth) // Shift down for padding
      ..lineTo(bottomRight.dx - borderWidth, bottomRight.dy - borderWidth)
      ..lineTo(bottomLeft.dx + borderWidth, bottomLeft.dy - borderWidth)
      ..close();

    canvas.drawPath(fillTrianglePath, fillPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}