import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'screens/login_screen.dart';
import 'screens/root_router_screen.dart';
import 'theme/app_theme.dart';

// ============================================================
// FILL THESE IN before you run the app.
// Get them from: Supabase Dashboard → Project Settings → API
//
// SECURITY NOTE (pre-launch checklist item "get secrets off the front
// end"): unlike a typical API key, Supabase's "anon" key is DESIGNED to
// be public — it ships inside every Flutter/web/mobile app that uses
// Supabase and is visible to anyone who decompiles the app or inspects
// network traffic. It is NOT a secret. What actually protects your data
// is Row-Level Security (see sql/schema.sql) — the anon key only proves
// "this request came from the Pair app," every actual permission check
// happens in Postgres. Never put your Supabase *service role* key here
// or anywhere in the client — that one IS a real secret and bypasses RLS
// entirely; it belongs only in server-side code (Edge Functions), never
// in this repo.
// ============================================================
const String supabaseUrl = 'https://awugwteqgxitimcdduga.supabase.co'; // always https — Supabase does not offer plain http
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3dWd3dGVxZ3hpdGltY2RkdWdhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE1NTA3NTQsImV4cCI6MjEwNzEyNjc1NH0.oanhnuwZdlvSn3XhUQ5dZqdv_tbH4k5Dtx4MNW1I1gE';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Required once at startup for ScheduleService's DST-aware timezone
  // conversion (see lib/services/schedule_service.dart).
  tz_data.initializeTimeZones();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const PairApp());
}

final supabase = Supabase.instance.client;

class PairApp extends StatelessWidget {
  const PairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pair',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // Flutter's equivalent of a website's custom 404 page: if a deep
      // link (mainly relevant on the web build) doesn't match a route
      // this app actually defines, show something friendly instead of a
      // blank screen or a crash.
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.explore_off, size: 48, color: AppTheme.plum),
                const SizedBox(height: 12),
                const Text("This page doesn't exist."),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const RootRouterScreen()),
                    (route) => false,
                  ),
                  child: const Text('Take me home'),
                ),
              ],
            ),
          ),
        ),
      ),
      home: supabase.auth.currentSession == null
          ? const LoginScreen()
          : const RootRouterScreen(),
    );
  }
}
