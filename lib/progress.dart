// ignore_for_file: library_private_types_in_public_api

// Packages
import 'package:flutter/material.dart';

// Progress Screen
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Progress Screen",
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
