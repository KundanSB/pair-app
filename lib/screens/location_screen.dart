import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class LocationScreen extends StatefulWidget {
  final Pairing pairing;
  const LocationScreen({super.key, required this.pairing});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _locationService = LocationService();
  final _mapController = MapController();

  bool _sharingOn = false;
  bool _loading = true;
  LatLng? _myLatest;
  LatLng? _partnerLatest;
  double _myKmThisWeek = 0;
  double _partnerKmThisWeek = 0;
  String? _partnerId;

  /// `geolocator` has no first-party Linux implementation. Uses
  /// `defaultTargetPlatform`, NOT `dart:io`'s `Platform` — importing
  /// `dart:io` at all breaks web compilation, even if the call itself
  /// would be guarded away from ever running there.
  bool get _platformSupportsLocation => kIsWeb || defaultTargetPlatform != TargetPlatform.linux;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final myId = supabase.auth.currentUser!.id;
    _partnerId = widget.pairing.partnerIdFor(myId);

    _sharingOn = await _locationService.isSharingEnabled(myId);
    if (_sharingOn && _platformSupportsLocation) {
      _locationService.startTracking(widget.pairing.id);
    }

    await _refresh();

    _locationService.watchPings(widget.pairing.id, (ping) {
      if (!mounted) return;
      setState(() {
        final point = LatLng(ping.latitude, ping.longitude);
        if (ping.userId == myId) {
          _myLatest = point;
        } else {
          _partnerLatest = point;
        }
      });
    });

    setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    final myId = supabase.auth.currentUser!.id;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    final myHistory = await _locationService.getHistory(myId, widget.pairing.id, since: weekAgo);
    final myLatest = await _locationService.getLatest(myId, widget.pairing.id);

    List<LocationPing> partnerHistory = [];
    LocationPing? partnerLatest;
    if (_partnerId != null) {
      partnerHistory = await _locationService.getHistory(_partnerId!, widget.pairing.id, since: weekAgo);
      partnerLatest = await _locationService.getLatest(_partnerId!, widget.pairing.id);
    }

    if (!mounted) return;
    setState(() {
      _myKmThisWeek = LocationService.totalDistanceKm(myHistory);
      _partnerKmThisWeek = LocationService.totalDistanceKm(partnerHistory);
      _myLatest = myLatest == null ? null : LatLng(myLatest.latitude, myLatest.longitude);
      _partnerLatest = partnerLatest == null ? null : LatLng(partnerLatest.latitude, partnerLatest.longitude);
    });
  }

  Future<void> _toggleSharing(bool value) async {
    if (value) {
      final granted = await _locationService.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is needed to share your position.')),
          );
        }
        return;
      }
    }
    await _locationService.setSharingEnabled(value);
    setState(() => _sharingOn = value);
    if (value) {
      _locationService.startTracking(widget.pairing.id);
    } else {
      _locationService.stopTracking();
    }
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = _myLatest ?? _partnerLatest ?? const LatLng(20, 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Journey')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (!_platformSupportsLocation)
                  Container(
                    width: double.infinity,
                    color: AppTheme.blush,
                    padding: const EdgeInsets.all(12),
                    child: const Text(
                      'Live location isn\'t supported on Linux desktop yet (a plugin '
                      'limitation, not an app bug) — this works normally on Android, '
                      'iOS, web, Windows, and macOS.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                SwitchListTile(
                  title: const Text('Share my live location'),
                  subtitle: Text(_sharingOn
                      ? 'Your partner can see where you are, anytime, until you turn this off.'
                      : "Off — your partner can't see your location."),
                  value: _sharingOn,
                  onChanged: _platformSupportsLocation ? _toggleSharing : null,
                ),
                if (_sharingOn && _partnerId != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: AppTheme.sage.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(14)),
                    child: Text(
                      _partnerLatest != null
                          ? "You can see each other's location right now."
                          : "Waiting for your partner to turn sharing on too — once they do, you'll see each other live.",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: _myLatest == null && _partnerLatest == null ? 2 : 12,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.pairapp.app',
                      ),
                      MarkerLayer(
                        markers: [
                          if (_myLatest != null)
                            Marker(
                              point: _myLatest!, width: 40, height: 40,
                              child: const Icon(Icons.person_pin_circle, color: AppTheme.plum, size: 36, semanticLabel: 'Your location'),
                            ),
                          if (_partnerLatest != null)
                            Marker(
                              point: _partnerLatest!, width: 40, height: 40,
                              child: const Icon(Icons.person_pin_circle, color: AppTheme.coral, size: 36, semanticLabel: "Partner's location"),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(child: _StatCard(label: 'You — last 7 days', value: '${_myKmThisWeek.toStringAsFixed(1)} km', color: AppTheme.plum)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Partner — last 7 days',
                          value: _partnerId == null ? '—' : '${_partnerKmThisWeek.toStringAsFixed(1)} km',
                          color: AppTheme.coral,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
