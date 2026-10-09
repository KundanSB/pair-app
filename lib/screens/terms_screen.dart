import 'package:flutter/material.dart';

/// Same caveat as privacy_policy_screen.dart: accurate starting draft for
/// what this app does, not a substitute for real legal review.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = [
    _Section(
      'What Pair is',
      'Pair is a private, two-person app for couples, friends, or family '
          'members who want to stay connected across distance and time '
          'zones. It is intended for use by two people who both agree to '
          'be paired together — it is not a public social network.',
    ),
    _Section(
      'Your responsibilities',
      'Don\'t use Pair to harass, stalk, or track someone without their '
          'knowledge and consent — location sharing, in particular, must '
          'always be something both people knowingly turned on for '
          'themselves. You\'re responsible for what you send through the '
          'app.',
    ),
    _Section(
      'Account & pairing',
      'A pairing code connects exactly two accounts and cannot be reused '
          'once redeemed. You can only be actively paired with one person '
          'at a time.',
    ),
    _Section(
      'Availability',
      'Pair is provided as-is, currently in testing. Features, including '
          'free access to premium features during this testing period, '
          'may change as the app develops.',
    ),
    _Section(
      'Termination',
      'We may suspend an account that violates these terms, particularly '
          'around non-consensual location tracking or harassment.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Last updated: fill in your launch date', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          for (final s in _sections) ...[
            Text(s.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(s.body),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _Section {
  final String title;
  final String body;
  const _Section(this.title, this.body);
}
