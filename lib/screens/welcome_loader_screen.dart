import 'package:flutter/material.dart';
import '../services/nickname_service.dart';
import '../data/quotes.dart';
import '../theme/app_theme.dart';

/// Shown briefly while RootRouterScreen figures out where to send the
/// user. Greeting is personalized by whatever nickname the PARTNER set
/// for this user, falling back to a plain "Welcome back."
class WelcomeLoaderScreen extends StatefulWidget {
  const WelcomeLoaderScreen({super.key});
  @override
  State<WelcomeLoaderScreen> createState() => _WelcomeLoaderScreenState();
}

class _WelcomeLoaderScreenState extends State<WelcomeLoaderScreen> with SingleTickerProviderStateMixin {
  String? _petName;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    NicknameService().getMyPetName().then((name) {
      if (mounted) setState(() => _petName = name);
    }).catchError((_) {
      // Not paired yet, or offline — fall back silently to the generic greeting.
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final greeting = (_petName == null || _petName!.trim().isEmpty) ? 'Welcome back' : 'Welcome back, ${_petName!}';
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
              child: const Icon(Icons.favorite, size: 64, color: AppTheme.coral),
            ),
            const SizedBox(height: 20),
            Text(greeting, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(Quotes.today(), style: const TextStyle(fontStyle: FontStyle.italic, color: AppTheme.plum), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppTheme.lavender),
          ],
        ),
      ),
    );
  }
}
