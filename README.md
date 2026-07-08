# The Gathering

**Uplifting activities. Genuine friendships. Right where you are.**

Mobile app for members of The Church of Jesus Christ of Latter-day Saints to discover and organize wholesome, faith-aligned activities nearby.

## Design Document
See `the-gathering-design-doc.md` in this repo for the full design, PR roadmap (12 phases), architecture, and personas.

See PR1_COMPLETION.md, PR2_COMPLETION.md, PR3_COMPLETION.md, PR4_COMPLETION.md for milestone details.

## Tech Stack (per design)
- **Mobile**: Flutter (preferred)
- **Backend**: Supabase (Postgres + PostGIS for geo queries, Auth, Realtime, Storage)
- **Maps**: Google Maps / Apple Maps or Mapbox
- **Notifications**: FCM / APNs

## Current Status
**PR1: COMPLETE** - Bootstrap + Auth (email + mandatory phone OTP + attestation)
**PR2: COMPLETE** - Profiles + 4-area interests taxonomy + avatar gate + My Profile tab
**PR3: COMPLETE** - Event creation wizard + EventsService (Supabase, templates, standards)
**PR4: COMPLETE** - Real location + PostGIS RPC + flutter_map (user circle, tappable markers, distance mi, radius slider, search + filters + pagination)

### Polish Applied
- flutter analyze clean (0 issues)
- Debug prints removed / disabled
- Dead code + outdated TODOs cleaned
- Map markers now tap to event detail
- Distance shown in miles (consistent with radius)
- Create Event: "Use current location" for GPS coords
- Lints addressed (const, quotes)
- Providers + real Supabase flows wired end-to-end

Run instructions remain the same (install Flutter + Supabase).

Full details in PR1_COMPLETION.md and PR2_COMPLETION.md + design doc.

See PR1_COMPLETION.md, PR2_COMPLETION.md, PR3_COMPLETION.md and the design doc for details.

See the PR Plan in the design doc for the full 12-PR roadmap.

## Getting Everything Running

### 1. Flutter SDK (the env has it at ~/development/flutter)
export PATH="$HOME/development/flutter/bin:$PATH"
flutter --version

### 2. Project setup
cd Projects/the-gathering
./run_app.sh   # or manually:
flutter pub get

### 3. Supabase
- Create free project at supabase.com (project ref: dhryaddmqbbgekezskpl)
- Enable Phone (SMS) provider in Authentication
- Copy URL and publishable/anon key to .env (see .env.example)
- Link locally: `supabase link --project-ref dhryaddmqbbgekezskpl` (use access token)
- Run migrations: `supabase db push` (or paste SQL from supabase/migrations/ in SQL Editor)
- Enable PostGIS extension (in Dashboard or SQL: `create extension postgis;`)
- Create Storage bucket named `avatars` (public recommended)
- Run storage policies from `supabase/storage_policies.sql` in SQL Editor
- (Optional) Add reports/policies: `supabase db push` after latest migration

**Agent Skills (recommended for development):**
Run `npx skills add supabase/agent-skills` to install Supabase + Postgres best-practice instructions for AI coding tools.

### Server-side / Edge usage (@supabase/server)
For server environments (Edge Functions, Node servers, etc.):
- `npm install @supabase/server`
- Uses env vars: `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_SECRET_KEY`, `SUPABASE_JWKS_URL`
- Use `withSupabase` helper to create authenticated handlers:

```js
import { withSupabase } from "@supabase/server"

export default {
  fetch: withSupabase({ auth: "user" }, async (_req, ctx) => {
    const { data } = await ctx.supabase.from("events").select()
    return Response.json(data)
  }),
}
```

Auth modes: "user", "publishable", "secret", "none".
On Supabase Edge Functions, env vars are auto-injected. For non-user auth, set `verify_jwt = false` in supabase/config.toml if needed.
Get the secret key and JWKS from the Supabase dashboard Connect dialog. **Never commit the secret key.**

### 4. Run the app
flutter run -d "iPhone 16 Pro Max"   # or your device

Note: First run will download more if needed. Accept Xcode license if prompted: sudo xcodebuild -license accept

The app will start with auth screen.

**Full flow for running:**
1. `flutter pub get`
2. Set real values in .env (URL, keys, password if using DB direct)
3. `supabase link ...` + `supabase db push`
4. Create 'avatars' bucket + run storage_policies.sql
5. Run on simulator/device
6. Sign up (email + phone + attestation)
7. Edit Profile: add photo (uploads to storage), interests, save
8. Create events, discover them

Profile save + event creation + auth are fully integrated with Supabase.

### Environment note
Flutter was manually cloned because of tool limits. In normal dev machine, `brew install --cask flutter` after accepting Xcode license.

## Name
"The Gathering" (finalized)

## Important
- Not affiliated with The Church of Jesus Christ of Latter-day Saints.
- All activities must align with Church standards (Word of Wisdom, etc.).

## Production Readiness Notes
- **Keys**: Never commit real keys. Use `--dart-define` for release builds or secure secret management in CI.
  Example: `flutter build ios --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...`
- **Error handling**: All critical paths have try/catch with user-friendly messages.
- **Realtime**: Events and RSVPs now listen for live updates.
- **Auth**: Centralized Riverpod auth provider with automatic redirects.
- **Security**: RLS enforced on all tables. Use service_role key only server-side (see supabase/server-example.js).
- **Storage**: Avatars bucket + policies required (see supabase/storage_policies.sql).
- **Next for full prod**: 
  - Add Crashlytics / Sentry
  - Edge Functions for banned keyword checks and verification queue
  - Proper map integration (Google/Apple Maps)
  - Pagination for large event lists
  - App review + release on stores

Run `flutter build apk --release` or `flutter build ios --release` when ready.

## Web Hosting (Deploy to Website)

The app fully supports web (PWA-ready with service worker). Here's everything you need.

### 1. Build for Web

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Output will be in `build/web/`.

**For local testing of the web build:**
```bash
cd build/web
python -m http.server 8000
# Open http://localhost:8000
```

### 2. Deploy Options

#### Option A: Vercel (Recommended - Fastest)

1. Install Vercel CLI:
   ```bash
   npm i -g vercel
   ```

2. Deploy:
   ```bash
   cd build/web
   vercel --prod
   ```

Or connect your GitHub repo on [vercel.com](https://vercel.com) for automatic deploys on every push.

Create a `vercel.json` (already in repo) for proper SPA routing with GoRouter.

#### Option B: Netlify (Easiest Drag & Drop)

1. Go to https://app.netlify.com/drop
2. Drag the entire `build/web` folder.
3. Get an instant URL.

For Git integration, connect your repo and set:
- Build command: `flutter build web --release --dart-define=...`
- Publish directory: `build/web`

#### Option C: GitHub Pages (Free)

The repo includes `.github/workflows/deploy-web.yml` that builds and deploys on push to main.

**Setup:**
1. Push code to GitHub.
2. Go to repo → Settings → Pages → Build and deployment → Source: "GitHub Actions".
3. Add repository secrets:
   - `SUPABASE_URL`
   - `SUPABASE_PUBLISHABLE_KEY`
4. The workflow will deploy to `https://<username>.github.io/<repo-name>/`

#### Option D: Firebase Hosting

```bash
npm install -g firebase-tools
firebase login
firebase init hosting
# Select build/web as public directory
firebase deploy
```

### Production Tips

- **Never hardcode secrets** in code or .env for web builds. Always use `--dart-define` (visible in JS but required for client-side Supabase).
- The web build includes a service worker for PWA-like experience.
- Location works via browser Geolocation API (user will be prompted).
- Image upload works via browser file picker.
- For custom domain: Configure in your hosting provider.
- Test on mobile browsers too — the UI is mobile-first but responsive.

Example full build for CI/CD:

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=${{ secrets.SUPABASE_PUBLISHABLE_KEY }}
```

## Next Steps After Hosting

- Share the web URL alongside the mobile app.
- Monitor usage in Supabase dashboard.
- Add web-specific polish (desktop layout, better navigation) if needed.
