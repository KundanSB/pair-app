import 'package:flutter/material.dart';
import 'game_session_controller.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

abstract class LiveGameScreen extends StatefulWidget {
  final Pairing pairing;
  final bool isHost;
  const LiveGameScreen({super.key, required this.pairing, required this.isHost});
}

/// Handles the three things every game needs and none should reimplement:
/// creating the session controller, tearing it down on dispose, and
/// providing a "partner left" banner. A concrete game only overrides
/// [onGameState] and [buildGame]. See tictactoe_screen.dart for the
/// smallest complete example.
abstract class LiveGameScreenState<W extends LiveGameScreen> extends State<W> {
  late final GameSessionController controller;
  String? partnerLeftMessage;

  @override
  void initState() {
    super.initState();
    controller = GameSessionController(pairing: widget.pairing, isHost: widget.isHost);
    controller.onState = onGameState;
    controller.onPartnerLeft = () => setState(() => partnerLeftMessage = 'Your partner left the game.');
    controller.start();
  }

  @override
  void dispose() {
    controller.leave();
    super.dispose();
  }

  /// Apply an incoming state update from your partner.
  void onGameState(Map<String, dynamic> state);

  /// Build your own Scaffold here; call [partnerLeftBanner] wherever you
  /// want the "partner left" notice to appear inside it.
  Widget buildGame(BuildContext context);

  /// Uses AppTheme.alertText (not the decorative `coral`) — this is real
  /// text a user needs to read, and coral fails contrast checks for text.
  Widget partnerLeftBanner() => partnerLeftMessage == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(partnerLeftMessage!, style: const TextStyle(color: AppTheme.alertText, fontWeight: FontWeight.w600)),
        );

  void sendState(Map<String, dynamic> data) => controller.sendState(data);

  @override
  Widget build(BuildContext context) => buildGame(context);
}
