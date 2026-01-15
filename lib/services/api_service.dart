import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart'; // [Cần thêm thư viện này]

class ApiService {
  // --- [TỐI ƯU] Gom URL về 1 biến để dễ sửa ---
  static const String baseUrl = AppConstants.apiBaseUrl;

  // 1. Đăng ký
  Future<bool> register(String email, String password, String fullName) async {
    final url = Uri.parse('$baseUrl/Auth/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'fullName': fullName,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi Register: $e");
      return false;
    }
  }

  // 2. Đăng nhập Step 1
  Future<String?> loginStep1(String email, String password) async {
    final url = Uri.parse('$baseUrl/Auth/login-step1');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        return null;
      }
    } catch (e) {
      print("Lỗi Login Step 1: $e");
      return null;
    }
  }

  // 3. Đăng nhập Step 2 (QUAN TRỌNG: Đã thêm phần lưu Token)
  Future<Map<String, dynamic>?> loginStep2(String email, String otp) async {
    final url = Uri.parse('$baseUrl/Auth/login-step2');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otpCode': otp, // Key này phải khớp với DTO VerifyOtpDto bên C#
        }),
      );

      // --- THÊM LOG ĐỂ SOI LỖI ---
      print("Status Code: ${response.statusCode}");
      print("Body trả về: ${response.body}");
      // ---------------------------

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print("Lỗi Login Step 2: $e");
      return null;
    }
  }

  // 4. Quên mật khẩu
  Future<bool> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/Auth/forgot-password');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 5. Đặt lại mật khẩu
  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    final url = Uri.parse('$baseUrl/Auth/reset-password');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otpCode': otp,
          'newPassword': newPassword,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  // 6. Gửi lại mã OTP (Chỉ cần Email)
  Future<bool> resendOtp(String email) async {
    final url = Uri.parse('$baseUrl/Auth/resend-otp-login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi Resend OTP: $e");
      return false;
    }
  }
  // Helper: Lấy Header có chứa Token
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Gửi Token để Server biết là Admin
    };
  }

  // 1. Lấy danh sách Users
  Future<List<dynamic>> getAllUsers() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(Uri.parse('$baseUrl/Admin/users'), headers: headers);
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print("Lỗi get users: $e");
    }
    return [];
  }

  // 2. Xóa User
  Future<bool> deleteUser(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(Uri.parse('$baseUrl/Admin/user/$id'), headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 3. Lấy lịch sử Sudoku
  Future<List<dynamic>> getAllSudokuMatches() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(Uri.parse('$baseUrl/Admin/sudoku-matches'), headers: headers);
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print("Lỗi get sudoku: $e");
    }
    return [];
  }

  // 4. Xóa ván Sudoku
  Future<bool> deleteSudokuMatch(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(Uri.parse('$baseUrl/Admin/sudoku-match/$id'), headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 12. [ADMIN] Lấy toàn bộ lịch sử Rubik (Sửa theo API mới)
  Future<List<dynamic>> getAllRubikGames() async {
    try {
      final headers = await _getAuthHeaders();
      // Dựa vào code C# anh gửi: [HttpGet("rubik-games")]
      // Em giả định nó nằm trong AdminController
      final response = await http.get(Uri.parse('$baseUrl/Admin/rubik-games'), headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Lỗi get all rubik: $e");
    }
    return []; // Trả về list rỗng nếu lỗi
  }

  // 6. Xóa ván Rubik
  Future<bool> deleteRubikGame(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(Uri.parse('$baseUrl/Admin/rubik-game/$id'), headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  // 7. Thêm User mới
  Future<bool> createUser(String email, String password, String fullName) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/Admin/user'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'fullName': fullName
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi create user: $e");
      return false;
    }
  }

  // 8. Cập nhật User
  Future<bool> updateUser(int id, String fullName, String role, String? newPassword) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/Admin/user/$id'),
        headers: headers,
        body: jsonEncode({
          'fullName': fullName,
          'role': role,
          'password': newPassword // Gửi null hoặc chuỗi rỗng nếu không đổi
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi update user: $e");
      return false;
    }
  }
  // --- CARO API ---
  Future<bool> finishCaro(int result, int moves, double duration, String mode) async {
    try {
      final headers = await _getAuthHeaders(); // Hàm lấy header có token
      final response = await http.post(
        Uri.parse('$baseUrl/Caro/finish'),
        headers: headers,
        body: jsonEncode({
          'result': result,
          'moves': moves,
          'duration': duration,
          'mode': mode
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  // 16. Lấy lịch sử đấu Caro
  Future<List<dynamic>> getCaroHistory() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(Uri.parse('$baseUrl/Caro/history'), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Lỗi get caro history: $e");
    }
    return [];
  }

  // 17. Lấy bảng xếp hạng Caro
  Future<List<dynamic>> getCaroLeaderboard() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(Uri.parse('$baseUrl/Caro/leaderboard'), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Lỗi get caro leaderboard: $e");
    }
    return [];
  }
  // --- THÊM VÀO ApiService ---

  // 13. [ADMIN] Lấy toàn bộ lịch sử Caro của tất cả người chơi
  Future<List<dynamic>> getAllCaroMatches() async {
    try {
      final headers = await _getAuthHeaders();
      // Giả sử API Admin bên C# là: GET /api/Admin/caro-matches
      final response = await http.get(Uri.parse('$baseUrl/Admin/caro-matches'), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Lỗi get all caro: $e");
    }
    return [];
  }

  // 14. [ADMIN] Xóa ván Caro
  Future<bool> deleteCaroMatch(int id) async {
    try {
      final headers = await _getAuthHeaders();
      // Giả sử API Admin bên C# là: DELETE /api/Admin/caro-match/{id}
      final response = await http.delete(Uri.parse('$baseUrl/Admin/caro-match/$id'), headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
