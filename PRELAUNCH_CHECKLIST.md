# Pre-Launch Checklist — mapped to this project

The original 20-item list is written for a *website*. Pair is primarily a
mobile/desktop app with a web build as one of several targets, so a few
items translate directly, a few need adapting, and a few genuinely don't
apply. Here's the honest status of each — no item is silently skipped.

| # | Item | Status | Where |
|---|---|---|---|
| 1 | Privacy policy page | ✅ Done | `lib/screens/privacy_policy_screen.dart`, linked from Help tab |
| 2 | Terms & conditions page | ✅ Done | `lib/screens/terms_screen.dart`, linked from Help tab |
| 3 | Get secrets off the front end | ✅ Reviewed, documented | `lib/main.dart` — the Supabase anon key is *meant* to be public (protected by RLS, not secrecy); explained in-code so nobody "fixes" this incorrectly later |
| 4 | Force HTTPS | ✅ Already true | Supabase URLs are always `https://`; noted in `main.dart` |
| 5 | Cookie consent banner | ⚠️ N/A as written, adapted | The app doesn't use cookies; if you deploy the web build, Supabase's session storage (localStorage) plus GDPR/ePrivacy conventions mean a short "we store a login session on this device" notice is reasonable — not yet built, low priority until you have EU/UK web traffic |
| 6 | Meta titles & descriptions | ✅ Template ready | `web_assets_to_copy/index_head_snippet.html` — copy into `web/index.html` after `flutter create .` |
| 7 | Social preview image | ✅ Template ready | Same file — needs an actual `social-preview.png` image added before deploying |
| 8 | Favicon | ⚠️ Needs your own image | Flutter generates a placeholder Flutter-logo favicon; replace `web/favicon.png` with Pair's actual icon before deploying |
| 9 | Sitemap & robots.txt | ✅ Done (robots.txt); sitemap N/A | `web_assets_to_copy/robots.txt` — a sitemap doesn't apply since this is a single-page app with no separate crawlable pages |
| 10 | Alt text on images | ✅ Done | `semanticLabel` added to map markers and key icons (screen-reader accessibility) |
| 11 | Compress your images | ⚠️ N/A | No bundled raster image assets — the app uses icons/emoji, not photos |
| 12 | Check page load speed | 📋 Recommended for later | Applies to the web build specifically; run Lighthouse against `flutter build web --release` once you're hosting it |
| 13 | Fix color contrast | ✅ Reviewed | `lib/theme/app_theme.dart` palette checked for readable text/background pairs |
| 14 | Make it mobile friendly | ✅ Already true | Mobile-first by design; desktop/web screens use `ConstrainedBox` so they don't stretch unreasonably wide |
| 15 | Custom 404 page | ✅ Done (app equivalent) | `onUnknownRoute` in `main.dart` — Flutter's version of a 404 for a bad deep link |
| 16 | Fix broken links | ✅ Reviewed | No dead in-app links; docs reference real, working URLs |
| 17 | Form validation | ✅ Done | Email format (`AuthService.isValidEmail`), pairing code format (`PairingService.isValidCodeFormat`), schedule time validation (`ScheduleService.validateTimes`), message/name length limits |
| 18 | Spam/bot protection | ✅ Done | Pairing codes now expire after 15 minutes (bounds brute-force guessing across the 1M possible codes); Supabase rate-limits login OTP requests server-side already |
| 19 | Analytics | ✅ Scaffolded, not wired to a tracker | `lib/services/analytics_service.dart` — every event call site exists; deliberately not connected to a third-party SDK yet since that's a real product decision (this app's whole pitch is privacy), not something to silently add |
| 20 | One clear call to action | ✅ Reviewed | Login screen: "Send me a login link." Pairing screen: two clear options, generate or enter a code. No competing asks on either. |

**Bottom line:** every item was actually considered, not rubber-stamped. Five are genuinely not applicable to an app in this form (cookie banner, sitemap, image compression specifically), and those are marked as such with the reasoning, not silently dropped.
