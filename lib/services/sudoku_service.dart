import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SudokuService {
  // ⚠️ LƯU Ý: Nếu URL Conveyor thay đổi, hãy cập nhật dòng này
  static const String _baseUrl = 'https://greatpurpleshop22.conveyor.cloud/api';

  // --- 1. CÁC HÀM HỖ TRỢ (PRIVATE) ---

  // Lấy Token đã lưu trong máy
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Tạo Header tự động (kèm Token nếu có)
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Hàm xử lý phản hồi chung (Tránh lặp lại code kiểm tra lỗi)
  dynamic _processResponse(http.Response response) {
    // Trường hợp 200 OK: Thành công
    if (response.statusCode == 200) {
      // Nếu body rỗng thì trả về null tránh crash
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    // Trường hợp Lỗi (400, 401, 500...)
    else {
      print("API Error (${response.statusCode}): ${response.body}");
      try {
        final decoded = jsonDecode(response.body);

        // Nếu backend trả về JSON object chứa message lỗi
        if (decoded is Map<String, dynamic>) {
          // Ưu tiên lấy key 'message' hoặc 'Message'
          throw Exception(decoded['message'] ?? decoded['Message'] ?? 'Lỗi không xác định từ server.');
        }
        // Nếu backend trả về chuỗi trần
        else {
          throw Exception(decoded.toString());
        }
      } catch (e) {
        // Nếu không parse được JSON (ví dụ lỗi HTML 404/502 từ Conveyor)
        throw Exception(response.body.isNotEmpty ? response.body : 'Lỗi kết nối (${response.statusCode})');
      }
    }
  }

  // --- 2. CÁC API GAME SUDOKU ---

  // Bắt đầu game mới
  Future<Map<String, dynamic>> startGame(int difficulty) async {
    final uri = Uri.parse('$_baseUrl/Sudoku/start');
    final body = jsonEncode({'difficulty': difficulty});

    try {
      final response = await http.post(uri, headers: await _getHeaders(), body: body);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Lỗi Start Game: $e');
    }
  }

  // Đi nước (Điền số)
  Future<Map<String, dynamic>> makeMove({
    required int matchId,
    required int row,
    required int col,
    required int value,
  }) async {
    final uri = Uri.parse('$_baseUrl/Sudoku/move');
    final body = jsonEncode({
      'matchId': matchId,
      'row': row,
      'col': col,
      'value': value,
    });

    try {
      final response = await http.post(uri, headers: await _getHeaders(), body: body);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Lỗi Move: $e');
    }
  }

  // Lấy gợi ý
  Future<Map<String, dynamic>> getHint(int matchId) async {
    final uri = Uri.parse('$_baseUrl/Sudoku/hint/$matchId');
    try {
      final response = await http.post(uri, headers: await _getHeaders());
      return _processResponse(response);
    } catch (e) {
      throw Exception('$e'); // Ném lỗi đã xử lý
    }
  }

  // Đầu hàng
  Future<Map<String, dynamic>> surrenderGame(int matchId) async {
    final uri = Uri.parse('$_baseUrl/Sudoku/surrender/$matchId');
    try {
      final response = await http.put(uri, headers: await _getHeaders());
      return _processResponse(response);
    } catch (e) {
      throw Exception('Lỗi Surrender: $e');
    }
  }

  // Tải lại ván đang chơi (Resume)
  Future<Map<String, dynamic>> getGame(int matchId) async {
    final uri = Uri.parse('$_baseUrl/Sudoku/$matchId');
    try {
      final response = await http.get(uri, headers: await _getHeaders());
      return _processResponse(response);
    } catch (e) {
      throw Exception('Lỗi Load Game: $e');
    }
  }

  // --- 3. CÁC API DỮ LIỆU ---

  // Lấy lịch sử đấu của tôi
  Future<List<dynamic>> getMyHistory() async {
    final uri = Uri.parse('$_baseUrl/Sudoku/history');
    try {
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return []; // Trả về danh sách rỗng nếu lỗi nhẹ
    } catch (e) {
      print("Lỗi History: $e");
      return [];
    }
  }

  // Lấy bảng xếp hạng theo độ khó
  Future<List<dynamic>> getLeaderboard(int difficulty) async {
    final uri = Uri.parse('$_baseUrl/Sudoku/leaderboard?difficulty=$difficulty');
    try {
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print("Lỗi Leaderboard: $e");
      return [];
    }
  }
}