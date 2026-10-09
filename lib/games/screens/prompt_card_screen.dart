import 'dart:math';
import 'package:flutter/material.dart';
import '../live_game_screen.dart';
import '../../theme/app_theme.dart';

/// One screen powers every prompt-card game — new game = new content
/// list in prompt_packs.dart + one catalog entry, zero new screens.
class PromptCardScreen extends LiveGameScreen {
  final String title;
  final List<String> deck;
  const PromptCardScreen({super.key, required super.pairing, required super.isHost, required this.title, required this.deck});
  @override
  State<PromptCardScreen> createState() => _PromptCardScreenState();
}

class _PromptCardScreenState extends LiveGameScreenState<PromptCardScreen> {
  List<int> _order = [];
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isHost) {
      _order = List.generate(widget.deck.length, (i) => i)..shuffle(Random());
      // Short delay lets the guest's subscription attach after accepting
      // the invite and this screen mounting, before we send the order.
      Future.delayed(const Duration(milliseconds: 400), () => sendState({'order': _order, 'index': _index}));
    }
  }

  @override
  void onGameState(Map<String, dynamic> state) {
    setState(() {
      _order = List<int>.from(state['order'] as List);
      _index = state['index'] as int;
    });
  }

  void _next() {
    if (_order.isEmpty || partnerLeftMessage != null) return;
    setState(() => _index = (_index + 1) % _order.length);
    sendState({'order': _order, 'index': _index});
  }

  @override
  Widget buildGame(BuildContext context) {
    final ready = _order.isNotEmpty;
    final card = ready ? widget.deck[_order[_index]] : null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              partnerLeftBanner(),
              ...!ready
                  ? const [CircularProgressIndicator(color: AppTheme.lavender), SizedBox(height: 12), Text('Shuffling the deck...')]
                  : [
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 180),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.lavender, AppTheme.blush]), borderRadius: BorderRadius.circular(24)),
                        alignment: Alignment.center,
                        child: Text(card!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 8),
                      Text('${_index + 1} / ${_order.length}', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 20),
                      FilledButton.icon(onPressed: _next, icon: const Icon(Icons.skip_next), label: const Text('Next card')),
                    ],
            ],
          ),
        ),
      ),
    );
  }
}
