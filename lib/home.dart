// ignore: library_private_types_in_public_api

// Packages
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

// Files
import 'utils.dart';
import 'signupprocess.dart';

// ignore: must_be_immutable
class HomeScreen extends StatefulWidget {
  String username;
  final bool shouldReload;
  final bool isEditing;

  HomeScreen({super.key, required this.username, required this.shouldReload, required this.isEditing});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  InAppWebViewController? webViewController;
  String srcGlb = '';

  @override
  void initState() {
    super.initState();
    _loadAvatar();
    _loadUsername();

    // ✅ Automatically reload WebView when returning from Avatar Editor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.shouldReload) {
        webViewController?.reload();
        debugPrint("🔄 Auto-reloading WebView...");
      }
    });
  }

  Future<void> _loadUsername() async {
  final prefs = await SharedPreferences.getInstance();
  final String? storedUsername = prefs.getString('username');

  if (storedUsername != null && storedUsername.isNotEmpty) {
    setState(() {
      widget.username = storedUsername;  // ✅ Update UI with correct username
    });
    debugPrint('✅ Username Loaded: $storedUsername');
  } else {
    debugPrint("❌ No username found in SharedPreferences");
  }
}

  // ✅ Load avatar data from SharedPreferences and update the UI
    Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final ProfileData? profile = userFromPrefs(prefs);

    if (profile != null && profile.avatarUrl != null) {
      setState(() {
        srcGlb = profile.avatarUrl!;
      });
      debugPrint('✅ Avatar URL Loaded: $srcGlb');
    } else {
      debugPrint("❌ No avatar URL found in SharedPreferences");
    }
  }

  // ✅ Open Fullscreen Avatar Creator
  void openAvatarEditor() async {
    final prefs = await SharedPreferences.getInstance();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AvatarCreatorScreen(prefs: prefs, isEditing: true),
      ),
    ).then((shouldReload) async {
      if (shouldReload == true) {
        // ✅ Fetch updated avatar URL
        final ProfileData? updatedProfile = userFromPrefs(prefs);
        if (updatedProfile != null && updatedProfile.avatarUrl != null) {
          setState(() {
            srcGlb = updatedProfile.avatarUrl!;
          });
          debugPrint("✅ Updated Avatar URL Loaded: $srcGlb");
        } else {
          debugPrint("❌ Failed to load updated avatar URL");
        }

        // ✅ Reload WebView with updated model
        webViewController?.reload();
        debugPrint("🔄 WebView reloaded after avatar edit.");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: Text(
          "Welcome, ${widget.username}!",
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              webViewController?.reload();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔹 Row 1: Top Section (Optional UI)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.1,
            child: Container(
              color: Colors.transparent,
              child: const Center(child: Text("Top Section (Stats, Info, etc.)")),
            ),
          ),

          // 🔹 Row 2: Avatar Section (WebView + Edit Icon)
          Expanded(
            flex: 5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 🌍 WebView Displaying Avatar
                InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri("https://localhost/assets/viewer.html"),
                  ),
                  initialSettings: InAppWebViewSettings(
                    transparentBackground: true,
                    allowFileAccess: true,
                    allowUniversalAccessFromFileURLs: true,
                    allowFileAccessFromFileURLs: true,
                    clearCache: true,
                    useShouldInterceptRequest: true,
                    disableVerticalScroll: true,
                  ),
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                  },
                  shouldInterceptRequest: (controller, request) async {
                    if (request.url.toString().startsWith("https://localhost/assets/")) {
                      String assetPath = request.url.toString().replaceFirst(
                          "https://localhost/assets/", "assets/");
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
                  },
                  onLoadStop: (controller, url) async {
                    final prefs = await SharedPreferences.getInstance();
                    final String? userGender = prefs.getString('userGender');

                    if (userGender != null && webViewController != null) {
                      String jsCode = "window.setUserGender('$userGender');";
                      await webViewController!.evaluateJavascript(source: jsCode);
                      debugPrint("✅ Sent user gender to WebView: $userGender");
                    }

                    if (srcGlb.isNotEmpty) {
                      String jsCode = "loadGLBModel('$srcGlb');";
                      await webViewController!.evaluateJavascript(source: jsCode);
                      debugPrint("✅ Passed GLB URL to WebView: $srcGlb");
                    }
                  },
                ),

                // ✏️ Floating Edit Button (Opens Avatar Creator)
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 30),
                    onPressed: openAvatarEditor, // 🖌️ Call function to open editor
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Row 3: Bottom Section (Buttons, Controls, etc.)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.15,
            child: Container(
              color: Colors.transparent,
              child: const Center(child: Text("Bottom Section (Buttons, Actions)")),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Helper function to get correct MIME type for assets
String _getMimeType(String path) {
  if (path.endsWith(".html")) return "text/html";
  if (path.endsWith(".js")) return "application/javascript";
  if (path.endsWith(".css")) return "text/css";
  if (path.endsWith(".glb")) return "model/gltf-binary";
  if (path.endsWith(".fbx")) return "application/octet-stream";
  return "text/plain";
}
