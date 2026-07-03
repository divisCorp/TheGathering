# PR1 Completion: Project Bootstrap & Foundational Auth

## Status
✅ Structure complete per design document (The Gathering design doc, PR1 section).

## Deliverables Matched
- Flutter project init (pubspec + lib/ structure)
- Auth screens: email/phone signup/login + **mandatory phone verification**
- Self-attestation with exact wording + ban consequences
- Supabase project setup notes + env
- Basic RLS migration (001_init_users_rls.sql)
- Storage bucket guidance
- Verification queue stub (`verification_status: 'pending_review'`)
- Onboarding skeleton + location permission explanation screen (ephemeral use emphasized)
- Privacy policy/terms stub
- Basic navigation shell + limited home screen
- User profile model (coarse location only)

## Key Design Alignments
- Name: The Gathering
- Privacy: No persistent precise user location in profiles
- Standards: Attestation + future keyword filters
- Complementary: Strong disclaimer

## To Run (on your machine)
1. Install Flutter (https://flutter.dev) and accept Xcode license: `sudo xcodebuild -license accept`
2. `cd Projects/the-gathering`
3. `flutter create . --platforms=ios,android` (or use existing files)
4. `flutter pub get`
5. Copy .env.example to .env and fill Supabase keys
6. Create Supabase project and run the SQL migration
7. `flutter run`

## Next PRs (per design)
PR2: Profiles + interests + avatar gate
PR3: Event model + creation + filters + keyword enforcement

See full PR Plan in the-gathering-design-doc.md
