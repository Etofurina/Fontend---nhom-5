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

  // 2. Hàm Reload dữ liệu (Chỉ cần setState để FutureBuilder chạy lại)
  Future<void> _refreshData() async {
    setState(() {});
    // Giả lập chờ 1 xíu cho người dùng thấy hiệu ứng loading
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
                    _refreshData(); // Reload lại danh sách sau khi lưu
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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Admin Dashboard"),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          actions: [
            // --- [MỚI] NÚT RELOAD DỮ LIỆU ---
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.blueAccent),
              tooltip: "Làm mới dữ liệu",
              onPressed: _refreshData,
            ),
            // ---------------------------------
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
            tabs: [
              Tab(icon: Icon(Icons.people), text: "Users"),
              Tab(icon: Icon(Icons.grid_on), text: "Sudoku"),
              Tab(icon: Icon(Icons.casino), text: "Rubik"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserTab(),
            _buildSudokuTab(),
            _buildRubikTab(),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: QUẢN LÝ USER ---
  Widget _buildUserTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () => _showUserDialog(),
      ),
      body: RefreshIndicator( // [MỚI] Vuốt xuống để refresh
        onRefresh: _refreshData,
        child: FutureBuilder<List<dynamic>>(
          future: _apiService.getAllUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // Phải bọc trong ListView để RefreshIndicator hoạt động được khi rỗng
              return ListView(children: [Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Chưa có người dùng nào.")))]);
            }

            final users = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.only(bottom: 80),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: user['role'] == 'Admin' ? Colors.redAccent : Colors.blueAccent,
                      child: Text(user['fullName'] != null && user['fullName'].isNotEmpty
                          ? user['fullName'][0].toUpperCase()
                          : "U", style: TextStyle(color: Colors.white)),
                    ),
                    title: Text(user['fullName'] ?? "No Name", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${user['email']}"),
                        Container(
                          margin: EdgeInsets.only(top: 4),
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: user['role'] == 'Admin' ? Colors.red[50] : Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: user['role'] == 'Admin' ? Colors.red : Colors.blue, width: 0.5),
                          ),
                          child: Text(
                              user['role'],
                              style: TextStyle(fontSize: 10, color: user['role'] == 'Admin' ? Colors.red : Colors.blue, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showUserDialog(user: user),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(
                            "Xóa User?",
                            "Hành động này sẽ xóa User '${user['email']}'!",
                                () async {
                              bool success = await _apiService.deleteUser(user['id']);
                              if (success) _refreshData(); // Reload sau khi xóa
                            },
                          ),
                        ),
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

  // --- TAB 2: QUẢN LÝ SUDOKU ---
  Widget _buildSudokuTab() {
    return RefreshIndicator( // [MỚI] Vuốt xuống để refresh
      onRefresh: _refreshData,
      child: FutureBuilder<List<dynamic>>(
        future: _apiService.getAllSudokuMatches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return ListView(children: [Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Chưa có ván Sudoku nào.")))]);
          }

          final matches = snapshot.data!;
          return ListView.builder(
            physics: AlwaysScrollableScrollPhysics(), // Đảm bảo luôn cuộn được để refresh
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Icon(Icons.grid_on, color: Colors.orange, size: 30),
                  title: Text(match['userEmail'] ?? "Unknown"),
                  subtitle: Text("Điểm: ${match['score']} | Cấp độ: ${match['difficulty']}\n${match['date']}"),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(
                      "Xóa ván game?",
                      "Bạn muốn xóa ván Sudoku này?",
                          () async {
                        bool success = await _apiService.deleteSudokuMatch(match['id']);
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

  // --- TAB 3: QUẢN LÝ RUBIK ---
  Widget _buildRubikTab() {
    return RefreshIndicator( // [MỚI] Vuốt xuống để refresh
      onRefresh: _refreshData,
      child: FutureBuilder<List<dynamic>>(
        future: _apiService.getAllRubikGames(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return ListView(children: [Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Chưa có ván Rubik nào.")))]);
          }

          final games = snapshot.data!;
          return ListView.builder(
            physics: AlwaysScrollableScrollPhysics(),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Icon(Icons.casino, color: Colors.purple, size: 30),
                  title: Text(game['userEmail'] ?? "Unknown"),
                  subtitle: Text("Thời gian: ${game['time']}s | ${game['mode']}\n${game['date']}"),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(
                      "Xóa ván game?",
                      "Bạn muốn xóa ván Rubik này?",
                          () async {
                        bool success = await _apiService.deleteRubikGame(game['id']);
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