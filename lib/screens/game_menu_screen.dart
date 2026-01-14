import 'package:flutter/material.dart';
import 'package:loginpage/game_rubik/rubik_game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import các màn hình liên quan
import 'login_screen.dart';
import 'sudoku_game_screen.dart';
import 'leaderboard_screen.dart';
import 'history_screen.dart';
import 'WorldChatScreen.dart';
import '../services/sudoku_service.dart';
import '../sliding_puzzle/image_selection_screen.dart'; // Import màn hình xếp hình
import '../game_rubik/rubik_game_screen.dart';
class GameMenuScreen extends StatelessWidget {
  final SudokuService _sudokuService = SudokuService();

  // Danh sách game
  final List<Map<String, dynamic>> games = [
    {'name': 'Sudoku', 'icon': Icons.grid_on_rounded, 'color': Colors.blueAccent, 'isReady': true, 'desc': 'Thử thách trí tuệ'},
    {'name': 'Cờ Caro', 'icon': Icons.close_rounded, 'color': Colors.orangeAccent, 'isReady': false, 'desc': 'Chiến thuật cổ điển'},
    {'name': 'Rubik 3D', 'icon': Icons.casino_rounded, 'color': Colors.redAccent, 'isReady': true, 'desc': 'Không gian 3 chiều'},
    {'name': 'Xếp Hình', 'icon': Icons.view_quilt_rounded, 'color': Colors.purpleAccent, 'isReady': true, 'desc': 'Ghép hình kinh điển'},
  ];

  GameMenuScreen({super.key});

  // --- CÁC HÀM ĐIỀU HƯỚNG ---

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

  void _openHistory(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryScreen()));
  }

  void _openLeaderboard(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardScreen()));
  }

  void _openWorldChat(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => WorldChatScreen()));
  }

  // --- LOGIC GAME SUDOKU (Giữ nguyên không đụng vào) ---

  void _showDifficultyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Chọn Độ Khó", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildDifficultyButton(context, "Dễ", "1000 điểm", Colors.green, 1),
              const SizedBox(height: 10),
              _buildDifficultyButton(context, "Trung Bình", "2000 điểm", Colors.orange, 2),
              const SizedBox(height: 10),
              _buildDifficultyButton(context, "Khó", "3000 điểm", Colors.red, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(BuildContext context, String label, String subLabel, Color color, int level) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color)),
        ),
        onPressed: () {
          Navigator.pop(context); // Đóng dialog
          _startNewSudokuGame(context, level);
        },
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(subLabel, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _startNewSudokuGame(BuildContext context, int difficulty) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await _sudokuService.startGame(difficulty);

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      final matchId = result['gameId'] ?? result['GameId'];
      final initialBoard = result['board'] ?? result['Board'];

      if (matchId != null && initialBoard != null) {
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SudokuGameScreen(
              matchId: matchId,
              initialBoard: initialBoard,
              difficulty: difficulty,
            ),
          ),
        );
      } else {
        _showError(context, "Lỗi dữ liệu game!");
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showError(context, "Lỗi: ${e.toString().replaceAll('Exception:', '')}");
      }
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red)
    );
  }

  // --- GIAO DIỆN CHÍNH ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text("Game Zone", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          _buildActionButton(Icons.public, "Chat", () => _openWorldChat(context), Colors.blue),
          _buildActionButton(Icons.emoji_events, "BXH", () => _openLeaderboard(context), Colors.orange),
          _buildActionButton(Icons.history, "Lịch sử", () => _openHistory(context), Colors.purple),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () => _handleLogout(context),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Xin chào, Game thủ! 👋", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
            const Text("Chọn trò chơi để bắt đầu", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: games.length,
                itemBuilder: (context, index) => _buildGameCard(context, games[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String tooltip, VoidCallback onTap, Color color) {
    return IconButton(icon: Icon(icon, color: color), tooltip: tooltip, onPressed: onTap);
  }

  Widget _buildGameCard(BuildContext context, Map<String, dynamic> game) {
    final bool isReady = game['isReady'];
    final Color color = isReady ? (game['color'] as Color) : Colors.grey;

    return GestureDetector(
      onTap: () {
        if (game['name'] == 'Sudoku') {
          _showDifficultyDialog(context);
        } else if (game['name'] == 'Xếp Hình') {
          // Điều hướng sang màn hình xếp hình
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ImageSelectionScreen()),
          );
        }
        else if (game['name'] == 'Rubik 3D') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RubikGameScreen()),
          );
        }else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Game ${game['name']} đang phát triển!"), behavior: SnackBarBehavior.floating)
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: color.withOpacity(isReady ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(game['icon'], size: 40, color: color),
            ),
            const SizedBox(height: 16),
            Text(game['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isReady ? Colors.black87 : Colors.grey)),
            const SizedBox(height: 4),
            Text(game['desc'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 12),
            if (isReady)
              Icon(Icons.play_circle_fill, color: color, size: 28)
            else
              const Text("Sắp ra mắt", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
