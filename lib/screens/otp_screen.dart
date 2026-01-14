import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'game_menu_screen.dart';
import 'admin_dashboard_screen.dart';
class OtpScreen extends StatefulWidget {
  final String email;

  OtpScreen({required this.email});

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  int _start = 60;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startTimer(); // Tự động đếm ngược ngay khi vào màn hình
  }

  @override
  void dispose() {
    _timer?.cancel(); // Hủy timer khi thoát màn hình để tránh lỗi
    super.dispose();
  }

  void startTimer() {
    setState(() {
      _canResend = false;
      _start = 60;
    });
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
          _canResend = true; // Cho phép bấm
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  // Hàm xử lý xác thực
  void _handleVerify() async {
    if (_otpController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng nhập đủ 6 số OTP!"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = false);

    // Gọi API Step 2 (Lúc này nhận về Map chứ không phải String)
    final response = await _apiService.loginStep2(
        widget.email,
        _otpController.text
    );

    setState(() => _isLoading = false);

    if (response != null) {
      // DEBUG: In ra xem lấy được chưa
      print("Response tại màn hình: $response");

      // Chú ý: Key ở đây phải giống hệt key anh viết trong Backend ở Bước 1
      String token = response['token'];
      String role = response['role'];

      // 2. Lưu vào máy
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('role', role); // Lưu role chuẩn

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đăng nhập thành công! Quyền: $role"), backgroundColor: Colors.green),
      );

      // 3. Điều hướng dựa trên Role thật
      Widget nextScreen;
      if (role == 'Admin') {
        nextScreen = AdminDashboardScreen();
      } else {
        nextScreen = GameMenuScreen();
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
            (route) => false,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mã OTP không đúng hoặc đã hết hạn!"), backgroundColor: Colors.red),
      );
    }
  }


  void _resendOtp() async {
    if (!_canResend) return; // Chặn bấm nếu chưa hết giờ

    setState(() => _isLoading = true);

    bool success = await _apiService.resendOtp(widget.email);

    setState(() => _isLoading = false);

    if (success) {
      startTimer(); // <--- QUAN TRỌNG: Gọi lại hàm này để đếm ngược lại từ đầu

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Đã gửi lại mã mới vào email!"),
            backgroundColor: Colors.green
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Lỗi hệ thống, vui lòng thử lại sau!"),
            backgroundColor: Colors.red
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87), // Nút back màu đen
        title: Text("Xác thực 2 bước", style: TextStyle(color: Colors.black87)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Icon minh họa
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_clock_rounded, size: 60, color: Colors.blueAccent),
              ),
              SizedBox(height: 30),

              // 2. Thông báo gửi mã
              Text(
                "Nhập mã xác thực",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "Mã OTP gồm 6 số đã được gửi đến email:",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              SizedBox(height: 5),
              Text(
                widget.email,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),

              SizedBox(height: 40),

              // 3. Ô nhập OTP được cách điệu
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 16, // Kỹ thuật tạo khoảng cách số
                    color: Colors.blueAccent
                ),
                decoration: InputDecoration(
                  counterText: "", // Ẩn bộ đếm ký tự góc dưới
                  hintText: "••••••",
                  hintStyle: TextStyle(letterSpacing: 16, color: Colors.grey[300]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              SizedBox(height: 30),

              // 4. Nút Xác Nhận
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _handleVerify,
                child: Text(
                  "XÁC NHẬN",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
              ),

              SizedBox(height: 20),

              // 5. Gửi lại mã (Đã cập nhật logic đếm ngược)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Chưa nhận được mã? ", style: TextStyle(color: Colors.grey)),
                  TextButton(
                    // Nếu _canResend = false (đang đếm) thì null (vô hiệu hóa nút)
                    onPressed: _canResend ? _resendOtp : null,
                    child: Text(
                      _canResend ? "Gửi lại" : "Gửi lại (${_start}s)", // Hiện số giây
                      style: TextStyle(
                          color: _canResend ? Colors.blueAccent : Colors.grey,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}