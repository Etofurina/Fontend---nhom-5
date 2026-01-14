import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // [Cần thêm thư viện này]

class ApiService {
  // --- [TỐI ƯU] Gom URL về 1 biến để dễ sửa ---
  static const String baseUrl = "https://earlygreenpencil99.conveyor.cloud/api";

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
  Future<String?> loginStep2(String email, String otp) async {
    final url = Uri.parse('$baseUrl/Auth/login-step2');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otpCode': otp}),
      );

      if (response.statusCode == 200) {
        final token = response.body;

        // --- [SỬA LỖI TẠI ĐÂY] ---
        // Lưu token vào máy để ChatService và SudokuService dùng được
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('email', email); // Lưu luôn email để dùng cho Chat
        // -------------------------

        return token;
      } else {
        return null;
      }
    } catch (e) {
      print("Lỗi Verify OTP: $e");
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
}