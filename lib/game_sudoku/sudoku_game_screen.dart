// File: lib/game_sudoku/sudoku_game_screen.dart
import 'package:flutter/material.dart';
import 'sudoku_service.dart'; // [QUAN TRỌNG] Đã sửa dòng này (bỏ ../services/)
import 'dart:async';

class SudokuGameScreen extends StatefulWidget {
  final int matchId;
  final String initialBoard;
  final int difficulty; // 1: Dễ, 2: TB, 3: Khó

  const SudokuGameScreen({
    Key? key,
    required this.matchId,
    required this.initialBoard,
    required this.difficulty,
  }) : super(key: key);

  @override
  _SudokuGameScreenState createState() => _SudokuGameScreenState();
}

class _SudokuGameScreenState extends State<SudokuGameScreen> {
  // Quản lý bàn cờ
  late List<int> _currentBoard;
  late List<int> _fixedNumbers;
  int? _selectedRow;
  int? _selectedCol;

  final SudokuService _sudokuService = SudokuService();

  // Trạng thái Game
  String _message = 'Sẵn sàng!';
  Timer? _timer;
  int _secondsElapsed = 0;

  // Chỉ số
  int _mistakeCount = 0;
  int _hintCount = 0;
  int _score = 0;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    // Parse Board
    _currentBoard = widget.initialBoard.split('').map(int.parse).toList();
    _fixedNumbers = widget.initialBoard.split('').map(int.parse).toList();

    // Tính điểm khởi đầu
    _calculateInitialScore();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- LOGIC TÍNH ĐIỂM ---
  void _calculateInitialScore() {
    _score = widget.difficulty * 1000;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isGameOver) {
        setState(() {
          _secondsElapsed++;
          _calculateLocalScore(); // Trừ điểm hiển thị theo thời gian
        });
      }
    });
  }

  void _calculateLocalScore() {
    int baseScore = widget.difficulty * 1000;
    int mistakePenalty = _mistakeCount * 50;
    int hintPenalty = _hintCount * 100;
    int timePenalty = _secondsElapsed;

    int tempScore = baseScore - mistakePenalty - hintPenalty - timePenalty;
    _score = tempScore > 0 ? tempScore : 0;
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // --- LOGIC GAME ---
  int _toIndex(int row, int col) => row * 9 + col;

  void _selectCell(int row, int col) {
    if (_isGameOver) return;
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
    });
  }

  // Xử lý nhập số
  Future<void> _handleNumberInput(int value) async {
    if (_selectedRow == null || _selectedCol == null || _isGameOver) return;

    int row = _selectedRow!;
    int col = _selectedCol!;
    int index = _toIndex(row, col);

    if (_fixedNumbers[index] != 0) {
      _showSnackbar('Không thể thay đổi ô cố định!', isError: true);
      return;
    }

    setState(() {
      _currentBoard[index] = value;
      _message = 'Đang kiểm tra...';
    });

    try {
      final result = await _sudokuService.makeMove(
        matchId: widget.matchId,
        row: row,
        col: col,
        value: value,
      );

      setState(() {
        // [FIX] Dùng ?? để chấp nhận cả 'board' và 'Board'
        final boardStr = result['board'] ?? result['Board'];
        _currentBoard = (boardStr as String).split('').map(int.parse).toList();

        _message = result['message'] ?? result['Message'];

        // Cập nhật chỉ số từ server (chấp nhận cả hoa/thường)
        _score = result['score'] ?? result['Score'] ?? _score;
        _mistakeCount = result['mistakeCount'] ?? result['MistakeCount'] ?? _mistakeCount;
      });

      // Kiểm tra thua (3 lỗi)
      if (_mistakeCount >= 3) {
        _timer?.cancel();
        _isGameOver = true;
        _showLossDialog();
        return;
      }

      // Kiểm tra thắng
      final msg = _message.toUpperCase();
      final isCompleted = result['isCompleted'] ?? result['IsCompleted'] ?? false;

      if (msg.contains('WIN') || isCompleted == true) {
        _timer?.cancel();
        _isGameOver = true;
        _showWinDialog();
      }

    } catch (e) {
      // Xử lý lỗi sạch
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _currentBoard[index] = 0; // Hoàn tác
        _message = "Lỗi!";
      });
      _showSnackbar('Lỗi: $errorMsg', isError: true);
    }
  }

  // Xử lý Gợi ý (Hint)
  Future<void> _handleHint() async {
    if (_isGameOver) return;

    if (_hintCount >= 3) {
      _showSurrenderPrompt();
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang tìm gợi ý..."), duration: Duration(milliseconds: 500)));

      final result = await _sudokuService.getHint(widget.matchId);

      setState(() {
        // [FIX] Handle casing
        final boardStr = result['board'] ?? result['Board'];
        _currentBoard = (boardStr as String).split('').map(int.parse).toList();

        _score = result['score'] ?? result['Score'];
        _hintCount = result['hintCount'] ?? result['HintCount'];
        _message = result['message'] ?? result['Message'];

        // Auto focus vào ô gợi ý
        final sRow = result['suggestedRow'] ?? result['SuggestedRow'];
        final sCol = result['suggestedCol'] ?? result['SuggestedCol'];
        if (sRow != null && sCol != null) {
          _selectedRow = sRow;
          _selectedCol = sCol;
        }
      });

      final isCompleted = result['isCompleted'] ?? result['IsCompleted'] ?? false;
      if (isCompleted == true) {
        _timer?.cancel();
        _isGameOver = true;
        _showWinDialog();
      }

    } catch (e) {
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      // Nếu backend trả về lỗi hết lượt
      if (errorMsg.contains("hết 3 lần")) {
        _showSurrenderPrompt();
      } else {
        _showSnackbar("Lỗi: $errorMsg", isError: true);
      }
    }
  }

  // Xử lý Đầu hàng (Surrender)
  Future<void> _handleSurrender() async {
    try {
      final result = await _sudokuService.surrenderGame(widget.matchId);
      setState(() {
        // [FIX] Handle casing và fallback key
        final boardStr = result['board'] ?? result['Board'] ?? result['Solution'];
        _currentBoard = (boardStr as String).split('').map(int.parse).toList();

        _isGameOver = true;
        _score = 0;
        _message = "Đã hiện lời giải.";
        _timer?.cancel();
      });
    } catch (e) {
      _showSnackbar("Lỗi: ${e.toString().replaceAll('Exception: ', '')}", isError: true);
    }
  }

  // Hộp thoại hỏi đầu hàng
  void _showSurrenderPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hết lượt gợi ý! 🚫"),
        content: const Text("Bạn đã hết 3 quyền trợ giúp.\nĐầu hàng để xem đáp án?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tự chơi")),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _handleSurrender();
              },
              child: const Text("Đầu hàng", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  // --- UI WIDGETS ---

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green, duration: const Duration(milliseconds: 1500)),
    );
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("CHIẾN THẮNG! 🏆"),
        content: Text("Điểm: $_score\nThời gian: ${_formatTime(_secondsElapsed)}\nLỗi: $_mistakeCount"),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text("Về Menu")),
        ],
      ),
    );
  }

  void _showLossDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("GAME OVER 😔", style: TextStyle(color: Colors.red)),
        content: Text("Quá 3 lỗi!\nĐiểm: $_score"),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text("Thoát")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Thoát game?'),
            content: const Text('Tiến trình sẽ bị mất.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ở lại')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Thoát')),
            ],
          ),
        );
        if (shouldPop == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sudoku'),
          actions: [
            // Nút Gợi ý
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.lightbulb, color: _hintCount < 3 ? Colors.amber : Colors.grey),
                  tooltip: "Gợi ý",
                  onPressed: _handleHint,
                ),
                if (_hintCount < 3)
                  Positioned(
                    right: 8, bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text('${3 - _hintCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  )
              ],
            ),
            // Nút Đầu hàng
            IconButton(
              icon: const Icon(Icons.flag_outlined, color: Colors.redAccent),
              tooltip: "Đầu hàng",
              onPressed: () async {
                final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Đầu hàng?"),
                      content: const Text("Điểm sẽ về 0."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Huỷ")),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Đồng ý", style: TextStyle(color: Colors.red))),
                      ],
                    )
                );
                if(confirm == true) _handleSurrender();
              },
            )
          ],
        ),
        body: Column(
          children: [
            // Stats Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem("Mức độ", widget.difficulty == 1 ? "Dễ" : (widget.difficulty == 2 ? "TB" : "Khó"), Colors.black),
                  _buildStatItem("Lỗi", "$_mistakeCount/3", _mistakeCount >= 3 ? Colors.red : Colors.black),
                  _buildStatItem("Thời gian", _formatTime(_secondsElapsed), Colors.blue),
                  _buildStatItem("Điểm", "$_score", Colors.purple),
                ],
              ),
            ),

            Expanded(
              child: Center(child: AspectRatio(aspectRatio: 1, child: _buildSudokuGrid())),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(_message, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            ),

            _buildNumberPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  Widget _buildSudokuGrid() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2)),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 9, childAspectRatio: 1.0),
        itemCount: 81,
        itemBuilder: (context, index) {
          final row = index ~/ 9;
          final col = index % 9;
          final value = _currentBoard[index];
          final isFixed = _fixedNumbers[index] != 0;
          final isSelected = row == _selectedRow && col == _selectedCol;

          final bool rightBorder = (col % 3 == 2 && col != 8);
          final bool bottomBorder = (row % 3 == 2 && row != 8);

          return GestureDetector(
            onTap: () => _selectCell(row, col),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.amber.shade100 : (isFixed ? Colors.grey.shade300 : Colors.white),
                border: Border(
                  right: BorderSide(width: rightBorder ? 2.0 : 0.5, color: rightBorder ? Colors.black : Colors.grey),
                  bottom: BorderSide(width: bottomBorder ? 2.0 : 0.5, color: bottomBorder ? Colors.black : Colors.grey),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                value == 0 ? '' : value.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: isFixed ? FontWeight.bold : FontWeight.w500,
                  color: isFixed ? Colors.black : (_mistakeCount >= 3 ? Colors.red : Colors.blue.shade900),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNumberPad() {
    return Container(
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int i = 1; i <= 9; i++) _buildKeyButton(i),
          _buildKeyButton(0, icon: Icons.backspace_outlined, color: Colors.red.shade400),
        ],
      ),
    );
  }

  Widget _buildKeyButton(int number, {IconData? icon, Color? color}) {
    return SizedBox(
      width: 36, height: 45,
      child: ElevatedButton(
        onPressed: (_selectedRow != null && !_isGameOver) ? () => _handleNumberInput(number) : null,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: color ?? Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: icon != null
            ? Icon(icon, size: 18)
            : Text("$number", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}