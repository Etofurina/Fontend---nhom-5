import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/game_menu_screen.dart';
import 'screens/otp_screen.dart';
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
void main() async {
  HttpOverrides.global = MyHttpOverrides();
  // Đảm bảo Flutter binding khởi tạo trước khi gọi native code
  WidgetsFlutterBinding.ensureInitialized();

  // Kiểm tra token
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Game Hub',
      theme: ThemeData(primarySwatch: Colors.blue),
      // Nếu đã login -> Vào Menu, Ngược lại -> Vào Login
      home: isLoggedIn ? GameMenuScreen() : LoginScreen(),
    );
  }
}