// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';

class AchievementsScreen extends StatelessWidget {
  // Pass achievements data here.
  final List<String>? achievements;

  const AchievementsScreen({Key? key, this.achievements}) : super(key: key);

  // Generates a single hexagon slot with a question icon in the middle
  Widget _buildHexagonSlot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipPath(
        clipper: HexagonClipper(),
        child: Container(
          width: 80, // Hexagon size
          height: 85,
          decoration: BoxDecoration(
            color: Colors.grey[700],
          ),
          child: const Center(
            child: Icon(Icons.question_mark, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Earned Achievements (0/15)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Display 12 hexagon slots in a grid (3 columns, 4 rows)
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: List.generate(15, (index) => _buildHexagonSlot()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom clipper to create a hexagon shape.
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
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
