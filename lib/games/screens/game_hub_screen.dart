import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/pair_channel.dart';
import '../../theme/app_theme.dart';
import '../game_catalog.dart';

class GameHubScreen extends StatelessWidget {
  final Pairing pairing;
  const GameHubScreen({super.key, required this.pairing});

  void _startGame(BuildContext context, GameDefinition game) {
    // HomeScreen is always listening on this same channel for 'invite'
    // and shows an accept/decline prompt wherever the partner is.
    PairChannel('game', pairing.id).send({'type': 'invite', 'gameId': game.id});
    Navigator.push(context, MaterialPageRoute(builder: (_) => game.builder(pairing, true)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Games')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppTheme.sage.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)),
            child: const Text('Games are played live, together — nothing is saved. If either of you leaves, the game just ends.', style: TextStyle(fontSize: 13)),
          ),
          for (final category in GameCategory.values) ...[
            Text(category.label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: GameCatalog.inCategory(category).map((game) => _GameTile(game: game, onTap: () => _startGame(context, game))).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  final GameDefinition game;
  final VoidCallback onTap;
  const _GameTile({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play ${game.title}',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.blush)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(game.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(game.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
