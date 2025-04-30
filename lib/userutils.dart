// ignore_for_file: library_private_types_in_public_api

// Packages
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

Future<void> loadHtmlFromAssets(WebViewController controller, String asset) async {
  await controller.loadFlutterAsset(asset);
}

// Function to retrieve and process the avatar data from SharedPreferences
ProfileData? build3DAvatarUrl(SharedPreferences prefs) {
  final Map<String, dynamic> json =
    jsonDecode(prefs.getString('avatar') ?? '{}');
  if (json.isNotEmpty) {
    final avatarUrl = json['data']['url'];
    return ProfileData(avatarUrl);
  }
  return null;
}

String build2DAvatarUrl(String fullAvatarUrl) {
  const String baseUrl = "https://models.readyplayer.me/";
  // If the fullAvatarUrl starts with the baseUrl and ends with .glb,
  // extract the avatar id from it
  if (fullAvatarUrl.startsWith(baseUrl)) {
    // Remove the base and the .glb extension
    String id = fullAvatarUrl.substring(baseUrl.length).replaceAll('.glb', '');
    // Construct the 2D image URL using the id
    return "$baseUrl$id.png?blendShapes[mouthSmile]=0.8";
  }
  // Otherwise, fallback to the original URL
  return fullAvatarUrl;
}

Future<String?> createGuestUser() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? storedUserId = prefs.getString('guestUserId');

  // If a user already exists, return the same user ID
  if (storedUserId != null) {
    debugPrint("🔄 Using existing guest user ID: $storedUserId");
    return storedUserId;
  }

  // Otherwise, create a new guest user
  try {
    final response = await http.post(
      Uri.parse("https://api.readyplayer.me/v1/users"),
      headers: {
        "Content-Type": "application/json",
        "x-api-key": "sk_live_6SlgKmUtxreglkIWRKpHMDDrZu6ocfIyryLo"
      },
      body: jsonEncode({
        "data": {
          "applicationId": "67b32a1b2940b78d59ccba3a"
        }
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) { // Handle 201
      final data = jsonDecode(response.body);
      String newUserId = data['data']['id'];

      // Store the guest user ID for future app restarts
      await prefs.setString('guestUserId', newUserId);

      debugPrint("✅ Created new guest user ID: $newUserId");
      return newUserId;
    } else {
      debugPrint("❌ Failed to create guest user. Status: ${response.statusCode}");
      debugPrint("📜 Response: ${response.body}");
      return null;
    }
  } catch (e) {
    debugPrint("❌ Error creating guest user: $e");
    return null;
  }
}

String subdomain = "25210394-sz5yd2";

Future<String?> getSessionToken(String userId) async {
  final response = await http.get(
    Uri.parse(
        'https://api.readyplayer.me/v1/auth/token?userId=$userId&partner=$subdomain'),
    headers: {
      'x-api-key': 'sk_live_6SlgKmUtxreglkIWRKpHMDDrZu6ocfIyryLo'
    },
  );

  if (response.statusCode == 200 || response.statusCode == 201) { // Handle 201
    final responseData = jsonDecode(response.body);
    String token = responseData['data']['token'];
    debugPrint("✅ Successfully generated session token: $token");
    return token;
  } else {
    debugPrint("❌ Failed to generate session token. Status: ${response.statusCode}");
    debugPrint("📜 Response: ${response.body}");
    return null;
  }
}

// Global XP threshold
int getXpThresholdForLevel(int level) {
  return level * 10;
}

class ProfileData {
  ProfileData(this.avatarUrl);
  final String? avatarUrl;
}