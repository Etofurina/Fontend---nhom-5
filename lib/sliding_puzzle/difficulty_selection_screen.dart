import '/sliding_puzzle/level_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DifficultySelectionScreen extends StatelessWidget {
  const DifficultySelectionScreen({Key? key}) : super(key: key);

  void _navigateToLevelSelection(BuildContext context, int gridSize) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelSelectionScreen(gridSize: gridSize),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chọn Độ Khó',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DifficultyCard(
              title: 'DỄ',
              gridSizeText: '3 x 3',
              color: Colors.green.shade700,
              onTap: () => _navigateToLevelSelection(context, 3),
            ),
            const SizedBox(height: 24),
            DifficultyCard(
              title: 'TRUNG BÌNH',
              gridSizeText: '4 x 4',
              color: Colors.orange.shade800,
              onTap: () => _navigateToLevelSelection(context, 4),
            ),
            const SizedBox(height: 24),
            DifficultyCard(
              title: 'KHÓ',
              gridSizeText: '5 x 5',
              color: Colors.red.shade800,
              onTap: () => _navigateToLevelSelection(context, 5),
            ),
          ],
        ),
      ),
    );
  }
}

class DifficultyCard extends StatelessWidget {
  final String title;
  final String gridSizeText;
  final Color color;
  final VoidCallback onTap;

  const DifficultyCard({
    Key? key,
    required this.title,
    required this.gridSizeText,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900, // Extra-bold for title
                  fontSize: 28,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                gridSizeText,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
