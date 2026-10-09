import 'package:flutter_timezone/flutter_timezone.dart';
import '../main.dart';
import 'analytics_service.dart';

class AuthService {
  /// Basic RFC-5322-lite email check — good enough to catch typos before
  /// hitting the network, not meant to be a fully spec-compliant validator
  /// (checklist item: form validation).
  static bool isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  }

  /// Sends a one-time magic link to the user's email. No password, no SMS,
  /// so this stays entirely inside every provider's free tier. Supabase
  /// also rate-limits OTP requests server-side, which is most of your
  /// spam/bot protection for this flow — you don't need to reimplement it.
  Future<void> sendMagicLink(String email) async {
    if (!isValidEmail(email)) {
      throw ArgumentError('Enter a valid email address.');
    }
    await supabase.auth.signInWithOtp(
      email: email.trim(),
      emailRedirectTo: 'io.pairapp://login-callback',
    );
  }

  /// Call this once after a user's first successful login to create
  /// their profile row with their device's detected timezone.
  Future<void> ensureProfile(String displayName) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final existing = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();

    if (existing == null) {
      String tz = 'UTC';
      try {
        tz = await FlutterTimezone.getLocalTimezone();
      } catch (_) {
        // Falls back to UTC if the platform lookup fails.
      }
      final safeName = displayName.trim().isEmpty ? 'Someone' : displayName.trim().substring(0, displayName.trim().length.clamp(0, 40));
      await supabase.from('profiles').insert({'id': user.id, 'display_name': safeName, 'timezone': tz});
      Analytics.track('profile_created');
    }
  }

  Future<void> signOut() => supabase.auth.signOut();
}
