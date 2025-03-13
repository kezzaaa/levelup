
// ignore_for_file: library_private_types_in_public_api

// Packages
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Files
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = "@username"; // Placeholder username
  String fullName = "John Doe"; // Placeholder full name
  String profilePath = ""; // Path for the selected avatar image
  String joinDate = "Unknown"; // Default placeholder for join date

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user details from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = "@${prefs.getString('username') ?? 'username'}";
      fullName = prefs.getString('fullName') ?? "John Doe";
      profilePath = prefs.getString('profilePath') ?? "";
      joinDate = prefs.getString('joinDate') ?? "Unknown";
    });

    debugPrint("📤 Loaded Profile Path: $profilePath");
    debugPrint("📆 Join Date: $joinDate");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Account"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Row
            Row(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: ClipOval(
                    child: SizedBox(
                      width: 80, // Ensure the same width in both screens
                      height: 80, // Ensure the same height in both screens
                      child: Image(
                        image: (profilePath.isNotEmpty && File(profilePath).existsSync())
                            ? FileImage(File(profilePath)) as ImageProvider
                            : const AssetImage('assets/images/defaultpicture.png'),
                        fit: BoxFit.cover, // ✅ Ensure proper scaling
                      ),
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
                // Row containing the title and button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title: "Customise My Missions"
                    const Text(
                      "Customise My Missions",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    
                    // Green Button: "Choose Exclusions"
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to Exclusions Screen (to be implemented)
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ExclusionsScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // Green background
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      ),
                      child: const Text("Update Exclusions",
                      style: TextStyle(color: Colors.white,
                      fontSize: 14,
                      )),
                    ),
                  ],
                ),

                const SizedBox(height: 12), // Space before rotating stack

                // Swipeable Stack (PageView)
                SizedBox(
                  height: 150, // Set fixed height
                  child: PageView.builder(
                    itemCount: 5, // 5 questions
                    controller: PageController(viewportFraction: 0.9), // Makes it look swipeable
                    itemBuilder: (context, index) {
                      return Container(
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
                        child: Center(
                          child: Text(
                            _questions[index], // Dynamic question text
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30), // Space before settings button
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
                  "Settings",
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
                  "Log Out",
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
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
              // Profile Picture
              Stack(
                alignment: Alignment.center, // Ensures the elements stay properly aligned
                children: [
                  // Profile Picture
                  GestureDetector(
                    onTap: _pickImage, // ✅ Opens gallery
                    child: ClipOval(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: (profilePath.isNotEmpty && File(profilePath).existsSync())
                                ? FileImage(File(profilePath)) as ImageProvider
                                : const AssetImage('assets/images/defaultpicture.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Non-Clickable Edit Icon (Positioned at Bottom Right)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54, // ✅ Semi-transparent background
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18, // ✅ Small icon size
                      ),
                    ),
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
                  hint: const Text("Select Gender"),
                  items: ['🚹 Male', '🚺 Female'].map((String value) {
                    return DropdownMenuItem(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedGender = value),
                  dropdownColor:const Color(0xFF1C1C1C),
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
                  hint: const Text("Select Country"),
                  items: ['🦅 USA', '🍁 Canada', '☕ UK', '🐊 Australia'].map((String value) {
                    return DropdownMenuItem(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCountry = value),
                  dropdownColor:const Color(0xFF1C1C1C),
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

class ExclusionsScreen extends StatelessWidget {
  const ExclusionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Exclusions")),
      body: const Center(child: Text("Exclusions selection coming soon!")),
    );
  }
}

final List<String> _questions = [
  "Do you enjoy fitness-related challenges?",
  "Are you interested in learning new skills?",
  "Would you like gaming-related missions?",
  "Do you prefer outdoor activities?",
  "Are you okay with food-related missions?",
];

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