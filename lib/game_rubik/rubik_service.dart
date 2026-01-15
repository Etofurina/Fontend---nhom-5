import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class RubikService {
  // Dùng hằng số Domain chung cho cả App để dễ sửa đổi sau này
  static const String baseUrl = AppConstants.domain;

  // Lấy Token xác thực
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // --- 1. API START GAME ---
  Future<Map<String, dynamic>?> startGame(int difficulty, {String challengeCode = ""}) async {
    try {
      String? token = await _getToken();
      if (token == null) {
        print("Lỗi: Chưa có Token");
        return null;
      }

      // [LƯU Ý] Đảm bảo đường dẫn đúng với Controller bên Backend
      final uri = Uri.parse('$baseUrl/api/Rubik/start');

      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          // Viết Hoa chữ cái đầu (PascalCase) để khớp với C# Model
          "Difficulty": difficulty,
          "ChallengeCode": challengeCode
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Service Error (Start Rubik): $e");
      return null;
    }
  }

  // --- 2. API FINISH GAME ---
  // [QUAN TRỌNG] Hàm này dễ bị lỗi nhất nếu sai tên biến
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

      final bodyData = json.encode({
        // [SỬA LẠI] Đổi sang PascalCase để Backend nhận diện được
        "MatchId": matchId,        // Bên C# là public string/int MatchId { get; set; }
        "Duration": duration,      // Bên C# là public double Duration { get; set; }
        "Mistakes": mistakes,      // Bên C# là public int Mistakes { get; set; }
        "CreateChallenge": createChallenge
      });

      print("Gửi kết quả Rubik: $bodyData"); // Log ra xem gửi cái gì

      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: bodyData,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print("Lỗi Finish Rubik: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Service Error (Finish Rubik): $e");
      return null;
    }
  }

  // --- 3. API LỊCH SỬ CÁ NHÂN ---
  Future<List<dynamic>?> getHistory() async {
    try {
      String? token = await _getToken();
      if (token == null) return null;

      // [QUAN TRỌNG] Đảm bảo URL này đúng
      final uri = Uri.parse('$baseUrl/api/Rubik/history');

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        // Log ra để kiểm tra xem Server trả về gì
        print("Rubik History Response: ${response.body}");
        return json.decode(response.body) as List<dynamic>;
      }
      return null;
    } catch (e) {
      print("Service Error (Rubik History): $e");
      return null;
    }
  }

  // --- 4. API BẢNG XẾP HẠNG ---
  Future<List<dynamic>?> getLeaderboard(int difficulty) async {
    try {
      String? token = await _getToken();
      if (token == null) return null;

      final uri = Uri.parse('$baseUrl/api/Rubik/leaderboard?difficulty=$difficulty');

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
      print("Service Error (Rubik Leaderboard): $e");
      return null;
    }
  }
}