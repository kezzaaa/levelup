
// ignore_for_file: library_private_types_in_public_api, use_key_in_widget_constructors, use_super_parameters

// Packages
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';

// Files
import 'userutils.dart';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String srcGlb = ''; // Placeholder 2D avatar URL
  String username = "@username"; // Placeholder username
  String fullName = "John Doe"; // Placeholder full name
  String profilePath = ""; // Path for the selected avatar image
  String joinDate = "Unknown"; // Default placeholder for join date
  bool useAvatar = true;

  @override
  void initState() {
    super.initState();
    _checkFirstTimeUser();
    _loadUserData();
  }

  // Load user details from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final ProfileData? profile = build3DAvatarUrl(prefs);
    setState(() {
      if (profile != null && profile.avatarUrl != null) {
        srcGlb = profile.avatarUrl!;
        debugPrint('✅ Avatar URL Loaded: $srcGlb');
      } else {
        debugPrint("❌ No avatar URL found in SharedPreferences");
      }
      username = "@${prefs.getString('username') ?? 'username'}";
      fullName = prefs.getString('fullName') ?? "John Doe";
      profilePath = prefs.getString('profilePath') ?? "";
      joinDate = prefs.getString('joinDate') ?? "Unknown";
      // Read the stored active choice. If not set, default to true.
      useAvatar = prefs.getBool('useAvatar') ?? true;
    });

    String avatar2DUrl = build2DAvatarUrl(srcGlb);
    debugPrint("2D Avatar URL: $avatar2DUrl");
    debugPrint("📤 Loaded Profile Path: $profilePath");
    debugPrint("📆 Join Date: $joinDate");
  }

  void _resetMissions() {
    setState(() {
      debugPrint("🔄 Resetting missions...");
    });
  }

  // ✅ Function to check if user has seen profile tutorial before
  Future<void> _checkFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenTutorial = prefs.getBool('hasSeenProfileTutorial') ?? false;

    if (!hasSeenTutorial) {
      // ✅ Show tutorial pop-up
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showProfileTutorial(context);
      });

      // ✅ Mark tutorial as seen
      await prefs.setBool('hasSeenProfileTutorial', true);
    }
  }

  void _showProfileTutorial(BuildContext context) {
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
                  "Welcome to the Profile Page",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "• Edit your details ✏️\n"
                  "• Pin achievements to your profile 🏅\n"
                  "• Filter your missions with swipeable questions that make them more personalised! ⭐\n"
                  "• Change settings ⚙️\n",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Your Account",
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: IconButton(
              icon: const Icon(Icons.help_center_outlined, color: Colors.white),
              onPressed: () => _showProfileTutorial(context),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Row
            Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: useAvatar
                        ? Transform.translate(
                            offset: const Offset(2.5, 25), // Shift upward
                            child: Transform.scale(
                              scale: 2, // Zoom in the 2D avatar
                              child: Image(
                                image: srcGlb.isNotEmpty
                                    ? NetworkImage(build2DAvatarUrl(srcGlb))
                                    : const AssetImage('assets/images/defaultpicture.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : (profilePath.isNotEmpty && File(profilePath).existsSync())
                            ? Image.file(
                                File(profilePath),
                                fit: BoxFit.cover,
                              )
                            : const Image(
                                image: AssetImage('assets/images/defaultpicture.png'),
                                fit: BoxFit.cover,
                              ),
                  ),
                ),
                const SizedBox(width: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      username,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                IconButton(
                  icon: const Icon(Icons.edit_square, color: Colors.white),
                  onPressed: () async {
                    bool? updated = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                    );

                    if (updated == true) {
                      _loadUserData();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title: Pinned Achievements
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    "Pinned Achievements",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 12), // Space before hexagons

                // Row with Hexagon Achievement Slots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) => _buildHexagonSlot()), // Generates 3 placeholders
                ),
              ],
            ),
            const SizedBox(height: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Button Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Customise My Missions",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),

                    Row(
                      children: [
                        // Trash Button: Clears all saved data
                        IconButton(
                          onPressed: () async {
                            bool confirmDelete = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text("Confirm Reset"),
                                  content: const Text(
                                    "Are you sure you want to clear all saved interests and mission preferences? \n\n"
                                    "This action cannot be undone. \n\n"
                                    "(Page must be refreshed)",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false), // Cancel action
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true), // Confirm action
                                      child: const Text("Clear", style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmDelete == true) {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.remove('userPreferences'); // Clear saved preferences
                              await prefs.remove('answeredQuestions'); // Clear dismissed questions

                              debugPrint("🗑️ All saved tags and dismissed missions cleared.");
                            }
                          },
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.white, // White trash icon
                            size: 24,
                          ),
                          tooltip: "Reset Preferences", // Shows on long-press
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12), // Space before rotating stack

                // ✅ Add Swipeable Question Stack Here
                SwipeableQuestionStack(onReset: _resetMissions),

                const SizedBox(height: 30), // Space before settings button
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()), // Navigate to Settings
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "⚙️ Settings",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()), // Navigate to Login
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "🏃‍➡️ Log Out",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // ✅ Been leveling up since [joinDate]
            Center(
              child: Text(
                "Been leveling up since: $joinDate",
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
          ], 
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  String? _selectedGender;
  final TextEditingController _selectedDateOfBirth = TextEditingController();
  String? _selectedCountry;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String username = "";
  String profilePath = "";
  final ImagePicker _picker = ImagePicker();
  String srcGlb = "";
  bool _useAvatar = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final ProfileData? profile = build3DAvatarUrl(prefs);
    setState(() {
      if (profile != null && profile.avatarUrl != null) {
        srcGlb = profile.avatarUrl!;
        debugPrint('✅ Avatar URL Loaded: $srcGlb');
      } else {
        debugPrint("❌ No avatar URL found in SharedPreferences");
      }
      _firstNameController.text = prefs.getString('firstName') ?? "";
      _lastNameController.text = prefs.getString('lastName') ?? "";
      _selectedGender = prefs.getString('gender') ?? "";
      _selectedDateOfBirth.text = prefs.getString('dob') ?? ""; // ✅ Corrected assignment
      _selectedCountry = prefs.getString('location') ?? "";
      _emailController.text = prefs.getString('email') ?? "";
      _phoneController.text = prefs.getString('phone') ?? "";
      username = prefs.getString('username') ?? "@username";
      profilePath = prefs.getString('profilePath') ?? "";
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String fullName = "$firstName $lastName";

    await prefs.setString('firstName', firstName);
    await prefs.setString('lastName', lastName);
    await prefs.setString('fullName', fullName);
    await prefs.setString('gender', _selectedGender ?? "");
    await prefs.setString('dob', _selectedDateOfBirth.text.trim());
    await prefs.setString('location', _selectedCountry ?? "");
    await prefs.setString('email', _emailController.text);
    await prefs.setString('phone', _phoneController.text);

    // Save which image is active:
    await prefs.setBool('useAvatar', _useAvatar);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profilePath', pickedFile.path);
      setState(() {
        profilePath = pickedFile.path;
      });
    }
  }

  // Function to show the date picker
  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) { // ✅ Ensure a date was picked
      setState(() {
        _selectedDateOfBirth.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  String getLocalPath(String path) {
    return Uri.parse(path).toFilePath();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Discard changes and go back
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // ✅ Prevents unnecessary scrolling
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Picture + Toggle Stack
              Column(
                children: [
                  const Text(
                    "Select Active Profile Picture",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // "Your Avatar" Option (2D Avatar)
                      Column(
                        children: [
                          const Text(
                            "Your Avatar:",
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              // Set this option as active
                              setState(() {
                                _useAvatar = true;
                              });
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                // Highlight with a white border if _useAvatar is true
                                border: _useAvatar
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                              ),
                              child: ClipOval(
                                child: SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Transform.translate(
                                    offset: const Offset(2.5, 25), // Shift upward
                                    child: Transform.scale(
                                      scale: 2, // Zoom in
                                      child: Image(
                                        image: srcGlb.isNotEmpty
                                            ? NetworkImage(build2DAvatarUrl(srcGlb))
                                            : const AssetImage('assets/images/defaultpicture.png'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // "Custom Image" Option (Uploaded image)
                      Column(
                        children: [
                          const Text(
                            "Custom Image:",
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              // Tapping the custom image sets it as active (highlighted)
                              setState(() {
                                _useAvatar = false;
                              });
                            },
                            child: Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    // Highlight if _useAvatar is false
                                    border: !_useAvatar
                                        ? Border.all(color: Colors.white, width: 2)
                                        : null,
                                  ),
                                  child: ClipOval(
                                    child: (profilePath.isNotEmpty &&
                                            File(getLocalPath(profilePath)).existsSync())
                                        ? Image.file(
                                            File(getLocalPath(profilePath)),
                                            fit: BoxFit.cover,
                                          )
                                        : const Image(
                                            image: AssetImage('assets/images/defaultpicture.png'),
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                                // Positioned edit icon; tapping opens image picker
                                Positioned(
                                  bottom: -5,
                                  right: -5,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF212121), // Grey circle background
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                                      onPressed: () {
                                        // Open image picker
                                        _pickImage();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16), // Reduced spacing

              // Input Fields
              _buildTextField("First Name", _firstNameController),
              _buildTextField("Last Name", _lastNameController),
              _buildTextField("Username", TextEditingController(text: username), isEditable: false),
              const SizedBox(height: 10),

              // Gender Dropdown
              SizedBox(
                height: 75, // Reduced height
                child: DropdownButtonFormField<String>(
                  value: _selectedGender,
                  hint: Text(
                    "Select Gender",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  items: ['🚹 Male', '🚺 Female'].map((String value) {
                    return DropdownMenuItem(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedGender = value),
                  dropdownColor: const Color(0xFF141414),
                  decoration: const InputDecoration(labelText: "Gender"),
                ),
              ),

              // Birth Date Picker
              SizedBox(
                height: 75,
                child: TextFormField(
                  controller: _selectedDateOfBirth,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: const InputDecoration(
                    labelText: 'Birth Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),

              // Country Dropdown
              SizedBox(
                height: 65,
                child: DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  hint: Text(
                    "Select Country",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  items: ['🇺🇸 USA', '🇨🇦 Canada', '🇬🇧 UK', '🇦🇺 Australia'].map((String value) {
                    return DropdownMenuItem(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCountry = value),
                  dropdownColor: const Color(0xFF141414),
                  decoration: const InputDecoration(labelText: "Country"),
                ),
              ),

              _buildTextField("Email", _emailController),
              _buildTextField("Phone", _phoneController),

              const SizedBox(height: 10),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text("Save and Update"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isEditable = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        enabled: isEditable,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

Widget _buildHexagonSlot() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: ClipPath(
      clipper: HexagonClipper(),
      child: Container(
        width: 80, // Hexagon size
        height: 85,
        decoration: BoxDecoration(
          color: Colors.grey[700], // Dark grey placeholder
        ),
        child: const Center(
          child: Icon(Icons.add, color: Colors.white, size: 24), // White "+" icon
        ),
      ),
    ),
  );
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double width = size.width;
    final double height = size.height;
    final double heightOffset = height / 4;

    Path path = Path()
      ..moveTo(width * 0.5, 0)
      ..lineTo(width, heightOffset)
      ..lineTo(width, height - heightOffset)
      ..lineTo(width * 0.5, height)
      ..lineTo(0, height - heightOffset)
      ..lineTo(0, heightOffset)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class Question {
  final String text;
  final String tag;

  Question({required this.text, required this.tag});
}

class SwipeableQuestionStack extends StatefulWidget {
  final VoidCallback onReset;

  const SwipeableQuestionStack({Key? key, required this.onReset}) : super(key: key);

  @override
  _SwipeableQuestionStackState createState() => _SwipeableQuestionStackState();
}

class _SwipeableQuestionStackState extends State<SwipeableQuestionStack> {
  final List<Question> _allQuestions = [
  Question(text: "Are you vegetarian?", tag: "vegetarian"),
  Question(text: "Are you a morning person?", tag: "morning_person"),
  Question(text: "Do you prefer a minimalist lifestyle?", tag: "minimalist"),
  Question(text: "Do you enjoy spending time outdoors?", tag: "outdoors"),
  Question(text: "Are you more of a homebody?", tag: "homebody"),
  Question(text: "Do you prefer quiet evenings over loud parties?", tag: "quiet_evenings"),
  Question(text: "Are you environmentally conscious?", tag: "environmentally_conscious"),
  Question(text: "Do you enjoy exploring new cuisines?", tag: "exploring_cuisines"),
  Question(text: "Do you prefer urban living over suburban or rural life?", tag: "urban_living"),
  Question(text: "Do you enjoy creative hobbies (like painting, writing, etc.)?", tag: "creative_hobbies"),
  Question(text: "Are you a fan of reading and literature?", tag: "reading"),
];

  List<Question> _questions = [];
  Set<String> savedTags = {};
  Set<String> answeredTags = {}; // Tracks answered questions by their tag
  bool _currentCardIsHearted = false;

  @override
  void initState() {
    super.initState();
    _loadSavedTags();
    _loadAnsweredQuestions();
  }

  /// Load answered questions by their tags and filter them out
  Future<void> _loadAnsweredQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      answeredTags = (prefs.getStringList('answeredQuestions') ?? []).toSet();
      _questions = _allQuestions.where((q) => !answeredTags.contains(q.tag)).toList();
      _questions.shuffle(Random()); // Randomize order on startup
    });
  }

  /// Save answered question by tag
  Future<void> _markQuestionAsAnswered(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    answeredTags.add(tag);
    await prefs.setStringList('answeredQuestions', answeredTags.toList());
  }

  Future<void> _loadSavedTags() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedTags = (prefs.getStringList('userPreferences') ?? []).toSet();
    });
  }

  Future<void> _saveTag(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> storedTags = prefs.getStringList('userPreferences') ?? [];

    if (!storedTags.contains(tag)) {
      storedTags.add(tag);
      await prefs.setStringList('userPreferences', storedTags);
      setState(() {
        savedTags.add(tag);
      });
      debugPrint("✅ Tag Saved: $tag");
    }
  }

  void _removeCurrentQuestion() {
    if (_questions.isNotEmpty) {
      String removedTag = _questions.first.tag;
      _questions.removeAt(0);
      _markQuestionAsAnswered(removedTag);
      setState(() {
        _currentCardIsHearted = false;
      });
    }
  }

  void _toggleHeart() {
    setState(() {
      if (savedTags.contains(_questions[0].tag)) {
        savedTags.remove(_questions[0].tag);
        _currentCardIsHearted = false;
      } else {
        savedTags.add(_questions[0].tag);
        _currentCardIsHearted = true;
      }
    });
  }

  void resetMissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userPreferences');
    await prefs.remove('answeredQuestions');

    setState(() {
      answeredTags.clear();
      savedTags.clear();
      _questions = List.from(_allQuestions);
      _questions.shuffle(Random());
    });

    debugPrint("🗑️ Questions and tags reset.");
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: MediaQuery.of(context).size.width * 0.9,
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1), // New cards slide in from the bottom.
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
          child: _questions.isEmpty
              ? const Center(
                  key: ValueKey("empty"),
                  child: Text(
                    "🏆 No more questions!",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                )
              : GestureDetector(
                  key: ValueKey(_questions[0].tag),
                  onDoubleTap: _toggleHeart,
                  child: Dismissible(
                    key: ValueKey<String>(_questions[0].tag),
                    direction: DismissDirection.up,
                    confirmDismiss: (direction) async {
                      if (_currentCardIsHearted) {
                        _saveTag(_questions[0].tag); // Save by tag
                      }
                      return true;
                    },
                    onDismissed: (direction) {
                      _removeCurrentQuestion();
                    },
                    background: Align(
                      alignment: Alignment.center,
                      child: Icon(
                        _currentCardIsHearted ? Icons.add : Icons.close,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1C),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _questions[0].text,
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          IconButton(
                            onPressed: _toggleHeart,
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(scale: animation, child: child);
                              },
                              child: savedTags.contains(_questions[0].tag)
                                  ? Icon(Icons.favorite, key: const ValueKey('filled'), color: Colors.red, size: 30)
                                  : Icon(Icons.favorite_border, key: const ValueKey('border'), color: Colors.white, size: 30),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: const Center(
        child: Text(
          "Settings Page",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}