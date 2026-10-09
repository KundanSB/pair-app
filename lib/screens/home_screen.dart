import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/profile_service.dart';
import '../services/pair_channel.dart';
import '../services/feature_access.dart';
import '../widgets/daily_quote_card.dart';
import '../games/game_catalog.dart';
import '../games/screens/game_hub_screen.dart';
import 'chat_screen.dart';
import 'schedule_screen.dart';
import 'location_screen.dart';
import 'instructions_screen.dart';
import 'call_screen.dart';

/// The main 4-tab screen once two people are paired. Also owns two
/// always-on listeners (calls + game invites) so either can be accepted
/// from wherever the user currently is in the app — see PairChannel's
/// doc comment for why these listeners and the eventual call/game
/// screens deliberately share one channel instance per topic instead of
/// each subscribing separately.
class HomeScreen extends StatefulWidget {
  final Pairing pairing;
  const HomeScreen({super.key, required this.pairing});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  Profile? _me;
  late final PairChannel _callSignaling;
  late final PairChannel _gameSignaling;
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    _callSignaling = PairChannel('call', widget.pairing.id);
    _callSignaling.addListener(_onCallSignal);
    _gameSignaling = PairChannel('game', widget.pairing.id);
    _gameSignaling.addListener(_onGameSignal);
    ProfileService().getMyProfile().then((p) {
      if (mounted) setState(() => _me = p);
    });
  }

  @override
  void dispose() {
    _callSignaling.removeListener(_onCallSignal);
    _gameSignaling.removeListener(_onGameSignal);
    super.dispose();
  }

  void _onCallSignal(Map<String, dynamic> payload) {
    if (payload['type'] != 'offer' || _dialogShowing) return;
    _dialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Incoming call 💛'),
        content: const Text('Your partner is calling you.'),
        actions: [
          TextButton(
            onPressed: () {
              _callSignaling.send({'type': 'decline'});
              _dialogShowing = false;
              Navigator.pop(context);
            },
            child: const Text('Decline'),
          ),
          FilledButton(
            onPressed: () {
              _dialogShowing = false;
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    pairing: widget.pairing,
                    isCaller: false,
                    video: payload['video'] ?? true,
                    initialOfferSdp: payload['sdp'],
                  ),
                ),
              );
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  /// Mirrors _onCallSignal exactly — same PairChannel class, topic
  /// 'game' instead of 'call', different payload shape.
  void _onGameSignal(Map<String, dynamic> payload) {
    if (payload['type'] != 'invite' || _dialogShowing) return;
    final game = GameCatalog.byId(payload['gameId'] as String);
    _dialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${game.emoji} Play ${game.title}?'),
        content: const Text('Your partner wants to play together right now.'),
        actions: [
          TextButton(
            onPressed: () {
              _dialogShowing = false;
              Navigator.pop(context);
            },
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              _dialogShowing = false;
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => game.builder(widget.pairing, false)));
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _startCall({required bool video}) {
    final me = _me;
    if (me == null) return;
    if (!FeatureAccess.canUseCalling(me)) {
      FeatureAccess.showUpsell(context, 'Video & audio calling');
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => CallScreen(pairing: widget.pairing, isCaller: true, video: video)));
  }

  void _openGames() {
    final me = _me;
    if (me == null) return;
    if (!FeatureAccess.canUseGames(me)) {
      FeatureAccess.showUpsell(context, 'Games');
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => GameHubScreen(pairing: widget.pairing)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ChatScreen(pairing: widget.pairing),
      ScheduleScreen(pairing: widget.pairing),
      LocationScreen(pairing: widget.pairing),
      const InstructionsScreen(embedded: true),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair'),
        actions: [
          IconButton(icon: const Icon(Icons.videogame_asset_outlined), tooltip: 'Games', onPressed: _openGames),
          IconButton(icon: const Icon(Icons.call_outlined), tooltip: 'Audio call', onPressed: () => _startCall(video: false)),
          IconButton(icon: const Icon(Icons.videocam_outlined), tooltip: 'Video call', onPressed: () => _startCall(video: true)),
        ],
      ),
      body: Column(
        children: [
          if (_tab == 0) const DailyQuoteCard(),
          Expanded(child: pages[_tab]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.schedule), label: 'Schedule'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Journey'),
          NavigationDestination(icon: Icon(Icons.help_outline), label: 'Help'),
        ],
      ),
    );
  }
}
