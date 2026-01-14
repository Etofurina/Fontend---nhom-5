import 'package:flutter/material.dart';
import 'sudoku_service.dart';
import '../screens/private_chat_screen.dart'; // Import màn hình chat riêng

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SudokuService _service = SudokuService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 Tab: Dễ, TB, Khó
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bảng Xếp Hạng"),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Dễ"),
            Tab(text: "Trung Bình"),
            Tab(text: "Khó"),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.amber.withOpacity(0.1), Colors.white],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildList(1), // Tab Dễ
            _buildList(2), // Tab TB
            _buildList(3), // Tab Khó
          ],
        ),
      ),
    );
  }

  Widget _buildList(int difficulty) {
    return FutureBuilder<List<dynamic>>(
      future: _service.getLeaderboard(difficulty),
      builder: (context, snapshot) {
        // 1. Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // 2. Error
        else if (snapshot.hasError) {
          return Center(
            child: Text("Lỗi: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
          );
        }
        // 3. Empty
        else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Chưa có ai ghi danh ở mức này!", style: TextStyle(color: Colors.grey)));
        }

        // 4. Data Available
        final list = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];

            // --- XỬ LÝ DỮ LIỆU AN TOÀN (CHỐNG NULL) ---
            final name = item['userName'] ?? item['UserName'] ?? 'Ẩn danh';
            final score = item['score'] ?? item['Score'] ?? 0;

            // QUAN TRỌNG: Lấy Email để chat
            // Backend phải trả về trường 'email' hoặc 'Email'
            // Nếu Backend chưa trả về Email, nút chat sẽ không hiện hoặc dùng tạm userName (có thể lỗi)
            final email = item['email'] ?? item['Email'] ?? item['userName'] ?? item['UserName'] ?? "";

            // Xử lý thời gian
            final timeStr = item['timeElapsed'] ?? item['TimeElapsed'] ?? "N/A";
            final dateStr = item['timePlayed'] ?? item['TimePlayed'] ?? "";

            // Logic Icon Huy chương
            Widget rankWidget;
            Color cardColor = Colors.white;

            if (index == 0) {
              rankWidget = const Icon(Icons.emoji_events, color: Colors.amber, size: 36);
              cardColor = Colors.amber.shade50;
            } else if (index == 1) {
              rankWidget = const Icon(Icons.emoji_events, color: Colors.grey, size: 36);
            } else if (index == 2) {
              rankWidget = const Icon(Icons.emoji_events, color: Colors.brown, size: 36);
            } else {
              rankWidget = CircleAvatar(
                backgroundColor: Colors.blueGrey.shade100,
                radius: 15,
                child: Text("${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              );
            }

            return Card(
              color: cardColor,
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                // Cột bên trái: Thứ hạng
                leading: SizedBox(width: 40, child: Center(child: rankWidget)),

                // Cột giữa: Tên và Thời gian
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text("$timeStr  •  $dateStr", style: const TextStyle(fontSize: 12)),

                // Cột bên phải: Điểm số & Nút Chat
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("$score đ", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),

                    const SizedBox(width: 8),

                    // Nút Chat (Chỉ hiện nếu có địa chỉ email để gửi)
                    if (email.toString().isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.green),
                        tooltip: "Chat với $name",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PrivateChatScreen(
                                targetEmail: email, // ID để gửi tin
                                targetName: name,   // Tên hiển thị trên thanh tiêu đề
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}