import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controller cho các ô nhập liệu
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController(); // Thêm ô nhập lại pass

  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _obscurePass = true;       // Ẩn hiện mật khẩu
  bool _obscureConfirmPass = true; // Ẩn hiện mật khẩu xác nhận

  // Hàm xử lý đăng ký
  void _handleRegister() async {
    // 1. Kiểm tra dữ liệu đầu vào (Validation)
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passController.text.isEmpty) {
      _showSnackBar("Vui lòng điền đầy đủ thông tin!", Colors.orange);
      return;
    }

    if (!_emailController.text.contains('@')) {
      _showSnackBar("Email không hợp lệ!", Colors.orange);
      return;
    }

    if (_passController.text != _confirmPassController.text) {
      _showSnackBar("Mật khẩu xác nhận không khớp!", Colors.redAccent);
      return;
    }

    // 2. Bắt đầu gọi API
    setState(() => _isLoading = true);

    final success = await _apiService.register(
      _emailController.text,
      _passController.text,
      _nameController.text,
    );

    setState(() => _isLoading = false);

    // 3. Xử lý kết quả
    if (success) {
      if (!mounted) return;
      _showSnackBar("Đăng ký thành công! Vui lòng đăng nhập.", Colors.green);

      // Đợi 1 chút cho người dùng đọc thông báo rồi mới back
      await Future.delayed(Duration(seconds: 1));
      Navigator.pop(context); // Quay lại trang Login
    } else {
      if (!mounted) return;
      _showSnackBar("Đăng ký thất bại. Email có thể đã tồn tại!", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating, // Thông báo nổi lên trên
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Tạo Tài Khoản", style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87), // Mũi tên back màu đen
      ),
      body: SafeArea(
        child: SingleChildScrollView( // Chống lỗi tràn màn hình khi hiện bàn phím
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Text
              Text(
                "Bắt đầu hành trình!",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              Text(
                "Điền thông tin bên dưới để đăng ký",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 30),

              // 1. Họ và tên
              _buildTextField(
                controller: _nameController,
                label: "Họ và tên",
                icon: Icons.person_outline,
                hint: "Nguyễn Văn A",
              ),
              SizedBox(height: 16),

              // 2. Email
              _buildTextField(
                controller: _emailController,
                label: "Email",
                icon: Icons.email_outlined,
                hint: "example@email.com",
                inputType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),

              // 3. Mật khẩu
              _buildPasswordField(
                controller: _passController,
                label: "Mật khẩu",
                obscureText: _obscurePass,
                onToggle: () => setState(() => _obscurePass = !_obscurePass),
              ),
              SizedBox(height: 16),

              // 4. Nhập lại mật khẩu
              _buildPasswordField(
                controller: _confirmPassController,
                label: "Nhập lại mật khẩu",
                obscureText: _obscureConfirmPass,
                onToggle: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
              ),

              SizedBox(height: 30),

              // 5. Nút Đăng Ký
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _handleRegister,
                child: Text(
                    "ĐĂNG KÝ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
              ),

              SizedBox(height: 20),

              // 6. Nút chuyển về đăng nhập
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Đã có tài khoản? ", style: TextStyle(color: Colors.grey[700])),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      "Đăng nhập ngay",
                      style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
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

  // Widget con để vẽ ô nhập text thường
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  // Widget con để vẽ ô nhập mật khẩu
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock_outline, color: Colors.blueAccent),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}