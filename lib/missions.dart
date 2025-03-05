// ignore_for_file: library_private_types_in_public_api

// Packages
import 'dart:math';
import 'package:flutter/material.dart';
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
    _unloadCompletedMissions();
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

  void _toggleMission(int index, bool isUserMission) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> completedMissions = prefs.getStringList('completedMissions') ?? [];

    if (!isUserMission) {
      String missionTitle = _systemMissions[index]['title'];

      setState(() {
        _systemMissions[index]['completed'] = true;
        _systemMissions[index]['removing'] = true;
      });

      if (!completedMissions.contains(missionTitle)) {
        completedMissions.add(missionTitle);
        await prefs.setStringList('completedMissions', completedMissions);
      }
    
      int xpReward = _systemMissions[index]['experience'];
      completeMission(xpReward);
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          if (isUserMission && index < _userMissions.length && _userMissions[index]['removing']) {
            _userMissions.removeAt(index);
          } else if (!isUserMission && index < _systemMissions.length && _systemMissions[index]['removing']) {
            _systemMissions.removeAt(index);
          }
        });
      }
    });
  }

  Future<void> _unloadCompletedMissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> completedMissions = prefs.getStringList('completedMissions') ?? [];

    setState(() {
      _systemMissions.removeWhere((mission) => completedMissions.contains(mission['title']));
    });
  }

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

    debugPrint("✅ Mission completed! New XP: $currentXP, Level: $currentLevel");

    // ✅ Notify `home.dart` to update XP bar
    // ignore: use_build_context_synchronously
    if (Navigator.canPop(context)) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context, xpReward); // Send XP reward back to HomeScreen
    }
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
      onPressed: () {
        setState(() {
          if (isUserFilter) {
            _setUserFilter(type);
            for (var mission in _userMissions) {
              mission['expanded'] = false;
            } // Close all expanded missions
          } else {
            _setSystemFilter(type);
            for (var mission in _systemMissions) {
              mission['expanded'] = false;
            } // Close all expanded missions
          }
        });
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
        child: isUserMission ? Icon(Icons.delete_sweep_rounded, color: Colors.white) : Icon(Icons.refresh, color: Colors.white,),
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
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // 🔲 White Outline (Always visible)
                                Icon(
                                  Icons.star_outline_rounded,
                                  color: Colors.white, // White border
                                  size: 44, // Slightly larger than main star
                                ),
                                // ⭐ Filled Star (Yellow) or Transparent Border for Empty Stars
                                Icon(
                                  i < difficulty ? Icons.star_rounded : Icons.star_border_rounded,
                                  color: i < difficulty ? const Color.fromARGB(255, 239, 215, 0) : Colors.transparent, // Filled if active, transparent if not
                                  size: 35, // Main star size
                                ),
                              ],
                            );
                          }),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // XP Indicator (Blue Circle)
                            Container(
                              width: 33, // Fixed width
                              height: 33, // Fixed height
                              alignment: Alignment.center, // Ensure text stays centered
                              decoration: BoxDecoration(
                                color: Colors.cyan,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Text(
                                "$xp",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5), // Adjust spacing between XP and triangle

                            // 🔺 Triangle and Number Wrapped in Stack
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Move triangle left
                                Transform.translate(
                                  offset: const Offset(0, 2), // Adjust the X offset (- moves left)
                                  child: CustomPaint(
                                    size: const Size(40, 40), // Adjusted size
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