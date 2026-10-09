import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/pairing_service.dart';
import 'welcome_loader_screen.dart';
import 'pairing_screen.dart';
import 'home_screen.dart';

/// Decides what the user sees on launch: the welcome loader while
/// checking pairing status, then either the pairing flow or home tabs.
class RootRouterScreen extends StatefulWidget {
  const RootRouterScreen({super.key});
  @override
  State<RootRouterScreen> createState() => _RootRouterScreenState();
}

class _RootRouterScreenState extends State<RootRouterScreen> {
  final _pairingService = PairingService();
  Pairing? _pairing;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pairing = await _pairingService.getMyPairing();
    if (!mounted) return;
    setState(() {
      _pairing = pairing;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const WelcomeLoaderScreen();
    if (_pairing == null || _pairing!.status != 'active') {
      return PairingScreen(existingPairing: _pairing, onPaired: _load);
    }
    return HomeScreen(pairing: _pairing!);
  }
}
