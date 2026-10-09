import 'package:flutter/material.dart';
import '../live_game_screen.dart';
import '../../theme/app_theme.dart';

enum _Choice { rock, paper, scissors }

/// Known simplification: no commit-reveal protocol, so in principle a
/// partner could wait to see your choice before locking theirs in —
/// acceptable trust assumption for two people playing casually together.
class RockPaperScissorsScreen extends LiveGameScreen {
  const RockPaperScissorsScreen({super.key, required super.pairing, required super.isHost});
  @override
  State<RockPaperScissorsScreen> createState() => _RockPaperScissorsScreenState();
}

class _RockPaperScissorsScreenState extends LiveGameScreenState<RockPaperScissorsScreen> {
  _Choice? _myChoice;
  _Choice? _partnerChoice;

  @override
  void onGameState(Map<String, dynamic> state) {
    final choiceStr = state['choice'] as String?;
    setState(() {
      _partnerChoice = choiceStr == null ? null : _Choice.values.firstWhere((c) => c.name == choiceStr);
      if (state['reset'] == true) _myChoice = null;
    });
  }

  void _pick(_Choice choice) {
    if (partnerLeftMessage != null) return;
    setState(() => _myChoice = choice);
    sendState({'choice': choice.name});
  }

  void _reset() {
    setState(() {
      _myChoice = null;
      _partnerChoice = null;
    });
    sendState({'choice': null, 'reset': true});
  }

  bool _beats(_Choice a, _Choice b) =>
      (a == _Choice.rock && b == _Choice.scissors) || (a == _Choice.paper && b == _Choice.rock) || (a == _Choice.scissors && b == _Choice.paper);

  String _emoji(_Choice c) => switch (c) { _Choice.rock => '🪨', _Choice.paper => '📄', _Choice.scissors => '✂️' };

  @override
  Widget buildGame(BuildContext context) {
    final bothPicked = _myChoice != null && _partnerChoice != null;
    final resultText = !bothPicked
        ? null
        : _myChoice == _partnerChoice
            ? "It's a tie!"
            : _beats(_myChoice!, _partnerChoice!)
                ? 'You win! 🎉'
                : 'Your partner wins!';

    return Scaffold(
      appBar: AppBar(title: const Text('Rock Paper Scissors')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              partnerLeftBanner(),
              ...bothPicked
                  ? [
                      Text(resultText!, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(children: [const Text('You'), Text(_emoji(_myChoice!), style: const TextStyle(fontSize: 48))]),
                          const SizedBox(width: 32),
                          Column(children: [const Text('Partner'), Text(_emoji(_partnerChoice!), style: const TextStyle(fontSize: 48))]),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FilledButton(onPressed: _reset, child: const Text('Play again')),
                    ]
                  : [
                      Text(_myChoice == null ? 'Pick one!' : 'Waiting for your partner to pick...', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _Choice.values.map((c) {
                          final selected = _myChoice == c;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Semantics(
                              button: true,
                              label: c.name,
                              child: GestureDetector(
                                onTap: () => _pick(c),
                                child: CircleAvatar(radius: 36, backgroundColor: selected ? AppTheme.sage : AppTheme.blush, child: Text(_emoji(c), style: const TextStyle(fontSize: 32))),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
            ],
          ),
        ),
      ),
    );
  }
}
