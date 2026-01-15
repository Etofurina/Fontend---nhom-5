import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
//import '../services/caro_service.dart';
import 'caro_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final CaroService _service = CaroService();

  // Các hàm đọc dữ liệu an toàn
  String _safeString(dynamic val) => val?.toString() ?? "";
  int _safeInt(dynamic val) => int.tryParse(val.toString()) ?? 0;
  double _safeDouble(dynamic val) => double.tryParse(val.toString()) ?? 0.0;

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
        title: Text(
          "LỊCH SỬ ĐẤU",
          style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: FutureBuilder<List<dynamic>>(
          future: _service.getHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_toggle_off, size: 80, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    Text("Chưa có lịch sử đấu", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 18)),
                  ],
                ),
              );
            }

            final history = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.only(top: 100, bottom: 20, left: 16, right: 16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final match = history[index];

                // --- [SỬA ĐỔI LOGIC TẠI ĐÂY] ---

                // 1. Lấy kết quả dạng CHỮ ("Thắng", "Thua", "Hòa") từ API
                // API trả về key là "Result" (viết hoa) hoặc "result"
                String resultStr = _safeString(match['Result'] ?? match['result']);

                // 2. Lấy các thông số khác
                // API trả về "Date" đã format sẵn (dd/MM/yyyy HH:mm)
                String date = _safeString(match['Date'] ?? match['date']);
                int moves = _safeInt(match['Moves'] ?? match['moves']);
                double duration = _safeDouble(match['Duration'] ?? match['duration']);

                // --------------------------------

                Color statusColor;
                String statusText;
                IconData statusIcon;

                // So sánh chuỗi ký tự thay vì số
                if (resultStr == "Thắng") {
                  statusColor = Colors.greenAccent;
                  statusText = "CHIẾN THẮNG";
                  statusIcon = Icons.emoji_events;
                } else if (resultStr == "Thua") {
                  statusColor = Colors.redAccent;
                  statusText = "THẤT BẠI";
                  statusIcon = Icons.close;
                } else {
                  // Trường hợp "Hòa" hoặc khác
                  statusColor = Colors.amberAccent;
                  statusText = "HÒA";
                  statusIcon = Icons.handshake;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                            color: statusColor.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4)
                        )
                      ]
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusIcon, color: statusColor),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            statusText,
                            style: GoogleFonts.outfit(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16
                            )
                        ),
                        // Nếu API trả về Mode thì hiện, không thì ẩn hoặc hiện mặc định
                        if (match['Mode'] != null || match['mode'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                            child: Text(
                                _safeString(match['Mode'] ?? match['mode']),
                                style: const TextStyle(color: Colors.white70, fontSize: 12)
                            ),
                          )
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            const Icon(Icons.timer, size: 14, color: Colors.white54),
                            const SizedBox(width: 4),
                            Text("${duration.toStringAsFixed(0)}s", style: const TextStyle(color: Colors.white54)),
                            const SizedBox(width: 12),
                            const Icon(Icons.grid_3x3, size: 14, color: Colors.white54),
                            const SizedBox(width: 4),
                            Text("$moves moves", style: const TextStyle(color: Colors.white54)),
                          ]),
                          Text(date, style: const TextStyle(color: Colors.white30, fontSize: 12)),
                        ],
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