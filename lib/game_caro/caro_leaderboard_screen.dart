import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'caro_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final CaroService _service = CaroService();

  int _safeInt(dynamic val) => int.tryParse(val.toString()) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("BẢNG XẾP HẠNG", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: FutureBuilder<List<dynamic>>(
          future: _service.getLeaderboard(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text("Chưa có dữ liệu", style: GoogleFonts.outfit(color: Colors.white54)));
            }

            final leaders = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 20),
              itemCount: leaders.length,
              itemBuilder: (context, index) {
                final user = leaders[index];
                final name = user['userName'] ?? "Unknown";
                // Ép kiểu an toàn cho số trận thắng
                final wins = _safeInt(user['wins']);

                Color rankColor;
                double scale = 1.0;

                if (index == 0) {
                  rankColor = const Color(0xFFFFD700); // Vàng
                  scale = 1.05;
                } else if (index == 1) {
                  rankColor = const Color(0xFFC0C0C0); // Bạc
                } else if (index == 2) {
                  rankColor = const Color(0xFFCD7F32); // Đồng
                } else {
                  rankColor = Colors.white54;
                }

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: index < 3 ? rankColor.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: index < 3 ? Border.all(color: rankColor.withOpacity(0.5)) : null,
                    ),
                    child: ListTile(
                      leading: index < 3
                          ? Icon(Icons.emoji_events, color: rankColor, size: 32)
                          : Container(
                        width: 30, height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                        child: Text("${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(name, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "$wins Wins",
                          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
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
}