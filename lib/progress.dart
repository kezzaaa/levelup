// ignore_for_file: library_private_types_in_public_api

// Packages
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Files
import 'focusareas.dart';

// Progress Screen
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<String> _focusAreas = [];

  final Map<String, Color> focusColors = {
    '[💪]  Fitness': Colors.red,
    '[💸]  Finances': Colors.green,
    '[🥗]  Diet': Colors.blue,
    '[✏️]  Productivity': Colors.orange,
    '[🎨]  Creativity': Colors.purple,
    '[🧘]  Mindfulness': Colors.yellow,
    '[📚]  Education': Colors.indigo,
    '[🌙]  Sleep': Colors.grey,
    '[🎯]  Hobbies': Colors.cyan,
    '[🧑‍🤝‍🧑]  Social': Colors.pink,
    '[👔]  Career': Colors.brown,
    '[🥇]  Confidence': Colors.lime,
    '[🫂]  Relationships': Colors.amber,
    '[💌]  Dating': Colors.teal,
    '[📱]  Screentime': Colors.blueGrey,
    '[🤹]  Skills': Colors.deepOrange,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Progress"),
        backgroundColor: Theme.of(context).colorScheme.secondary,
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
                : Wrap(
                    spacing: 8,
                    children: _focusAreas.map((area) {
                      return Chip(
                        label: Text(area),
                        backgroundColor: focusColors[area] ?? Colors.grey,
                        labelStyle: const TextStyle(color: Colors.white),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 20),

            // ✅ Button to update focus areas
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
                    _loadFocusAreas(); // ✅ Reload focus areas when coming back
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