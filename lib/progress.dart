// ignore_for_file: library_private_types_in_public_api

// Packages
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

// Files
import 'focusareas.dart';

Future<void> resetAllSkillBars() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> focusAreas = prefs.getStringList('userFocuses') ?? [];
  for (var area in focusAreas) {
    // Remove the emoji from the area string
    String normalizedArea = area.replaceFirst(RegExp(r'^[^\s]+\s*'), '').trim().toLowerCase();
    await prefs.setInt('skillPercent_$normalizedArea', 0);
    debugPrint("Reset skill percent for $normalizedArea to 0");
  }
}

// Progress Screen
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<String> _focusAreas = [];
  final Map<String, int> _focusSkillPercents = {};
  List<Map<String, dynamic>> _trackedHabits = [];
  List<Map<String, dynamic>> _trackedAddictions = [];
  Timer? _addictionTimer;

  final Map<String, Color> focusColors = {
    '💪  Fitness': Colors.red,
    '💸  Finances': Colors.green,
    '🥗  Diet': Colors.blue,
    '✏️  Productivity': Colors.orange,
    '🎨  Creativity': Colors.purple,
    '🧘  Mindfulness': Colors.yellow,
    '📚  Education': Colors.indigo,
    '🌙  Sleep': Colors.grey,
    '🎯  Hobbies': Colors.cyan,
    '🧑‍🤝‍🧑  Social': Colors.pink,
    '👔  Career': Colors.brown,
    '🥇  Confidence': Colors.lime,
    '🫂  Relationships': Colors.amber,
    '💌  Dating': Colors.teal,
    '📱  Screentime': Colors.blueGrey,
    '🤹  Skills': Colors.deepOrange,
  };

  @override
  void initState() {
    super.initState();
    _checkFirstTimeUser();
    _loadFocusAreas();
    _loadTrackedHabits();
    _loadTrackedAddictions();

    // Start a timer that ticks every second so that addiction timers update.
    _addictionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _addictionTimer?.cancel();
    super.dispose();
  }

  // ✅ Function to check if user has seen progress tutorial before
  Future<void> _checkFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenTutorial = prefs.getBool('hasSeenProgressTutorial') ?? false;

    if (!hasSeenTutorial) {
      // ✅ Show tutorial pop-up
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showProgressTutorial(context);
      });

      // ✅ Mark tutorial as seen
      await prefs.setBool('hasSeenProgressTutorial', true);
    }
  }

  void _showProgressTutorial(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Welcome to the Progress Page",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Edit your life focuses and see their current level 💫\n"
                  "Earn and see your achievements by clicking the medal icon 🏅\n"
                  "Set habits and mark them off daily 📑\n"
                  "Wanting to quit something? Use the addiction tracker! ❌\n",
                  textAlign: TextAlign.center,
                ),
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

  Future<void> _loadFocusAreas() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _focusAreas = prefs.getStringList('userFocuses') ?? [];
    });

  for (var area in _focusAreas) {
      // Remove the emoji (the first token) and then normalize.
      String normalizedArea = area.replaceFirst(RegExp(r'^[^\s]+\s*'), '').trim().toLowerCase();
      debugPrint("Area: '$area' normalized to: '$normalizedArea'");
      int percent = prefs.getInt('skillPercent_$normalizedArea') ?? 0;
      debugPrint("Loaded skill percent for '$area' (normalized: '$normalizedArea'): $percent");
      setState(() {
        _focusSkillPercents[area] = percent;
      });
    }
  }

  // Helper function to extract the emoji from the focus area string.
  // For a string like "💪  Fitness", it returns "💪".
  String extractEmoji(String area) {
    return area.split(RegExp(r'\s+')).first;
  }

  Map<String, int> calculateSkillLevelAndProgress(int percent) {
    int extraLevels = percent ~/ 100; // full 100% increments
    int displayProgress = percent % 100; // remaining progress
    int level = 1 + extraLevels;
    return {'level': level, 'progress': displayProgress};
  }

  Future<void> _saveTrackedHabits() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> habitsJson = _trackedHabits.map((habit) {
      return json.encode({
        "name": habit["name"],
        "description": habit["description"],
        "icon": habit["icon"],
        "fontFamily": habit["fontFamily"],
        "fontPackage": habit["fontPackage"],
        "color": habit["color"],
        "days": habit["days"],
        "marked": habit["marked"],
        // Save the last marked date as an ISO string:
        "lastMarkedDate": habit["lastMarkedDate"] ?? DateTime.now().toIso8601String(),
      });
    }).toList();
    await prefs.setStringList('trackedHabits', habitsJson);
  }

  // Helper function: checks if two dates are on the same day
  bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  // Helper function to compute a simple week number for a given date.
  // (This is a simplified calculation; adjust if you need strict ISO week numbers.)
  int weekNumber(DateTime date) {
    // Get the first day of the year.
    DateTime firstDayOfYear = DateTime(date.year, 1, 1);
    // Calculate the difference in days, then divide by 7 and round up.
    return ((date.difference(firstDayOfYear).inDays) / 7).ceil() + 1;
  }

  Future<void> _loadTrackedHabits() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> habitsJson = prefs.getStringList('trackedHabits') ?? [];
    DateTime now = DateTime.now();
    int currentWeek = weekNumber(now);

    setState(() {
      _trackedHabits = habitsJson.map((str) {
        final habit = json.decode(str);
        // Parse stored lastMarkedDate if available.
        DateTime? storedLastMarked;
        if (habit.containsKey("lastMarkedDate") &&
            habit["lastMarkedDate"].toString().isNotEmpty) {
          storedLastMarked = DateTime.tryParse(habit["lastMarkedDate"]);
        }
        // If not available, assume habit was last marked today.
        storedLastMarked ??= now;
        int storedWeek = weekNumber(storedLastMarked);

        if (currentWeek != storedWeek) {
          // New week: clear all marked days and reset the 'marked' flag.
          habit["days"] = List<bool>.filled(7, false);
          habit["marked"] = false;
        } else if (!isSameDay(now, storedLastMarked)) {
          // Same week but new day: reset today's 'marked' flag.
          habit["marked"] = false;
        }
        // Only update lastMarkedDate when a user toggles marking (not here)
        // Optionally, if you want to initialize it, do so if missing.
        if (!habit.containsKey("lastMarkedDate") ||
            habit["lastMarkedDate"].toString().isEmpty) {
          habit["lastMarkedDate"] = now.toIso8601String();
        }

        return {
          "name": habit["name"],
          "description": habit["description"],
          "icon": IconData(
            habit["icon"],
            fontFamily: habit["fontFamily"],
            fontPackage: (habit["fontFamily"] == "FontAwesomeSolid" ||
                    habit["fontFamily"] == "FontAwesomeBrands" ||
                    habit["fontFamily"] == "FontAwesomeRegular")
                ? "font_awesome_flutter"
                : (habit["fontPackage"] == "" ? null : habit["fontPackage"]),
          ),
          "color": Color(habit["color"]),
          "days": List<bool>.from(habit["days"]),
          "marked": habit["marked"] ?? false,
          "lastMarkedDate": habit["lastMarkedDate"],
        };
      }).toList();
    });
  }

  final List<IconData> _iconChoices = [
    FontAwesomeIcons.dumbbell,
    FontAwesomeIcons.appleWhole,
    FontAwesomeIcons.briefcase,
    FontAwesomeIcons.book,
    FontAwesomeIcons.droplet,
    FontAwesomeIcons.guitar,
    FontAwesomeIcons.drum,
    FontAwesomeIcons.music,
    FontAwesomeIcons.paintbrush,
    FontAwesomeIcons.personWalking,
    FontAwesomeIcons.car,
    FontAwesomeIcons.cartShopping,
  ];
  
  final List<String> _weekDays = ["M", "T", "W", "T", "F", "S", "S"];

  void _addHabitDialog() {
    // Make selectedIcon mutable by not using final.
    IconData selectedIcon = _iconChoices.first;
    Color selectedColor = Colors.blue;
    TextEditingController nameController = TextEditingController();
    TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add New Habit"),
          content: SizedBox(
            width: 350,
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Habit Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Icon grid replacement
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Choose Icon",
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        GridView.count(
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: _iconChoices.map((icon) {
                            bool isSelected = icon == selectedIcon;
                            return GestureDetector(
                              onTap: () {
                                setStateDialog(() {
                                  selectedIcon = icon;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: isSelected
                                      ? Border.all(color: Colors.white, width: 2)
                                      : null,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(icon, size: 24, color: Colors.white),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Colour picker remains unchanged.
                    Row(
                      children: [
                        const Text("Choose Colour: "),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Pick a color"),
                                content: BlockPicker(
                                  pickerColor: selectedColor,
                                  onColorChanged: (Color color) {
                                    setStateDialog(() {
                                      selectedColor = color;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: selectedColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _trackedHabits.add({
                      "name": nameController.text,
                      "description": descController.text,
                      "icon": selectedIcon.codePoint,
                      // Force the correct FontAwesome properties:
                      "fontFamily": "FontAwesomeSolid",
                      "fontPackage": "font_awesome_flutter",
                      "color": selectedColor.value,
                      "days": List<bool>.filled(7, false),
                      "marked": false,
                    });
                  });
                  _saveTrackedHabits();
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadTrackedAddictions() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> addictionsJson = prefs.getStringList('trackedAddictions') ?? [];
    setState(() {
      _trackedAddictions = addictionsJson
          .map((str) => json.decode(str) as Map<String, dynamic>)
          .toList();
    });
  }

  Future<void> _saveTrackedAddictions() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> addictionsJson =
        _trackedAddictions.map((addiction) => json.encode(addiction)).toList();
    await prefs.setStringList('trackedAddictions', addictionsJson);
  }

  // Define your sample addictions list in your _ProgressScreenState:
  final List<Map<String, dynamic>> addictionsList = [
    {
      "name": "Smoking",
      "icon": Icons.smoking_rooms,
      "color": Colors.brown,
    },
    {
      "name": "Social Media",
      "icon": Icons.chat,
      "color": Colors.blue,
    },
    {
      "name": "Caffeine",
      "icon": Icons.local_cafe,
      "color": Colors.orange,
    },
    {
      "name": "Weed",
      "icon": FaIcon(FontAwesomeIcons.cannabis),
      "color": Colors.green,
    },
    {
      "name": "Explicit Content",
      "icon": FaIcon(FontAwesomeIcons.faceKissWinkHeart),
      "color": Colors.red,
    },
    {
      "name": "Alcohol",
      "icon": FaIcon(FontAwesomeIcons.wineBottle),
      "color": Colors.yellow,
    },
    {
      "name": "Gambling",
      "icon": FaIcon(FontAwesomeIcons.dice),
      "color": Colors.purple,
    },
    {
      "name": "Sports Betting",
      "icon": FaIcon(FontAwesomeIcons.horse),
      "color": Colors.lime,
    },
    {
      "name": "Self Harm",
      "icon": FaIcon(FontAwesomeIcons.heart),
      "color": Colors.pink,
    }
  ];

  String _formatDuration(Duration duration) {
    int days = duration.inDays;
    int hours = duration.inHours % 24;
    int minutes = duration.inMinutes % 60;
    int seconds = duration.inSeconds % 60;
    return "${days}D ${hours}H ${minutes}M ${seconds}S";
  }

  // Updated _addAddiction method using a dropdown and storing startTime.
  void _addAddiction() {
    // Predefined time frames.
    final List<Map<String, dynamic>> timeFrames = [
      {"label": "Forever", "duration": null},
      {"label": "1 Week", "duration": Duration(days: 7).inMilliseconds},
      {"label": "1 Month", "duration": Duration(days: 30).inMilliseconds},
      {"label": "1 Year", "duration": Duration(days: 365).inMilliseconds},
    ];

    // Filter the addictionsList to only those that are not already tracked.
    List<Map<String, dynamic>> availableAddictions = addictionsList.where((addiction) {
      return !_trackedAddictions.any((active) =>
          active["name"].toString().toLowerCase() ==
          addiction["name"].toString().toLowerCase());
    }).toList();

    // If all addictions are already tracked, show a message and exit.
    if (availableAddictions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All addictions are already tracked.")),
      );
      return;
    }

    // Set the initial selected addiction to the first available one.
    Map<String, dynamic>? selectedAddiction = availableAddictions.first;
    Map<String, dynamic> selectedTimeFrame = timeFrames.first;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Addiction"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    dropdownColor: const Color(0xFF141414),
                    value: selectedAddiction,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Select Addiction",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (Map<String, dynamic>? newValue) {
                      setStateDialog(() {
                        selectedAddiction = newValue;
                      });
                    },
                    items: availableAddictions.map((addiction) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: addiction,
                        child: Text(addiction["name"]),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    dropdownColor: const Color(0xFF141414),
                    value: selectedTimeFrame,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Select Time Frame",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (Map<String, dynamic>? newValue) {
                      setStateDialog(() {
                        if (newValue != null) selectedTimeFrame = newValue;
                      });
                    },
                    items: timeFrames.map((timeFrame) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: timeFrame,
                        child: Text(timeFrame["label"]),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (selectedAddiction != null) {
                  setState(() {
                    _trackedAddictions.add({
                      "name": selectedAddiction!["name"],
                      "icon": selectedAddiction!["icon"] is IconData
                          ? selectedAddiction!["icon"].codePoint // Material Icons
                          : selectedAddiction!["icon"].icon.codePoint, // FontAwesome Icons
                      "fontFamily": selectedAddiction!["icon"] is IconData
                          ? selectedAddiction!["icon"].fontFamily
                          : "FontAwesomeSolid", // Set the correct FontAwesome font family
                      "color": (selectedAddiction!["color"] as Color).value,
                      "startTime": DateTime.now().millisecondsSinceEpoch,
                      "targetDuration": selectedTimeFrame["duration"],
                    });
                  });
                  _saveTrackedAddictions();
                }
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  IconData getIconFromData(Map<String, dynamic> data) {
    if (data["fontFamily"] == "FontAwesomeSolid" || 
        data["fontFamily"] == "FontAwesomeBrands" || 
        data["fontFamily"] == "FontAwesomeRegular") {
      return IconData(
        data["icon"],
        fontFamily: data["fontFamily"],
        fontPackage: "font_awesome_flutter",
      );
    } else {
      return IconData(
        data["icon"],
        fontFamily: data["fontFamily"], // Material Icons
      );
    }
  }

  String getTargetLabel(int? targetDuration) {
    if (targetDuration == null) return "Forever";
    if (targetDuration == Duration(days: 7).inMilliseconds) return "1 Week";
    if (targetDuration == Duration(days: 30).inMilliseconds) return "1 Month";
    if (targetDuration == Duration(days: 365).inMilliseconds) return "1 Year";
    // Customize further if needed.
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Progress"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 0),
            child: IconButton(
              icon: const Icon(FontAwesomeIcons.medal, color: Colors.white),
              onPressed: () => (),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: IconButton(
              icon: const Icon(Icons.help_center_outlined, color: Colors.white),
              onPressed: () => _showProgressTutorial(context),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Focus Areas Section (unchanged)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Focus Tracker:",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_square, color: Colors.white),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const FocusAreaScreen(isEditing: true),
                      ),
                    );
                    if (result == true) {
                      _loadFocusAreas();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            _focusAreas.isEmpty
                ? const Text("No focus areas selected yet.")
                : Column(
                    children: _focusAreas.map((area) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: (focusColors[area] ?? Colors.grey).withValues(alpha: 0.4), // Adjust transparency here
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(color: Colors.white, width: 1.25),
                              ),
                              child: Center(
                                child: Text(
                                  extractEmoji(area),
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${area.replaceFirst(RegExp(r'^[^\s]+\s*'), '').trim()}: Level ${calculateSkillLevelAndProgress(_focusSkillPercents[area] ?? 0)['level']}",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      double progressFraction =
                                          ((_focusSkillPercents[area] ?? 0) % 100) /
                                              100.0;
                                      return TweenAnimationBuilder<double>(
                                        tween: Tween<double>(
                                            begin: 0, end: progressFraction),
                                        duration: const Duration(
                                            milliseconds: 500),
                                        builder:
                                            (context, animatedProgress, child) {
                                          double filledWidth =
                                              constraints.maxWidth *
                                                  animatedProgress;
                                          return Stack(
                                            children: [
                                              Container(
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[700],
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              if (animatedProgress > 0)
                                                Container(
                                                  width: filledWidth,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    color: focusColors[area] ??
                                                        Colors.grey,
                                                    borderRadius:
                                                        BorderRadius.circular(10),
                                                    border: Border.all(
                                                        color: Colors.white,
                                                        width: 2),
                                                  ),
                                                ),
                                              Positioned.fill(
                                                child: Center(
                                                  child: Text(
                                                    "${(_focusSkillPercents[area] ?? 0) % 100}%",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              const SizedBox(height: 20),
              SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Habit Tracker:",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: _addHabitDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _trackedHabits.isEmpty
                        ? Center(
                            child: Text(
                              "No habits currently being tracked.",
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Column(
                            children: _trackedHabits.map((habit) {
                              final DateTime lastMarkedDate =
                                DateTime.tryParse(habit["lastMarkedDate"] ?? "") ?? DateTime.now();
                              bool markedToday =
                                isSameDay(lastMarkedDate, DateTime.now()) ? (habit["marked"] ?? false) : false;
                              // Convert the stored color and icon values if needed.
                              final habitColor = habit["color"] is int
                                  ? Color(habit["color"])
                                  : habit["color"];
                              final iconData = habit["icon"] is int
                                  ? ((habit["fontFamily"] == "FontAwesomeSolid" ||
                                          habit["fontFamily"] == "FontAwesomeBrands" ||
                                          habit["fontFamily"] == "FontAwesomeRegular")
                                      ? IconData(habit["icon"],
                                          fontFamily: habit["fontFamily"],
                                          fontPackage: "font_awesome_flutter")
                                      : IconData(habit["icon"],
                                          fontFamily: habit["fontFamily"]))
                                  : habit["icon"];
                              final int habitIndex = _trackedHabits.indexOf(habit);
                              final int currentDayIndex = DateTime.now().weekday - 1;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  // Use withAlpha() if you want transparency.
                                  color: habitColor.withAlpha(50),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Top Row: Icon, Habit Name, Check Icon, and Three Dots.
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start, // So the top of each side lines up
                                      children: [
                                        // Left side: Icon + Name + Description
                                        Flexible(
                                          fit: FlexFit.loose, // Let this side take only as much width as it needs
                                          child: Row(
                                            children: [
                                              const SizedBox(width: 10),
                                              Icon(iconData, color: habitColor, size: 28),
                                              const SizedBox(width: 20),
                                              // Force text to wrap instead of overflowing
                                              Flexible(
                                                fit: FlexFit.loose,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      habit["name"],
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                      softWrap: true, // Wrap onto new line if needed
                                                      maxLines: 2,    // Limit to 2 lines if you want
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (habit["description"].isNotEmpty)
                                                      Text(
                                                        habit["description"],
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.white70,
                                                        ),
                                                        softWrap: true,
                                                        maxLines: 3, // e.g., 3 lines max
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Right side: Check Icon & Three Dots
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                markedToday ? Icons.check_circle : Icons.check_circle_outline,
                                                color: markedToday ? habitColor : Colors.white70,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  habit["marked"] = !markedToday;
                                                  habit["days"][currentDayIndex] = habit["marked"];
                                                  habit["lastMarkedDate"] = DateTime.now().toIso8601String();
                                                });
                                                _saveTrackedHabits();
                                              },
                                            ),
                                            PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert, color: Colors.white),
                                              onSelected: (String choice) {
                                                if (choice == 'Remove') {
                                                  setState(() {
                                                    _trackedHabits.removeAt(habitIndex);
                                                  });
                                                }
                                              },
                                              itemBuilder: (BuildContext context) => [
                                                const PopupMenuItem<String>(
                                                  value: 'Remove',
                                                  child: Text('Remove Habit'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Weekday Labels.
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: _weekDays.map((day) {
                                        return SizedBox(
                                          width: 42.5,
                                          child: Text(
                                            day,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    // Weekday Progress Row with Expand Icon.
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Weekday Boxes.
                                        Row(
                                          children: List.generate(7, (dayIndex) {
                                            final bool isPastDay =
                                                dayIndex < DateTime.now().weekday - 1;
                                            return Container(
                                              margin: const EdgeInsets.symmetric(
                                                  horizontal: 8.75),
                                              width: 25,
                                              height: 25,
                                              decoration: BoxDecoration(
                                                color: habit["days"][dayIndex]
                                                    ? habitColor
                                                    : (isPastDay
                                                        ? Colors.grey[800]
                                                        : Colors.grey[700]),
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                            );
                                          }),
                                        ),
                                        // Expand Icon.
                                        IconButton(
                                          icon: const Icon(FontAwesomeIcons.expand,
                                              color: Colors.white),
                                          onPressed: () {
                                            // Expand functionality (Placeholder).
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Addiction Tracker Section with Title Row & Plus Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Addiction Tracker:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _addAddiction,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Display each addiction as a full-width tile.
              _trackedAddictions.isEmpty
                ? Center(
                    child: Text(
                      "No addictions currently being tracked.",
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Column(
                children: _trackedAddictions.map((addiction) {
                  // Calculate elapsed time.
                  int startTime =
                      addiction["startTime"] ?? DateTime.now().millisecondsSinceEpoch;
                  Duration elapsed = Duration(
                    milliseconds:
                        DateTime.now().millisecondsSinceEpoch - startTime,
                  );
                  String timerText = _formatDuration(elapsed);

                  int? targetDuration = addiction["targetDuration"]; // in ms, or null for Forever.
                  double progressFraction = 0;
                  if (targetDuration != null) {
                    progressFraction = elapsed.inMilliseconds / targetDuration;
                    if (progressFraction > 1) progressFraction = 1;
                  }

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Color(addiction["color"]).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 1.25),
                    ),
                    child: Stack(
                      children: [
                        // Main content row.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left side: icon, label, timer text.
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        getIconFromData(addiction), // Use helper function to reconstruct the correct icon
                                        color: Color(addiction["color"]),
                                        size: 30,
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Text(
                                          addiction["name"],
                                          style: const TextStyle(
                                              fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Free for: $timerText",
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            // Right side: gauge with right padding if a target duration is set; otherwise, show empty text.
                            Padding(
                              padding: const EdgeInsets.only(right: 40.0),
                              child: targetDuration != null
                                  ? SemiCircularGauge(
                                      progressFraction: progressFraction,
                                      fillColor: Color(addiction["color"]),
                                      backgroundColor: Colors.grey[700]!,
                                      size: 100,
                                      progressText:
                                          "${(progressFraction * 100).toStringAsFixed(0)}%",
                                      targetLabel: getTargetLabel(targetDuration),
                                    )
                                  : const Text(
                                      "",
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 14),
                                    ),
                            ),
                          ],
                        ),
                        // Three dot icon positioned at the top right.
                        Positioned(
                          top: -10,
                          right: -10,
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            onSelected: (String choice) {
                              if (choice == 'Relapse') {
                                // Reset timer by updating the startTime.
                                setState(() {
                                  addiction["startTime"] =
                                      DateTime.now().millisecondsSinceEpoch;
                                });
                                _saveTrackedAddictions();
                              } else if (choice == 'Remove') {
                                setState(() {
                                  _trackedAddictions.remove(addiction);
                                });
                                _saveTrackedAddictions();
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem<String>(
                                value: 'Relapse',
                                child: Text('Relapse (Reset Timer)'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'Remove',
                                child: Text('Remove Addiction'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
      ),
    );
  }
}

class SemiCircularGauge extends StatelessWidget {
  final double progressFraction; // 0.0 to 1.0
  final Color fillColor;
  final Color backgroundColor;
  final double size; // Width of the gauge, height will be half of this.
  final String progressText;
  final String targetLabel; // <-- Duration label (e.g., 1 Week, 1 Month)

  const SemiCircularGauge({
    Key? key,
    required this.progressFraction,
    required this.fillColor,
    required this.backgroundColor,
    required this.size,
    required this.progressText,
    required this.targetLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size / 2, // Semi-circle height
      child: Stack(
        alignment: Alignment.center, // Centers text inside the gauge
        children: [
          CustomPaint(
            size: Size(size, size / 2),
            painter: _SemiCircularGaugePainter(
              progressFraction: progressFraction,
              fillColor: fillColor,
              backgroundColor: backgroundColor,
            ),
          ),
          Positioned(
            top: size * 0.12, // ⬅ Adjust this value to lower the text
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  progressText, // Percentage text
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  targetLabel, // Duration label (e.g., "1 Month")
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SemiCircularGaugePainter extends CustomPainter {
  final double progressFraction;
  final Color fillColor;
  final Color backgroundColor;

  _SemiCircularGaugePainter({
    required this.progressFraction,
    required this.fillColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    // For a semi circle, position the circle such that its bottom center is at the widget's bottom center.
    final Offset center = Offset(size.width / 2, size.height);
    final double strokeWidth = 8.0;

    final Paint bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw full semi circle (180 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, // start at 180°
      pi, // sweep 180°
      false,
      bgPaint,
    );

    final Paint fillPaint = Paint()
      ..color = fillColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw fill arc based on progressFraction
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, // same start
      pi * progressFraction, // fill portion
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SemiCircularGaugePainter oldDelegate) {
    return oldDelegate.progressFraction != progressFraction ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}