import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/pairing_service.dart';
import 'instructions_screen.dart';

class PairingScreen extends StatefulWidget {
  final Pairing? existingPairing;
  final VoidCallback onPaired;
  const PairingScreen({super.key, this.existingPairing, required this.onPaired});
  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _pairingService = PairingService();
  final _codeController = TextEditingController();
  String? _myCode;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingPairing != null && widget.existingPairing!.status == 'pending') {
      _watch(widget.existingPairing!.id);
    }
  }

  void _watch(String pairingId) {
    _pairingService.watchPairing(pairingId, (updated) {
      if (updated.status == 'active') widget.onPaired();
    });
  }

  Future<void> _generateCode() async {
    setState(() => _loading = true);
    try {
      final code = await _pairingService.generateCode();
      final pairing = await _pairingService.getMyPairing();
      setState(() => _myCode = code);
      if (pairing != null) _watch(pairing.id);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _joinCode() async {
    final code = _codeController.text.trim();
    // Client-side format check for instant feedback — the real
    // enforcement (correct code, not expired, not reused) happens
    // server-side in the join_pairing SQL function regardless.
    if (!PairingService.isValidCodeFormat(code)) {
      _showError('Enter the 6-digit code your partner shared with you.');
      return;
    }
    setState(() => _loading = true);
    try {
      await _pairingService.joinWithCode(code);
      widget.onPaired();
    } catch (e) {
      _showError("That code didn't work — it may be wrong or have expired (codes last 15 minutes). Ask your partner to generate a new one.");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect with your person'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'How this works',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InstructionsScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Nobody else can see this app\'s content — it\'s just the two of you. Either generate a code and send it to your partner, or enter the code they sent you.'),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('Option 1: Invite them', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (_myCode == null)
                            FilledButton(onPressed: _loading ? null : _generateCode, child: const Text('Generate my code'))
                          else ...[
                            Semantics(
                              label: 'Your pairing code is $_myCode',
                              child: Text(_myCode!, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 8)),
                            ),
                            const SizedBox(height: 8),
                            const Text('Send this code to your partner. It expires in 15 minutes. Waiting for them to enter it...'),
                            const SizedBox(height: 8),
                            const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('Option 2: Enter their code', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24, letterSpacing: 6),
                            decoration: const InputDecoration(counterText: ''),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(onPressed: _loading ? null : _joinCode, child: const Text('Connect')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
