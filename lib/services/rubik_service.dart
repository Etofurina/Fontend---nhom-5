import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart'; // <--- Thêm dòng này

class RubikService {
  static const String baseUrl = AppConstants.domain;

  // --- HÀM LẤY TOKEN TỪ BỘ NHỚ (Do api_service đã lưu) ---
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Lấy token với key 'token' giống như trong file api_service bạn gửi
    return prefs.getString('token');
  }

  // --- 1. API START GAME ---
  Future<Map<String, dynamic>?> startGame(int difficulty, {String challengeCode = ""}) async {
    try {
      String? token = await _getToken();
      if (token == null) {
        print("Lỗi: Chưa có Token (Chưa đăng nhập Step 2)");
        return null;
      }

      final uri = Uri.parse('$baseUrl/api/Rubik/start');

      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // <--- Tự động điền token
        },
        body: json.encode({
          "difficulty": difficulty,
          "challengeCode": challengeCode
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Service Error (Start): $e");
      return null;
    }
  }

  // --- 2. API FINISH GAME ---
  Future<Map<String, dynamic>?> finishGame(
      String matchId,
      double duration,
      int mistakes,
      {bool createChallenge = false}
      ) async {
    try {
      String? token = await _getToken();
      if (token == null) return null;

      final uri = Uri.parse('$baseUrl/api/Rubik/finish');

      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          "matchId": matchId,
          "duration": duration,
          "mistakes": mistakes,
          "createChallenge": createChallenge
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Service Error (Finish): $e");
      return null;
    }
  }

  // --- 3. API LỊCH SỬ ---
  Future<List<dynamic>?> getHistory() async {
    try {
      String? token = await _getToken();
      if (token == null) return null;

      final uri = Uri.parse('$baseUrl/api/rubik/history');

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
      return null;
    } catch (e) {
      print("Service Error (History): $e");
      return null;
    }
  }
  // --- 4. API BẢNG XẾP HẠNG (MỚI) ---
  // Input: difficulty (1, 2, 3)
  Future<List<dynamic>?> getLeaderboard(int difficulty) async {
    try {
      String? token = await _getToken();
      if (token == null) return null;

      // URL: /api/rubik/leaderboard?difficulty=...
      final uri = Uri.parse('$baseUrl/api/rubik/leaderboard?difficulty=$difficulty');

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
      return null;
    } catch (e) {
      print("Service Error (Leaderboard): $e");
      return null;
    }
  }


}