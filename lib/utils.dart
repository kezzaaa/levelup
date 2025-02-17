// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

class ProfileData {
  ProfileData(this.avatarUrl);
  final String? avatarUrl;
}