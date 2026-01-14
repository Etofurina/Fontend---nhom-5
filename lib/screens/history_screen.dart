import 'package:flutter/material.dart';
import '../services/sudoku_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SudokuService _service = SudokuService();

  // Hàm helper để lấy màu theo độ khó
  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1: return Colors.green;  // Dễ
      case 2: return Colors.orange; // TB
      case 3: return Colors.red;    // Khó
      default: return Colors.blue;
    }
  }

  String _getDifficultyText(int difficulty) {
    switch (difficulty) {
      case 1: return "Dễ";
      case 2: return "Trung Bình";
      case 3: return "Khó";
      default: return "Khác";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch Sử Đấu"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _service.getMyHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Bạn chưa chơi ván nào!"));
          }

          final list = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];

              final difficulty = item['difficulty'] ?? item['Difficulty'] ?? 1;
              final score = item['score'] ?? item['Score'] ?? 0;
              final status = item['status'] ?? item['Status'] ?? "Không rõ";
              final date = item['date'] ?? item['Date'] ?? "";
              final mistakes = item['mistakeCount'] ?? item['MistakeCount'] ?? 0;
              final hints = item['hintCount'] ?? item['HintCount'] ?? 0;

              // --- SỬA LOGIC HIỂN THỊ TẠI ĐÂY ---
              final bool isCompleted = status.toString().contains("Hoàn thành") || status.toString() == "true";

              // Logic phân loại kết quả:
              // 1. Nếu chưa xong -> Đang chơi
              // 2. Nếu xong và điểm > 0 -> Thắng
              // 3. Nếu xong và điểm == 0 -> Đầu hàng / Thua
              String resultText;
              Color resultColor;
              IconData resultIcon;

              if (!isCompleted) {
                resultText = "Đang chơi";
                resultColor = Colors.blue;
                resultIcon = Icons.timelapse;
              } else if (score > 0) {
                resultText = "Thắng";
                resultColor = Colors.green;
                resultIcon = Icons.emoji_events;
              } else {
                resultText = "Đầu hàng"; // Hoặc "Thua"
                resultColor = Colors.red;
                resultIcon = Icons.flag;
              }

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(difficulty).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getDifficultyText(difficulty),
                              style: TextStyle(color: _getDifficultyColor(difficulty), fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$score Điểm",
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.error_outline, size: 16, color: Colors.red.shade300),
                                    Text(" Lỗi: $mistakes  ", style: const TextStyle(fontSize: 13)),
                                    Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber.shade600),
                                    Text(" Gợi ý: $hints", style: const TextStyle(fontSize: 13)),
                                  ],
                                )
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Icon(resultIcon, color: resultColor, size: 30),
                              Text(
                                resultText,
                                style: TextStyle(fontSize: 12, color: resultColor, fontWeight: FontWeight.bold),
                              )
                            ],
                          )
                        ],
                      ),
                    ],
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