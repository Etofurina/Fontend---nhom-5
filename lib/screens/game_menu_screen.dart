import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- IMPORT CÁC MÀN HÌNH ---
import '../game_sudoku/WorldChatScreen.dart';
import 'login_screen.dart';

// Game 1: Xếp Hình
import '../sliding_puzzle/image_selection_screen.dart';

// Game 2: Rubik
import '../game_rubik/rubik_game_screen.dart';

// Game 3: Sudoku
import '../game_sudoku/sudoku_menu_screen.dart';

// Game 4: Caro
import '../game_caro/caro_screen.dart';

class GameMenuScreen extends StatelessWidget {
  GameMenuScreen({super.key});

  // --- DANH SÁCH GAME ---
  final List<Map<String, dynamic>> games = [
    {
      'name': 'Sudoku',
      'icon': Icons.grid_on_rounded,
      'color': Colors.blueAccent,
      'isReady': true,
      'desc': 'Thử thách trí tuệ',
    },
    {
      'name': 'Cờ Caro',
      'icon': Icons.close_rounded,
      'color': Colors.orangeAccent,
      'isReady': true,
      'desc': 'Chiến thuật cổ điển',
    },
    {
      'name': 'Rubik 3D',
      'icon': Icons.casino_rounded,
      'color': Colors.redAccent,
      'isReady': true,
      'desc': 'Không gian 3 chiều',
    },
    {
      'name': 'Xếp Hình',
      'icon': Icons.view_quilt_rounded,
      'color': Colors.purpleAccent,
      'isReady': true,
      'desc': 'Ghép hình kinh điển',
    },
  ];

  // --- ĐĂNG XUẤT ---
  void _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
    );
  }

  // --- CHAT THẾ GIỚI ---
  void _openWorldChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorldChatScreen()),
    );
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Game Hub",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.public, color: Colors.blue),
            tooltip: "Chat Thế Giới",
            onPressed: () => _openWorldChat(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: "Đăng xuất",
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Xin chào, Game thủ! 👋",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Text(
              "Chọn trò chơi để bắt đầu",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: games.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  return _buildGameCard(context, games[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CARD GAME ---
  Widget _buildGameCard(BuildContext context, Map<String, dynamic> game) {
    final bool isReady = game['isReady'];
    final Color color = isReady ? game['color'] : Colors.grey;

    return GestureDetector(
      onTap: () {
        if (!isReady) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Game ${game['name']} đang phát triển!"),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        // --- ĐIỀU HƯỚNG ---
        switch (game['name']) {
          case 'Sudoku':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SudokuMenuScreen()),
            );
            break;

          case 'Cờ Caro':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) =>  CaroScreen()),
            );
            break;

          case 'Xếp Hình':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ImageSelectionScreen(),
              ),
            );
            break;

          case 'Rubik 3D':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RubikGameScreen(),
              ),
            );
            break;
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isReady ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                game['icon'],
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              game['name'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isReady ? Colors.black87 : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              game['desc'] ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 12),
            isReady
                ? Icon(Icons.play_circle_fill, color: color, size: 28)
                : const Text(
              "Sắp ra mắt",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
