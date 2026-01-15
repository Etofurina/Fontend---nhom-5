import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

// Import các file trong dự án

import 'caro_history.dart';
import 'caro_leaderboard_screen.dart';
import 'caro_service.dart';

class CaroScreen extends StatefulWidget {
  const CaroScreen({Key? key}) : super(key: key);

  @override
  State<CaroScreen> createState() => _CaroScreenState();
}

class _CaroScreenState extends State<CaroScreen> {
  final CaroService _caroService = CaroService();

  // --- CÀI ĐẶT GAME ---
  int _boardSize = 10;
  String _mode = 'PvP'; // 'PvP' hoặc 'PvE'
  String _difficulty = 'Medium';
  String _p1Name = "Người X";
  String _p2Name = "Người O";

  final TextEditingController _p1Controller = TextEditingController();
  final TextEditingController _p2Controller = TextEditingController();

  // --- TRẠNG THÁI GAME ---
  Timer? _timer;
  static const int _maxTime = 15; // Thời gian cho mỗi lượt đi
  int _timeLeft = _maxTime;

  // [QUAN TRỌNG] Biến tính thời gian tổng của ván đấu
  DateTime? _gameStartTime;

  Point<int>? _hintMove;
  List<List<int>> _board = [];
  bool _isXTurn = true;
  bool _isGameOver = false;
  bool _isBotThinking = false;
  final List<Point<int>> _moveHistory = []; // Lưu danh sách các nước đã đi
  int _scoreX = 0;
  int _scoreO = 0;
  int _cumulativeScore = 0; // Rank tổng từ server

  @override
  void initState() {
    super.initState();
    // Khởi tạo game và load điểm rank
    _startNewGame();
    _loadCumulativeScore();
    // Hiện popup nhập tên sau khi màn hình load xong
    WidgetsBinding.instance.addPostFrameCallback((_) => _showNameInputDialog());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _p1Controller.dispose();
    _p2Controller.dispose();
    super.dispose();
  }

  Future<void> _loadCumulativeScore() async {
    try {
      int score = await _caroService.getTotalScore();
      if(mounted) setState(() => _cumulativeScore = score);
    } catch (_) {}
  }

  // --- 1. LOGIC GAME CORE ---

  void _startNewGame() {
    setState(() {
      // Reset bàn cờ
      _board = List.generate(_boardSize, (_) => List.generate(_boardSize, (_) => 0));
      _isXTurn = true;
      _isGameOver = false;
      _isBotThinking = false;
      _moveHistory.clear();
      _hintMove = null;

      // [QUAN TRỌNG] Bắt đầu đếm giờ tổng thời gian chơi
      _gameStartTime = DateTime.now();

      _startTimer();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = _maxTime;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_isGameOver) {
        t.cancel();
        return;
      }
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          t.cancel();
          _handleTimeout();
        }
      });
    });
  }

  // Xử lý khi hết giờ 1 lượt
  void _handleTimeout() {
    int p = (_mode == 'PvP') ? (_isXTurn ? 1 : 2) : 1;
    // Tự động đánh random nếu hết giờ
    Point<int>? m = _getRandomMove();
    if (m != null) {
      _makeMove(m.x, m.y, p);
      if (_mode == 'PvE' && !_isGameOver) _triggerBot();
    }
  }

  // Xử lý khi người chơi bấm vào ô cờ
  void _onCellTapped(int r, int c) {
    if (r >= _boardSize || c >= _boardSize || _isGameOver || _board[r][c] != 0 || _isBotThinking) return;

    // Nếu đấu máy mà chưa tới lượt người thì chặn
    if (_mode == 'PvE' && !_isXTurn) return;

    int p = (_mode == 'PvP') ? (_isXTurn ? 1 : 2) : 1; // 1=X, 2=O
    _makeMove(r, c, p);

    // Sau khi người đánh, kích hoạt Bot
    if (_mode == 'PvE' && !_isGameOver) _triggerBot();
  }

  // Thực hiện nước đi
  void _makeMove(int r, int c, int p) {
    setState(() {
      _board[r][c] = p;
      _moveHistory.add(Point(r, c));
      _hintMove = null;

      // Kiểm tra thắng/thua/hòa
      if (_checkWin(r, c, p)) {
        _isGameOver = true;
        _timer?.cancel();
        _handleWin(p);
      } else if (_isBoardFull()) {
        _isGameOver = true;
        _timer?.cancel();
        _handleDraw();
      } else {
        // Đổi lượt
        _isXTurn = !_isXTurn;
        // Nếu là PvE và đến lượt máy -> Không start timer cho máy (để máy tự tính)
        if (!(_mode == 'PvE' && !_isXTurn)) _startTimer();
      }
    });
  }

  void _undoMove() {
    if (_moveHistory.isEmpty || _isBotThinking || _isGameOver) return;
    setState(() {
      if (_mode == 'PvP') {
        _revert();
      } else if (_moveHistory.length >= 2) {
        // PvE thì phải lui 2 bước (cả máy và người)
        _revert();
        _revert();
      }
      _startTimer();
    });
  }

  void _revert() {
    if (_moveHistory.isNotEmpty) {
      var last = _moveHistory.removeLast();
      _board[last.x][last.y] = 0;
      _isXTurn = !_isXTurn;
    }
  }

  // --- 2. LOGIC KIỂM TRA THẮNG / BOT ---

  bool _checkWin(int row, int col, int p) {
    final ds = [[0,1],[1,0],[1,1],[1,-1]]; // Ngang, Dọc, Chéo 1, Chéo 2
    for (var d in ds) {
      int c = 1;
      // Check hướng dương
      for (int i = 1; i < 5; i++) {
        int r = row + d[0]*i, c2 = col + d[1]*i;
        if (r<0||r>=_boardSize||c2<0||c2>=_boardSize||_board[r][c2]!=p) break;
        c++;
      }
      // Check hướng âm
      for (int i = 1; i < 5; i++) {
        int r = row - d[0]*i, c2 = col - d[1]*i;
        if (r<0||r>=_boardSize||c2<0||c2>=_boardSize||_board[r][c2]!=p) break;
        c++;
      }
      if (c >= 5) return true;
    }
    return false;
  }

  bool _isBoardFull() {
    for(var r in _board) if(r.contains(0)) return false;
    return true;
  }

  // Logic Bot đơn giản (Random + Delay giả lập suy nghĩ)
  void _triggerBot() {
    setState(() => _isBotThinking = true);
    _timer?.cancel();
    Future.delayed(const Duration(milliseconds: 600), () {
      if(mounted && !_isGameOver) {
        _botMove();
        if(mounted) setState(() => _isBotThinking = false);
      }
    });
  }

  void _botMove() {
    Point<int>? m = _getRandomMove();
    if(m != null) _makeMove(m.x, m.y, 2);
  }

  Point<int>? _getRandomMove() {
    List<Point<int>> e=[];
    for(int i=0;i<_boardSize;i++)
      for(int j=0;j<_boardSize;j++)
        if(_board[i][j]==0) e.add(Point(i,j));
    return e.isEmpty?null:e[Random().nextInt(e.length)];
  }

  void _showHint() {
    if(_isGameOver||_isBotThinking) return;
    Point<int>? m = _getRandomMove();
    setState(()=>_hintMove=m);
    Future.delayed(const Duration(seconds: 1), ()=>setState(()=>_hintMove=null));
  }

  // --- 3. XỬ LÝ KẾT QUẢ & GỬI API ---

  void _handleWin(int p) async {
    String winner = p == 1 ? "$_p1Name (X)" : "$_p2Name (O)";
    int pts = p == 1 ? 10 : -10; // X thắng được 10 điểm, O thắng (máy) thì người chơi bị -10

    // [QUAN TRỌNG] Tính toán thời gian chơi thực tế
    double duration = 0;
    if (_gameStartTime != null) {
      duration = DateTime.now().difference(_gameStartTime!).inSeconds.toDouble();
    }
    int totalMoves = _moveHistory.length; // Số nước đi thực tế

    setState(() {
      if (p == 1) _scoreX++; else _scoreO++;
    });

    _showGameOverDialog("${p == 1 ? _p1Name : _p2Name} Thắng!", pts, p);

    // Gửi kết quả lên Server
    try {
      await _caroService.saveMatchResult(MatchLog(
          date: DateTime.now().toString(),
          winner: winner,
          mode: _mode,
          difficulty: _difficulty,
          scoreEarned: pts,
          player1Name: _p1Name,
          player2Name: _p2Name,
          moves: totalMoves,   // <--- Gửi số nước đi thật
          duration: duration   // <--- Gửi thời gian thật
      ));
      await _loadCumulativeScore(); // Load lại rank
    } catch (_) {
      print("Lỗi lưu kết quả");
    }
  }

  void _handleDraw() async {
    _showGameOverDialog("Hòa!", 5, 0);
    // Anh có thể thêm logic lưu kết quả Hòa ở đây nếu muốn
  }

  // --- 4. CÁC DIALOG (UI) ---

  void _showGameOverDialog(String t, int p, int w) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white24)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ElasticIn(child: Icon(w!=0 ? Icons.emoji_events : Icons.handshake, size: 80, color: Colors.amber)),
              const SizedBox(height: 16),
              Text(t, style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text("Điểm: ${p > 0 ? '+' : ''}$p", style: TextStyle(fontSize: 20, color: p >= 0 ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white30)), child: const Text("Xem lại", style: TextStyle(color: Colors.white))),
                ElevatedButton(onPressed: (){ Navigator.pop(ctx); _startNewGame(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent), child: const Text("Chơi tiếp", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
              ])
            ]),
          ),
        ],
      ),
    ));
  }

  void _showNameInputDialog() {
    _p1Controller.text = _p1Name;
    _p2Controller.text = _p2Name;
    if (_mode == 'PvE') _p2Controller.text = "Máy AI ($_difficulty)";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("NHẬP TÊN", style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildTextField(_p1Controller, "Người chơi X", Icons.person, Colors.blue),
            const SizedBox(height: 12),
            if (_mode == 'PvP') _buildTextField(_p2Controller, "Người chơi O", Icons.person_outline, Colors.pinkAccent),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setState(() {
                    _p1Name = _p1Controller.text.isEmpty ? "Người X" : _p1Controller.text;
                    _p2Name = _mode == 'PvP' ? (_p2Controller.text.isEmpty ? "Người O" : _p2Controller.text) : "Máy AI ($_difficulty)";
                  });
                  Navigator.pop(ctx);
                  _startNewGame();
                },
                child: Text("VÀO GAME", style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ]),
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(context: context, builder: (context) {
      int sz = _boardSize; String md = _mode; String df = _difficulty;
      return StatefulBuilder(builder: (ctx, setSt) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("CÀI ĐẶT", style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildSettingRow("Kích thước", DropdownButton(
                dropdownColor: const Color(0xFF2C3E50),
                value: sz, style: const TextStyle(color: Colors.white),
                items: [10, 20].map((e)=>DropdownMenuItem(value:e, child:Text("$e x $e"))).toList(),
                onChanged: (v)=>setSt(()=>sz=v as int)
            )),
            _buildSettingRow("Chế độ", DropdownButton(
                dropdownColor: const Color(0xFF2C3E50),
                value: md, style: const TextStyle(color: Colors.white),
                items: ['PvP', 'PvE'].map((e)=>DropdownMenuItem(value:e, child:Text(e))).toList(),
                onChanged: (v)=>setSt(()=>md=v as String)
            )),
            if(md == 'PvE') _buildSettingRow("Độ khó", DropdownButton(
                dropdownColor: const Color(0xFF2C3E50),
                value: df, style: const TextStyle(color: Colors.white),
                items: ['Easy', 'Medium', 'Hard'].map((e)=>DropdownMenuItem(value:e, child:Text(e))).toList(),
                onChanged: (v)=>setSt(()=>df=v as String)
            )),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                  onPressed: () {
                    setState(() { _boardSize = sz; _mode = md; _difficulty = df; _scoreX = 0; _scoreO = 0; });
                    Navigator.pop(context); _showNameInputDialog();
                  },
                  child: const Text("Lưu", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
              ),
            ])
          ]),
        ),
      ));
    });
  }

  // --- 5. UI COMPONENTS ---

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, Color color) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: color),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color)),
      ),
    );
  }

  Widget _buildSettingRow(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)), child]),
    );
  }

  Widget _buildPlayerInfo(String n, int s, bool x, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? (x ? Colors.cyan.withOpacity(0.2) : Colors.pink.withOpacity(0.2)) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: active ? Border.all(color: x ? Colors.cyanAccent : Colors.pinkAccent) : Border.all(color: Colors.transparent),
      ),
      child: Column(children: [
        Icon(x ? Icons.close : Icons.circle_outlined, color: x ? Colors.cyanAccent : Colors.pinkAccent),
        const SizedBox(height: 4),
        Text(n.length > 8 ? "${n.substring(0, 6)}.." : n, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text("$s", style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Gradient nền Deep Space cực đẹp
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)])
        ),
        child: SafeArea(
          child: Column(children: [
            // Header
            Padding(padding: const EdgeInsets.all(16.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              CircleAvatar(backgroundColor: Colors.white12, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context))),
              Column(children: [
                Text("CARO PRO", style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text("🏆 Rank: $_cumulativeScore", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)))
              ]),
              Row(children: [
                IconButton(icon: const Icon(Icons.history, color: Colors.white70), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
                IconButton(icon: const Icon(Icons.leaderboard, color: Colors.white70), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()))),
                IconButton(icon: const Icon(Icons.settings, color: Colors.white70), onPressed: _showSettingsDialog),
              ])
            ])),

            // Score Board
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _buildPlayerInfo(_p1Name, _scoreX, true, _isXTurn),
                Column(children: [
                  Text("$_timeLeft", style: GoogleFonts.outfit(fontSize: 36, color: _timeLeft < 5 ? Colors.redAccent : Colors.white, fontWeight: FontWeight.bold)),
                  const Text("SEC", style: TextStyle(color: Colors.white38, fontSize: 10))
                ]),
                _buildPlayerInfo(_p2Name, _scoreO, false, !_isXTurn),
              ]),
            ),

            // Status & Hint
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if(_isBotThinking) const Text("🤖 Máy đang tính...", style: TextStyle(color: Colors.cyanAccent)),
                if(!_isBotThinking) IconButton(onPressed: _showHint, icon: const Icon(Icons.lightbulb, color: Colors.yellowAccent), tooltip: "Gợi ý"),
              ]),
            ),

            // Game Board
            Expanded(child: Center(child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
              child: InteractiveViewer(
                minScale: 0.5, maxScale: 4.0,
                child: Center(
                  child: SizedBox(
                    width: _boardSize * 36.0, height: _boardSize * 36.0,
                    child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _boardSize, crossAxisSpacing: 3, mainAxisSpacing: 3),
                        itemCount: _boardSize*_boardSize,
                        itemBuilder: (ctx, i) {
                          int r = i~/_boardSize, c = i%_boardSize;
                          if(r>=_board.length || c>=_board[r].length) return const SizedBox();
                          int v = _board[r][c];
                          bool h = _hintMove != null && _hintMove!.x == r && _hintMove!.y == c;
                          bool last = _moveHistory.isNotEmpty && _moveHistory.last.x == r && _moveHistory.last.y == c;

                          return GestureDetector(
                            onTap: () => _onCellTapped(r, c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: h ? Colors.greenAccent.withOpacity(0.5) : (last ? Colors.white24 : Colors.white.withOpacity(0.08)),
                                borderRadius: BorderRadius.circular(6),
                                border: last ? Border.all(color: Colors.amber, width: 2) : null,
                              ),
                              child: v == 0 ? null : ZoomIn(child: Icon(
                                v == 1 ? Icons.close : Icons.circle_outlined,
                                color: v == 1 ? Colors.cyanAccent : Colors.pinkAccent,
                                size: 24,
                              )),
                            ),
                          );
                        }
                    ),
                  ),
                ),
              ),
            ))),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _undoMove,
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.undo, color: Colors.black),
      ),
    );
  }
}