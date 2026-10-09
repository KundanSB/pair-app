# Pair — Setup & Testing Guide

Everything is **free right now** — the premium/admin tier exists in the code but is switched off with one flag (`lib/services/feature_access.dart`) until you're ready for a subscription model.

This app targets **Android, iOS, Web, Windows, macOS, and Linux** from one codebase (Linux has one known gap: live location — see the platform matrix in `ENGINEERING_HANDOFF.md`).

**For the fastest path to an APK you can install on a phone right now, skip straight to `ANDROID_APK_GUIDE.md`** — this file covers full project setup for anyone building all platforms.

---

## 0. One-time local setup

```bash
flutter doctor          # install Flutter first if you haven't: docs.flutter.dev/get-started/install
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop

cd pair_app
flutter create .        # generates android/ ios/ web/ windows/ macos/ linux/ folders
flutter pub get
```

---

## 1. Create your free backend (Supabase)

1. **supabase.com** → sign up free → **New Project**.
2. **SQL Editor → New query** → paste all of `sql/schema.sql` → **Run**.
3. **Project Settings → API** → copy the **Project URL** and **anon public key** into `lib/main.dart`.
4. **Authentication → URL Configuration** → add `io.pairapp://login-callback` (mobile) and `http://localhost:PORT/**` (web/desktop testing).

(The anon key is safe to put directly in the app — see the security note right above it in `lib/main.dart` for why.)

---

## 2. Device permissions

**Android** (`android/app/src/main/AndroidManifest.xml`, inside `<manifest>`, above `<application>`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

**iOS** (`ios/Runner/Info.plist`, inside the top-level `<dict>`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Pair uses your location so your partner can see it, only if you turn sharing on.</string>
<key>NSCameraUsageDescription</key>
<string>Pair needs your camera for video calls.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Pair needs your microphone for calls.</string>
```

**Web:** nothing to configure — browsers prompt automatically. Two caveats: location/camera/mic require `https://` or `localhost` (fail silently on plain `http://`), and schedule reminders don't work on web at all (no plugin support).

---

## 3. Web SEO basics (only matters if you deploy the web build publicly)

After `flutter create .`, copy the files from `web_assets_to_copy/` into your generated `web/` folder — see `PRELAUNCH_CHECKLIST.md` for exactly which checklist items this covers (meta tags, social preview, robots.txt).

---

## 4. Run it

```bash
flutter run -d chrome      # Web
flutter run                # Android/iOS — picks from connected devices/emulators
flutter run -d windows     # only on a Windows machine
flutter run -d macos       # only on a Mac
flutter run -d linux       # only on a Linux machine
```

---

## 5. Testing as Person A and Person B

See `ANDROID_APK_GUIDE.md` for the full two-phone walkthrough, including the manual test checklist covering every feature (chat, schedule, location, calling, games, nicknames).

---

## Later: Publishing to Google Play (do this only once testing is done)

<details>
<summary>Click to expand — not needed yet</summary>

**iOS note:** you don't need Apple's $99/year fee just to test — a free Apple ID + Xcode installs directly on your own iPhone via USB (re-signs every 7 days). The paid program is only for TestFlight/App Store/sharing without a cable. The real requirement is a Mac, not money.

1. Sign the app for real (the CI/local debug-signed APK is fine for testing, not for the Play Store):
   ```bash
   keytool -genkey -v -keystore ~/pair-app-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pairapp
   ```
   Wire it into `android/app/build.gradle` per Flutter's guide: docs.flutter.dev/deployment/android
2. `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`
3. Google Play Console (play.google.com/console) — one-time $25 fee.
4. Store listing → Data safety section → upload the `.aab` → Closed Testing track first → Production.

</details>

---

## What's built

Private pairing · real-time chat · timezone-aware schedule planning with reminders · opt-in live location + distance tracking · peer-to-peer video/audio calling · 9 live-only games across 3 reusable engines · privacy policy & terms pages · form validation throughout · pairing-code expiry (anti-brute-force) · analytics scaffolding (not wired to a tracker) · a calming custom theme reviewed for contrast · a fully-wired (currently disabled) premium tier.

See `ENGINEERING_HANDOFF.md` for architecture and `PRELAUNCH_CHECKLIST.md` for the full 20-item checklist status.
