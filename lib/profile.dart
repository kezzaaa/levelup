// ignore_for_file: library_private_types_in_public_api

// Packages
import 'package:flutter/material.dart';

// Files
import 'package:levelup/login.dart';

// ProfileScreen displaying the log-out button
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          
          // Red Log Out Button
          ElevatedButton(
            onPressed: () {
              // Implement logout logic here (e.g., clear saved user data)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()), // Navigate to LoginScreen
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // Red background color
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12), // Adjust padding if needed
            ),
            child: const Text(
              "Log Out",
              style: TextStyle(color: Colors.white), // White text
            ),
          ),
        ],
      ),
    );
  }
}

