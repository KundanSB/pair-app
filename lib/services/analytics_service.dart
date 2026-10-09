import 'package:flutter/foundation.dart';

/// Deliberately NOT wired to a third-party analytics SDK (Firebase
/// Analytics, Mixpanel, etc.) out of the box — this app's whole product
/// pitch is privacy (no public data, no strangers, RLS-enforced access),
/// and silently shipping a tracking SDK would undercut that without the
/// person building on this codebase making that call explicitly.
///
/// What this gives you instead: every place in the app that WOULD want
/// an analytics event already calls `Analytics.track(...)` — during
/// testing it just prints to the debug console. When you're ready for
/// real analytics, implement the provider's SDK inside `track()` below;
/// every call site in the app stays exactly the same.
class Analytics {
  static void track(String event, [Map<String, dynamic>? properties]) {
    if (kDebugMode) {
      debugPrint('[analytics] $event ${properties ?? ''}');
    }
    // TODO(launch): replace this block with your chosen provider, e.g.:
    //   FirebaseAnalytics.instance.logEvent(name: event, parameters: properties);
    // Keep the call sites elsewhere in the app untouched — they should
    // never need to change when you swap the provider.
  }
}
