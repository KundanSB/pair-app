import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../main.dart';
import '../models/models.dart';

class LocationService {
  StreamSubscription<Position>? _positionSub;

  /// Requests location permission. `geolocator` has first-party support
  /// for Android, iOS, web, Windows, and macOS, but NOT Linux desktop —
  /// see the platform guard in location_screen.dart, which checks
  /// `defaultTargetPlatform` (not `dart:io`'s `Platform`, which would
  /// break web compilation) before ever calling this.
  Future<bool> requestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  Future<void> setSharingEnabled(bool enabled) async {
    await supabase.from('profiles').update({'location_sharing_enabled': enabled}).eq('id', supabase.auth.currentUser!.id);
  }

  Future<bool> isSharingEnabled(String userId) async {
    final res = await supabase.from('profiles').select('location_sharing_enabled').eq('id', userId).single();
    return res['location_sharing_enabled'] ?? false;
  }

  /// Throttled to 25m of movement between writes — keeps well inside
  /// free-tier DB limits even with daily continuous use.
  void startTracking(String pairingId) {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 25),
    ).listen((pos) async {
      await supabase.from('location_pings').insert({
        'user_id': supabase.auth.currentUser!.id,
        'pairing_id': pairingId,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'accuracy_m': pos.accuracy,
      });
    });
  }

  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  Future<LocationPing?> getLatest(String userId, String pairingId) async {
    final res = await supabase
        .from('location_pings')
        .select()
        .eq('user_id', userId)
        .eq('pairing_id', pairingId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return res == null ? null : LocationPing.fromMap(res);
  }

  Future<List<LocationPing>> getHistory(String userId, String pairingId, {DateTime? since}) async {
    var query = supabase.from('location_pings').select().eq('user_id', userId).eq('pairing_id', pairingId);
    if (since != null) query = query.gte('recorded_at', since.toUtc().toIso8601String());
    final res = await query.order('recorded_at', ascending: true);
    return (res as List).map((p) => LocationPing.fromMap(p)).toList();
  }

  void watchPings(String pairingId, void Function(LocationPing) onInsert) {
    supabase
        .channel('location:$pairingId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'location_pings',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'pairing_id', value: pairingId),
          callback: (payload) => onInsert(LocationPing.fromMap(payload.newRecord)),
        )
        .subscribe();
  }

  /// Sums great-circle distance (km) between consecutive points — GPS
  /// displacement, not device step-counting, chosen because it works
  /// identically on web and native.
  static double totalDistanceKm(List<LocationPing> points) {
    if (points.length < 2) return 0;
    double total = 0;
    for (var i = 0; i < points.length - 1; i++) {
      total += _haversineKm(points[i].latitude, points[i].longitude, points[i + 1].latitude, points[i + 1].longitude);
    }
    return total;
  }

  static double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180);
}
