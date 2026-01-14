import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class RoyalLeaderboardItem extends StatelessWidget {
  final int index;      // Thứ hạng (0, 1, 2...)
  final String name;    // Tên người chơi
  final String score;   // Điểm số
  final String time;    // Thời gian giải

  const RoyalLeaderboardItem({
    Key? key,
    required this.index,
    required this.name,
    required this.score,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int rank = index + 1;
    bool isTop1 = rank == 1;
    bool isTop3 = rank <= 3;

    // Chiều cao cố định 72px giúp danh sách gọn gàng, hiển thị được nhiều người hơn
    return Container(
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Stack(
        children: [
          // LỚP 1: BACKGROUND & HIỆU ỨNG
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: _getBackgroundGradient(rank),
                color: isTop3 ? null : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isTop3 ? 0.2 : 0.05),
                    blurRadius: isTop3 ? 8 : 3,
                    offset: const Offset(0, 3),
                  ),
                ],
                // Viền vàng cho Top 1
                border: isTop1 ? Border.all(color: const Color(0xFFFFD700), width: 1.5) : null,
              ),
              // Hiệu ứng Shimmer (Lấp lánh) chỉ dành cho nền của Top 1
              child: isTop1
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Shimmer.fromColors(
                  baseColor: Colors.transparent,
                  highlightColor: Colors.white.withOpacity(0.3),
                  period: const Duration(seconds: 3),
                  child: Container(color: Colors.white.withOpacity(0.1)),
                ),
              )
                  : null,
            ),
          ),

          // LỚP 2: NỘI DUNG CHÍNH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                // 1. ICON / RANK (Avatar)
                _buildRoleAvatar(rank),

                const SizedBox(width: 12),

                // 2. TÊN & DANH HIỆU (Căn trái)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isTop3 ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getRankTitle(rank),
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: isTop3 ? Colors.white.withOpacity(0.9) : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. ĐIỂM SỐ & THỜI GIAN (Căn phải)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Dòng trên: Điểm số (Nổi bật)
                    Row(
                      children: [
                        Text(
                          score,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isTop3 ? Colors.white : const Color(0xFFD32F2F), // Đỏ đậm cho người thường
                          ),
                        ),
                        if (isTop3) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.star, color: Colors.yellowAccent, size: 14),
                        ] else ...[
                          const SizedBox(width: 4),
                          const Text("pts", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Dòng dưới: Thời gian (Nhỏ hơn)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(isTop3 ? 0.2 : 0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 10, color: isTop3 ? Colors.white70 : Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: TextStyle(
                              fontFamily: 'RobotoMono', // Font số đơn giản
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isTop3 ? Colors.white70 : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- CÁC HÀM LOGIC HIỂN THỊ ---

  Widget _buildRoleAvatar(int rank) {
    // Top 4 trở đi hiển thị số thứ tự trong vòng tròn xám
    if (rank > 3) {
      return Container(
        width: 40, height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          "#$rank",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 14),
        ),
      );
    }

    // Top 3 hiển thị Icon đặc biệt
    IconData iconData;
    Color iconColor;
    Color bgColor;
    Color borderColor;

    switch (rank) {
      case 1: // Vua
        iconData = Icons.workspace_premium;
        iconColor = Colors.yellow;
        bgColor = Colors.red.shade900;
        borderColor = Colors.yellow;
        break;
      case 2: // Tướng
        iconData = Icons.military_tech;
        iconColor = Colors.white;
        bgColor = Colors.blue.shade800;
        borderColor = Colors.white70;
        break;
      case 3: // Hiệp sĩ
        iconData = Icons.shield;
        iconColor = Colors.white70;
        bgColor = Colors.brown.shade700;
        borderColor = const Color(0xFFFFCC80);
        break;
      default:
        iconData = Icons.person;
        iconColor = Colors.black;
        bgColor = Colors.white;
        borderColor = Colors.grey;
    }

    return Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  String _getRankTitle(int rank) {
    switch (rank) {
      case 1: return "King 👑";
      case 2: return "Master ⚔️";
      case 3: return "Knight 🛡️";
      default: return "Solver";
    }
  }

  LinearGradient? _getBackgroundGradient(int rank) {
    switch (rank) {
      case 1: return const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case 2: return const LinearGradient(colors: [Color(0xFFCFD8DC), Color(0xFF90A4AE)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case 3: return const LinearGradient(colors: [Color(0xFFD7CCC8), Color(0xFF8D6E63)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      default: return null;
    }
  }
}