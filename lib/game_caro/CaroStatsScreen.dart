import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CaroStatsScreen extends StatefulWidget {
  final int initialIndex;
  CaroStatsScreen({this.initialIndex = 0});

  @override
  _CaroStatsScreenState createState() => _CaroStatsScreenState();
}
class _CaroStatsScreenState extends State<CaroStatsScreen> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialIndex, // [MỚI] Cài đặt tab mở mặc định
      child: Scaffold(
        appBar: AppBar(
          title: Text("Thống kê Cao thủ Caro"),
          backgroundColor: Colors.blue[800],
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.history), text: "Lịch sử đấu"),
              Tab(icon: Icon(Icons.leaderboard), text: "Bảng xếp hạng"),
            ],
          ),
        ),
        body: Container(
          color: Colors.grey[100],
          child: TabBarView(
            children: [
              _buildHistoryTab(),
              _buildLeaderboardTab(),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 1: LỊCH SỬ ĐẤU ---
  Widget _buildHistoryTab() {
    return FutureBuilder<List<dynamic>>(
      future: _apiService.getCaroHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off, size: 60, color: Colors.grey),
                SizedBox(height: 10),
                Text("Bạn chưa chơi ván nào!", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final history = snapshot.data!;
        return ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final match = history[index];
            final isWin = match['result'] == "Thắng";

            return Card(
              elevation: 2,
              margin: EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isWin ? Colors.green[100] : Colors.red[100],
                  child: Icon(
                    isWin ? Icons.emoji_events : Icons.close,
                    color: isWin ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  isWin ? "CHIẾN THẮNG" : "THẤT BẠI",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isWin ? Colors.green[700] : Colors.red[700],
                  ),
                ),
                subtitle: Text("Số nước: ${match['moves']} • Thời gian: ${match['duration']}s"),
                trailing: Text(
                  match['date'] ?? "",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- TAB 2: BẢNG XẾP HẠNG ---
  Widget _buildLeaderboardTab() {
    return FutureBuilder<List<dynamic>>(
      future: _apiService.getCaroLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("Chưa có dữ liệu xếp hạng."));
        }

        final leaders = snapshot.data!;
        return ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: leaders.length,
          itemBuilder: (context, index) {
            final user = leaders[index];
            // Top 1, 2, 3 có màu đặc biệt
            Color rankColor = Colors.grey;
            if (index == 0) rankColor = Colors.amber; // Vàng
            if (index == 1) rankColor = Colors.grey[400]!; // Bạc
            if (index == 2) rankColor = Colors.brown[300]!; // Đồng

            return Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: rankColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "#${index + 1}",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                title: Text(
                  user['userName'] ?? "Ẩn danh",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text("Thắng nhanh nhất: ${user['bestTime']}s"),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    "${user['wins']} Trận thắng",
                    style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}