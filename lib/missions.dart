// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

// Packages
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:levelup/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Files
import 'userutils.dart';
import 'completedmissions.dart';

extension StringCasingExtension on String {
  String get toTitleCase {
    if (isEmpty) return this;
    return split(" ")
        .map((word) => word.isNotEmpty
            ? "${word[0].toUpperCase()}${word.substring(1).toLowerCase()}"
            : "")
        .join(" ");
  }
}

enum SortOrder { none, asc, desc }
SortOrder _userSortOrder = SortOrder.none;

// Missions Screen
class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  _MissionsScreenState createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> with WidgetsBindingObserver, RouteAware {
  List<Map<String, dynamic>> _allMissions = [];
  final List<Map<String, dynamic>> _systemMissions = [];
  final List<Map<String, dynamic>> _userMissions = [];
  List<Map<String, dynamic>> missionAchievements = [];

  int _dailyResetTime = 0;
  int _weeklyResetTime = 0;
  int _monthlyResetTime = 0;

  String _userFilter = '';
  String _systemFilter = '';
  int _refreshTokens = 3;

  late Timer _countdownTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _checkFirstTimeUser();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!mounted) return;

        final now = DateTime.now().millisecondsSinceEpoch;

        if (now >= _dailyResetTime) {
          debugPrint("🔄 Daily Missions Reset Triggered");
          _resetMissions('daily');
          _dailyResetTime = _getNextResetTime('daily');
          await _loadMissionTimers();
        }
        if (now >= _weeklyResetTime) {
          debugPrint("🔄 Weekly Missions Reset Triggered");
          _resetMissions('weekly');
          _weeklyResetTime = _getNextResetTime('weekly');
          await _loadMissionTimers();
        }
        if (now >= _monthlyResetTime) {
          debugPrint("🔄 Monthly Missions Reset Triggered");
          _resetMissions('monthly');
          _monthlyResetTime = _getNextResetTime('monthly');
          await _loadMissionTimers();
        }

        setState(() {}); // Update countdown every second
    });

    // Load missions first, then create if necessary
    _loadMissions().then((_) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Load saved filters, if available
      _userFilter = prefs.getString('userFilter') ?? 'daily';
      _systemFilter = prefs.getString('systemFilter') ?? 'daily';

      List<String>? savedSystemMissions = prefs.getStringList('activeSystemMissions');
      if (savedSystemMissions == null || savedSystemMissions.isEmpty) {
          debugPrint("🛑 No active system missions found, creating new ones...");
          _createMissions("daily", 3);
          _createMissions("weekly", 3);
          _createMissions("monthly", 3);
      }

      setState(() {}); // Update UI with loaded filters
    });

    _loadMissionTimers();
    _loadRefreshTokens();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndResetMissions();
    }
  }

  @override
  void didPopNext() {
    _checkAndResetMissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _saveActiveMissions();
    _countdownTimer.cancel();
    super.dispose();
  }

  Future<void> _checkAndResetMissions() async {
    final now = DateTime.now();
    final newDailyResetTime = _getNextResetTime('daily');
    final newWeeklyResetTime = _getNextResetTime('weekly');
    final newMonthlyResetTime = _getNextResetTime('monthly');

    final prefs = await SharedPreferences.getInstance();

    if (now.millisecondsSinceEpoch >= newDailyResetTime) {
      debugPrint("🔄 Daily Missions Reset Triggered on resume");
      _resetMissions('daily');
      await prefs.setInt('dailyResetTime', newDailyResetTime);
    }
    if (now.millisecondsSinceEpoch >= newWeeklyResetTime) {
      debugPrint("🔄 Weekly Missions Reset Triggered on resume");
      _resetMissions('weekly');
      await prefs.setInt('weeklyResetTime', newWeeklyResetTime);
    }
    if (now.millisecondsSinceEpoch >= newMonthlyResetTime) {
      debugPrint("🔄 Monthly Missions Reset Triggered on resume");
      _resetMissions('monthly');
      await prefs.setInt('monthlyResetTime', newMonthlyResetTime);
    }

    setState(() {
      _dailyResetTime = newDailyResetTime;
      _weeklyResetTime = newWeeklyResetTime;
      _monthlyResetTime = newMonthlyResetTime;
    });
  }

  // Function to check if user has seen mission tutorial before
  Future<void> _checkFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenTutorial = prefs.getBool('hasSeenMissionTutorial') ?? false;

    if (!hasSeenTutorial) {
      // Show tutorial pop-up
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showMissionsTutorial(context);
      });

      // Mark tutorial as seen
      await prefs.setBool('hasSeenMissionTutorial', true);
    }
  }

  Future<List<Map<String, dynamic>>> _createMissions(String type, int count,
      {bool clearExisting = true, bool addToList = true, List<String> excludeNames = const []}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get user-selected focuses and preferences from SharedPreferences
    List<String> selectedAreas = prefs.getStringList('userFocuses') ?? [];
    List<String> userPreferences = prefs.getStringList('userPreferences') ?? [];

    // Normalize selected areas to match lowercase skillsector values
    List<String> normalizedSelectedAreas = selectedAreas
        .map((area) {
          final parts = area.split(RegExp(r'\s+'));
          return parts.length > 1 ? parts.sublist(1).join(' ').trim().toLowerCase() : area.trim().toLowerCase();
        })
        .toList();

    // Optionally remove old missions of the same type
    if (clearExisting) {
      setState(() {
        _systemMissions.removeWhere((m) => m['type'] == type);
      });
    }

    // Filter available missions:
    List<Map<String, dynamic>> availableMissions = _allMissions.where((m) {
      bool meetsCriteria = ((!m['completed']) || (m['completed'] && m['repeatable'] == true)) &&
          m['type'] == type &&
          normalizedSelectedAreas.contains(m['skillsector']) &&
          !excludeNames.contains(m['title']);

      // Check if the mission has a 'tags' property and is not empty
      if (m.containsKey('tags') && m['tags'] is List && m['tags'].isNotEmpty) {
        List<String> missionTags = List<String>.from(m['tags']); // Convert to List<String>

        // Ensure at least one mission tag matches a user preference
        bool tagMatch = missionTags.any((tag) => userPreferences.contains(tag));
        if (!tagMatch) return false; // Exclude mission if no matching tags
      }

      // Check if the mission has an 'exclusions' property
      if (m.containsKey('exclusions') && m['exclusions'] is List && m['exclusions'].isNotEmpty) {
        List<String> missionExclusions = List<String>.from(m['exclusions']); // Convert to List<String>

        // If any exclusion matches a user preference, filter the mission out
        bool hasExclusionConflict = missionExclusions.any((exclusion) => userPreferences.contains(exclusion));
        if (hasExclusionConflict) return false;
      }

      return meetsCriteria;
    }).toList();

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

  // Function to generate a unique ID
  int _generateUniqueId() {
      return DateTime.now().millisecondsSinceEpoch * 1000 + Random().nextInt(1000);
  }

  Future<void> _saveActiveMissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Save system missions
    List<String> systemMissionsJson = _systemMissions.map((m) => json.encode(m)).toList();
    await prefs.setStringList('activeSystemMissions', systemMissionsJson);

    // Save user-created missions
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

        // Only create new missions if no saved missions exist
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

    debugPrint("Loaded reset times: now=$now, daily=$_dailyResetTime, weekly=$_weeklyResetTime, monthly=$_monthlyResetTime");

    if (now >= _dailyResetTime) {
      debugPrint("🔄 Daily Missions Reset Triggered in _loadMissionTimers");
      _resetMissions('daily');
    }
    if (now >= _weeklyResetTime) {
      debugPrint("🔄 Weekly Missions Reset Triggered in _loadMissionTimers");
      _resetMissions('weekly');
    }
    if (now >= _monthlyResetTime) {
      debugPrint("🔄 Monthly Missions Reset Triggered in _loadMissionTimers");
      _resetMissions('monthly');
    }
  }

  // Calculate next reset time based on type
  int _getNextResetTime(String type) {
    DateTime now = DateTime.now();
    DateTime nextReset;
    
    if (type == 'daily') {
      // Set reset to next midnight
      nextReset = DateTime(now.year, now.month, now.day + 1);
    } else if (type == 'weekly') {
      // Calculate next Monday at midnight
      int daysToAdd = (8 - now.weekday) % 7;
      if (daysToAdd == 0) daysToAdd = 7; // ensure it's the next Monday
      nextReset = DateTime(now.year, now.month, now.day).add(Duration(days: daysToAdd));
    } else if (type == 'monthly') {
      // Already fixed: first day of next month at midnight
      nextReset = DateTime(now.year, now.month + 1, 1);
    } else {
      return now.millisecondsSinceEpoch;
    }
    
    return nextReset.millisecondsSinceEpoch;
  }

  void _resetMissions(String type) async {
    final prefs = await SharedPreferences.getInstance();

    // Step 1: Remove old missions for this type
    setState(() {
        _systemMissions.removeWhere((m) => m['type'] == type);
    });

    await Future.delayed(Duration(milliseconds: 100)); // Let Flutter process state update

    // Step 2: Create new missions for this type
    List<Map<String, dynamic>> newMissions = await _createMissions(type, 3, clearExisting: false);

    if (newMissions.isEmpty) {
        debugPrint("⚠️ No new missions available for $type!");
        return;
    }

    // Step 3: Ensure unique IDs and add them to the mission list
    Set<int> existingIds = _systemMissions.map((m) => m['id'] as int).toSet();
    newMissions.removeWhere((m) => existingIds.contains(m['id']));

    setState(() {
        _systemMissions.addAll(newMissions);
    });

    // Step 4: Save updated mission list
    await prefs.setStringList(
        'activeSystemMissions',
        _systemMissions.map((m) => json.encode(m)).toList(),
    );

    // Step 5: Update reset time
    int newResetTime = _getNextResetTime(type);
    await prefs.setInt('${type}ResetTime', newResetTime);

    debugPrint("✅ $type missions reset! New reset time: $newResetTime");
  }

  // Load refresh tokens from SharedPreferences
  Future<void> _loadRefreshTokens() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _refreshTokens = prefs.getInt('refreshTokens') ?? 3; // Default to 3 if not set
    });
  }

  // Save refresh token count
  Future<void> _updateRefreshTokens(int amount) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _refreshTokens = (_refreshTokens + amount).clamp(0, 99); // Prevents negative values
    });
    await prefs.setInt('refreshTokens', _refreshTokens);
  }

  // Function to show missions tutorial pop-up
  void _showMissionsTutorial(BuildContext context) {
    final PageController pageController = PageController();
    const int totalPages = 5;
    int currentPage = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Container(
                height: 300, // Set an appropriate height for your dialog
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // PageView for paginated content
                    Expanded(
                      child: PageView(
                        controller: pageController,
                        onPageChanged: (index) {
                          setState(() {
                            currentPage = index;
                          });
                        },
                        children: [
                          // Page 1
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "Welcome to the Missions Page",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Complete missions to earn XP and skill points, that level up your avatar. View them by clicking the trophy icon! 🏆",
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          // Page 2
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "LevelUp Missions",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "LevelUp missions are auto-generated and are themed based on your selected focus areas. They can be refreshed for new ones by swiping left ⬅️",
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          // Page 3
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "Your Missions",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "You can create your own missions with custom properties! Swipe left on user-created missions to delete them ❌",
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          // Page 4
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "Expanded Section",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Click the drop down to see a missions description, the difficulty, the XP it grants and the skill points it rewards! 🤩",
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          // Page 5
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "Get Started!",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Press the '+ Add' button to create custom missions! Or get started on a LevelUp mission! 📝\n\nStart your journey now! 🗺️",
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Navigation Row: arrow buttons and page indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white,),
                          onPressed: currentPage > 0
                              ? () {
                                  setState(() {
                                    currentPage--;
                                  });
                                  pageController.previousPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut);
                                }
                              : null,
                        ),
                        Text("${currentPage + 1}/$totalPages"),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward, color: Colors.white),
                          onPressed: currentPage < totalPages - 1
                              ? () {
                                  setState(() {
                                    currentPage++;
                                  });
                                  pageController.nextPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut);
                                }
                              : null,
                        ),
                      ],
                    ),
                    // "Got it!" button to close the dialog
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

  // Function to add new mission
  void _addMission() {
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    int selectedDifficulty = 1;
    String selectedType = 'daily'; // Default to daily
    String selectedSkillSector = ''; // Default skill sector
    List<String> skillSectors = [
      'fitness',
      'diet',
      'mindfulness',
      'productivity',
      'creativity',
      'education',
      'sleep',
      'hobbies',
      'social',
      'career',
      'confidence',
      'relationships',
      'dating',
      'screentime',
      'skills'
    ];

    showDialog(
      context: context,
      builder: (context) {
        // A local variable in the dialog scope
        int localSelectedSegments = 1;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1C1C1C),
              title: const Text(
                'Add New Mission',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: 300,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mission Title
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: "Mission Title",
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 30,
                      ),
                      const SizedBox(height: 20),
                      // Mission Description (multiple lines, smaller text)
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Mission Description",
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 100,
                      ),
                      const SizedBox(height: 20),
                      // Mission Type Dropdown
                      DropdownButtonFormField<String>(
                        dropdownColor: const Color(0xFF141414),
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: "Mission Type",
                        ),
                        items: ['daily', 'weekly', 'monthly'].map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type.toTitleCase,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selectedType = value!;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Skill Sector Search Field using Autocomplete
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return skillSectors;
                          }
                          return skillSectors.where((String option) {
                            return option
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        // Custom options view with a dark grey background and title-cased values
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              color: const Color(0xFF141414),
                              child: SizedBox(
                                width: 280,
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final String option = options.elementAt(index);
                                    return ListTile(
                                      title: Text(
                                        option.toTitleCase,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      onTap: () {
                                        onSelected(option.toTitleCase);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        onSelected: (String selection) {
                          selectedSkillSector = selection;
                        },
                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: "Skill Sector",
                              hintText: "Leave blank for none",
                              suffixIcon: const Icon(Icons.search, color: Colors.white), // Search icon on the right
                            ),
                            style: const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // Difficulty Selector
                      DropdownButtonFormField<int>(
                        dropdownColor: const Color(0xFF141414),
                        value: selectedDifficulty,
                        decoration: const InputDecoration(
                          labelText: "Difficulty",
                        ),
                        items: List.generate(3, (i) => i + 1).map((diff) {
                          return DropdownMenuItem(
                            value: diff,
                            child: Text(
                              "⭐" * diff,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selectedDifficulty = value!;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Segments Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Segments",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            height: 40,
                            child: Row(
                              children: [
                                // "N/A" (represents value 1)
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        localSelectedSegments = 1;
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1C1C1C),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: localSelectedSegments == 1
                                              ? Colors.white
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "N/A",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Options 2 through 5
                                ...List.generate(4, (index) => index + 2).map((seg) {
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setDialogState(() {
                                          localSelectedSegments = seg;
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1C1C1C),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: localSelectedSegments == seg
                                                ? Colors.white
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "$seg",
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      setState(() {
                        _userMissions.add({
                          "id": DateTime.now().millisecondsSinceEpoch +
                              Random().nextInt(1000),
                          'title': titleController.text,
                          'description': descriptionController.text,
                          'type': selectedType,
                          'skillsector': selectedSkillSector,
                          'difficulty': selectedDifficulty,
                          'segments': localSelectedSegments,
                          'progress': 0,
                          'completed': false,
                          'removing': false,
                          'expanded': false,
                        });
                      });
                      debugPrint(
                          "📌 New Mission Added: Title - ${titleController.text}");
                    }
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
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
                _userMissions[index]['progress']++;  // Increment progress
            });

            await prefs.setInt('progress_$missionTitle', _userMissions[index]['progress']);
        }

        // Delay marking as completed so the UI updates properly
        if (_userMissions[index]['progress'] >= segments) {
            Future.delayed(const Duration(milliseconds: 0), () { // Short delay to allow UI to update
                if (mounted) {
                    setState(() {
                        _userMissions[index]['completed'] = true;
                        _userMissions[index]['removing'] = true;
                    });

                    debugPrint("✅ User Mission Completed: $missionTitle");
                }
            });

            // Ensure full fade-out before removing
            Future.delayed(const Duration(milliseconds: 1000), () { // Forces full 1.5s fade-out
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
                _systemMissions[index]['progress']++;  // Increment progress
            });

            await prefs.setInt('progress_$missionTitle', _systemMissions[index]['progress']);
        }

        // Delay marking as completed so the UI updates properly
        if (_systemMissions[index]['progress'] >= segments) {
            Future.delayed(const Duration(milliseconds: 0), () { // Short delay to allow UI to update
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
                int missionSkillPoints = _systemMissions[index]['skillpoints'] ?? 0;
                String focusArea = _systemMissions[index]['skillsector'] ?? '';
                completeMission(xpReward, missionSkillPoints, focusArea);

                updateMissionAchievements(_systemMissions[index]);
              }
            });

            // Ensure full fade-out before removing
            Future.delayed(const Duration(milliseconds: 1000), () { // Forces full 1.5s fade-out
                if (mounted && index < _systemMissions.length) {
                    setState(() {
                        _systemMissions.removeAt(index);
                    });
                }
            });
        }
    }
  }

  // Complete a mission, reward XP, and update skill stat
  void completeMission(int xpReward, int missionSkillPoints, String focusArea) async {
    final prefs = await SharedPreferences.getInstance();

    // Load XP, Level, and Refresh Tokens
    int currentXP = prefs.getInt('userXP') ?? 0;
    int currentLevel = prefs.getInt('userLevel') ?? 1;
    int refreshTokens = prefs.getInt('refreshTokens') ?? 3; // Default to 3 if not set

    currentXP += xpReward;
    int xpThreshold = getXpThresholdForLevel(currentLevel);

    // Level-up logic
    while (currentXP >= xpThreshold) {
      currentXP -= xpThreshold;
      currentLevel++;
      xpThreshold = getXpThresholdForLevel(currentLevel);

      // Grant +3 Refresh Tokens on Level Up
      refreshTokens += 3;

      debugPrint("🎉 Level Up! New Level = $currentLevel, Refresh Tokens = $refreshTokens");
    }

    // Save updated values to SharedPreferences
    await prefs.setInt('userXP', currentXP);
    await prefs.setInt('userLevel', currentLevel);
    await prefs.setInt('refreshTokens', refreshTokens); // Save refresh tokens

    // Skill Stat Update
    String normalizedFocusArea = focusArea.trim().toLowerCase();
    int currentSkillPercent = prefs.getInt('skillPercent_$normalizedFocusArea') ?? 0;
    currentSkillPercent += missionSkillPoints * 10;
    await prefs.setInt('skillPercent_$normalizedFocusArea', currentSkillPercent);

    debugPrint("🎯 Mission Completed: +$xpReward XP, $missionSkillPoints SP in $focusArea");
    debugPrint("💎 Updated Refresh Tokens: $refreshTokens");

    // Close the mission screen & return XP gained
    if (Navigator.canPop(context)) {
      Navigator.pop(context, xpReward);
    }
  }

  void updateMissionAchievements(Map<String, dynamic> mission) {
    String title = mission['title'];
    String skillSector = mission['skillsector'];
    String now = DateTime.now().toIso8601String(); // You can customize the date format if desired.

    // Look for an existing entry with the same title and skill sector.
    int index = missionAchievements.indexWhere(
      (m) => m['title'] == title && m['skillsector'] == skillSector,
    );

    if (index != -1) {
      // Already exists – increment timesCompleted and update the date.
      missionAchievements[index]['timesCompleted'] += 1;
      missionAchievements[index]['dateCompleted'] = now;
    } else {
      // Not found – add a new mission achievement entry.
      missionAchievements.add({
        'title': title,
        'skillsector': skillSector,
        'dateCompleted': now,
        'timesCompleted': 1,
      });
    }
  }

  // Show confirmation popup before refreshing a mission
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

    // Show Confirmation Dialog if User Has Tokens
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
              onPressed: () => Navigator.pop(context, false), // Cancel
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true), // Confirm Refresh
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  // Refresh a mission
  void _deductRefreshToken(int index) async {
    if (_refreshTokens <= 0) return; // Stop if no tokens left
    await _updateRefreshTokens(-1); // Deduct a refresh token
  }

  Future<void> _setUserFilter(String filter) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userFilter', filter); // Save filter selection
    setState(() {
        _userFilter = filter;
    });
  }

  Future<void> _setSystemFilter(String filter) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('systemFilter', filter); // Save filter selection
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
          await onFilterChange(type); // Calls the correct filter function
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

  // Format to Xm Xh Xs
  String _formatCountdown(int millis) {
    if (millis <= 0) return "0s"; // Ensures it never shows negative time

    Duration duration = Duration(milliseconds: millis);
    int days = duration.inDays;
    int hours = duration.inHours % 24;
    int minutes = duration.inMinutes % 60;
    int seconds = duration.inSeconds % 60;

    List<String> parts = [];

    if (days > 0) parts.add("$days" "d");
    if (hours > 0) parts.add("$hours" "h");
    if (minutes > 0) parts.add("$minutes" "m");
    if (seconds > 0 || parts.isEmpty) parts.add("$seconds" "s"); // Always show seconds if no other units

    return parts.join(" ");
  }

  void _showCompletedMissions(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) {
          return CompletedMissionsScreen(completedMissions: missionAchievements);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0, 1); // Start from the bottom
          const end = Offset.zero;
          const curve = Curves.easeOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
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
        ? mission['skillsector'].toString().trim().toLowerCase()
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
            // Expanded Content (Only visible when expanded)
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
                    // Difficulty Rating System (Now works for both User & System Missions)
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
                              // Triangle and Number Wrapped in Stack
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
    // Compute filtered missions based on the selected filter.
    final filteredMissions = _userMissions.where((m) => m['type'] == _userFilter).toList();

    // Sort the missions if a sort order is applied.
    if (_userSortOrder == SortOrder.asc) {
      filteredMissions.sort((a, b) =>
          a['title'].toLowerCase().compareTo(b['title'].toLowerCase()));
    } else if (_userSortOrder == SortOrder.desc) {
      filteredMissions.sort((a, b) =>
          b['title'].toLowerCase().compareTo(a['title'].toLowerCase()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.emoji_events),
          tooltip: "View Completed Missions",
          onPressed: () => _showCompletedMissions(context),
        ),
        title: Center(
          child: Text(
            "🔄 $_refreshTokens",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_center_outlined),
            tooltip: "Mission Tutorial",
            onPressed: () => _showMissionsTutorial(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // System Missions Section
            const Text(
              'LevelUp Missions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                const Spacer(),
                _buildMissionTimer(_systemFilter),
              ],
            ),
            const SizedBox(height: 20),
            _systemMissions.where((m) => m['type'] == _systemFilter).isEmpty
                ? Column(
                    children: const [
                      SizedBox(height: 10),
                      Center(
                        child: Text(
                          "No missions currently available, come back later.",
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: _systemMissions
                        .where((m) => m['type'] == _systemFilter)
                        .map((mission) => Container(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: _buildMissionTile(
                                  mission, _systemMissions.indexOf(mission), false),
                            ))
                        .toList(),
                  ),
            const SizedBox(height: 20),
            // User Missions Section Header with sort button.
            const Text(
              'Your Missions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildFilterButton('Daily', 'daily', true, _setUserFilter),
                const SizedBox(width: 8),
                _buildFilterButton('Weekly', 'weekly', true, _setUserFilter),
                const SizedBox(width: 8),
                _buildFilterButton('Monthly', 'monthly', true, _setUserFilter),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _userSortOrder == SortOrder.none
                        ? Icons.sort
                        : _userSortOrder == SortOrder.asc
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_userSortOrder == SortOrder.none) {
                        _userSortOrder = SortOrder.asc;
                      } else if (_userSortOrder == SortOrder.asc) {
                        _userSortOrder = SortOrder.desc;
                      } else {
                        _userSortOrder = SortOrder.none;
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // User Missions List
            filteredMissions.isEmpty
                ? ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 10),
                      Center(
                        child: Text(
                          "Out of missions? Make your own!",
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredMissions.length,
                    itemBuilder: (context, index) {
                      final mission = filteredMissions[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _buildMissionTile(mission, index, true),
                      );
                    },
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMission,
        backgroundColor: Colors.green,
        child: const Icon(
          Icons.add,
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

    // Equilateral Triangle Size Calculation
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

    // Draw White Border First
    canvas.drawPath(trianglePath, borderPaint);

    // Draw Filled Triangle Slightly Smaller
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