import 'package:flutter/material.dart';
import '../live_game_screen.dart';
import '../grid_win_checker.dart';
import '../../theme/app_theme.dart';

const int _cols = 7;
const int _rows = 6;

class ConnectFourScreen extends LiveGameScreen {
  const ConnectFourScreen({super.key, required super.pairing, required super.isHost});
  @override
  State<ConnectFourScreen> createState() => _ConnectFourScreenState();
}

class _ConnectFourScreenState extends LiveGameScreenState<ConnectFourScreen> {
  List<List<String?>> _board = List.generate(_rows, (_) => List.filled(_cols, null));
  bool _myTurn = false;

  @override
  void initState() {
    super.initState();
    _myTurn = widget.isHost; // host plays Red and moves first
  }

  @override
  void onGameState(Map<String, dynamic> state) {
    final flat = List<String?>.from(state['board'] as List);
    setState(() {
      _board = List.generate(_rows, (r) => flat.sublist(r * _cols, (r + 1) * _cols));
      _myTurn = state['turn'] == (widget.isHost ? 'host' : 'guest');
    });
  }

  void _drop(int col) {
    if (!_myTurn || partnerLeftMessage != null) return;
    int? targetRow;
    for (int r = _rows - 1; r >= 0; r--) {
      if (_board[r][col] == null) {
        targetRow = r;
        break;
      }
    }
    if (targetRow == null) return; // column full
    setState(() {
      _board[targetRow!][col] = widget.isHost ? 'R' : 'Y';
      _myTurn = false;
    });
    _send(nextTurn: widget.isHost ? 'guest' : 'host');
  }

  void _send({required String nextTurn}) => sendState({'board': _board.expand((r) => r).toList(), 'turn': nextTurn});

  void _reset() {
    setState(() {
      _board = List.generate(_rows, (_) => List.filled(_cols, null));
      _myTurn = widget.isHost;
    });
    _send(nextTurn: 'host');
  }

  @override
  Widget buildGame(BuildContext context) {
    final winCells = GridWinChecker.find(_board, _rows, _cols, 4);
    return Scaffold(
      appBar: AppBar(title: const Text('Connect Four')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              partnerLeftBanner(),
              Text(
                winCells != null ? "It's a win! 🎉" : (_myTurn ? 'Your turn — tap a column' : "Waiting for your partner..."),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Column(
                children: List.generate(_rows, (r) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_cols, (c) {
                      final mark = _board[r][c];
                      final isWin = winCells?.any((cell) => cell[0] == r && cell[1] == c) ?? false;
                      return Semantics(
                        button: true,
                        label: 'Column ${c + 1}${mark != null ? ', has a piece' : ', empty'}',
                        child: GestureDetector(
                          onTap: () => _drop(c),
                          child: Container(
                            width: 40, height: 40, margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isWin ? AppTheme.sage : Theme.of(context).colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: mark == null ? null : Icon(Icons.circle, color: mark == 'R' ? AppTheme.coral : AppTheme.lavender),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
              const SizedBox(height: 20),
              if (winCells != null) OutlinedButton(onPressed: _reset, child: const Text('Play again')),
            ],
          ),
        ),
      ),
    );
  }
}
