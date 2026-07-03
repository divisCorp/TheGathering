# The Gathering

**Uplifting activities. Genuine friendships. Right where you are.**

Mobile app for members of The Church of Jesus Christ of Latter-day Saints to discover and organize wholesome, faith-aligned activities nearby.

## Design Document
Full design at: `/Users/jamesdivis/the-gathering-design-doc.md`

## Tech Stack (per design)
- **Mobile**: Flutter (preferred)
- **Backend**: Supabase (Postgres + PostGIS for geo queries, Auth, Realtime, Storage)
- **Maps**: Google Maps / Apple Maps or Mapbox
- **Notifications**: FCM / APNs

## Current Status
**PR1: COMPLETE** - Bootstrap + Auth (phone verification + attestation)
**PR2: COMPLETE** - Profiles + Interest model (4 areas taxonomy, avatar gate, My Profile tab)
**PR3: COMPLETE** - Event creation wizard + EventsService (Supabase create/fetch)
**PR4 start** - Dynamic Discover list with filters using events + map placeholder

### Progress
- Full scaffold + MainShell nav
- 4-area interests
- Event wizard with templates, tiers, standards enforcement
- Home loads + filters events (Supabase or mock)
- Map placeholder in Discover

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
- Create free project at supabase.com
- Enable Phone (SMS) provider in Authentication
- Copy URL and anon key to .env (replace the placeholders)
- Run the SQL in supabase/migrations/001... and 002... in SQL editor
- Enable PostGIS extension for geo if advanced.

### 4. Run the app
flutter run

Use emulator or physical device (iOS/Android).

Note: First run will download more if needed. Accept Xcode license if prompted: sudo xcodebuild -license accept

The app will start with auth screen.

### Environment note
Flutter was manually cloned because of tool limits. In normal dev machine, `brew install --cask flutter` after accepting Xcode license.

## Name
"The Gathering" (finalized)

## Important
- Not affiliated with The Church of Jesus Christ of Latter-day Saints.
- All activities must align with Church standards (Word of Wisdom, etc.).
