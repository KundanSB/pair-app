import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// Single source of truth for premium/admin gating.
///
///   EVERYTHING IS FREE FOR NOW — see `allFeaturesFreeForNow` below.
///
/// The `role` column and `hasPremiumAccess` check are fully implemented
/// and wired into HomeScreen's call/games entry points. To turn on the
/// subscription model later, flip this ONE flag to `false` — no other
/// code changes are required anywhere else in the app.
class FeatureAccess {
  static const bool allFeaturesFreeForNow = true;

  static bool canUseCalling(Profile me) => allFeaturesFreeForNow || me.hasPremiumAccess;
  static bool canUseGames(Profile me) => allFeaturesFreeForNow || me.hasPremiumAccess;

  static void showUpsell(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: const [
          Icon(Icons.lock_outline, color: AppTheme.coral),
          SizedBox(width: 8),
          Text('Premium feature'),
        ]),
        content: Text('$featureName is part of Pair Premium. Ask whoever manages your account to upgrade you.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
      ),
    );
  }
}
