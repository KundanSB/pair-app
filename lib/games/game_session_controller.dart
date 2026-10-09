import '../services/pair_channel.dart';
import '../models/models.dart';

/// Every game screen wraps its moves through this controller instead of
/// talking to PairChannel directly. Adding a new game means writing its
/// rules, not its networking.
///
/// Trust model: moves are applied as soon as received, no server-side
/// validation — appropriate for two partners playing casually together,
/// not for competitive play against strangers (which would need it).
class GameSessionController {
  GameSessionController({required this.pairing, required this.isHost}) : _signaling = PairChannel('game', pairing.id);

  final Pairing pairing;
  final bool isHost;
  final PairChannel _signaling;

  void Function(Map<String, dynamic> state)? onState;
  void Function()? onPartnerLeft;

  void start() => _signaling.addListener(_handle);

  void _handle(Map<String, dynamic> payload) {
    if (payload['type'] == 'state') {
      onState?.call(Map<String, dynamic>.from(payload['data'] as Map));
    } else if (payload['type'] == 'leave') {
      onPartnerLeft?.call();
    }
  }

  void sendState(Map<String, dynamic> data) => _signaling.send({'type': 'state', 'data': data});

  void leave() {
    _signaling.send({'type': 'leave'});
    _signaling.removeListener(_handle);
  }
}
