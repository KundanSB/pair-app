import 'package:flutter/material.dart';

/// A real, working privacy policy has to say what THIS app actually does
/// — not generic boilerplate. This draft is accurate to the current
/// codebase (see sql/schema.sql and each service file). Have an actual
/// lawyer review this before using it for a real launch, especially the
/// GDPR/UK sections if you'll have EU/UK users — this is a solid,
/// honest starting draft, not legal advice.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    _Section(
      'What we collect',
      'Your email address (for login), a display name, your device\'s '
          'timezone, chat messages you send within your pairing, schedule '
          'blocks you create, and — only if you turn it on — your live '
          'location and GPS history. We do not collect anything beyond '
          'what\'s needed for the app\'s features to work.',
    ),
    _Section(
      'Who can see your data',
      'Only the one person you are paired with. There are no public '
          'profiles, no shared feeds, and no way for anyone outside your '
          'pairing to access your messages, schedule, or location — this '
          'is enforced at the database level (Row-Level Security), not '
          'just hidden in the app\'s interface.',
    ),
    _Section(
      'Location data specifically',
      'Location sharing is off by default. When you turn it on, your '
          'position is shared with your partner only, for as long as '
          'sharing stays on. Turning it off stops new location data '
          'immediately. Past location history is not automatically '
          'deleted — contact support if you want it removed.',
    ),
    _Section(
      'Where data is stored',
      'All data is stored with Supabase, a database hosting provider, on '
          'their infrastructure. We do not sell, rent, or share your data '
          'with advertisers or third parties.',
    ),
    _Section(
      'Your rights',
      'You can request a copy of your data or request it be deleted at '
          'any time. Deleting your account removes your profile, and your '
          'messages become inaccessible to your former partner as well.',
    ),
    _Section(
      'Changes to this policy',
      'If this policy changes in a way that matters, we\'ll let you know '
          'inside the app before the change takes effect.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
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
