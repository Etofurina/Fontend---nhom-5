import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();

  // 1. Hàm đăng xuất
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Xóa token, role
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
    );
  }

  // 2. Hàm Reload dữ liệu
  Future<void> _refreshData() async {
    setState(() {});
    await Future.delayed(Duration(milliseconds: 500));
  }

  // 3. Hàm hiển thị popup xác nhận xóa
  void _confirmDelete(String title, String content, Function onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(color: Colors.redAccent)),
        content: Text(content),
        actions: [
          TextButton(
            child: Text("Hủy"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text("XÓA NGAY", style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(ctx); // Đóng popup
              onConfirm(); // Thực hiện xóa
            },
          ),
        ],
      ),
    );
  }

  // 4. Hàm hiển thị Popup Thêm / Sửa User
  void _showUserDialog({Map<String, dynamic>? user}) {
    final isEdit = user != null;
    final _emailController = TextEditingController(text: isEdit ? user['email'] : '');
    final _nameController = TextEditingController(text: isEdit ? user['fullName'] : '');
    final _passController = TextEditingController();

    String _selectedRole = isEdit ? user['role'] : 'User';
    List<String> roles = ['User', 'Admin'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isEdit ? "Sửa thông tin User" : "Thêm User mới"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isEdit)
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: "Email"),
                    ),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: "Họ tên"),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(labelText: "Quyền hạn (Role)"),
                    items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) {
                      setStateDialog(() => _selectedRole = val!);
                    },
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _passController,
                    decoration: InputDecoration(
                      labelText: isEdit ? "Mật khẩu mới (Bỏ trống nếu không đổi)" : "Mật khẩu",
                      helperText: isEdit ? "Nhập để reset pass cho user này" : "Bắt buộc khi tạo mới",
                    ),
                    obscureText: true,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(child: Text("Hủy"), onPressed: () => Navigator.pop(ctx)),
              ElevatedButton(
                child: Text("LƯU"),
                onPressed: () async {
                  bool success;
                  if (isEdit) {
                    success = await _apiService.updateUser(
                      user['id'],
                      _nameController.text,
                      _selectedRole,
                      _passController.text.isEmpty ? null : _passController.text,
                    );
                  } else {
                    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vui lòng nhập đủ email và pass")));
                      return;
                    }
                    success = await _apiService.createUser(
                      _emailController.text,
                      _passController.text,
                      _nameController.text,
                    );
                  }

                  Navigator.pop(ctx);
                  if (success) {
                    _refreshData();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Thành công!"), backgroundColor: Colors.green));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Có lỗi xảy ra!"), backgroundColor: Colors.red));
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // [SỬA] Tăng lên 4 Tab
      child: Scaffold(
        appBar: AppBar(
          title: Text("Admin Dashboard"),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.blueAccent),
              tooltip: "Làm mới dữ liệu",
              onPressed: _refreshData,
            ),
            IconButton(
              icon: Icon(Icons.logout, color: Colors.redAccent),
              tooltip: "Đăng xuất",
              onPressed: _logout,
            )
          ],
          bottom: TabBar(
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
            isScrollable: true, // [NÊN DÙNG] Cho phép cuộn ngang nếu màn hình nhỏ
            tabs: [
              Tab(icon: Icon(Icons.people), text: "Users"),
              Tab(icon: Icon(Icons.grid_on), text: "Sudoku"),
              Tab(icon: Icon(Icons.casino), text: "Rubik"),
              Tab(icon: Icon(Icons.grid_4x4), text: "Caro"), // [MỚI] Tab Caro
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserTab(),
            _buildSudokuTab(),
            _buildRubikTab(),
            _buildCaroTab(), // [MỚI] Hàm dựng giao diện Caro
          ],
        ),
      ),
    );
  }

  // --- TAB 1: USER ---
  Widget _buildUserTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () => _showUserDialog(),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<List<dynamic>>(
          future: _apiService.getAllUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.isEmpty) return ListView(children: [Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Chưa có người dùng nào.")))]);

            final users = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.only(bottom: 80),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: user['role'] == 'Admin' ? Colors.redAccent : Colors.blueAccent,
                      child: Text(user['fullName'] != null && user['fullName'].isNotEmpty ? user['fullName'][0].toUpperCase() : "U", style: TextStyle(color: Colors.white)),
                    ),
                    title: Text(user['fullName'] ?? "No Name", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${user['email']} • ${user['role']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () => _showUserDialog(user: user)),
                        IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete("Xóa User?", "Xóa vĩnh viễn user này?", () async {
                          bool success = await _apiService.deleteUser(user['id']);
                          if (success) _refreshData();
                        })),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // --- TAB 2: SUDOKU ---
  Widget _buildSudokuTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: FutureBuilder<List<dynamic>>(
        future: _apiService.getAllSudokuMatches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return ListView(children: [Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Chưa có ván Sudoku nào.")))]);

          final matches = snapshot.data!;
          return ListView.builder(
            physics: AlwaysScrollableScrollPhysics(),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Icon(Icons.grid_on, color: Colors.orange),
                  title: Text(match['userEmail'] ?? "Unknown"),
                  subtitle: Text("Điểm: ${match['score']} | Cấp độ: ${match['difficulty']}\n${match['date']}"),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmDelete("Xóa ván game?", "Bạn muốn xóa ván này?", () async {
                      bool success = await _apiService.deleteSudokuMatch(match['id']);
                      if (success) _refreshData();
                    }),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- TAB 3: RUBIK ---
  Widget _buildRubikTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: FutureBuilder<List<dynamic>>(
        future: _apiService.getAllRubikGames(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return ListView(children: [Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Chưa có ván Rubik nào.")))]);

          final games = snapshot.data!;
          return ListView.builder(
            physics: AlwaysScrollableScrollPhysics(),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Icon(Icons.casino, color: Colors.purple),
                  title: Text(game['userEmail'] ?? "Unknown"),
                  subtitle: Text("Thời gian: ${game['time']}s | ${game['mode']}\n${game['date']}"),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmDelete("Xóa ván game?", "Bạn muốn xóa ván này?", () async {
                      bool success = await _apiService.deleteRubikGame(game['id']);
                      if (success) _refreshData();
                    }),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- TAB 4: CARO (MỚI) ---
  Widget _buildCaroTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: FutureBuilder<List<dynamic>>(
        future: _apiService.getAllCaroMatches(),
        builder: (context, snapshot) {
          // 1. Loading
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());

          // 2. Empty
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return ListView(children: [Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Chưa có ván Caro nào.")))]);
          }

          // 3. Data List
          final matches = snapshot.data!;
          return ListView.builder(
            physics: AlwaysScrollableScrollPhysics(),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];

              // Parse dữ liệu an toàn (tránh lỗi null)
              String winner = match['winner'] ?? match['result'] ?? 'Unknown';
              // Nếu result là số (1/-1) thì convert sang chữ cho đẹp (Tùy API trả về gì)
              if (winner == '1') winner = "Thắng";
              else if (winner == '-1') winner = "Thua";
              else if (winner == '0') winner = "Hòa";

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  // Icon Caro màu xanh lá
                  leading: Icon(Icons.grid_4x4, color: Colors.green, size: 30),

                  title: Text(match['userEmail'] ?? "Unknown User", style: TextStyle(fontWeight: FontWeight.bold)),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Kết quả: $winner"),
                      Text("Số nước: ${match['moves']} | Thời gian: ${match['duration']}s"),
                      Text("Ngày: ${match['date'] ?? match['playedAt'] ?? ''}", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),

                  isThreeLine: true,

                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(
                      "Xóa ván Caro?",
                      "Hành động này không thể hoàn tác!",
                          () async {
                        bool success = await _apiService.deleteCaroMatch(match['id']);
                        if (success) _refreshData();
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}