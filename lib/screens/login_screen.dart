import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'forgot_password_screen.dart';
import 'otp_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _obscureText = true; // Biến để kiểm soát việc ẩn/hiện mật khẩu

  void _handleLogin() async {
    // Kiểm tra sơ bộ trước khi gọi API để tránh lãng phí tài nguyên
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Vui lòng nhập đầy đủ email và mật khẩu!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Giả lập delay hoặc gọi API thật
    final result = await _apiService.loginStep1(
        _emailController.text,
        _passController.text
    );

    setState(() => _isLoading = false);

    if (result != null) {
      if (!mounted) return; // Kiểm tra widget còn tồn tại không trước khi chuyển trang
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => OtpScreen(email: _emailController.text)
          )
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Sai email hoặc mật khẩu! Vui lòng thử lại."),
            backgroundColor: Colors.redAccent
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước màn hình để căn chỉnh cho đẹp
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white, // Nền trắng sạch sẽ
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Phần Header / Logo
                Icon(
                    Icons.lock_person_rounded,
                    size: 80,
                    color: Colors.blueAccent
                ),
                SizedBox(height: 20),
                Text(
                  "Chào mừng trở lại!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "Đăng nhập để tiếp tục",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 40),

                // 2. Ô nhập Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    hintText: "example@gmail.com",
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Bo góc mềm mại
                    ),
                    filled: true,
                    fillColor: Colors.grey[100], // Màu nền nhẹ cho ô nhập
                  ),
                ),
                SizedBox(height: 20),

                // 3. Ô nhập Mật khẩu
                TextField(
                  controller: _passController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: "Mật khẩu",
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),

                // 4. Quên mật khẩu
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ForgotPasswordScreen())
                      );
                    },
                    child: Text(
                      "Quên mật khẩu?",
                      style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // 5. Nút Đăng Nhập
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _handleLogin,
                  child: Text(
                    "ĐĂNG NHẬP",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, // Màu chủ đạo
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5, // Đổ bóng nhẹ tạo độ nổi
                  ),
                ),

                SizedBox(height: 20),

                // 6. Chuyển sang đăng ký
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Chưa có tài khoản? ", style: TextStyle(color: Colors.grey[700])),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen()));
                      },
                      child: Text(
                        "Đăng ký ngay",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}