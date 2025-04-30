// ignore_for_file: library_private_types_in_public_api, use_super_parameters

// Packages
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Files
import 'main.dart';

String build2DAvatarUrl(String srcGlb) {
  return srcGlb;
}

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  _SocialScreenState createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Dummy friend profiles
  final List<Map<String, String>> _friends = [
    {
      "username": "@johndoe",
      "firstName": "John",
      "avatarUrl": "https://models.readyplayer.me/67e80533d9b62ad194ad77ea.png?blendShapes[mouthSmile]=0.8",
      "online": "true",
    },
    {
      "username": "@janedoe",
      "firstName": "Jane",
      "avatarUrl": "https://models.readyplayer.me/67e8050620fb15c07d852697.png?blendShapes[mouthSmile]=0.8",
      "online": "false",
    },
    {
      "username": "@mikesmith",
      "firstName": "Mike",
      "avatarUrl": "https://models.readyplayer.me/67e80552fecd1f4a86c16fc8.png?blendShapes[mouthSmile]=0.8",
      "online": "true",
    },
  ];

  // Dummy user profiles
  final List<Map<String, dynamic>> _users = [
    {
      "username": "@allycat",
      "firstName": "Alice",
      "avatarUrl": "https://models.readyplayer.me/67e7f1ad636cf9b459b6e934.png?blendShapes[mouthSmile]=0.8",
      "3dAvatarUrl": "https://models.readyplayer.me/67e7f1ad636cf9b459b6e934.glb",
      "pictures": [
        "https://picsum.photos/id/1/600/800",
        "https://picsum.photos/id/30/600/800",
        "https://picsum.photos/id/78/600/800"
      ],
      "gender": "Female",
      "age": "24",
      "bio": "Passionate gamer and digital nomad, exploring virtual worlds and real-life adventures one level at a time.",
      "country": "🇺🇸",
      "platform": "PC",
      "level": "9",
      "discord": "allyoop#3675",
      "interests": "skateboarding, coding, dancing",
      "favouriteGame": "Overwatch 2"
    },
    {
      "username": "@bobthebuilder",
      "firstName": "Bob",
      "avatarUrl": "https://models.readyplayer.me/67e7f1ffc6a2a945818807b4.png?blendShapes[mouthSmile]=0.8",
      "3dAvatarUrl": "https://models.readyplayer.me/67e7f1ffc6a2a945818807b4.glb",
      "pictures": [
        "https://picsum.photos/id/432/600/800",
        "https://picsum.photos/id/522/600/800",
        "https://picsum.photos/id/678/600/800"
      ],
      "gender": "Male",
      "age": "20",
      "bio": "I live for epic quests, immersive storytelling, and the thrill of discovering new realms. Always ready for the next challenge!",
      "country": "🇨🇦",
      "platform": "Playstation",
      "level": "12",
      "discord": "bobbingduck#7775",
      "interests": "taekwondo, climbing, photography",
      "favouriteGame": "Valorant"
    },
    {
      "username": "@chezza",
      "firstName": "Charlie",
      "avatarUrl": "https://models.readyplayer.me/67e7f1e2f4667aed0b22c4b1.png?blendShapes[mouthSmile]=0.8",
      "3dAvatarUrl": "https://models.readyplayer.me/67e7f1e2f4667aed0b22c4b1.glb",
      "pictures": [
        "https://picsum.photos/id/777/600/800",
        "https://picsum.photos/id/865/600/800",
        "https://picsum.photos/id/932/600/800"
      ],
      "gender": "Male",
      "age": "22",
      "bio": "Tech-savvy and competitive—whether it's a tournament or a casual session, I'm all in for gaming and life upgrades.",
      "country": "🇬🇧",
      "platform": "Playstation",
      "level": "3",
      "discord": "chezzacheese#6969",
      "interests": "cars, guitar, boxing",
      "favouriteGame": "Rocket League"
    },
    {
      "username": "@sureshsuresh",
      "firstName": "Suresh",
      "avatarUrl": "https://models.readyplayer.me/67e7f165e1b76ee38bde3a12.png?blendShapes[mouthSmile]=0.8",
      "3dAvatarUrl": "https://models.readyplayer.me/67e7f165e1b76ee38bde3a12.glb",
      "pictures": [
        "https://picsum.photos/id/101/600/800",
        "https://picsum.photos/id/117/600/800",
        "https://picsum.photos/id/129/600/800"
      ],
      "gender": "Male",
      "age": "19",
      "bio": "A lover of indie games, quirky humor, and creative escapes. I thrive on late-night sessions and unexpected digital journeys.",
      "country": "🇮🇳",
      "platform": "Mobile",
      "level": "8",
      "discord": "sureshsureshsuresh#9999",
      "interests": "piano, cleaning, music",
      "favouriteGame": "PUBG: Battlegrounds"
    },
    {
      "username": "@adamandeve",
      "firstName": "Eve",
      "avatarUrl": "https://models.readyplayer.me/67e7f1333dcb59a654edd8b2.png?blendShapes[mouthSmile]=0.8",
      "3dAvatarUrl": "https://models.readyplayer.me/67e7f1333dcb59a654edd8b2.glb",
      "pictures": [
        "https://picsum.photos/id/130/600/800",
        "https://picsum.photos/id/149/600/800",
        "https://picsum.photos/id/151/600/800"
      ],
      "gender": "Female",
      "age": "17",
      "bio": "Just a casual gamer with a passion for fantasy worlds, friendly competition, and making every play session count.",
      "country": "🇦🇺",
      "platform": "Xbox",
      "level": "5",
      "discord": "eeveelover#1234",
      "interests": "violin, cooking, arts and crafts",
      "favouriteGame": "Stardew Valley"
    },
  ];

  // Mapping of platform names to FontAwesome icons
  final Map<String, IconData> platformIcons = {
    "PC": FontAwesomeIcons.desktop,
    "Playstation": FontAwesomeIcons.playstation,
    "Xbox": FontAwesomeIcons.xbox,
    "Mobile": FontAwesomeIcons.mobile,
  };

  List<Map<String, dynamic>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = _users;
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFriendTile(Map<String, String> friend) {
    final avatarUrl = build2DAvatarUrl(friend['avatarUrl']!);
    final bool online = friend['online'] == "true";
    return GestureDetector(
      onTap: () => {},
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(avatarUrl),
                  backgroundColor: Colors.transparent,
                ),
                if (online)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              friend['firstName']!,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              friend['username']!,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
  
  // New filter state variables
  String _selectedAge = "All";
  String _selectedGender = "All";
  String _selectedCountry = "All";
  String _selectedPlatform = "All";

  // Updated filter function to include selected filters
  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final username = user['username']!.toLowerCase();
        final firstName = user['firstName']!.toLowerCase();
        final age = int.tryParse(user['age']!) ?? 0;
        final gender = user['gender']!;
        final country = user['country']!;
        final platform = user['platform']!;

        // Text filter check
        bool matchesQuery = username.contains(query) || firstName.contains(query);

        // Age filter check (example logic)
        bool matchesAge = true;
        if (_selectedAge != "All") {
          if (_selectedAge == "16-18") {
            matchesAge = age >= 16 && age <= 18;
          } else if (_selectedAge == "18+") {
            matchesAge = age >= 18;
          } else if (_selectedAge == "21+") {
            matchesAge = age >= 21;
          }
        }

        // Gender filter check
        bool matchesGender = _selectedGender == "All" || gender.toLowerCase() == _selectedGender.toLowerCase();

        // Country filter check
        bool matchesCountry = _selectedCountry == "All" || country == _selectedCountry;

        // Platform filter check
        bool matchesPlatform = _selectedPlatform == "All" || platform == _selectedPlatform;

        return matchesQuery && matchesAge && matchesGender && matchesCountry && matchesPlatform;
      }).toList();
    });
  }

  // Show a dialog with search settings filters
    void _showSearchSettingsDialog() {
    // Temporary variables to hold the new selections
    String tempAge = _selectedAge;
    String tempGender = _selectedGender;
    String tempCountry = _selectedCountry;
    String tempPlatform = _selectedPlatform;

    showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder to manage state within the dialog
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Search Filters"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Age filter
                    DropdownButtonFormField<String>(
                      value: tempAge,
                      dropdownColor: const Color(0xFF141414),
                      decoration: const InputDecoration(labelText: "Age Range"),
                      items: <String>["All", "16-18", "18+", "21+"].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          tempAge = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    // Gender filter
                    DropdownButtonFormField<String>(
                      value: tempGender,
                      dropdownColor: const Color(0xFF141414),
                      decoration: const InputDecoration(labelText: "Gender"),
                      items: <String>["All", "Male", "Female", "Other"].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          tempGender = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    // Country filter
                    DropdownButtonFormField<String>(
                      value: tempCountry,
                      dropdownColor: const Color(0xFF141414),
                      decoration: const InputDecoration(labelText: "Country"),
                      items: <String>["All", "🇺🇸", "🇨🇦", "🇬🇧", "🇮🇳", "🇦🇺"].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          tempCountry = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    // Platform filter
                    DropdownButtonFormField<String>(
                      value: tempPlatform,
                      dropdownColor: const Color(0xFF141414),
                      decoration: const InputDecoration(labelText: "Platform"),
                      items: <String>["All", "PC", "Playstation", "Xbox", "Mobile"].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          tempPlatform = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update the state variables with the new filter values
                    setState(() {
                      _selectedAge = tempAge;
                      _selectedGender = tempGender;
                      _selectedCountry = tempCountry;
                      _selectedPlatform = tempPlatform;
                    });
                    _filterUsers(); // Re-apply filtering with new settings
                    Navigator.pop(context);
                  },
                  child: const Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openProfileDetail(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text("Social Tab"),
            actions: [
              Padding(
                padding: const EdgeInsets.only(left: 0),
                child: IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    // Handle profile icon tap
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 0),
                child: IconButton(
                  icon: const Icon(Icons.chat),
                  onPressed: () {
                    // Handle chat icon tap
                  },
                ),
              ),
              // Email icon with notification badge
              Padding(
                padding: const EdgeInsets.only(left: 0),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.email),
                      onPressed: () {
                        // Handle email icon tap
                      },
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: const Center(
                          child: Text(
                            "1",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
                  icon: const Icon(Icons.leaderboard),
                  onPressed: () {
                    // Handle leaderboard icon tap
                  },
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Friends section header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Friends (${_friends.length})",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Horizontal friend list
              SizedBox(
                height: 120,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _friends.length,
                    itemBuilder: (context, index) {
                      final friend = _friends[index];
                      return _buildFriendTile(friend);
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Search bar with settings icon
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "User Lookup",
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Search users...",
                            prefixIcon: const Icon(Icons.search),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 0, horizontal: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune, color: Colors.white),
                        onPressed: _showSearchSettingsDialog,
                      ),
                    ),
                  ],
                ),
              ),
              // List of user profile tiles
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    final avatarUrl = build2DAvatarUrl(user['avatarUrl']!);
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1C),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              offset: const Offset(0, 3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(avatarUrl),
                            backgroundColor: Colors.transparent,
                          ),
                          title: Text(
                            "${user['firstName']!}, ${user['age']}",
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            user['username']!,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.cyan,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    user['level']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user['country']!,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                platformIcons[user['platform']!] ??
                                    FontAwesomeIcons.question,
                                size: 16,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                          onTap: () => _openProfileDetail(user),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Blur overlay covering the entire screen (app bar and body)
        ValueListenableBuilder<bool>(
          valueListenable: blurEnabledNotifier,
          builder: (context, isBlurEnabled, child) {
            if (!isBlurEnabled) {
              return const SizedBox.shrink();
            }
            return Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    color: Colors.black.withOpacity(0.2),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            "🔒",
                            style: TextStyle(fontSize: 64),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Social features disabled.\nWant to unlock it? Change it in the settings.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
  
class ProfileDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ProfileDetailScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ProfileDetailScreenState createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  bool _infoOverlayVisible = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Helper to load local assets for your viewer
  Future<WebResourceResponse?> _shouldInterceptRequest(
    InAppWebViewController controller,
    WebResourceRequest request,
  ) async {
    if (request.url.toString().startsWith("https://localhost/assets/")) {
      String assetPath = request.url.toString().replaceFirst("https://localhost/assets/", "assets/");
      try {
        ByteData data = await rootBundle.load(assetPath);
        return WebResourceResponse(
          data: data.buffer.asUint8List(),
          contentType: _getMimeType(assetPath),
        );
      } catch (e) {
        debugPrint("❌ Error loading asset: $e");
        return null;
      }
    }
    return null;
  }

  // Basic MIME-type helper
  String _getMimeType(String path) {
    if (path.endsWith(".html")) return "text/html";
    if (path.endsWith(".js")) return "application/javascript";
    if (path.endsWith(".css")) return "text/css";
    if (path.endsWith(".glb")) return "model/gltf-binary";
    if (path.endsWith(".fbx")) return "application/octet-stream";
    return "text/plain";
  }

  // When the carousel is tapped, move to the next image.
  void _goToNextImage() {
    setState(() {
      _currentPage = (_currentPage + 1) % _carouselImages.length;
    });
    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  // Get the user's carousel images from the "pictures" key. Fallback to avatarUrl if missing.
  List<String> get _carouselImages {
    debugPrint("Pictures value: ${widget.user["pictures"]}");
    if (widget.user.containsKey("pictures") && widget.user["pictures"] != null) {
      return List<String>.from(widget.user["pictures"] as List);
    } else {
      return [widget.user["avatarUrl"]!];
    }
  }

  // Mapping of platform names to FontAwesome icons
  final Map<String, IconData> platformIcons = {
    "PC": FontAwesomeIcons.desktop,
    "Playstation": FontAwesomeIcons.playstation,
    "Xbox": FontAwesomeIcons.xbox,
    "Mobile": FontAwesomeIcons.mobile,
  };

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final String firstName = user['firstName'] ?? "User";
    final String age = user['age'] ?? "??";
    final String glbUrl = user['3dAvatarUrl'] ?? ""; // 3D avatar will now be shown in the bio section

    return Scaffold(
      appBar: AppBar(
      ),
      body: Column(
        children: [
          // Top 85%: Tinder-style area with carousel and segment indicators.
          Expanded(
            flex: 850,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Stack(
                  children: [
                    // Carousel PageView (tapping cycles images)
                    GestureDetector(
                      onTap: _goToNextImage,
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _carouselImages.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              _carouselImages[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          );
                        },
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                      ),
                    ),
                    // Segment indicators at the top
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_carouselImages.length, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 12 : 8,
                            height: _currentPage == index ? 12 : 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index ? Colors.white : Colors.white54,
                            ),
                          );
                        }),
                      ),
                    ),
                    // Fade/blur effect at the bottom of the carousel so the name/age can be read
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 300,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black87,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // First name and age over the fade area
                    Positioned(
                      left: 16,
                      bottom: 80,
                      child: Text(
                        "$firstName, $age",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 5,
                              color: Colors.black,
                            )
                          ],
                        ),
                      ),
                    ),
                    // User bio below the name and age
                    Positioned(
                      left: 16,
                      bottom: 20, // Adjust to position bio closer to the bottom fade area
                      right: 70, // So it doesn't overflow
                      child: Text(
                        user['bio'] ?? "",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 5,
                              color: Colors.black,
                            )
                          ],
                        ),
                      ),
                    ),
                    // Down arrow to toggle overlay.
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _infoOverlayVisible = !_infoOverlayVisible;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                          child: Icon(
                            _infoOverlayVisible
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                    // Animated overlay that slides up from the bottom when expanded
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: 0,
                      right: 0,
                      bottom: _infoOverlayVisible ? 0 : -600, // Off-screen when hidden
                      child: Container(
                        height: 375,
                        clipBehavior: Clip.none, // Allow content to overflow
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1C),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none, // Ensure children can overflow
                          children: [
                            // InAppWebView for 3D Avatar that clips upward
                            if (_infoOverlayVisible)
                              Positioned(
                                top: -275, // Negative offset to show part outside the overlay
                                left: 0,
                                right: 0,
                                child: SizedBox(
                                  height: 400,
                                  child: InAppWebView(
                                    initialUrlRequest: URLRequest(
                                      url: WebUri("https://localhost/assets/viewer.html"),
                                    ),
                                    initialSettings: InAppWebViewSettings(
                                      transparentBackground: true,
                                      allowFileAccess: true,
                                      allowUniversalAccessFromFileURLs: true,
                                      allowFileAccessFromFileURLs: true,
                                      clearCache: true,
                                      disableVerticalScroll: true,
                                    ),
                                    shouldInterceptRequest: _shouldInterceptRequest,
                                    onLoadStop: (controller, url) async {
                                      if (glbUrl.isNotEmpty) {
                                        await controller.evaluateJavascript(
                                          source: "loadGLBModel('$glbUrl');",
                                        );
                                        debugPrint("3D Avatar URL passed to viewer: $glbUrl");
                                      }
                                    },
                                  ),
                                ),
                              ),
                            // Expand/collapse button positioned at the top right of the overlay
                            Positioned(
                              top: 20,
                              right: 20,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _infoOverlayVisible = false;
                                  });
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green,
                                  ),
                                  child: const Icon(
                                    Icons.keyboard_arrow_up,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                            // Important icons: country and platform
                            Positioned(
                              top: 20,
                              left: 20,
                              child: Row(
                                children: [
                                  Text(
                                    widget.user['country'] ?? "",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    platformIcons[widget.user['platform']] ?? FontAwesomeIcons.question,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                            // Level indicator
                            Positioned(
                              top: 60,
                              left: 20,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.cyan,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    widget.user['level'] ?? "",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Discord info
                            Positioned(
                              top: 150,
                              left: 0,
                              right: 0,
                              child: Align(
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141414),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        FontAwesomeIcons.discord,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        widget.user['discord'] ?? "",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Bio text, interests, and favourite game
                            Positioned(
                              bottom: 40,
                              left: 22,
                              right: 22,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.user['bio'] ?? "No bio provided.",
                                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Interests: ${widget.user['interests'] ?? "No interests provided."}",
                                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Favourite Game: ${widget.user['favouriteGame'] ?? "None"}",
                                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom 15%: Profile actions and friend request message.
          Expanded(
            flex: 150,
            child: Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 32),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Block action placeholder
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Icon(Icons.block, color: Colors.white),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Follow action placeholder
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Icon(Icons.person_add, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: "Enter message...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Follow action placeholder.
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}