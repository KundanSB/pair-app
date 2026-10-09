/// Finds `winLength` identical, non-null marks in a straight line (any
/// direction) on a `rows` x `cols` board. Powers Tic-Tac-Toe (3x3,
/// length 3) and Connect Four (6x7, length 4) — one algorithm, not two.
class GridWinChecker {
  static List<List<int>>? find(List<List<String?>> board, int rows, int cols, int winLength) {
    const directions = [[0, 1], [1, 0], [1, 1], [1, -1]];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final mark = board[r][c];
        if (mark == null) continue;
        for (final dir in directions) {
          final cells = <List<int>>[];
          for (int k = 0; k < winLength; k++) {
            final rr = r + dir[0] * k, cc = c + dir[1] * k;
            if (rr < 0 || rr >= rows || cc < 0 || cc >= cols || board[rr][cc] != mark) break;
            cells.add([rr, cc]);
          }
          if (cells.length == winLength) return cells;
        }
      }
    }
    return null;
  }
}
