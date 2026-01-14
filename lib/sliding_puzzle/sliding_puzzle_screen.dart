import 'dart:async';
import 'puzzle_progress_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class SlidingPuzzleScreen extends StatefulWidget {
  final String imagePath;
  final int gridSize;
  final int levelNumber;

  const SlidingPuzzleScreen({
    super.key,
    required this.imagePath,
    required this.gridSize,
    required this.levelNumber,
  });

  @override
  State<SlidingPuzzleScreen> createState() => _SlidingPuzzleScreenState();
}

class _SlidingPuzzleScreenState extends State<SlidingPuzzleScreen> {
  late List<int> tiles;
  late int emptyTileValue;
  int moves = 0;
  Timer? _timer;
  late int _secondsRemaining;
  bool _isPaused = false;
  bool _isGameOver = false;
  late ConfettiController _confettiController;

  int _getMaxTime() {
    if (widget.gridSize == 3) return 600; 
    if (widget.gridSize == 4) return 1200; 
    return 1800; 
  }

  int? _getMaxMoves() {
    if (widget.gridSize == 3) return null; 
    if (widget.gridSize == 4) return 3500; 
    return 4000; 
  }

  @override
  void initState() {
    super.initState();
    emptyTileValue = widget.gridSize * widget.gridSize - 1;
    _secondsRemaining = _getMaxTime();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _resetGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isPaused && !_isGameOver) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _handleGameOver('Hết thời gian mất rồi!');
          }
        });
      }
    });
  }

  void _resetGame() {
    setState(() {
      _isGameOver = false;
      _isPaused = false;
      moves = 0;
      _secondsRemaining = _getMaxTime();
      tiles = List.generate(widget.gridSize * widget.gridSize, (index) => index);
      
      do {
        tiles.shuffle(Random());
      } while (!_isSolvable() || _isAlreadyWin());
      
      _startTimer();
    });
  }

  bool _isAlreadyWin() {
    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i] != i) return false;
    }
    return true;
  }

  void _handleGameOver(String reason) {
    _timer?.cancel();
    setState(() {
      _isGameOver = true;
    });
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _buildGameOverDialog(ctx, reason));
  }

  bool _isSolvable() {
    int inversions = 0;
    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i] == emptyTileValue) continue;
      for (int j = i + 1; j < tiles.length; j++) {
        if (tiles[j] == emptyTileValue) continue;
        if (tiles[i] > tiles[j]) inversions++;
      }
    }
    if (widget.gridSize.isOdd) return inversions.isEven;
    int emptyRowFromBottom = widget.gridSize - (tiles.indexOf(emptyTileValue) ~/ widget.gridSize);
    return emptyRowFromBottom.isEven ? inversions.isOdd : inversions.isEven;
  }

  void _onTileTap(int tappedPosition) {
    if (_isPaused || _isGameOver) return;
    int emptyPosition = tiles.indexOf(emptyTileValue);
    if (_isAdjacent(tappedPosition, emptyPosition)) {
      setState(() {
        tiles[emptyPosition] = tiles[tappedPosition];
        tiles[tappedPosition] = emptyTileValue;
        moves++;
      });
      _checkWinCondition();
      
      int? maxMoves = _getMaxMoves();
      if (maxMoves != null && moves >= maxMoves && !_isGameOver) {
        _handleGameOver('Bạn đã hết lượt đi!');
      }
    }
  }

  bool _isAdjacent(int index1, int index2) {
    int r1 = index1 ~/ widget.gridSize, c1 = index1 % widget.gridSize;
    int r2 = index2 ~/ widget.gridSize, c2 = index2 % widget.gridSize;
    return (r1 == r2 && (c1 - c2).abs() == 1) || (c1 == c2 && (r1 - r2).abs() == 1);
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _checkWinCondition() async {
    bool isWin = true;
    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i] != i) {
        isWin = false;
        break;
      }
    }
    if (isWin) {
      _timer?.cancel();
      setState(() { _isGameOver = true; });
      _confettiController.play();
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _buildWinDialog(ctx));
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxMoves = _getMaxMoves();
    final movesDisplay = maxMoves == null ? moves.toString() : '$moves / $maxMoves';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Xếp Hình - Ải ${widget.levelNumber}', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 30),
            onPressed: () => setState(() => _isPaused = !_isPaused),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard('BƯỚC ĐI', movesDisplay, Icons.touch_app_rounded, Colors.blueAccent),
                      _buildStatCard('THỜI GIAN', _formatTime(_secondsRemaining), Icons.timer_rounded, _secondsRemaining < 60 ? Colors.redAccent : Colors.orangeAccent),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: _buildPuzzleGrid(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              if (_isPaused) _buildPausedOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.42,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.2)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleGrid() {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF2C3E50), 
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 15))],
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
        ),
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(builder: (context, constraints) {
          final size = constraints.maxWidth;
          final tileSize = size / widget.gridSize;
          return Stack(
            children: List.generate(widget.gridSize * widget.gridSize, (tileValue) {
              final tilePos = tiles.indexOf(tileValue);
              if (tileValue == emptyTileValue) return const SizedBox.shrink();
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                top: (tilePos ~/ widget.gridSize) * tileSize,
                left: (tilePos % widget.gridSize) * tileSize,
                child: GestureDetector(
                  onTap: () => _onTileTap(tilePos),
                  child: Container(
                    width: tileSize,
                    height: tileSize,
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -(tileValue ~/ widget.gridSize) * tileSize,
                              left: -(tileValue % widget.gridSize) * tileSize,
                              child: SizedBox(
                                width: size,
                                height: size,
                                child: Image.asset(widget.imagePath, fit: BoxFit.cover),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.white.withOpacity(0.1), Colors.transparent],
                                )
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildPausedOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.95),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('TẠM DỪNG', style: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.blueAccent, letterSpacing: 2)),
              const SizedBox(height: 20),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 25)],
                  border: Border.all(color: Colors.white, width: 6),
                  image: DecorationImage(image: AssetImage(widget.imagePath), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 10),
              Text('Hình ảnh mẫu', style: GoogleFonts.nunito(color: Colors.grey[600], fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              _buildMenuButton('TIẾP TỤC', Icons.play_arrow_rounded, Colors.blueAccent, () => setState(() => _isPaused = false)),
              const SizedBox(height: 12),
              _buildMenuButton('CHƠI LẠI', Icons.refresh_rounded, Colors.orangeAccent, () => _resetGame()),
              const SizedBox(height: 12),
              _buildMenuButton('THOÁT', Icons.exit_to_app_rounded, Colors.redAccent, () => Navigator.pop(context)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 200,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: color.withOpacity(0.5),
        ),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
      ),
    );
  }

  Widget _buildWinDialog(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Tuyệt vời!', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
          const SizedBox(height: 16),
          Text('Bạn đã hoàn thành trong $moves bước!', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
        ],
      ),
      actions: [
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context),
            child: const Text('XÁC NHẬN'),
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverDialog(BuildContext context, String reason) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(reason, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
      content: const Text('Đừng nản lòng, hãy thử lại nhé!', textAlign: TextAlign.center),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('THOÁT')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              onPressed: () { Navigator.pop(context); _resetGame(); }, 
              child: const Text('THỬ LẠI')
            ),
          ],
        )
      ],
    );
  }
}
