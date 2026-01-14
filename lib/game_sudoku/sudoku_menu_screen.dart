// File: lib/game_sudoku/sudoku_menu_screen.dart
import 'package:flutter/material.dart';
import 'sudoku_game_screen.dart'; // Import màn hình game (đã có trong cùng thư mục)
import 'sudoku_service.dart';     // Import service (đã có trong cùng thư mục)
import 'leaderboard_screen.dart'; // Import BXH (đã có trong cùng thư mục)
import 'history_screen.dart';     // Import Lịch sử (đã có trong cùng thư mục)

class SudokuMenuScreen extends StatelessWidget {
  final SudokuService _sudokuService = SudokuService();

  SudokuMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sudoku Master"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              const Icon(Icons.grid_on_rounded, size: 100, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text(
                "Sudoku",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              const Text("Thử thách trí tuệ", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 50),

              // Nút Chơi Ngay
              _buildMenuButton(
                context,
                "Chơi Ngay",
                Icons.play_arrow_rounded,
                Colors.blue,
                    () => _showDifficultyDialog(context),
              ),
              const SizedBox(height: 16),

              // Nút Bảng Xếp Hạng
              _buildMenuButton(
                context,
                "Bảng Xếp Hạng",
                Icons.emoji_events_rounded,
                Colors.orange,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
              ),
              const SizedBox(height: 16),

              // Nút Lịch Sử
              _buildMenuButton(
                context,
                "Lịch Sử Đấu",
                Icons.history_rounded,
                Colors.purple,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget nút bấm chung
  Widget _buildMenuButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: color.withOpacity(0.5))),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        icon: Icon(icon, size: 28),
        label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        onPressed: onPressed,
      ),
    );
  }

  // --- LOGIC CHỌN ĐỘ KHÓ ---
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

  // Hàm gọi API bắt đầu game rồi mới chuyển màn hình
  Future<void> _startNewSudokuGame(BuildContext context, int difficulty) async {
    // Hiện loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await _sudokuService.startGame(difficulty);

      if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); // Tắt loading

      final matchId = result['gameId'] ?? result['GameId'];
      final initialBoard = result['board'] ?? result['Board'];

      if (matchId != null && initialBoard != null) {
        if (!context.mounted) return;
        // Có dữ liệu rồi mới mở màn hình chơi game
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
        Navigator.of(context, rootNavigator: true).pop(); // Tắt loading
        _showError(context, "Lỗi: ${e.toString().replaceAll('Exception:', '')}");
      }
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}