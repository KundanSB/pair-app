import 'package:flutter/material.dart';
import '../live_game_screen.dart';
import '../grid_win_checker.dart';
import '../../theme/app_theme.dart';

class TicTacToeScreen extends LiveGameScreen {
  const TicTacToeScreen({super.key, required super.pairing, required super.isHost});
  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends LiveGameScreenState<TicTacToeScreen> {
  List<List<String?>> _board = List.generate(3, (_) => List.filled(3, null));
  bool _myTurn = false;

  @override
  void initState() {
    super.initState();
    _myTurn = widget.isHost; // host plays X and moves first
  }

  @override
  void onGameState(Map<String, dynamic> state) {
    final flat = List<String?>.from(state['board'] as List);
    setState(() {
      _board = List.generate(3, (r) => flat.sublist(r * 3, (r + 1) * 3));
      _myTurn = state['turn'] == (widget.isHost ? 'host' : 'guest');
    });
  }

  void _tap(int row, int col) {
    if (!_myTurn || _board[row][col] != null || partnerLeftMessage != null) return;
    setState(() {
      _board[row][col] = widget.isHost ? 'X' : 'O';
      _myTurn = false;
    });
    sendState({'board': _board.expand((r) => r).toList(), 'turn': widget.isHost ? 'guest' : 'host'});
  }

  void _reset() {
    setState(() {
      _board = List.generate(3, (_) => List.filled(3, null));
      _myTurn = widget.isHost;
    });
    sendState({'board': _board.expand((r) => r).toList(), 'turn': 'host'});
  }

  @override
  Widget buildGame(BuildContext context) {
    final winCells = GridWinChecker.find(_board, 3, 3, 3);
    return Scaffold(
      appBar: AppBar(title: const Text('Tic-Tac-Toe')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              partnerLeftBanner(),
              Text(
                winCells != null ? "It's a win! 🎉" : (_myTurn ? 'Your turn' : "Waiting for your partner..."),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 9,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
                itemBuilder: (context, i) {
                  final row = i ~/ 3, col = i % 3;
                  final value = _board[row][col];
                  final isWin = winCells?.any((cell) => cell[0] == row && cell[1] == col) ?? false;
                  return Semantics(
                    button: true,
                    label: value == null ? 'Empty cell, row ${row + 1}, column ${col + 1}' : 'Cell taken by $value',
                    child: GestureDetector(
                      onTap: () => _tap(row, col),
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: isWin ? AppTheme.sage : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(value ?? '', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: value == 'X' ? AppTheme.coral : AppTheme.plum)),
                      ),
                    ),
                  );
                },
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
