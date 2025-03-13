// ignore_for_file: library_private_types_in_public_api

// Packages
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _loadFocusAreas();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Progress"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Focus Areas:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _focusAreas.isEmpty
                ? const Text("No focus areas selected yet.")
                : Column(
                    children: _focusAreas.map((area) {
                      // Get the stored skill percentage (0 to 100) for this focus area.
                      int storedPercent = _focusSkillPercents[area] ?? 0;
                      // Get level and display progress from our helper.
                      final result = calculateSkillLevelAndProgress(storedPercent);
                      int level = result['level']!;
                      int displayPercent = result['progress']!;
                      double progressFraction = displayPercent / 100.0;
                      // For the label, remove the emoji (first token) from the area.
                      String labelText =
                          area.replaceFirst(RegExp(r'^[^\s]+\s*'), '').trim();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Square container with the emoji and matching background color.
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: focusColors[area] ?? Colors.grey,
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
                            // Column with label and progress bar.
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Label: "SkillSector: Level X"
                                  Text(
                                    "$labelText: Level $level",
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Animated progress bar that animates from 0% to the target display percentage.
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      double targetProgress = progressFraction; // 0.0 to 1.0
                                      return TweenAnimationBuilder<double>(
                                        tween: Tween<double>(begin: 0, end: targetProgress),
                                        duration: const Duration(milliseconds: 500),
                                        builder: (context, animatedProgress, child) {
                                          double filledWidth = constraints.maxWidth * animatedProgress;
                                          return Stack(
                                            children: [
                                              // Background progress bar.
                                              Container(
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[700],
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              // Conditionally display the filled progress meter.
                                              animatedProgress > 0
                                                  ? Container(
                                                      width: filledWidth,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: focusColors[area] ?? Colors.grey,
                                                        borderRadius: BorderRadius.circular(10),
                                                        border: Border.all(color: Colors.white, width: 2),
                                                      ),
                                                    )
                                                  : const SizedBox.shrink(),
                                              // Conditionally position the percentage text.
                                              animatedProgress > 0
                                                  ? Positioned(
                                                      left: 0,
                                                      top: 0,
                                                      bottom: 0,
                                                      child: Container(
                                                        width: filledWidth,
                                                        alignment: Alignment.center,
                                                        child: Text(
                                                          "$displayPercent%",
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
                                                          "$displayPercent%",
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
            // Button to update focus areas.
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FocusAreaScreen(isEditing: true),
                    ),
                  );
                  if (result == true) {
                    _loadFocusAreas(); // Reload focus areas (and their stats) when coming back.
                  }
                },
                child: const Text("Update Focus Areas"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
