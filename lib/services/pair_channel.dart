import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

typedef PairChannelHandler = void Function(Map<String, dynamic> payload);

/// One Realtime BROADCAST channel per (topic, pairing) — e.g. `call:<id>`
/// for calling, `game:<id>` for games. Ephemeral: nothing sent here is
/// ever written to a database table.
///
/// Singleton per (topic, pairingId) so a screen that starts listening
/// (HomeScreen watching for incoming calls/game invites) and a screen
/// that later joins an active session (CallScreen, a game screen) share
/// the exact same subscription instead of double-subscribing to the same
/// topic, which would double-deliver every message.
class PairChannel {
  static final Map<String, PairChannel> _instances = {};

  factory PairChannel(String topic, String pairingId) {
    final key = '$topic:$pairingId';
    return _instances.putIfAbsent(key, () => PairChannel._(key));
  }

  PairChannel._(String key) {
    _channel = supabase.channel(key)
      ..onBroadcast(
        event: 'signal',
        callback: (payload) {
          for (final handler in List<PairChannelHandler>.of(_handlers)) {
            handler(payload);
          }
        },
      )
      ..subscribe();
  }

  late final RealtimeChannel _channel;
  final List<PairChannelHandler> _handlers = [];

  void addListener(PairChannelHandler handler) => _handlers.add(handler);
  void removeListener(PairChannelHandler handler) => _handlers.remove(handler);
  void send(Map<String, dynamic> payload) => _channel.sendBroadcastMessage(event: 'signal', payload: payload);
}
