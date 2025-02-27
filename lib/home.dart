// ignore: library_private_types_in_public_api

// Packages
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

// Files
import 'utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.username});

  final String username;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  InAppWebViewController? webViewController;
  String srcGlb = '';

  @override
  void initState() {
    super.initState();
    _loadAvatar();
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
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri("https://localhost/assets/viewer.html"), // ✅ Correct WebView URL
        ),
        initialSettings: InAppWebViewSettings(
          transparentBackground: true,
          allowFileAccess: true,
          allowUniversalAccessFromFileURLs: true,
          allowFileAccessFromFileURLs: true,
          clearCache: true,
          useShouldInterceptRequest: true, // ✅ Allow local asset loading
        ),
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
        shouldInterceptRequest: (controller, request) async {
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
        },
        onLoadStop: (controller, url) async {
          if (webViewController != null && srcGlb.isNotEmpty) {
            String jsCode = "loadGLBModel('$srcGlb');"; // ✅ Call JavaScript function
            await webViewController!.evaluateJavascript(source: jsCode);
            debugPrint("✅ Passed GLB URL to WebView: $srcGlb");
          }
        },
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
