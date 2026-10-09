# Pair — Engineering Handoff

**Status:** Full feature set implemented — pairing, chat, timezone-aware scheduling, live location, calling, a 9-game live-only games system, notifications, privacy/terms pages, form validation, and security hardening (pairing-code expiry). All features are currently free for every account (see §5). Targets Android, iOS, Web, Windows, macOS, Linux from one codebase. Testing is the current milestone — see `ANDROID_APK_GUIDE.md` to get a real APK on two phones right now.

---

## 1. System Architecture

```
┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐
│  Android   │ │    iOS     │ │    Web     │ │  Windows   │ │   macOS    │ │   Linux    │
└─────┬──────┘ └─────┬──────┘ └─────┬──────┘ └─────┬──────┘ └─────┬──────┘ └─────┬──────┘
      └──────────────┴──────────────┴──────────────┴──────────────┴──────────────┘
                                     │  HTTPS (REST) + WSS (Realtime + Broadcast)
                           ┌─────────▼──────────┐
                           │   Supabase project   │
                           │ Postgres/GoTrue/     │
                           │ Realtime/PostgREST    │
                           └───────────────────────┘

    Calling media bypasses Supabase entirely once connected (STUN P2P):
┌──────────────────┐                              ┌──────────────────┐
│ Device A cam/mic  │◄────────────────────────────►│ Device B cam/mic  │
└──────────────────┘                              └──────────────────┘
```

**One backend, six client targets, no custom server.** Authorization lives in Postgres Row-Level Security, not app code — every table's policy is scoped to "you, or your paired partner," never "any authenticated user."

**Two real-time mechanisms, used deliberately for different things:**
- **Postgres Change subscriptions** — durable, row-backed: chat, pairing status, location pings.
- **Broadcast channels (`PairChannel`)** — ephemeral, never written to a table: call signaling AND game state. One generic class, parameterized by a topic string (`call` / `game`), used both places — see §5.

---

## 2. Stack & Key Decisions

| Concern | Choice | Why |
|---|---|---|
| Client | Flutter 3.x | One codebase, six targets |
| Backend | Supabase (free tier) | Real SQL + Auth + Realtime + auto-REST on one flat free tier |
| Auth | Supabase GoTrue, email magic-link | No password storage, no SMS cost; Supabase rate-limits OTP server-side (spam protection you don't have to build) |
| Maps | `flutter_map` + OpenStreetMap | Zero API key, zero billing account |
| Geolocation | `geolocator` | Best cross-platform coverage (no Linux support — see §6) |
| Timezone | `flutter_timezone` + `timezone` (IANA db) | `flutter_timezone` has real web support unlike `flutter_native_timezone`; the IANA package gives DST-aware schedule overlap math |
| Calling | `flutter_webrtc`, peer-to-peer, free STUN | $0 regardless of call volume; no TURN relay yet (see backlog) |
| Games | Ephemeral via `PairChannel`, zero DB persistence | Nothing needs saving — see §5 |
| Local notifications | `flutter_local_notifications` | Android/iOS/Windows/macOS; no web support (documented, not hidden) |
| Theming | Custom `ThemeData` + `google_fonts` | Explicit "calming, couple-friendly" product requirement |

---

## 3. Repository Layout

```
pair_app/
├── .github/workflows/build-apk.yml   # builds a real APK on every push — see ANDROID_APK_GUIDE.md
├── lib/
│   ├── main.dart                     # Supabase init, theme, 404-equivalent fallback route
│   ├── theme/app_theme.dart          # palette + typography; alertText vs. decorative coral — see §7
│   ├── data/quotes.dart
│   ├── models/models.dart
│   ├── widgets/daily_quote_card.dart
│   ├── services/
│   │   ├── auth_service.dart         # email validation, magic-link, profile bootstrap
│   │   ├── pairing_service.dart      # 6-digit code gen/redeem, format validation
│   │   ├── chat_service.dart         # message length limit
│   │   ├── schedule_service.dart     # timezone-aware overlap (pure fn), time validation
│   │   ├── location_service.dart     # permission handling, tracking, distance math
│   │   ├── profile_service.dart
│   │   ├── nickname_service.dart
│   │   ├── notification_service.dart
│   │   ├── feature_access.dart       # the ONE flag that turns premium gating on/off
│   │   ├── pair_channel.dart         # generic ephemeral broadcast channel (calls AND games)
│   │   ├── call_service.dart
│   │   └── analytics_service.dart    # event-tracking scaffold, not wired to a tracker — see §7
│   ├── games/
│   │   ├── game_session_controller.dart  # every game wraps its moves through this
│   │   ├── live_game_screen.dart         # shared base: controller lifecycle + "partner left" banner
│   │   ├── grid_win_checker.dart         # ONE win-checker used by Tic-Tac-Toe AND Connect Four
│   │   ├── game_catalog.dart             # THE list — add game #10 through #100+ here
│   │   ├── prompt_packs.dart             # content packs powering 6 prompt-card games off 1 screen
│   │   └── screens/                      # tictactoe, connect_four, rock_paper_scissors, prompt_card, game_hub
│   └── screens/
│       ├── login_screen.dart, welcome_loader_screen.dart, root_router_screen.dart, pairing_screen.dart
│       ├── home_screen.dart          # tabs + incoming call/game invite listeners
│       ├── chat_screen.dart, schedule_screen.dart, location_screen.dart, call_screen.dart
│       ├── instructions_screen.dart  # Help tab, includes partner-nickname setting + privacy/terms links
│       └── privacy_policy_screen.dart, terms_screen.dart
├── sql/schema.sql                    # source of truth for the DB
├── web_assets_to_copy/               # SEO meta tags, robots.txt — copy into web/ after flutter create .
├── README.md, ANDROID_APK_GUIDE.md, PRELAUNCH_CHECKLIST.md, ENGINEERING_HANDOFF.md
```

`android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` are NOT checked in — generated by `flutter create .`.

---

## 4. Data Model

Full DDL in `sql/schema.sql`.

| Table | Purpose |
|---|---|
| `profiles` | 1:1 with `auth.users`. timezone, location-sharing flag, `pet_name`, `role` |
| `pairings` | The 2-person room. **`expires_at`** bounds pairing-code brute-force risk (15 min) |
| `messages` | Chat + sticky notes + doodle metadata |
| `schedule_blocks` | Date-based (`for_date`), not recurring |
| `location_pings` | GPS history, written only while sharing is on |

**No `game_sessions` table** — games are ephemeral (§5). RLS restricts `profiles`/`schedule_blocks` reads to self + partner only, never "any authenticated user."

**`SECURITY DEFINER` functions:** `create_pairing()`, `join_pairing(code)` (now checks `expires_at`), `set_partner_nickname(nickname)`.

---

## 5. Games Architecture

Zero database persistence, by design — state lives only in memory while both partners are connected, exchanged over `PairChannel('game', pairingId)`. Leave the screen, the game's gone.

**Three pieces every game uses:**
1. `PairChannel` — the raw channel (shared class with calling; different topic string)
2. `GameSessionController` — wraps it with `sendState()`/`onState`/`onPartnerLeft`
3. `LiveGameScreen`/`LiveGameScreenState` — the shared base every game screen extends, handling controller lifecycle and the "partner left" banner so no game screen reimplements that boilerplate

**9 games, 3 reusable engines:** Tic-Tac-Toe + Connect Four (share `GridWinChecker` — one "N in a row" algorithm, two board sizes), Rock Paper Scissors, and six prompt-card games (Truth or Dare, Would You Rather, Never Have I Ever, This or That, 20 Questions, Couple Trivia — literally the same screen, different content list in `prompt_packs.dart`).

**Path to 100+:** a new prompt-card game is a content list + one `game_catalog.dart` entry (minutes). A genuinely new mechanic follows the `tictactoe_screen.dart` pattern (real engineering, but the networking/invite/UI-shell is solved once, not per-game).

---

## 6. Platform Support Matrix

| Feature | Android | iOS | Web | Windows | macOS | Linux |
|---|---|---|---|---|---|---|
| Core (auth/chat/schedule/pairing) | Y | Y | Y | Y | Y | Y |
| Live location | Y | Y | Y | Y | Y | No — no `geolocator` Linux support; guarded via `defaultTargetPlatform`, not `dart:io` (which would break web builds) |
| Calling | Y | Y | Y | Y | Y | Partial — needs extra native build deps beyond Flutter's Linux baseline |
| Reminders | Y | Y | No web plugin support | Y | Y | Partial — depends on a D-Bus notification daemon |
| Games | Y | Y | Y | Y | Y | Y |

---

## 7. Notable Design Decisions (read before "fixing" these)

- **Supabase anon key is public by design**, not a leaked secret — RLS is what actually protects data. Explained in `main.dart` right next to the key.
- **`AppTheme.coral` vs `AppTheme.alertText`** — coral fails WCAG AA contrast for body text; it's kept for icons/decorative accents only. Any actual sentence a user reads (errors, "partner left" notices) uses `alertText`.
- **`Analytics.track()` calls exist everywhere an event matters, but aren't wired to a real SDK** — deliberate: this app's whole pitch is privacy, so silently shipping a tracker would contradict that. Wire your chosen provider into `analytics_service.dart`'s one method when you decide to.
- **Games trust the two partners** — moves apply immediately, no server validation, because this is casual play between people who trust each other, not a competitive mode against strangers.

---

## 8. Known Limitations / Backlog

1. **No TURN relay for calling** — STUN-only; some NATs may fail to connect. Add a free TURN tier to `CallService._config`.
2. **No automated tests yet** — `ScheduleService.overlapFreeWindows`, `LocationService.totalDistanceKm`, and `GridWinChecker.find` are pure functions; start there.
3. **No presence indicator** — `profiles.is_online`/`last_seen_at` exist but nothing writes to them.
4. **No in-app payment flow** — `role` is set manually in Supabase's table editor. Next step: RevenueCat + a webhook to an Edge Function.
5. **Location history has no retention policy** — add a pg_cron job to prune old `location_pings`.
6. **iOS builds need a real Mac** — Xcode has no Linux/Windows equivalent. Free Apple ID for local device testing; $99/year only for TestFlight/App Store.

---

## 9. Testing Plan

See `ANDROID_APK_GUIDE.md` for the full manual checklist. Unit-test candidates (pure functions, no infra needed): `ScheduleService.overlapFreeWindows`, `LocationService.totalDistanceKm`, `GridWinChecker.find`.

**What "done" looks like:** every item in the Android guide's checklist passes between two independent phones, with no manual database intervention needed.
