class CaroLogic {
  static const int boardSize = 15; // Bàn cờ 15x15

  // Kiểm tra thắng (5 ô liên tiếp)
  static bool checkWin(List<int> board, int index, int player) {
    int row = index ~/ boardSize;
    int col = index % boardSize;

    // Các hướng: Ngang, Dọc, Chéo chính, Chéo phụ
    List<List<int>> directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];

    for (var dir in directions) {
      int count = 1;

      // Hướng xuôi
      for (int i = 1; i < 5; i++) {
        int r = row + dir[0] * i;
        int c = col + dir[1] * i;
        if (r < 0 || r >= boardSize || c < 0 || c >= boardSize) break;
        if (board[r * boardSize + c] == player) {
          count++;
        } else {
          break;
        }
      }

      // Hướng ngược
      for (int i = 1; i < 5; i++) {
        int r = row - dir[0] * i;
        int c = col - dir[1] * i;
        if (r < 0 || r >= boardSize || c < 0 || c >= boardSize) break;
        if (board[r * boardSize + c] == player) {
          count++;
        } else {
          break;
        }
      }

      if (count >= 5) return true;
    }
    return false;
  }

  // Bot random
  static int getBotMove(List<int> board) {
    List<int> emptyCells = [];
    for (int i = 0; i < board.length; i++) {
      if (board[i] == 0) emptyCells.add(i);
    }
    if (emptyCells.isEmpty) return -1;

    return emptyCells[DateTime.now().millisecond % emptyCells.length];
  }
}
