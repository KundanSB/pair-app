import 'package:flutter/material.dart';
import '../services/nickname_service.dart';
import '../theme/app_theme.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

class InstructionsScreen extends StatelessWidget {
  final bool embedded;
  const InstructionsScreen({super.key, this.embedded = false});

  static const _steps = [
    _HelpItem(icon: Icons.qr_code_2, title: '1. Connect with your person', body: 'One of you taps "Generate my code" to get a 6-digit code (valid 15 minutes). Send it to your partner, they enter it under "Enter their code" — you\'re now permanently connected. Nobody else can ever see or join your space.'),
    _HelpItem(icon: Icons.chat_bubble_outline, title: '2. Chat', body: 'A private chat, just the two of you. Messages arrive instantly across time zones and continents.'),
    _HelpItem(icon: Icons.schedule, title: '3. Schedule', body: 'Plan any day — including tomorrow, ahead of time. Pair converts between your timezone and your partner\'s automatically. Turn on "remind me" for a ring/vibrate reminder.'),
    _HelpItem(icon: Icons.map_outlined, title: '4. Journey — live location', body: 'Off by default. Flip it on and your partner sees a live pin plus how far you\'ve traveled recently. Turn it off any time to stop sharing immediately.'),
    _HelpItem(icon: Icons.videocam_outlined, title: '5. Video & audio calls', body: 'Tap the call icons at the top to ring your partner — they get an accept/decline prompt from anywhere in the app.'),
    _HelpItem(icon: Icons.videogame_asset_outlined, title: '6. Games', body: 'Tap the controller icon to start a game together, live — nothing is saved.'),
    _HelpItem(icon: Icons.lock_outline, title: 'Your privacy', body: 'No public profiles, no friend feeds, no strangers. Everything is visible only to the one person you paired with.'),
    _HelpItem(icon: Icons.help_outline, title: 'Something not working?', body: 'Check your internet connection and that you entered the code exactly as sent. If something isn\'t syncing, try closing and reopening the app.'),
  ];

  @override
  Widget build(BuildContext context) {
    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!embedded) ...[
          Text('How Pair works', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
        ],
        const _NicknameCard(),
        const SizedBox(height: 12),
        for (final step in _steps) _HelpCard(item: step),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
              child: const Text('Privacy Policy'),
            ),
            const Text('·'),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
              child: const Text('Terms & Conditions'),
            ),
          ],
        ),
      ],
    );

    if (embedded) return body;
    return Scaffold(appBar: AppBar(title: const Text('Help & Instructions')), body: body);
  }
}

class _NicknameCard extends StatefulWidget {
  const _NicknameCard();
  @override
  State<_NicknameCard> createState() => _NicknameCardState();
}

class _NicknameCardState extends State<_NicknameCard> {
  final _controller = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await NicknameService().setPartnerNickname(_controller.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved — that\'s what they\'ll see next time they open Pair 💛')));
        _controller.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.lavender, AppTheme.blush]), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personalize their welcome 💌', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Choose what your partner sees when Pair greets them (e.g. "baby," their name, an inside joke).', style: TextStyle(color: Colors.white, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLength: NicknameService.maxLength,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'e.g. baby',
                    hintStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    counterStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Save nickname',
                child: IconButton.filled(onPressed: _saving ? null : _save, icon: const Icon(Icons.check)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HelpItem {
  final IconData icon;
  final String title;
  final String body;
  const _HelpItem({required this.icon, required this.title, required this.body});
}

class _HelpCard extends StatelessWidget {
  final _HelpItem item;
  const _HelpCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(item.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
