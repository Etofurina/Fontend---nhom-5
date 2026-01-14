import 'dart:convert';
import '/sliding_puzzle/puzzle_progress_service.dart';
import '/sliding_puzzle/sliding_puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class LevelSelectionScreen extends StatefulWidget {
  final int gridSize;
  const LevelSelectionScreen({super.key, required this.gridSize});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  late Future<List<dynamic>> _dataFuture;

  // Danh sách ảnh cố định để đảm bảo logic chơi không đổi
  final List<String> _imageAssets = [
    'assets/Hinh Bo.jpg',
    'assets/Hinh Bo Sua.jpg',
    'assets/Hinh Ca.jpg',
    'assets/Hinh Capy.jpg',
    'assets/Hinh Chim.jpg',
    'assets/Hinh Cho.jpg',
    'assets/Hinh Ga.jpg',
    'assets/Hinh Meo.jpg',
    'assets/Hinh Trau.jpg',
    'assets/Hinh Vit.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _dataFuture = Future.wait([
      PuzzleProgressService.getUnlockedLevel(widget.gridSize),
      PuzzleProgressService.getAllBestTimes(widget.gridSize),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final difficultyMap = {3: 'Dễ', 4: 'Trung Bình', 5: 'Khó'};
    final difficultyName = difficultyMap[widget.gridSize] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Các Ải - $difficultyName',
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Lỗi tải dữ liệu tiến trình'));
          }

          final unlockedLevel = snapshot.data![0] as int;
          final bestTimes = snapshot.data![1] as Map<int, int>;

          return GridView.builder(
            padding: const EdgeInsets.all(20.0),
            itemCount: _imageAssets.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20.0,
              mainAxisSpacing: 20.0,
              childAspectRatio: 1.0, // Thẻ vuông cho đẹp
            ),
            itemBuilder: (context, index) {
              final levelNumber = index + 1;
              final isLocked = levelNumber > unlockedLevel;
              final bestTime = bestTimes[levelNumber];

              return LevelCard(
                levelNumber: levelNumber,
                bestTime: bestTime,
                isLocked: isLocked,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SlidingPuzzleScreen(
                        imagePath: _imageAssets[index],
                        gridSize: widget.gridSize,
                        levelNumber: levelNumber,
                      ),
                    ),
                  );
                  setState(() {
                    _loadData();
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}

class LevelCard extends StatelessWidget {
  final int levelNumber;
  final int? bestTime;
  final bool isLocked;
  final VoidCallback onTap;

  const LevelCard({
    super.key,
    required this.levelNumber,
    required this.bestTime,
    required this.isLocked,
    required this.onTap,
  });

  String _formatTime(int? seconds) {
    if (seconds == null) return '--:--';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isLocked ? 2.0 : 8.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: isLocked ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            // Hiệu ứng Gradient hiện đại thay cho ảnh nền bị lỗi
            gradient: isLocked
                ? LinearGradient(
                    colors: [Colors.grey.shade800, Colors.grey.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFF3282B8), Color(0xFF0F4C75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ẢI',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    '$levelNumber',
                    style: GoogleFonts.nunito(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  if (!isLocked) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events_rounded,
                            color: bestTime != null ? Colors.amber : Colors.white24,
                            size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(bestTime),
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              if (isLocked)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(Icons.lock_rounded, size: 40, color: Colors.white38),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
