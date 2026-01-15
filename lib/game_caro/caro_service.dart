import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Class DTO để chuyển dữ liệu từ màn hình Game sang Service
class MatchLog {
  final String date;
  final String winner;
  final String mode;
  final String difficulty;
  final int scoreEarned;
  final String player1Name;
  final String player2Name;
  final int moves;       // Số nước đi
  final double duration; // Thời gian chơi (giây)

  MatchLog({
    required this.date,
    required this.winner,
    required this.mode,
    required this.difficulty,
    required this.scoreEarned,
    required this.player1Name,
    required this.player2Name,
    this.moves = 0,
    this.duration = 0.0,
  });
}

class CaroService {
  // URL API Backend của anh
  static const String baseUrl = "https://rightpurpletower2.conveyor.cloud/api";

  // Helper: Lấy Header có chứa Token đăng nhập
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. Lưu kết quả trận đấu (API: POST /Caro/finish)
  Future<bool> saveMatchResult(MatchLog log) async {
    final url = Uri.parse('$baseUrl/Caro/finish');

    // Logic map điểm số từ Game sang trạng thái của Backend
    // Backend quy định: 1 = Thắng, -1 = Thua, 0 = Hòa
    int result = 0;
    if (log.scoreEarned >= 10) {
      result = 1; // Thắng
    } else if (log.scoreEarned < 0) {
      result = -1; // Thua
    } else {
      result = 0; // Hòa
    }

    try {
      final headers = await _getHeaders();

      // [QUAN TRỌNG] Các Key ở đây viết Hoa chữ cái đầu (PascalCase)
      // để khớp hoàn toàn với Model C# Backend, tránh lỗi không nhận dữ liệu.
      final body = jsonEncode({
        'Result': result,
        'Moves': log.moves > 0 ? log.moves : 1, // Đảm bảo không bị 0
        'Duration': log.duration > 0 ? log.duration : 1.0,
        'Mode': log.mode // "PvE" hoặc "PvP"
      });

      print("Sending Caro Result: $body"); // Log để kiểm tra

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Failed to save match. Status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error saving match: $e");
      return false;
    }
  }

  // 2. Lấy tổng điểm tích lũy (Rank)
  // (Tính toán dựa trên lịch sử đấu trả về)
  Future<int> getTotalScore() async {
    try {
      final history = await getHistory();
      int total = 0;
      for (var match in history) {
        // Parse an toàn để tránh lỗi crash nếu API trả về null hoặc string lạ
        int res = int.tryParse(match['result'].toString()) ?? 0;

        if (res == 1) total += 10;      // Thắng +10
        else if (res == 0) total += 5;  // Hòa +5
        // Thua không trừ hoặc trừ tùy logic anh muốn
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  // 3. Lấy Lịch sử đấu (API: GET /Caro/history)
  Future<List<dynamic>> getHistory() async {
    final url = Uri.parse('$baseUrl/Caro/history');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error fetching history: $e");
    }
    return [];
  }

  // 4. Lấy Bảng xếp hạng (API: GET /Caro/leaderboard)
  Future<List<dynamic>> getLeaderboard() async {
    final url = Uri.parse('$baseUrl/Caro/leaderboard');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error fetching leaderboard: $e");
    }
    return [];
  }
}