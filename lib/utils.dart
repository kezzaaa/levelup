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
ProfileData? userFromPrefs(SharedPreferences prefs) {
  final Map<String, dynamic> json =
    jsonDecode(prefs.getString('avatar') ?? '{}');
  if (json.isNotEmpty) {
    final avatarUrl = json['data']['url'];
    return ProfileData(avatarUrl);
  }
  return null;
}

Future<String?> createGuestUser() async {
  final response = await http.post(
    Uri.parse('https://api.readyplayer.me/v1/users'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'sk_live_6SlgKmUtxreglkIWRKpHMDDrZu6ocfIyryLo'
    },
    body: jsonEncode({
      'data': {'applicationId': '67b32a1b2940b78d59ccba3a'}
    }),
  );

  final responseData = jsonDecode(response.body);

  if (response.statusCode == 200 || response.statusCode == 201) {
    String userId = responseData['data']['id'];

    // Store user ID for session restoration
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('guestUserId', userId);

    debugPrint("✅ Successfully created guest user! ID: $userId");
    return userId;
  } else {
    debugPrint("❌ Failed to create guest user. Status: ${response.statusCode}");
    debugPrint("📜 Response: ${response.body}");
    return null;
  }
}

String subdomain = "25210394-sz5yd2";

Future<String?> getSessionToken(String userId) async {
  final response = await http.get(
    Uri.parse(
        'https://api.readyplayer.me/v1/auth/token?userId=$userId&partner=$subdomain'), // Replace with your subdomain
    headers: {
      'x-api-key': 'sk_live_6SlgKmUtxreglkIWRKpHMDDrZu6ocfIyryLo'
    },
  );

  if (response.statusCode == 200) {
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

class ProfileData {
  ProfileData(this.avatarUrl);
  final String? avatarUrl;
}