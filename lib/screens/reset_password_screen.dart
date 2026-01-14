import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  ResetPasswordScreen({required this.email});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // Controller
  final _otpController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController(); // Thêm controller xác nhận

  final ApiService _apiService = ApiService();

  // Biến trạng thái
  bool _isLoading = false;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  void _handleSubmit() async {
    // 1. Kiểm tra đầu vào (Validation)
    if (_otpController.text.isEmpty ||
        _newPassController.text.isEmpty ||
        _confirmPassController.text.isEmpty) {
      _showSnackBar("Vui lòng điền đầy đủ thông tin!", Colors.orange);
      return;
    }

    if (_newPassController.text != _confirmPassController.text) {
      _showSnackBar("Mật khẩu xác nhận không khớp!", Colors.redAccent);
      return;
    }

    if (_newPassController.text.length < 6) {
      _showSnackBar("Mật khẩu phải có ít nhất 6 ký tự!", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    // 2. Gọi API
    final success = await _apiService.resetPassword(
      widget.email,
      _otpController.text,
      _newPassController.text,
    );

    setState(() => _isLoading = false);

    // 3. Xử lý kết quả
    if (success) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đổi mật khẩu thành công! Hãy đăng nhập lại."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Đợi 1s cho người dùng đọc thông báo
      await Future.delayed(Duration(seconds: 1));

      // Quay về màn hình đầu tiên (Login)
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      if (!mounted) return;
      _showSnackBar("Mã OTP không đúng hoặc đã hết hạn!", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Đặt Lại Mật Khẩu", style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Icon minh họa
              Container(
                alignment: Alignment.center,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_reset_rounded, size: 60, color: Colors.blueAccent),
              ),
              SizedBox(height: 20),

              // 2. Thông báo Email
              Text(
                "Tạo mật khẩu mới",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  children: [
                    TextSpan(text: "Mã OTP xác thực đã được gửi đến email:\n"),
                    TextSpan(
                      text: widget.email,
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, height: 1.5),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // 3. Nhập OTP
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Nhập mã OTP", Icons.vpn_key_outlined),
              ),
              SizedBox(height: 16),

              // 4. Mật khẩu mới
              TextField(
                controller: _newPassController,
                obscureText: _obscureNewPass,
                decoration: _passwordDecoration(
                  "Mật khẩu mới",
                  _obscureNewPass,
                      () => setState(() => _obscureNewPass = !_obscureNewPass),
                ),
              ),
              SizedBox(height: 16),

              // 5. Xác nhận mật khẩu mới
              TextField(
                controller: _confirmPassController,
                obscureText: _obscureConfirmPass,
                decoration: _passwordDecoration(
                  "Nhập lại mật khẩu mới",
                  _obscureConfirmPass,
                      () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                ),
              ),

              SizedBox(height: 30),

              // 6. Nút Xác Nhận
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _handleSubmit,
                child: Text("CẬP NHẬT MẬT KHẨU", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent, // Đồng bộ màu xanh với toàn App
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function để style cho ô nhập thường
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  // Helper function để style cho ô nhập password
  InputDecoration _passwordDecoration(String label, bool isObscured, VoidCallback onToggle) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(Icons.lock_outline, color: Colors.blueAccent),
      suffixIcon: IconButton(
        icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
        onPressed: onToggle,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}