import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'reset_password_screen.dart'; // Màn hình tiếp theo (sẽ tạo ở Bước 3)

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  void _handleSendOtp() async {
    if (_emailController.text.isEmpty) return;

    setState(() => _isLoading = true);

    // Gọi API gửi OTP
    final success = await _apiService.forgotPassword(_emailController.text);

    setState(() => _isLoading = false);

    if (success) {
      // Thành công -> Chuyển sang màn hình nhập OTP & Mật khẩu mới
      // Nhớ truyền Email sang để người dùng đỡ phải nhập lại
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: _emailController.text),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email không tồn tại hoặc lỗi hệ thống!"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quên Mật Khẩu")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Nhập email để nhận mã xác thực:", style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email của bạn",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _handleSendOtp,
              child: Text("Gửi Mã OTP"),
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
            ),
          ],
        ),
      ),
    );
  }
}