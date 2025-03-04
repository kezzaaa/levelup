// ignore_for_file: library_private_types_in_public_api

// Packages
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Missions Screen
class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  _MissionsScreenState createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  final List<Map<String, dynamic>> _systemMissions = [
    {'title': 'Daily Mission 1', 'completed': false, 'type': 'daily', 'removing': false, 'expanded': false, 'difficulty': 1, 'skillsector': 'Fitness', 'skillpoints': 1, 'experience': 5, 'description': '[Placeholder]'},
    {'title': 'Daily Mission 2', 'completed': false, 'type': 'daily', 'removing': false, 'expanded': false, 'difficulty': 1, 'skillsector': 'Diet', 'skillpoints': 1, 'experience': 5, 'description': '[Placeholder]'},
    {'title': 'Daily Mission 3', 'completed': false, 'type': 'daily', 'removing': false, 'expanded': false, 'difficulty': 1, 'skillsector': 'Mindfulness', 'skillpoints': 1, 'experience': 5, 'description': '[Placeholder]'},
    {'title': 'Weekly Mission 1', 'completed': false, 'type': 'weekly', 'removing': false, 'expanded': false, 'difficulty': 2, 'skillsector': 'Fitness', 'skillpoints': 2, 'experience': 10, 'description': '[Placeholder]'},
    {'title': 'Weekly Mission 2', 'completed': false, 'type': 'weekly', 'removing': false, 'expanded': false, 'difficulty': 2, 'skillsector': 'Diet', 'skillpoints': 2, 'experience': 10, 'description': '[Placeholder]'},
    {'title': 'Weekly Mission 3', 'completed': false, 'type': 'weekly', 'removing': false, 'expanded': false, 'difficulty': 2, 'skillsector': 'Mindfulness', 'skillpoints': 2, 'experience': 10, 'description': '[Placeholder]'},
    {'title': 'Monthly Mission 1', 'completed': false, 'type': 'monthly', 'removing': false, 'expanded': false, 'difficulty': 3, 'skillsector': 'Fitness', 'skillpoints': 3, 'experience': 20, 'description': '[Placeholder]'},
    {'title': 'Monthly Mission 2', 'completed': false, 'type': 'monthly', 'removing': false, 'expanded': false, 'difficulty': 3, 'skillsector': 'Diet', 'skillpoints': 3, 'experience': 20, 'description': '[Placeholder]'},
    {'title': 'Monthly Mission 3', 'completed': false, 'type': 'monthly', 'removing': false, 'expanded': false, 'difficulty': 3, 'skillsector': 'Mindfulness', 'skillpoints': 3, 'experience': 20, 'description': '[Placeholder]'},
  ];

  final List<Map<String, dynamic>> _userMissions = [];
  String _userFilter = 'daily';
  String _systemFilter = 'daily';

  final ScrollController _userScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _checkFirstTimeUser();
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

  void _addMission() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Mission'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter mission title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _userMissions.add({
                      'title': controller.text,
                      'completed': false,
                      'type': _userFilter,
                      'removing': false,
                      'expanded': false, 
                      'description': '[Placeholder]',
                    });
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _setSystemFilter(String type) {
    setState(() {
      _systemFilter = type;
    });
  }

  void _setUserFilter(String type) {
    setState(() {
      _userFilter = type;
    });
  }

  void _toggleMission(int index, bool isUserMission) {
    setState(() {
      if (isUserMission) {
        _userMissions[index]['completed'] = true;
        _userMissions[index]['removing'] = true;
      } else {
        _systemMissions[index]['completed'] = true;
        _systemMissions[index]['removing'] = true;
      }
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        if (isUserMission && index < _userMissions.length && _userMissions[index]['removing']) {
          _userMissions.removeAt(index);
        } else if (!isUserMission && index < _systemMissions.length && _systemMissions[index]['removing']) {
          _systemMissions.removeAt(index);
        }
      });
    });
  }

  void _refreshMission(int index, bool isUserMission) {
    debugPrint("Mission at index $index refreshed (${isUserMission ? "User" : "System"})");
  }

  void _deleteMission(int index) {
    setState(() {
      _userMissions.removeAt(index);
    });
  }

  Widget _buildFilterButton(String text, String type, bool isUserFilter) {
    bool isActive = isUserFilter ? (_userFilter == type) : (_systemFilter == type);
    return SizedBox(
      width: 60,
      height: 25,
      child: TextButton(
        onPressed: () => isUserFilter ? _setUserFilter(type) : _setSystemFilter(type),
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

  Widget _buildMissionTile(Map<String, dynamic> mission, int index, bool isUserMission) {
    // Only system missions have these properties
    int difficulty = isUserMission ? 0 : (mission.containsKey('difficulty') ? mission['difficulty'] : 0);
    int xp = isUserMission ? 0 : (mission.containsKey('experience') ? mission['experience'] : 0);
    int skillPoints = isUserMission ? 0 : (mission.containsKey('skillpoints') ? mission['skillpoints'] : 0);
    String skillSector = isUserMission ? '' : (mission.containsKey('skillsector') ? mission['skillsector'] : '');

    // Define skill sector colors (Only applies to system missions)
    Map<String, Color> skillColors = {
      'Fitness': Colors.red,
      'Diet': Colors.blue,
      'Mindfulness': Colors.green,
      'Productivity': Colors.orange,
      'Creativity': Colors.purple,
    };
    Color skillColor = skillColors[skillSector] ?? Colors.grey; // Default if skill sector is missing

    return Dismissible(
      key: ValueKey(mission['title']),
      direction: DismissDirection.endToStart,
      background: Container(
        color: isUserMission ? Colors.red : Colors.green,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      onDismissed: (_) {
        _refreshMission(index, isUserMission);
      },
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Checkbox(
              value: mission['completed'],
              onChanged: (_) => _toggleMission(index, isUserMission),
            ),
            title: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Text(
                mission['title'],
                style: TextStyle(
                  decoration: mission['completed'] ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
            ),
            trailing: IconButton(
              icon: Icon(mission['expanded'] ? Icons.arrow_drop_up : Icons.arrow_drop_down),
              onPressed: () {
                setState(() {
                  mission['expanded'] = !mission['expanded'];
                });
              },
            ),
          ),
          if (mission['expanded'])
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUserMission) // Only show XP, stars, and skill triangle for system missions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ⭐ Difficulty Rating System
                        Row(
                          children: List.generate(3, (i) {
                            return Icon(
                              i < difficulty ? Icons.star : Icons.star_border,
                              color: i < difficulty ? Colors.yellow : Colors.white,
                              size: 20,
                            );
                          }),
                        ),
                        Row(
                          children: [
                            // 🔵 XP Indicator (Blue Circle)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "$xp",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8), // Spacing between XP and Skill Triangle
                            // 🔺 Skill Point Triangle (Only show if skillPoints > 0)
                            if (skillPoints > 0)
                              ClipPath(
                                clipper: TriangleClipper(),
                                child: Container(
                                  width: 25,
                                  height: 25,
                                  color: skillColor, // Dynamic color based on skill sector
                                  alignment: Alignment.center,
                                  child: Text(
                                    "$skillPoints",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Text(
                    mission['description'],
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events), // Trophy icon
            tooltip: "View Completed Missions",
            onPressed: () => _showCompletedMissions(context), // Show completed missions popup
          ),
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
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildFilterButton('Daily', 'daily', false),
                const SizedBox(width: 8),
                _buildFilterButton('Weekly', 'weekly', false),
                const SizedBox(width: 8),
                _buildFilterButton('Monthly', 'monthly', false),
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
                  : List.generate(
                      _systemMissions.where((m) => m['type'] == _systemFilter).length,
                      (index) {
                        final filteredMissions = _systemMissions.where((m) => m['type'] == _systemFilter).toList();
                        final mission = filteredMissions[index];

                        return AnimatedOpacity(
                          key: ValueKey(mission['title']),
                          duration: const Duration(milliseconds: 500),
                          opacity: mission['completed'] ? 0.0 : 1.0,
                          child: _buildMissionTile(mission, _systemMissions.indexOf(mission), false), // Use new method
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            const Text('Your Missions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildFilterButton('Daily', 'daily', true),
                const SizedBox(width: 8),
                _buildFilterButton('Weekly', 'weekly', true),
                const SizedBox(width: 8),
                _buildFilterButton('Monthly', 'monthly', true),
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
                        itemCount: _userMissions.where((m) => m['type'] == _userFilter).length,
                        itemBuilder: (context, index) {
                          final filteredMissions = _userMissions.where((m) => m['type'] == _userFilter).toList();
                          final mission = filteredMissions[index];
                          return AnimatedOpacity(
                            key: ValueKey(mission['title']),
                            duration: const Duration(milliseconds: 500),
                            opacity: mission['completed'] ? 0.0 : 1.0,
                            child: Dismissible(
                              key: ValueKey(mission['title']),
                              onDismissed: (_) {
                                _deleteMission(_userMissions.indexOf(mission)); // Ensure correct index when deleting
                              },
                              child: _buildMissionTile(mission, _userMissions.indexOf(mission), true), // Use _buildMissionTile
                            ),
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

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width / 2, 0); // Top point
    path.lineTo(size.width, size.height); // Bottom right
    path.lineTo(0, size.height); // Bottom left
    path.close(); // Complete the triangle
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
