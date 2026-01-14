import 'package:flutter/material.dart';
import 'CaroScreen.dart';
import 'CaroStatsScreen.dart';


class CaroMenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // Màu nền nhẹ nhàng
      appBar: AppBar(
        title: Text("Game Caro"),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. ICON LOGO
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
                  ],
                ),
                child: Icon(Icons.grid_4x4, size: 80, color: Colors.blueAccent),
              ),
            ),
            SizedBox(height: 40),

            // 2. NÚT CHƠI VỚI MÁY
            _buildBigButton(
                context,
                title: "CHƠI VỚI MÁY",
                icon: Icons.computer,
                color: Colors.blueAccent,
                onPressed: () {
                  // Truyền isPvE = true
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CaroScreen(initPvE: true)));
                }
            ),
            SizedBox(height: 15),

            // 3. NÚT CHƠI VỚI NGƯỜI
            _buildBigButton(
                context,
                title: "HAI NGƯỜI CHƠI",
                icon: Icons.people,
                color: Colors.orangeAccent,
                onPressed: () {
                  // Truyền isPvE = false
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CaroScreen(initPvE: false)));
                }
            ),
            SizedBox(height: 30),

            // 4. HÀNG NÚT THỐNG KÊ
            Row(
              children: [
                Expanded(
                  child: _buildSmallButton(
                      context,
                      title: "Lịch sử",
                      icon: Icons.history,
                      onPressed: () {
                        // Mở tab 0 (Lịch sử)
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CaroStatsScreen(initialIndex: 0)));
                      }
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: _buildSmallButton(
                      context,
                      title: "Xếp hạng",
                      icon: Icons.emoji_events,
                      onPressed: () {
                        // Mở tab 1 (Leaderboard)
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CaroStatsScreen(initialIndex: 1)));
                      }
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget nút to
  Widget _buildBigButton(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
      ),
      icon: Icon(icon, size: 28, color: Colors.white),
      label: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      onPressed: onPressed,
    );
  }

  // Widget nút nhỏ
  Widget _buildSmallButton(BuildContext context, {required String title, required IconData icon, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[800], // Màu chữ
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.blue.shade100)),
        elevation: 2,
      ),
      icon: Icon(icon, size: 20),
      label: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      onPressed: onPressed,
    );
  }
}