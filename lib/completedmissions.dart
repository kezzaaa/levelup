// ignore_for_file: use_super_parameters, library_private_types_in_public_api

// Packages
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CompletedMissionsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> completedMissions;

  const CompletedMissionsScreen({Key? key, required this.completedMissions}) : super(key: key);

  @override
  _CompletedMissionsScreenState createState() => _CompletedMissionsScreenState();
}

class _CompletedMissionsScreenState extends State<CompletedMissionsScreen> {
  List<String> userFocuses = [];

  @override
  void initState() {
    super.initState();
    _loadUserFocuses();
  }

  /// Fetch user-selected focuses from SharedPreferences
  Future<void> _loadUserFocuses() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userFocuses = prefs.getStringList('userFocuses') ?? [];
    });
  }

  /// Predefined color mapping for focus areas
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Completed Missions')),
      body: Column(
        children: [
          // Skill Buttons Column (Full Width)
          if (userFocuses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Column(
                children: userFocuses.map((focus) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to new page with filtered missions
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FilteredMissionsScreen(
                                skillName: focus,
                                completedMissions: widget.completedMissions,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: focusColors[focus] ?? Colors.grey, // Assign color from focusColors
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          focus,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center, // Center text inside button
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class FilteredMissionsScreen extends StatelessWidget {
  final String skillName;
  final List<Map<String, dynamic>> completedMissions;

  const FilteredMissionsScreen({
    Key? key,
    required this.skillName,
    required this.completedMissions,
  }) : super(key: key);

  // Helper function to normalize strings (remove emojis and extra characters)
  String normalize(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
  }

  String formatDate(String isoString) {
    DateTime dateTime = DateTime.parse(isoString);
    return DateFormat('dd/MM/yyyy (HH:mm)').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    String normalizedSkillName = normalize(skillName);

    // Filter missions based on normalized skill sector
    List<Map<String, dynamic>> filteredMissions = completedMissions.where((mission) {
      String missionSkill = mission['skillsector'].toString().toLowerCase();
      return missionSkill == normalizedSkillName;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('$skillName Missions')),
      body: filteredMissions.isEmpty
          ? const Center(
              child: Text(
                "No completed missions for this skill yet.",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredMissions.length,
              itemBuilder: (context, index) {
                final mission = filteredMissions[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.check, color: Colors.green),
                    title: Text(
                      mission['title'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Completed: ${mission['timesCompleted']} time(s) on ${formatDate(mission['dateCompleted'])}",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                );
              },
            ),
    );
  }
}