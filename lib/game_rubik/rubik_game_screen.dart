import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Thư viện toán học 3D
import 'package:vector_math/vector_math_64.dart' as v;
// Thư viện Logic & Giải Rubik
import 'package:cuber/cuber.dart' as logic;
// Import Service
import 'leaderboard_item.dart';
import '../services/rubik_service.dart';
import 'dart:ui';
// --- DATA MODEL ---
enum Face { up, down, left, right, front, back }

class Cubie {
  v.Vector3 position;
  final Map<Face, Color> colors;
  Cubie({required this.position, required this.colors});
}

// ==========================================
// MAIN WIDGET
// ==========================================

class RubikGameScreen extends StatefulWidget {
  const RubikGameScreen({Key? key}) : super(key: key);

  @override
  State<RubikGameScreen> createState() => _RubikGameScreenState();
}

class _RubikGameScreenState extends State<RubikGameScreen>
    with TickerProviderStateMixin {
  // --- CONFIG ---
  final double _cubieSize = 50.0;
  final double _gap = 0.0;
  final double _perspective = 0.0;
  final GlobalKey _sceneKey = GlobalKey();

  // --- API & GAME STATE ---
  final RubikService _api = RubikService();
  String? _currentMatchId;
  Timer? _gameTimer;
  int _elapsedSeconds = 0;
  bool _isPlaying = false;
  bool _isAutoRotating = false;

  // --- TÍNH ĐIỂM & UI ---
  int _mistakes = 0;
  bool _showWinEffect = false;

  // --- LOGIC CUBE ---
  logic.Cube _logicCube = logic.Cube.solved;
  List<String> _solutionMoves = [];
  bool _isGuideActive = false;

  // --- 3D VISUAL STATE ---
  List<Cubie> _cubies = [];
  double _cameraX = -0.5;
  double _cameraY = -0.5;

  // --- INTERACTION STATE ---
  Cubie? _touchedCubie;
  v.Vector3? _touchedNormal;
  bool _isRotatingCamera = false;
  bool _lockInput = false;

  final TextEditingController _codeController = TextEditingController();
  late AnimationController _confettiController;


  @override
  void initState() {
    super.initState();
    _initVisualCube();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _codeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _initVisualCube() {
    _cubies.clear();
    for (int x = -1; x <= 1; x++) {
      for (int y = -1; y <= 1; y++) {
        for (int z = -1; z <= 1; z++) {
          Map<Face, Color> colors = {
            Face.up: Colors.white,
            Face.down: Colors.yellow,
            Face.front: Colors.green,
            Face.back: Colors.blue,
            Face.right: Colors.red,
            Face.left: Colors.orange,
          };
          _cubies.add(Cubie(
            position: v.Vector3(x.toDouble(), y.toDouble(), z.toDouble()),
            colors: colors,
          ));
        }
      }
    }
  }

  // ---------------------------------------------------------
  // PHẦN 1: UI & DIALOGS (BẢNG XẾP HẠNG MỚI)
  // ---------------------------------------------------------

  void _showStartDialog() {
    if (_isPlaying) {
      _showSurrenderConfirm();
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Bắt đầu chơi",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDifficultyOption(ctx, "Dễ (Easy)", 1, Colors.green),
            _buildDifficultyOption(
                ctx, "Trung bình (Medium)", 2, Colors.orange),
            _buildDifficultyOption(ctx, "Khó (Hard)", 3, Colors.red),
          ],
        ),
      ),
    );
  }
// --- HÀM RESET RUBIK ---
  void _resetCube() {
    // Chỉ cho phép reset khi KHÔNG trong ván chơi
    if (_isPlaying) return;

    setState(() {
      // 1. Reset logic về trạng thái đã giải
      _logicCube = logic.Cube.solved;

      // 2. Xóa các gợi ý, hướng dẫn cũ (nếu có)
      _solutionMoves.clear();
      _isGuideActive = false;
      _mistakes = 0;

      // 3. Reset hiển thị 3D (Màu sắc và vị trí về ban đầu)
      _initVisualCube();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Đã làm mới khối Rubik!"),
        duration: Duration(seconds: 1),
      ),
    );
  }
  Widget _buildDifficultyOption(
      BuildContext ctx, String text, int diff, Color color) {
    return ListTile(
      title: Text(text,
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      leading: Icon(Icons.fitness_center, color: color),
      onTap: () {
        Navigator.pop(ctx);
        _handleStartGame(diff);
      },
    );
  }

  // --- HIỂN THỊ BẢNG XẾP HẠNG (MỚI) ---
  void _showLeaderboardDialog() {
    if (_isPlaying) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return DefaultTabController(
          length: 3, // 3 Tab: Dễ, Vừa, Khó
          child: AlertDialog(
            backgroundColor: Colors.grey[900],
            contentPadding: EdgeInsets.zero,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Center(
              child: Text("BẢNG XẾP HẠNG",
                  style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 22)),
            ),
            content: SizedBox(
              height: 500,
              width: double.maxFinite,
              child: Column(
                children: [
                  const TabBar(
                    indicatorColor: Colors.amber,
                    labelColor: Colors.amber,
                    unselectedLabelColor: Colors.white54,
                    tabs: [
                      Tab(text: "Dễ"),
                      Tab(text: "Vừa"),
                      Tab(text: "Khó"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildLeaderboardTab(1), // Dễ
                        _buildLeaderboardTab(2), // Vừa
                        _buildLeaderboardTab(3), // Khó
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Đóng",
                      style: TextStyle(color: Colors.white)))
            ],
          ),
        );
      },
    );
  }

  // Widget con để tải dữ liệu cho từng Tab (ĐÃ CẬP NHẬT)
  Widget _buildLeaderboardTab(int difficulty) {
    return FutureBuilder<List<dynamic>?>(
      future: _api.getLeaderboard(difficulty),
      builder: (context, snapshot) {
        // Trạng thái đang tải
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.amber));
        }

        // Trạng thái lỗi hoặc null
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(
              child: Text("Lỗi tải dữ liệu!",
                  style: TextStyle(color: Colors.redAccent)));
        }

        final list = snapshot.data!;

        // Trạng thái danh sách trống
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard, color: Colors.white24, size: 50),
                SizedBox(height: 10),
                Text("Chưa có ai lọt top!",
                    style: TextStyle(color: Colors.white54)),
              ],
            ),
          );
        }

        // Hiển thị danh sách
        return ListView.builder(
          padding: const EdgeInsets.symmetric(
              vertical: 15), // Padding trên dưới tổng thể
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];

            // Lấy và xử lý dữ liệu an toàn
            final String name = item['userName'] ?? "Ẩn danh";
            final int score = item['score'] ?? 0;
            final dynamic rawTime =
                item['time'] ?? 0; // Time có thể là int hoặc double

            return RoyalLeaderboardItem(
              index: index,
              name: name,
              score: score.toString(), // Truyền điểm số vào
              time: "${rawTime}s", // Truyền thời gian vào
            );
          },
        );
      },
    );
  }

  // --- LỊCH SỬ ĐẤU ---
  void _showHistoryDialog() async {
    if (_isPlaying) return;
    showDialog(
        context: context,
        builder: (ctx) => const Center(child: CircularProgressIndicator()));
    List<dynamic>? history = await _api.getHistory();
    if (mounted) Navigator.pop(context);

    if (history != null && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("LỊCH SỬ ĐẤU",
              style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: history.isEmpty
                ? const Center(
                child: Text("Chưa có dữ liệu",
                    style: TextStyle(color: Colors.white54)))
                : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                final int difficulty = item['difficulty'] ?? 1;
                final int score = item['score'] ?? 0;
                final int time = item['time'] ?? 0;
                final String mode = item['mode'] ?? "Thường";
                final String result = item['result'] ?? "---";

                String diffText = "Dễ";
                Color diffColor = Colors.green;
                if (difficulty == 2) {
                  diffText = "Vừa";
                  diffColor = Colors.orange;
                }
                if (difficulty == 3) {
                  diffText = "Khó";
                  diffColor = Colors.red;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                        left: BorderSide(color: diffColor, width: 4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(mode,
                                style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: diffColor.withOpacity(0.2),
                                    borderRadius:
                                    BorderRadius.circular(4)),
                                child: Text(diffText,
                                    style: TextStyle(
                                        color: diffColor, fontSize: 10)))
                          ]),
                          const SizedBox(height: 4),
                          Text("Kết quả: $result",
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("$score điểm",
                              style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text("${time}s",
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12))
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Đóng", style: TextStyle(color: Colors.white)))
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Lỗi tải lịch sử!")));
    }
  }

  // --- LOGIC NHẬP MÃ (GIAO DIỆN MỚI - MODERN UI) ---
  void _showJoinChallengeDialog() {
    if (_isPlaying) {
      _showSurrenderConfirm();
      return;
    }
    _codeController.clear();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        // Dùng Dialog thường thay vì AlertDialog để tùy biến full
        return Dialog(
          backgroundColor: Colors.transparent, // Để hiển thị bo góc của Container con
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              // Nền Gradient đậm chất Gaming (Tím than -> Đen)
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple.shade900,
                  const Color(0xFF1E1E1E),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Icon Header với hiệu ứng Glow
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueAccent.withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  // Dùng icon tay cầm game (nhìn rất hợp với không khí thi đấu)
                  child: const Icon(Icons.sports_esports, size: 40, color: Colors.cyanAccent), // Icon Kiếm hoặc Gamepad
                ),
                const SizedBox(height: 20),

                // 2. Tiêu đề
                const Text(
                  "THÁCH ĐẤU",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Nhập mã phòng để so tài",
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // 3. Ô nhập liệu (Custom TextField)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: TextField(
                    controller: _codeController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.yellowAccent, // Màu chữ nhập vào nổi bật
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0, // Dãn cách chữ rộng ra nhìn giống mã code
                      fontFamily: 'RobotoMono', // Font kiểu máy đánh chữ (nếu có)
                    ),
                    textCapitalization: TextCapitalization.characters, // Tự động viết hoa
                    decoration: const InputDecoration(
                      hintText: "XYZ-123",
                      hintStyle: TextStyle(color: Colors.white12, letterSpacing: 3.0),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // 4. Các nút bấm
                Row(
                  children: [
                    // Nút Hủy
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Hủy bỏ", style: TextStyle(color: Colors.white54)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nút Vào chơi (Gradient Button)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Colors.blueAccent, Colors.cyan],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            String code = _codeController.text.trim();
                            if (code.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Vui lòng nhập mã thách đấu!"),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            Navigator.pop(ctx);
                            _handleStartGame(2, challengeCode: code);
                          },
                          child: const Text(
                            "CHIẾN NGAY",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleStartGame(int difficulty, {String challengeCode = ""}) async {
    _initVisualCube();
    _logicCube = logic.Cube.solved;
    _solutionMoves.clear();
    _isGuideActive = false;
    _elapsedSeconds = 0;
    _mistakes = 0;
    _showWinEffect = false;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()));
    final data = await _api.startGame(difficulty, challengeCode: challengeCode);
    if (mounted) Navigator.of(context).pop();

    if (data != null) {
      _currentMatchId = data['matchId']?.toString();
      var rawScramble = data['scramble'];
      List<String> moves = [];
      if (rawScramble is String) {
        moves =
            rawScramble.trim().split(' ').where((s) => s.isNotEmpty).toList();
      } else if (rawScramble is List) {
        moves = rawScramble.map((e) => e.toString()).toList();
      }
      print("Scramble: $moves");
      _applyScramble(moves);
      if (challengeCode.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Đã tham gia thách đấu thành công!"),
            backgroundColor: Colors.green));
      }
    } else {
      if (mounted) {
        String msg = challengeCode.isNotEmpty
            ? "Mã thách đấu không chính xác!"
            : "Lỗi kết nối mạng!";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _applyScramble(List<String> moves) async {
    try {
      for (var m in moves) {
        _logicCube = _logicCube.move(logic.Move.parse(m));
      }
    } catch (e) {
      print("Lỗi logic scramble: $e");
    }
    setState(() => _isAutoRotating = true);
    for (String move in moves) {
      await _performAutoMoveVisual(move, delayMs: 50, updateLogic: false);
    }
    setState(() {
      _isAutoRotating = false;
      _isPlaying = true;
      _startTimer();
    });
  }

  void _startTimer() {
    _elapsedSeconds = 0;
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _elapsedSeconds++);
    });
  }

  // --- KẾT THÚC GAME ---
  void _showSurrenderConfirm() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text("Bỏ cuộc?",
                style: TextStyle(color: Colors.white)),
            content: const Text("Bạn sẽ chịu thua ván này.",
                style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Không")),
              TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _finishGame(isWin: false);
                  },
                  child: const Text("Đồng ý",
                      style: TextStyle(color: Colors.red)))
            ]));
  }

  void _finishGame({required bool isWin}) async {
    _gameTimer?.cancel();
    setState(() => _isPlaying = false);
    if (isWin) {
      setState(() => _showWinEffect = true);
      _confettiController.forward(from: 0);
    }
    bool wantChallenge = false;
    if (isWin) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      wantChallenge = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text("🏆 CHIẾN THẮNG!",
                  style: TextStyle(color: Colors.amber)),
              content: const Text(
                  "Bạn có muốn tạo mã thách đấu cho ván này không?",
                  style: TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Không",
                        style: TextStyle(color: Colors.white54))),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text("Tạo thách đấu",
                        style: TextStyle(color: Colors.black)))
              ])) ??
          false;
    }
    if (mounted) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()));
    }
    Map<String, dynamic>? result;
    if (_currentMatchId != null) {
      result = await _api.finishGame(
          _currentMatchId!, _elapsedSeconds.toDouble(), _mistakes,
          createChallenge: wantChallenge);
    }
    if (mounted) Navigator.of(context).pop();
    if (result != null && mounted) _showResultDialog(result, isWin);
  }

  void _showResultDialog(Map<String, dynamic> data, bool isWin) {
    int score = data['score'] ?? 0;
    String message = data['message'] ?? (isWin ? "Hoàn thành!" : "Thất bại");
    final String? challengeCode = data['challengeCode'];
    if (!isWin) message = "Bạn đã bỏ cuộc!";
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
            backgroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: isWin ? Colors.amber : Colors.red, width: 2)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(isWin ? Icons.emoji_events : Icons.mood_bad,
                  size: 60, color: isWin ? Colors.amber : Colors.grey),
              const SizedBox(height: 10),
              Text(isWin ? "XUẤT SẮC!" : "CỐ GẮNG LẦN SAU",
                  style: TextStyle(
                      color: isWin ? Colors.amber : Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(message, style: const TextStyle(color: Colors.white70)),
              const Divider(color: Colors.white24, height: 30),
              Text("Điểm số: $score",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold)),
              Text("Dùng gợi ý: $_mistakes lần",
                  style:
                  const TextStyle(color: Colors.orange, fontSize: 12)),
              if (challengeCode != null && challengeCode.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blueAccent)),
                    child: Column(children: [
                      const Text("MÃ THÁCH ĐẤU",
                          style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      SelectableText(challengeCode,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      InkWell(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: challengeCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Đã sao chép!")));
                          },
                          child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.copy,
                                    size: 14, color: Colors.white54),
                                SizedBox(width: 4),
                                Text("Sao chép",
                                    style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12))
                              ]))
                    ]))
              ]
            ]),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _isGuideActive = false;
                      _solutionMoves.clear();
                      _showWinEffect = false;
                    });
                  },
                  child: const Text("Đóng",
                      style: TextStyle(color: Colors.white))),
              if (!isWin)
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _handleGuide();
                    },
                    child: const Text("Xem lời giải"))
            ]));
  }

  // --- LOGIC HƯỚNG DẪN & VISUAL ---
  void _handleGuide() {
    if (_isGuideActive) {
      setState(() {
        _isGuideActive = false;
        _solutionMoves.clear();
      });
      return;
    }
    _forceOpenGuide();
  }

  void _forceOpenGuide() {
    setState(() => _isGuideActive = true);
    _updateSolution();
  }
  void _updateSolution() {
    // Nếu Rubik đã giải xong
    if (_logicCube.isSolved) {
      // TRƯỜNG HỢP 1: Đang trong ván đấu (Ranked/Challenge)
      if (_isPlaying) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _finishGame(isWin: true);
        });
        return;
      }

      // TRƯỜNG HỢP 2: Chơi tự do (Free Play) -> Chỉ tắt gợi ý, KHÔNG gọi API
      setState(() {
        _solutionMoves.clear();
        _isGuideActive = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Khối Rubik đã được giải hoàn chỉnh!"), duration: Duration(seconds: 1)),
      );
      return;
    }

    // Nếu chưa giải xong -> Tìm lời giải
    Future.microtask(() {
      // Tăng độ sâu tìm kiếm lên 25-30 để đảm bảo tìm ra lời giải cho các thế khó
      final solution = _logicCube.solve(maxDepth: 25);
      if (mounted) {
        setState(() {
          if (solution != null && solution.algorithm.moves.isNotEmpty) {
            _solutionMoves = solution.algorithm.moves.map((m) => m.toString()).toList();
          } else {
            _solutionMoves.clear(); // Không tìm thấy lời giải hoặc lỗi
          }
        });
      }
    });
  }
  // --- RENDER & TOUCH ---
  void _handlePanStart(DragStartDetails details) {
    if (_isAutoRotating) return;
    final RenderBox? renderBox =
    _sceneKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final viewMatrix = Matrix4.identity()
      ..setEntry(3, 2, _perspective)
      ..rotateX(_cameraX)
      ..rotateY(_cameraY);
    final size = renderBox.size;
    final touchX = details.localPosition.dx - size.width / 2;
    final touchY = details.localPosition.dy - size.height / 2;
    Map<double, Cubie> hits = {};
    for (var cubie in _cubies) {
      final worldPos = v.Vector3(
          cubie.position.x * (_cubieSize + _gap),
          cubie.position.y * (_cubieSize + _gap),
          cubie.position.z * (_cubieSize + _gap));
      var v4 = v.Vector4(worldPos.x, worldPos.y, worldPos.z, 1.0);
      v4 = viewMatrix * v4;
      if (v4.w <= 0.0) continue;
      double screenX = v4.x / v4.w;
      double screenY = v4.y / v4.w;
      double dist = sqrt(
          pow(screenX - touchX, 2) + pow(screenY - touchY, 2));
      double hitRadius = (_cubieSize / 1.3) / v4.w;
      if (dist < hitRadius) hits[v4.z] = cubie;
    }
    if (hits.isNotEmpty) {
      var sortedKeys = hits.keys.toList()..sort();
      _touchedCubie = hits[sortedKeys.last];
      _isRotatingCamera = false;
      _touchedNormal = _determineTouchedFaceNormal(viewMatrix);
    } else {
      _touchedCubie = null;
      _isRotatingCamera = true;
    }
  }

  v.Vector3 _determineTouchedFaceNormal(Matrix4 viewMatrix) {
    Matrix4 invCam = Matrix4.inverted(viewMatrix);
    v.Vector3 cameraDir = invCam.forward;
    List<v.Vector3> normals = [
      v.Vector3(1, 0, 0),
      v.Vector3(-1, 0, 0),
      v.Vector3(0, 1, 0),
      v.Vector3(0, -1, 0),
      v.Vector3(0, 0, 1),
      v.Vector3(0, 0, -1)
    ];
    v.Vector3 bestNormal = normals[0];
    double minDot = 100.0;
    for (var n in normals) {
      double dot = n.dot(cameraDir);
      if (dot < minDot) {
        minDot = dot;
        bestNormal = n;
      }
    }
    return bestNormal;
  }
  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isAutoRotating) return;

    // 1. Xử lý xoay Camera (nếu không chạm vào khối nào hoặc đang xoay camera)
    if (_isRotatingCamera || _touchedCubie == null) {
      setState(() {
        _cameraY += details.delta.dx * 0.01;
        _cameraX -= details.delta.dy * 0.01;
      });
      return;
    }

    if (_lockInput) return;
    if (details.delta.distance < 8.0) return; // Bỏ qua rung tay nhẹ

    // 2. Xác định hướng vuốt
    v.Vector3 normal = _touchedNormal!;
    List<v.Vector3> rotCandidates = [];

    // Tùy vào mặt đang chạm (Normal) mà xác định 2 trục xoay khả thi
    if (normal.x.abs() > 0.9) {
      rotCandidates = [v.Vector3(0, 1, 0), v.Vector3(0, 0, 1)];
    } else if (normal.y.abs() > 0.9) {
      rotCandidates = [v.Vector3(1, 0, 0), v.Vector3(0, 0, 1)];
    } else {
      rotCandidates = [v.Vector3(1, 0, 0), v.Vector3(0, 1, 0)];
    }

    // Ma trận xoay để tính toán hướng trên màn hình 2D
    final viewMatrix = Matrix4.identity()
      ..setEntry(3, 2, _perspective)
      ..rotateX(_cameraX)
      ..rotateY(_cameraY);
    final rotMat = Matrix4.copy(viewMatrix);
    rotMat.setTranslationRaw(0, 0, 0);

    v.Vector3 bestRotAxis = rotCandidates[0];
    double maxDot = -1.0;
    bool isPositiveDir = true;
    v.Vector2 swipeDir = v.Vector2(details.delta.dx, details.delta.dy).normalized();

    // Tìm trục xoay khớp nhất với hướng vuốt của ngón tay
    for (var axis in rotCandidates) {
      v.Vector3 moveDir3D = axis.cross(normal);
      v.Vector3 screenMove3D = rotMat.transformed3(moveDir3D);
      v.Vector2 screenMove2D = v.Vector2(screenMove3D.x, screenMove3D.y).normalized();
      double dot = screenMove2D.dot(swipeDir);
      if (dot.abs() > maxDot) {
        maxDot = dot.abs();
        bestRotAxis = axis;
        isPositiveDir = dot > 0;
      }
    }

    // 3. Xác định lớp (Layer) đang được xoay
    double filterVal = 0;
    if (bestRotAxis.x != 0) {
      filterVal = _touchedCubie!.position.x;
    } else if (bestRotAxis.y != 0) {
      filterVal = _touchedCubie!.position.y;
    } else {
      filterVal = _touchedCubie!.position.z;
    }

    // --- TÍNH NĂNG MỚI: KHÓA XOAY LỚP GIỮA ---
    // Rubik 3x3 có tọa độ các lớp là -1, 0, 1.
    // Nếu filterVal gần bằng 0 (lớp giữa), ta return luôn, không thực hiện xoay.
    if (filterVal.abs() < 0.1) {
      return;
    }
    // ------------------------------------------

    // 4. Thực hiện xoay
    _lockInput = true;
    _performInstantMove(bestRotAxis, filterVal, isPositiveDir, updateLogic: true);

    // Mở khóa input sau 200ms (thời gian animation)
    Future.delayed(const Duration(milliseconds: 200), () => _lockInput = false);
  }

  void _performInstantMove(v.Vector3 axis, double layerVal, bool isPositiveSwipe,
      {bool updateLogic = false}) {
    if (updateLogic) _syncLogicMove(axis, layerVal, isPositiveSwipe);
    List<Cubie> activeCubies = _cubies.where((c) {
      if (axis.x != 0) return (c.position.x - layerVal).abs() < 0.1;
      if (axis.y != 0) return (c.position.y - layerVal).abs() < 0.1;
      return (c.position.z - layerVal).abs() < 0.1;
    }).toList();
    if (activeCubies.isEmpty) return;
    double angle = (isPositiveSwipe ? 1.0 : -1.0) * pi / 2;
    final qRot = v.Quaternion.axisAngle(axis, angle);
    bool isClockwise = angle < 0;
    setState(() {
      for (var cubie in activeCubies) {
        cubie.position = qRot.rotate(cubie.position);
        cubie.position.x = cubie.position.x.roundToDouble();
        cubie.position.y = cubie.position.y.roundToDouble();
        cubie.position.z = cubie.position.z.roundToDouble();
        final oldColors = Map<Face, Color>.from(cubie.colors);
        if (axis.x.abs() > 0.9) {
          if (isClockwise) {
            cubie.colors[Face.up] = oldColors[Face.front]!;
            cubie.colors[Face.back] = oldColors[Face.up]!;
            cubie.colors[Face.down] = oldColors[Face.back]!;
            cubie.colors[Face.front] = oldColors[Face.down]!;
          } else {
            cubie.colors[Face.down] = oldColors[Face.front]!;
            cubie.colors[Face.back] = oldColors[Face.down]!;
            cubie.colors[Face.up] = oldColors[Face.back]!;
            cubie.colors[Face.front] = oldColors[Face.up]!;
          }
        } else if (axis.y.abs() > 0.9) {
          if (isClockwise) {
            cubie.colors[Face.right] = oldColors[Face.front]!;
            cubie.colors[Face.back] = oldColors[Face.right]!;
            cubie.colors[Face.left] = oldColors[Face.back]!;
            cubie.colors[Face.front] = oldColors[Face.left]!;
          } else {
            cubie.colors[Face.left] = oldColors[Face.front]!;
            cubie.colors[Face.back] = oldColors[Face.left]!;
            cubie.colors[Face.right] = oldColors[Face.back]!;
            cubie.colors[Face.front] = oldColors[Face.right]!;
          }
        } else if (axis.z.abs() > 0.9) {
          if (isClockwise) {
            cubie.colors[Face.right] = oldColors[Face.up]!;
            cubie.colors[Face.down] = oldColors[Face.right]!;
            cubie.colors[Face.left] = oldColors[Face.down]!;
            cubie.colors[Face.up] = oldColors[Face.left]!;
          } else {
            cubie.colors[Face.left] = oldColors[Face.up]!;
            cubie.colors[Face.down] = oldColors[Face.left]!;
            cubie.colors[Face.right] = oldColors[Face.down]!;
            cubie.colors[Face.up] = oldColors[Face.right]!;
          }
        }
      }
    });
  }

  void _syncLogicMove(v.Vector3 axis, double val, bool isPositiveSwipe) {
    bool visualClockwise = !isPositiveSwipe;
    logic.Move? move;
    if (axis.x == 1) {
      if (val > 0.5) {
        move = visualClockwise ? logic.Move.right : logic.Move.rightInv;
      } else if (val < -0.5) {
        move = visualClockwise ? logic.Move.leftInv : logic.Move.left;
      }
    } else if (axis.y == 1) {
      if (val > 0.5) {
        move = visualClockwise ? logic.Move.down : logic.Move.downInv;
      } else if (val < -0.5) {
        move = visualClockwise ? logic.Move.upInv : logic.Move.up;
      }
    } else if (axis.z == 1) {
      if (val > 0.5) {
        move = visualClockwise ? logic.Move.front : logic.Move.frontInv;
      } else if (val < -0.5) {
        try {
          if (visualClockwise)
            move = logic.Move.parse("B'");
          else
            move = logic.Move.parse("B");
        } catch (_) {}
      }
    }
    if (move != null) {
      try {
        _logicCube = _logicCube.move(move);

        // KIỂM TRA CHIẾN THẮNG
        if (_logicCube.isSolved) {
          if (_isPlaying) {
            // Chỉ finish game nếu đang trong chế độ chơi
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _finishGame(isWin: true);
            });
          } else {
            // Nếu chơi tự do -> Chỉ hiển thị thông báo nhỏ
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Tuyệt vời! Bạn đã giải xong."), duration: Duration(seconds: 1)),
            );
            setState(() {
              _isGuideActive = false;
              _solutionMoves.clear();
            });
          }
        }
      } catch (e) {
        print("Lỗi move logic: $e");
      }

      // Cập nhật lại gợi ý nếu đang bật
      if (_isGuideActive && !_logicCube.isSolved) {
        _updateSolution();
      } else {
        _solutionMoves.clear();
      }
    }
  }

  Future<void> _performAutoMoveVisual(String moveStr,
      {int delayMs = 300, bool updateLogic = true}) async {
    String cleanMove = moveStr.trim();
    bool isPrime = cleanMove.contains("'");
    bool isDouble = cleanMove.contains("2");
    String face = cleanMove[0];
    v.Vector3 axis = v.Vector3(1, 0, 0);
    double layerVal = 0;
    bool isPositiveSwipe = true;
    switch (face) {
      case 'R':
        axis = v.Vector3(1, 0, 0);
        layerVal = 1;
        isPositiveSwipe = false;
        break;
      case 'L':
        axis = v.Vector3(1, 0, 0);
        layerVal = -1;
        isPositiveSwipe = true;
        break;
      case 'U':
        axis = v.Vector3(0, 1, 0);
        layerVal = -1;
        isPositiveSwipe = true;
        break;
      case 'D':
        axis = v.Vector3(0, 1, 0);
        layerVal = 1;
        isPositiveSwipe = false;
        break;
      case 'F':
        axis = v.Vector3(0, 0, 1);
        layerVal = 1;
        isPositiveSwipe = false;
        break;
      case 'B':
        axis = v.Vector3(0, 0, 1);
        layerVal = -1;
        isPositiveSwipe = true;
        break;
    }
    if (isPrime) isPositiveSwipe = !isPositiveSwipe;
    if (updateLogic) {
      try {
        _logicCube = _logicCube.move(logic.Move.parse(cleanMove));
      } catch (_) {}
    }
    int loops = isDouble ? 2 : 1;
    for (int i = 0; i < loops; i++) {
      _performInstantMove(axis, layerVal, isPositiveSwipe, updateLogic: false);
      if (loops > 1) await Future.delayed(const Duration(milliseconds: 100));
    }
    await Future.delayed(Duration(milliseconds: delayMs));
  }

  double _getRenderZ(Cubie cubie, Matrix4 cameraMatrix) {
    Matrix4 transform = Matrix4.identity();
    transform.translate(
        cubie.position.x * (_cubieSize + _gap),
        cubie.position.y * (_cubieSize + _gap),
        cubie.position.z * (_cubieSize + _gap));
    final fullTransform = cameraMatrix * transform;
    return fullTransform.transformed3(v.Vector3.zero()).z;
  }
  @override
  Widget build(BuildContext context) {
    // Tính toán ma trận Camera
    final cameraMatrix = Matrix4.identity()
      ..setEntry(3, 2, _perspective)
      ..rotateX(_cameraX)
      ..rotateY(_cameraY);

    var sortedCubies = List<Cubie>.from(_cubies);
    sortedCubies.sort((a, b) => _getRenderZ(a, cameraMatrix)
        .compareTo(_getRenderZ(b, cameraMatrix)));

    return Scaffold(
      extendBodyBehindAppBar: true, // Cho phép nền tràn lên sau AppBar

      // --- APP BAR (Giữ nguyên phần đẹp đã làm) ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const BackButton(color: Colors.white),
          ),
        ),
        title: _isPlaying
            ? Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 10),
              Text(
                "${_elapsedSeconds}s",
                style: const TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        )
            : ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.apps, size: 28, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                "RUBIK MASTER",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontStyle: FontStyle.italic,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (!_isPlaying)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _resetCube,
                tooltip: "Làm mới",
                icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
              ),
            ),
        ],
      ),

      // --- BODY VỚI NỀN RADIAL GRADIENT MỚI ---
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center, // Tâm sáng ở giữa màn hình
            radius: 1.3,              // Độ lan tỏa
            colors: [
              Color(0xFF2C3E50),      // Xanh đen nhạt ở giữa (làm nổi Rubik)
              Color(0xFF000000),      // Đen tuyền ở các góc
            ],
            stops: [0.3, 1.0],        // Điểm chuyển màu
          ),
        ),
        child: Stack(
          children: [
            // LỚP 1: KHỐI RUBIK 3D
            Center(
              child: GestureDetector(
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                child: Container(
                  key: _sceneKey,
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: cameraMatrix,
                    child: Stack(
                      children: sortedCubies.map((cubie) {
                        Matrix4 cubieLocalTransform = Matrix4.identity();
                        cubieLocalTransform.translate(
                          cubie.position.x * (_cubieSize + _gap),
                          cubie.position.y * (_cubieSize + _gap),
                          cubie.position.z * (_cubieSize + _gap),
                        );
                        return Positioned(
                          child: Transform(
                            transform: cubieLocalTransform,
                            alignment: Alignment.center,
                            child: _buildSingleCubie(cubie, cubieLocalTransform, cameraMatrix),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),

            // LỚP 2: MENU CHỨC NĂNG (Bên phải - Glassmorphism)
            Positioned(
              top: kToolbarHeight + 80, // Đã sửa khoảng cách top=80
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!_isPlaying) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCustomButton(
                        icon: Icons.sports_esports,
                        label: "Thách đấu",
                        color: Colors.blueAccent,
                        onPressed: _showJoinChallengeDialog,
                        isRightAlign: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCustomButton(
                        icon: Icons.history,
                        label: "Lịch sử",
                        color: Colors.purpleAccent,
                        onPressed: _showHistoryDialog,
                        isRightAlign: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCustomButton(
                        icon: Icons.emoji_events,
                        label: "Xếp hạng",
                        color: Colors.amberAccent,
                        onPressed: _showLeaderboardDialog,
                        isRightAlign: true,
                      ),
                    ),
                  ],
                  // Nút Gợi ý
                  _buildCustomButton(
                    icon: Icons.lightbulb,
                    label: "Gợi ý",
                    color: _isGuideActive ? Colors.greenAccent : Colors.amber,
                    onPressed: _handleGuide,
                    isRightAlign: true,
                  ),
                ],
              ),
            ),

            // LỚP 3: NÚT BẮT ĐẦU (Dưới cùng)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  icon: Icon(_isPlaying ? Icons.flag : Icons.play_arrow, size: 28),
                  label: Text(
                    _isPlaying ? "Bỏ cuộc" : "BẮT ĐẦU CHƠI",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPlaying ? Colors.redAccent : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 10,
                    shadowColor: _isPlaying
                        ? Colors.redAccent.withOpacity(0.5)
                        : Colors.green.withOpacity(0.5),
                  ),
                  onPressed: _showStartDialog,
                ),
              ),
            ),

            // LỚP 4: Hiệu ứng chiến thắng
            if (_showWinEffect) _buildWinEffectOverlay(),

            // LỚP 5: Guide HUD
            if (_isGuideActive && _solutionMoves.isNotEmpty)
              Positioned(
                bottom: 110,
                left: 20,
                right: 20,
                child: _buildGuideHUD(),
              ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildCustomButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isRightAlign = false,
  }) {
    // ClipRRect để cắt bo góc cho hiệu ứng Blur bên trong
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        // Hiệu ứng làm mờ nền phía sau nút (Blur)
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            // Nền màu pha chút trong suốt
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            // Viền sáng nhẹ tạo cảm giác nổi khối 3D
            border: Border.all(color: color.withOpacity(0.5), width: 1),
            // Đổ bóng nhẹ cho nút
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onPressed,
              splashColor: color.withOpacity(0.3), // Hiệu ứng loang màu khi bấm
              highlightColor: color.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: isRightAlign
                      ? [
                    // Nếu căn phải: Text trước, Icon sau
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(icon, color: color, size: 22),
                  ]
                      : [
                    // Mặc định: Icon trước, Text sau
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildGuideHUD() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.yellowAccent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Hiển thị bước đi tiếp theo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Bước kế: ",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _solutionMoves.isNotEmpty ? _solutionMoves.first : "...",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. Hiển thị số bước còn lại
          Text(
            "Còn lại: ${_solutionMoves.length} bước",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // 3. Các nút điều khiển
          Row(
            children: [
              // Nút "Đi bước này"
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Đi bước này"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    // Chặn nếu đang xoay hoặc hết gợi ý
                    if (_isAutoRotating || _solutionMoves.isEmpty) return;

                    setState(() {
                      _isAutoRotating = true;
                      // CHỈ TÍNH LỖI NẾU ĐANG CHƠI GAME TÍNH ĐIỂM
                      if (_isPlaying) {
                        _mistakes++;
                      }
                    });

                    // Lấy nước đi tiếp theo
                    String move = _solutionMoves.first;
                    setState(() {
                      _solutionMoves.removeAt(0);
                    });

                    // Thực hiện xoay Visual + Logic
                    await _performAutoMoveVisual(move, updateLogic: true);

                    // --- LOGIC KIỂM TRA SAU KHI XOAY ---

                    // Trường hợp 1: Đã giải xong hoàn toàn
                    if (_logicCube.isSolved) {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (mounted) {
                          if (_isPlaying) {
                            // Nếu đang đua top -> Kết thúc game
                            _finishGame(isWin: true);
                          } else {
                            // Nếu chơi tự do -> Chỉ báo thành công và tắt gợi ý
                            setState(() => _isGuideActive = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Chúc mừng! Khối Rubik đã được giải."),
                                backgroundColor: Colors.purple,
                              ),
                            );
                          }
                        }
                      });
                    }
                    // Trường hợp 2: Hết gợi ý nhưng vẫn CHƯA giải xong
                    // (Có thể do thuật toán chia nhỏ bước hoặc người dùng xoay sai trước đó)
                    else if (_solutionMoves.isEmpty && !_logicCube.isSolved) {
                      // Tự động tìm lời giải tiếp theo cho trạng thái hiện tại
                      _updateSolution();
                    }

                    // Mở khóa input
                    setState(() => _isAutoRotating = false);
                  },
                ),
              ),

              const SizedBox(width: 10),

              // Nút Đóng gợi ý
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      _isGuideActive = false;
                      _solutionMoves.clear();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWinEffectOverlay() {
    return IgnorePointer(
      child: Stack(
        children: List.generate(20, (index) {
          final random = Random(index);
          return AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              double fall = _confettiController.value * 800 +
                  (random.nextDouble() * -200);
              double sway =
                  sin(_confettiController.value * 10 + index) * 50;
              return Positioned(
                top: fall - 50,
                left: (MediaQuery.of(context).size.width / 20) * index + sway,
                child: Opacity(
                  opacity: (1 - _confettiController.value).clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: _confettiController.value *
                        10 *
                        (index % 2 == 0 ? 1 : -1),
                    child: Container(
                      width: 10,
                      height: 10,
                      color: Colors.primaries[index % Colors.primaries.length],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildSingleCubie(
      Cubie cubie, Matrix4 cubieTransform, Matrix4 cameraMatrix) {
    List<Widget> faces = [];
    final faceDefs = [
      {
        'face': Face.front,
        'normal': v.Vector3(0, 0, 1),
        'matrix': Matrix4.identity()..translate(0.0, 0.0, _cubieSize / 2)
      },
      {
        'face': Face.back,
        'normal': v.Vector3(0, 0, -1),
        'matrix': Matrix4.identity()
          ..translate(0.0, 0.0, -_cubieSize / 2)
          ..rotateY(pi)
      },
      {
        'face': Face.up,
        'normal': v.Vector3(0, -1, 0),
        'matrix': Matrix4.identity()
          ..translate(0.0, -_cubieSize / 2, 0.0)
          ..rotateX(-pi / 2)
      },
      {
        'face': Face.down,
        'normal': v.Vector3(0, 1, 0),
        'matrix': Matrix4.identity()
          ..translate(0.0, _cubieSize / 2, 0.0)
          ..rotateX(pi / 2)
      },
      {
        'face': Face.left,
        'normal': v.Vector3(-1, 0, 0),
        'matrix': Matrix4.identity()
          ..translate(-_cubieSize / 2, 0.0, 0.0)
          ..rotateY(-pi / 2)
      },
      {
        'face': Face.right,
        'normal': v.Vector3(1, 0, 0),
        'matrix': Matrix4.identity()
          ..translate(_cubieSize / 2, 0.0, 0.0)
          ..rotateY(pi / 2)
      }
    ];

    for (var def in faceDefs) {
      if (_isFaceVisible(
          def['normal'] as v.Vector3, cubieTransform, cameraMatrix)) {
        faces.add(_buildFace(
            cubie, def['face'] as Face, def['matrix'] as Matrix4));
      }
    }
    return SizedBox(
      width: _cubieSize,
      height: _cubieSize,
      child: Stack(children: faces),
    );
  }

  bool _isFaceVisible(
      v.Vector3 faceNormal, Matrix4 cubieTransform, Matrix4 cameraMatrix) {
    final fullTransform = cameraMatrix * cubieTransform;
    final rotationOnly = Matrix4.copy(fullTransform);
    rotationOnly.setTranslationRaw(0, 0, 0);
    return rotationOnly.transformed3(faceNormal).z > 0;
  }

  Widget _buildFace(Cubie cubie, Face face, Matrix4 transform) {
    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: Container(
        width: _cubieSize,
        height: _cubieSize,
        decoration: BoxDecoration(
          color: cubie.colors[face]!,
          border: Border.all(color: Colors.black87, width: 2.0),
          borderRadius: BorderRadius.circular(3.0),
        ),
      ),
    );
  }
}