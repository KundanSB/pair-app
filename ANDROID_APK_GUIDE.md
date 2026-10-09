# How to Build an APK and Test Pair on Android

This is the one document to follow if all you want right now is: a real,
installable `.apk` file, put on two phones, played with as "Person A" and
"Person B."

---

## Part 1 — Get the backend running (5–10 minutes, do this first)

You need this before either build method below will actually work, since
the app needs somewhere to store pairings/messages/etc.

1. Go to **supabase.com** → sign up (free) → **New Project**.
2. Open **SQL Editor → New query**, paste the ENTIRE contents of
   `sql/schema.sql` from this project, and click **Run**.
3. Go to **Project Settings → API**. Copy the **Project URL** and the
   **anon public key**.
4. Open `lib/main.dart` in this project and replace:
   ```dart
   const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
   const String supabaseAnonKey = 'YOUR_ANON_PUBLIC_KEY';
   ```
   with your real values.
5. Still in Supabase: **Authentication → URL Configuration** → add
   `io.pairapp://login-callback` as a redirect URL.

That's the whole backend. No server to run, no hosting to set up.

---

## Part 2 — Build the APK (pick ONE method)

### Method A: GitHub Actions (no software to install on your computer)

1. Create a free account at **github.com** if you don't have one.
2. Create a new repository (name it anything, e.g. `pair-app`).
3. Upload this entire project folder into it — drag-and-drop through
   GitHub's web UI works fine ("Add file → Upload files"). Make sure the
   `.github` folder (including `.github/workflows/build-apk.yml`) comes
   along — it's what makes this automatic.
4. Commit. The moment you push, GitHub starts building automatically.
5. Click the **Actions** tab on your repo → click the run that's in
   progress (or just finished) → scroll to **Artifacts** → download
   **pair-app-release-apk**.
6. Unzip that download. Inside is `app-release.apk` — that's your file.

Typical build time: 3–6 minutes. You never installed anything locally.

### Method B: Build it yourself

Needs a computer (Windows/Mac/Linux) with Flutter installed.

```bash
flutter doctor          # install Flutter first if needed: docs.flutter.dev/get-started/install
cd pair_app
flutter create .        # generates the android/ folder (not included in the project as given)
flutter pub get
flutter build apk --release
```
Your file appears at:
```
build/app/outputs/flutter-apk/app-release.apk
```

**Both methods produce a fully working, installable APK.** The only
difference: it's signed with a default debug-style key rather than a real
release key — completely fine for installing on your own phones to test,
not what you'd eventually submit to the Play Store (see `README.md`'s
"Later" section for that step, whenever you're ready).

---

## Part 3 — Get the APK onto your Android phone(s)

You need this file on BOTH phones for the two-person test.

1. **Move the file to the phone.** Any of these work:
   - Email the `.apk` to yourself, open the email on the phone, download it
   - Upload to Google Drive, open the Drive app on the phone, download it
   - Plug the phone into a computer via USB and copy the file over
   - Send it to yourself via WhatsApp/Telegram "Saved Messages" and download

2. **Allow installing from this source** (one-time, per phone):
   - Open **Settings** → search for **"Install unknown apps"**
   - Find the app you used to open the file (Files, Chrome, Gmail, Drive — whichever you tapped the `.apk` from)
   - Toggle **Allow from this source** on

   (Exact wording/location varies slightly by phone brand — Samsung, Pixel,
   Xiaomi etc. all phrase this a little differently, but every Android
   phone has this setting somewhere under Settings → Apps or Security.)

3. **Tap the downloaded `.apk` file** → **Install** → **Open**.

Repeat this on the second phone.

---

## Part 4 — Test as Person A and Person B

With Pair installed on both phones:

1. **Phone A:** Open the app → enter an email → tap the magic link when
   it arrives in that inbox → set a display name → continue in.
2. **Phone B:** Repeat with a *different* email address.
   - Quick trick if you only have one Gmail address: `yourname+A@gmail.com`
     and `yourname+B@gmail.com` both deliver to the same inbox but count
     as different accounts to the app.
3. **Pair them:** On Phone A, tap **Generate my code**, note the 6-digit
   code. On Phone B, tap **Enter their code** and type it in. Both phones
   should land on the home screen within a couple of seconds.
   - Note: the code expires after 15 minutes — if you wait too long,
     just generate a fresh one.

### Full feature checklist — go through this with both phones side by side

- [ ] **Chat** — send a message from A, confirm it appears on B instantly (and vice versa)
- [ ] **Schedule** — add a "free" block for tomorrow on A, an overlapping one on B, confirm the overlap shows correctly on both; turn on "remind me" and confirm the reminder fires
- [ ] **Journey (location)** — turn on "Share my live location" on A, grant the permission prompt, confirm a pin appears on B's map within a few seconds; confirm the distance-traveled number updates
- [ ] **Calling** — tap the video-call icon on A, confirm B gets an "Incoming call" popup from wherever they are in the app, accept, confirm both video feeds connect; test the mute button; test hanging up from each side
- [ ] **Games** — tap the controller icon on A, pick a game (try Tic-Tac-Toe and one prompt-card game like Truth or Dare), confirm B gets a "wants to play" prompt, join, confirm moves sync correctly; close the game on one phone and confirm the other sees "partner left"
- [ ] **Nickname** — in the Help tab on A, set a nickname; relaunch the app on B and confirm B's welcome screen now shows that nickname
- [ ] **Privacy/Terms pages** — open both from the Help tab, confirm they read correctly
- [ ] **Help tab** — read through it as if you'd never seen the app before; note anything confusing

### If something doesn't work

Check the Supabase dashboard:
- **Table Editor** — confirms whether data is actually being written (if a message doesn't appear, check if the row exists here first)
- **Logs** — shows permission/RLS errors, which usually explain a "nothing happens when I tap X" symptom

---

## Quick reference: the two build methods compared

| | Method A: GitHub Actions | Method B: Build locally |
|---|---|---|
| Software needed on your computer | None | Flutter SDK |
| Time to first APK | ~5 min setup + ~5 min build | ~15 min Flutter install + ~2 min build |
| Good for | Getting an APK fast, no dev environment | Iterating on code changes repeatedly |
| Rebuilding after a code change | Push to GitHub again | Re-run `flutter build apk --release` |
