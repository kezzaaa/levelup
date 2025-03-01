// ignore_for_file: library_private_types_in_public_api

// Packages
import 'package:levelup/utils.dart';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

// Files
import 'signupprocess.dart';

class PreAvatarScreen extends StatefulWidget {
  const PreAvatarScreen({super.key});

  @override
  _PreAvatarScreenState createState() => _PreAvatarScreenState();
}

class _PreAvatarScreenState extends State<PreAvatarScreen> {
  @override
  void initState() {
    super.initState();
    
    // Delay navigation by 3 seconds
    Future.delayed(const Duration(seconds: 3), () async {
      final prefs = await SharedPreferences.getInstance();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AvatarCreatorScreen(prefs: prefs)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.primary,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Time to create your avatar!',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AvatarCreatorScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final bool isEditing;

  const AvatarCreatorScreen({super.key, required this.prefs, this.isEditing = false});

  @override
  _AvatarCreatorScreenState createState() => _AvatarCreatorScreenState();
}

class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
  late WebViewController _webViewController;
  bool _showOverlay = true; // ✅ Starts with overlay visible

  @override
  void initState() {
    super.initState();

    // ✅ Show overlay for 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showOverlay = false; // ✅ Hide overlay after delay
        });
      }
    });

    // ✅ Initialize WebViewController
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF212121))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint("Page started loading: $url");
          },
          onPageFinished: (String url) {
            debugPrint("Page finished loading: $url");
            loadGuestSession();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("WebView error: ${error.description}");
          },
        ),
      )
      ..addJavaScriptChannel(
        "AvatarCreated",
        onMessageReceived: (JavaScriptMessage message) async {
          // ✅ Save avatar to SharedPreferences
          await widget.prefs.setString('avatar', message.message);

          debugPrint('✅ Avatar URL Saved: ${message.message}');

          // ✅ Retrieve and process avatar data
          final user = userFromPrefs(widget.prefs);
          if (user != null) {
            debugPrint('✅ Avatar URL Loaded: ${user.avatarUrl}');
            if (mounted) {
              if (widget.isEditing) {
                Navigator.pop(context, true); // ✅ Go back and trigger reload
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const UsernamePasswordScreen()),
                );
              }
            }
          } else {
            debugPrint("❌ No avatar found in SharedPreferences");
          }
        },
      )
      ..loadFlutterAsset("assets/iframe.html");
  }

  Future<void> loadGuestSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('guestUserId');

    if (userId != null) {
      String? token = await getSessionToken(userId);
      if (token != null) {
        debugPrint("📢 WebView is ready! Sending token...");

        // ✅ Debug JavaScript execution
        String jsCode = """
          try {
            console.log("📤 Sending token from Flutter...");
            window.postMessage(${jsonEncode({
              "type": "setToken",
              "token": token
            })}, '*');
            console.log("✅ Token should be sent!");
          } catch (error) {
            console.error("❌ JavaScript execution error:", error);
          }
        """;

        // ✅ Ensure WebView has finished loading before injecting JavaScript
        _webViewController.runJavaScript(jsCode);
        debugPrint("📢 JavaScript injected into WebView!");
      } else {
        debugPrint("❌ Failed to get session token.");
      }
    } else {
      debugPrint("❌ Failed to get guest user ID.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (widget.isEditing) {
              // ✅ If editing, pop back to HomeScreen and trigger a refresh
              Navigator.pop(context, true);
            } else {
              // ✅ If signing up, go back to questionnaire
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const QuestionnaireScreen5()),
              );
            }
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // ✅ WebView in the background
          WebViewWidget(controller: _webViewController),

          // ✅ Fullscreen overlay (Shows for 3 seconds, then disappears)
          if (_showOverlay)
            Container(
              color: Color(0xFF212121), // 🔥 Fullscreen overlay
              alignment: Alignment.center,
              padding: EdgeInsets.only(bottom: 150), // ✅ Adjust this value to move text higher
              child: Column(
                mainAxisSize: MainAxisSize.min, // ✅ Ensures the content takes minimum space
                children: [
                  CircularProgressIndicator( // 🔥 Loading animation
                    color: Colors.white, // ✅ Match the theme
                    strokeWidth: 3, // ✅ Adjust thickness
                  ),
                  SizedBox(height: 20), // ✅ Spacing between loader & text
                  Text(
                    "Loading...",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}