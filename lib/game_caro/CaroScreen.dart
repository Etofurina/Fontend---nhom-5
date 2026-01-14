import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

import 'CaroStatsScreen.dart';
import 'caro_logic.dart';


class CaroScreen extends StatefulWidget {
  // Nhận chế độ chơi từ Menu truyền sang
  final bool initPvE;

  CaroScreen({this.initPvE = true}); // Mặc định là đấu máy

  @override
  _CaroScreenState createState() => _CaroScreenState();
}

class _CaroScreenState extends State<CaroScreen> {
  // 0: Trống, 1: Người (X), 2: Máy/Người chơi 2 (O)
  List<int> board = List.filled(CaroLogic.boardSize * CaroLogic.boardSize, 0);
  bool isPlayerTurn = true;
  bool isGameOver = false;
  int moves = 0;
  int seconds = 0;
  Timer? timer;

  // Biến này sẽ lấy giá trị từ widget.initPvE
  late bool isPvE;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    isPvE = widget.initPvE; // Thiết lập chế độ chơi ngay khi vào màn hình
    startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (t) => setState(() => seconds++));
  }

  void _handleTap(int index) async {
    // Nếu ô đã đánh hoặc game kết thúc thì bỏ qua
    if (board[index] != 0 || isGameOver) return;

    // Nếu đang đấu máy mà chưa đến lượt người chơi thì chặn
    if (isPvE && !isPlayerTurn) return;

    setState(() {
      board[index] = isPlayerTurn ? 1 : 2; // 1 là X, 2 là O
      moves++;
    });

    // Kiểm tra thắng sau nước đi
    if (CaroLogic.checkWin(board, index, isPlayerTurn ? 1 : 2)) {
      _endGame(isPlayerTurn ? 1 : -1); // 1: Thắng, -1: Thua (nếu đấu máy)
      return;
    }

    // Đổi lượt
    isPlayerTurn = !isPlayerTurn;

    // --- LOGIC BOT ĐÁNH ---
    if (isPvE && !isPlayerTurn && !isGameOver) {
      // Giả vờ suy nghĩ một chút cho tự nhiên
      await Future.delayed(Duration(milliseconds: 500));

      int botMove = CaroLogic.getBotMove(board);
      if (botMove != -1) {
        setState(() {
          board[botMove] = 2; // Máy đánh O
        });

        // Kiểm tra xem máy có thắng không
        if (CaroLogic.checkWin(board, botMove, 2)) {
          _endGame(-1); // Người thua
        } else {
          setState(() => isPlayerTurn = true); // Trả lượt cho người
        }
      }
    }
  }

  void _endGame(int result) async {
    timer?.cancel();
    setState(() => isGameOver = true);

    String msg = "";
    if (isPvE) {
      msg = result == 1 ? "BẠN THẮNG!" : "MÁY THẮNG!";
      // Chỉ lưu kết quả lên Server khi đấu với máy
      await _apiService.finishCaro(result, moves, seconds.toDouble(), "PvE");
    } else {
      msg = isPlayerTurn ? "X THẮNG!" : "O THẮNG!"; // PvP Local
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("KẾT THÚC"),
        content: Text(msg, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        actions: [
          TextButton(
            child: Text("Thoát"),
            onPressed: () {
              Navigator.pop(context); // Đóng Dialog
              Navigator.pop(context); // Thoát khỏi màn hình game về Menu
            },
          ),
          ElevatedButton(
            child: Text("Chơi lại"),
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
          )
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      board = List.filled(CaroLogic.boardSize * CaroLogic.boardSize, 0);
      isGameOver = false;
      isPlayerTurn = true;
      moves = 0;
      seconds = 0;
    });
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Tiêu đề thay đổi linh hoạt
        title: Text(isPvE ? "Đấu với Máy" : "Hai Người Chơi"),
        centerTitle: true,
        actions: [
          // Nút xem Thống kê & Xếp hạng
          IconButton(
            icon: Icon(Icons.bar_chart),
            tooltip: "Thành tích",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CaroStatsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Thanh thông tin trạng thái
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Thời gian: ${seconds}s", style: TextStyle(fontSize: 16)),
                Text(
                    isPvE
                        ? (isPlayerTurn ? "Lượt bạn (X)" : "Máy đang nghĩ...")
                        : (isPlayerTurn ? "Lượt X" : "Lượt O"),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPlayerTurn ? Colors.blue : Colors.red,
                        fontSize: 18
                    )
                ),
              ],
            ),
          ),

          // Bàn cờ Caro
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: CaroLogic.boardSize, // 15 cột
              ),
              itemCount: board.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _handleTap(index),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      color: board[index] == 0 ? Colors.white : Colors.yellow[50],
                    ),
                    child: Center(
                      child: board[index] == 0
                          ? null
                          : Text(
                        board[index] == 1 ? "X" : "O",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: board[index] == 1 ? Colors.blue : Colors.red,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}