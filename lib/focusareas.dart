// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

// Packages
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Files
import 'signupprocess.dart';
import 'progress.dart';
import 'avatarcreator.dart';

class FocusAreaScreen extends StatefulWidget {
  final bool isEditing; // Determines if it's for editing or setup

  const FocusAreaScreen({super.key, this.isEditing = false});

  @override
  _FocusAreaScreenState createState() => _FocusAreaScreenState();
}

class _FocusAreaScreenState extends State<FocusAreaScreen> {
  List<String> _selectedAreas = [];
    final List<String> _availableAreas = [
    "[💪]  Fitness",
    "[💸]  Finances",
    "[🥗]  Diet",
    "[✏️]  Productivity",
    "[🎨]  Creativity",
    "[🧘]  Mindfulness",
    "[📚]  Education",
    "[🌙]  Sleep",
    "[🎯]  Hobbies",
    "[🧑‍🤝‍🧑]  Social",
    "[👔]  Career",
    "[🥇]  Confidence",
    "[🫂]  Relationships",
    "[💌]  Dating",
    "[📱]  Screentime",
    "[🤹]  Skills",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserFocus();
  }

  Future<void> _loadUserFocus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAreas = prefs.getStringList('userFocuses') ?? [];
    });
  }

  Future<void> _saveFocusAreas() async {
    if (mounted) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('userFocuses', _selectedAreas);

      if (widget.isEditing) {
        Navigator.pop(context, true); // ✅ Pass `true` to signal a refresh
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PreAvatarScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (widget.isEditing) {
              Navigator.pop(
                context,
                MaterialPageRoute(builder: (context) => const ProgressScreen()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const QuestionnaireScreen4()),
              );
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "What are the areas of your life would you like to improve? (affects missions)",
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: _availableAreas.map((area) {
                  return CheckboxListTile(
                    title: Text(area),
                    value: _selectedAreas.contains(area),
                    onChanged: (bool? value) {
                      setState(() {
                        value == true ? _selectedAreas.add(area) : _selectedAreas.remove(area);
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ✅ Save button
            Padding(
              padding: const EdgeInsets.only(bottom: 50.0), // Adds space below button
              child: ElevatedButton(
                onPressed: _selectedAreas.isNotEmpty
                    ? () async {
                        await _saveFocusAreas();  // This already handles navigation
                      }
                    : null, // Disable button if no option is selected
                child: Text(widget.isEditing ? "Save & Update" : "Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}