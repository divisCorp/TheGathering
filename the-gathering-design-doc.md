# Design Document: The Gathering — Mobile App for Wholesome Activity Discovery & Fellowship (LDS Community Focus)

**Version:** 1.0  
**Date:** 2026-07-02  
**Status:** Draft — Ready for implementation planning  
**App Name:** The Gathering  
**Tagline:** "Uplifting activities. Genuine friendships. Right where you are."  
**Branding Note:** Primary public-facing name is "The Gathering". The name draws from LDS themes of gathering (e.g., gathering of Saints, gathering Israel) but the app is fully independent. See Compliance & Legal / Trademark section for details. No "LDS" or "Latter-day" in the primary brand name.  

**Name Finalized:** The Gathering (confirmed)  
**Platforms:** iOS and Android (cross-platform)  
**MVP Scope:** Core discovery, creation, joining, and RSVP for verified adult members; 15-mile default radius; initial launch in 2–3 high-density metro areas (e.g., Salt Lake/Provo, Phoenix, Southern California); complementary to (never replacing) official Church tools.  
**License/Positioning:** Community-built, explicitly not affiliated with The Church of Jesus Christ of Latter-day Saints. All content and events must align with Church standards (Word of Wisdom, modesty, uplifting focus).  

---

## Overview

The Gathering is a mobile-first application that helps members of The Church of Jesus Christ of Latter-day Saints discover and organize wholesome, uplifting activities near them. The primary goal is building genuine friendships and fellowship through casual, interest-based hangouts and service opportunities that complement assigned ward and stake programs.

The app addresses documented gaps in current Church digital tools by enabling cross-ward, user-initiated activities while strictly respecting geographic ward/stake structures, privacy norms, and faith-aligned standards. It draws direct inspiration from:

- The 4 areas of the Children & Youth program (Spiritual, Social, Physical, Intellectual).
- Real activity patterns (ward potlucks, firesides, service projects, YSA/mid-singles events, FHE-style gatherings, temple prep, family history).
- Pain points of new movers, singles (YSA 18–35 and single adults/mid-singles ~36+), and anyone seeking more frequent peer connections beyond official calendars.

The Gathering is **not** a dating app (Mutual exists for that purpose), not a replacement for Member Tools or Gospel Living, and not a directory or leadership tool. It is a focused discovery and organization layer for casual-to-structured fellowship.

---

## Background & Motivation

### LDS Church Structure (Grounding All Design)
- **Wards**: Primary local units (historically ~300–600 members; standardized minimums ~250 members / 100 participating adults in recent guidelines). Assignments are strictly geographic by home address. Led by volunteer bishopric. Primary venue for Sunday worship and many weekday activities.
- **Stakes**: 5–12 wards (minimum ~2,000 members). Organize larger events (sports, dances, conferences).
- All leadership is lay and temporary. Emphasis on ministering, service, and community within the assigned unit.

### Current Tools and Their Gaps (Directly from Research)
- **Member Tools** (org.lds.ldstools): Ward/stake directory (photos/contacts — highly private), event calendar, meetinghouse locator. Recent updates support making certain unit events public via Activity Sharing. Limitations: Primarily official/assigned-unit events only; no broad cross-ward discovery for casual user events; directory not for social browsing.
- **Gospel Living** (org.lds.liv): Inspiring content, personal goals in the 4 areas, **Circles** (private groups for family/quorum/class — chat, goal sharing, create group activities + invite + RSVP). Major reported limitations: No sync with Member Tools ward calendar; glitchy notifications and inconsistent adoption; youth/family-oriented; Circles are closed — no public/interest-based discovery across wards.
- **Mutual**: LDS dating app. Some event visibility for YSA but explicitly romantic focus.
- **Official Activity Sharing** (2025 rollout): Leaders can publish ward/stake activities to public-facing ward web pages (via calendar.churchofjesuschrist.org). Allows non-members to discover and RSVP for "love, share, and invite." Centralized public pages but limited to leader-published official events using community-friendly language. Does not support frequent, small, member-initiated casual activities.
- **Other realities**: Facebook groups, Marco Polo, stake emails/texts, word-of-mouth. Fragmented and low visibility for many great activities.

### Documented Pain Points (High-Priority Segments)
- **Geographic limits on self-selection**: Members are "limited in our ability to self-select who we attend church with."
- **Singles isolation**: Family wards are geared toward couples/families. YSA often have dedicated wards/branches (18–35). Mid-singles / single adults (roughly 31–45+, recently referenced as 36+) frequently report feeling they "don't belong anywhere," overlooked, or awkward in family settings. New movers and transplants are told "you will have to create a group."
- **Event discoverability**: Official calendars are fragmented and primarily for assigned units. Many wholesome activities (hikes, game nights, study groups, service) happen but only within tiny circles.
- **Desire for organic, frequent connections**: Users want more casual/interest-based hangouts (beyond infrequent big ward parties) with peers who share faith and values.
- **New movers and underserved**: Highest friction for integration and belonging.

### Activity Inspiration & Categorization
Activities naturally map to (and must balance) the **Children & Youth 4 areas** (extendable to adults):
1. Spiritual (scripture study, firesides, temple prep, testimony building)
2. Social / Fellowship (game nights, potlucks, movie nights, FHE-style)
3. Physical (hikes, sports, fitness, outdoors, service projects)
4. Intellectual (career nights, cooking/crafts, family history, skills, education)

Additional practical tags: Service/Ministering, Youth/Family-friendly, Singles-specific or age-filtered, Temple/Family History.

These patterns (ward talent shows, heart attacks/service, scavenger hunts, Book of Mormon themes, stake sports) provide rich, authentic content templates.

### Opportunity
User-generated events fill the "casual + frequent + cross-ward" gap that official tools (by design) cannot fully address. The app must feel authentic: uplifting, wholesome (Word of Wisdom compliant, modest standards of conduct), focused on friendship/fellowship, and positioned as a helpful complement.

---

## Goals & Non-Goals

### Goals
- Provide low-friction discovery of nearby uplifting activities via map + personalized feed (default ~15-mile radius, user-adjustable; interest and age filtering).
- Enable any member to easily create and host small-to-medium wholesome activities (templates + wizard grounded in real ward practices).
- Prioritize high-pain segments: new movers/transplants, YSA/singles (all ages including mid-singles), families seeking peer activities, and active members wanting deeper interest-based connections.
- Build genuine friendships through participation signals (RSVP, attendance history, shared interests) without romantic matching.
- Strictly align with LDS culture and standards: wholesome language, no alcohol/tobacco/substance events, modest expectations, uplifting tone. Explicit 4-area tagging.
- Remain complementary: Link outward to official calendars/Activity Sharing pages where relevant; never duplicate directory, callings, or official leadership functions.
- Privacy-first and safety-conscious for a sensitive faith community.
- Support offline viewing of cached events and maps; push notifications for timely discovery ("This weekend near you").
- Achieve critical mass in targeted areas through seeding, leader involvement, and easy creation.

### Non-Goals (Explicitly Out of Scope)
- Dating, romantic matching, or "see who is single" features (Mutual's domain).
- Replacement or deep duplication of Member Tools (directory, official unit calendars, callings) or Gospel Living (personal goals, private Circles).
- Official Church leadership/admin tools, reports, or record-keeping.
- Global rollout from day one or low-density rural areas in MVP (focus on density for critical mass).
- Commercial marketplace, paid promotions, or event ticketing beyond simple cost notes.
- Youth-only app or full parental controls for minors (MVP targets adults 18+ with clear age filters; future family flows require extra design).
- Scraping or exposing private Church directories.
- Political, divisive, or non-wholesome content.

---

## Proposed Design

### Target Personas (Grounded in Research)
1. **Alex (28, YSA, new mover)**: Recently relocated for work/school. Assigned to a family ward. Wants frequent, casual peer activities: weekend hikes, game nights, scripture study groups, service with other young adults who share values. Avoids feeling like an outsider at family events.
2. **Jordan (38, mid-single / single adult)**: Long-term in a family ward. Feels "I don't belong anywhere." Seeks adult-focused casual dinners, book clubs, fitness groups, or service projects with other singles or like-minded adults. Dating secondary or not primary.
3. **Taylor (family parent, 34)**: New to area with young kids. Wants wholesome, family-friendly physical/outdoor activities, service projects, or low-key socials that are uplifting and safe.
4. **Sam (45, active member)**: Wants more intellectual and skills-based connections (family history nights, career discussions, crafts) beyond what their ward council schedules. Open to cross-ward.

Secondary: Ward activity coordinators or Relief Society/Elders Quorum leaders who want to amplify great events or discover cross-unit ideas.

### Core Features (MVP + Phased)

**MVP (Launch Scope)**
- Authentication & Profile: Email/phone + password (or Apple/Google), **mandatory phone verification**, self-attestation of Church membership with explicit wording ("I affirm under penalty of community removal that I am a current, active or believing member of The Church of Jesus Christ of Latter-day Saints in good standing and will abide by all app standards and terms; false claims will result in permanent ban"), display name, approximate age range or decade, short bio, **profile photo (required for full activation and discovery access; used for host/attendee identification and trust)**, multi-select interests (4 areas + sub-tags), location (coarse: manual city/zip or last query city; precise GPS used only ephemerally for discovery queries and never persisted to profile), optional ward/stake name (explicitly private, used only for filters if enabled). All new accounts or first event creations are queued for light human review before full "verified member" access to discovery/creation (see Verification and Moderation).
- Discovery: Map (clustered pins) + list/feed. Filters: distance (5/10/15/25/50 mi), date range, 4-area tags + Fellowship/Service, age appropriateness (All / YSA 18-35 / Single Adults 31+ / Families with children / Adults), free only. (Basic "recurring / series" indicator and filter supported in MVP via minimal model fields; full recurring creation/series management post-MVP. See Data Models and PR3.)
- Event View & RSVP: Full details (description, **location details with privacy tiers** (see below), host profile link, attendee count + opt-in names, tags, standards reminder). One-tap RSVP (Going / Maybe). Calendar export (ICS). Share link (deep link or web view for non-users).
- Create Event: Simple wizard (title, description with guidance, date/time/duration, **location with tier selection** (picker or address + privacy level), tags from 4 areas + others, capacity, cost note, visibility: "Open to verified members" or "Invite only", **minimal recurring support: "This is a recurring/series event" checkbox + simple note e.g. "Weekly on Tuesdays" or "First Friday of month" stored as recurrence_note**). Templates: "Game Night", "Hike", "Service Project", "Scripture Study", "Potluck/FHE-style", "Sports" (FHE-style templates pre-filled with recurring suggestion per research). Full recurring series management (auto-generate instances) is post-MVP.
**Event Location Handling (MVP tiers for privacy/implementation)**:
  - Public venue (exact address + pin revealed immediately in details to all verified users; geocoded).
  - Approx / neighborhood pin (coarse location shown pre-RSVP; full address post-RSVP or on host approval).
  - Meetinghouse vicinity (user selects "near [ward meetinghouse]" using device or manual; resolves to approx lat/lon near known public meetinghouse data or user-provided; full address may be "contact host" or revealed post-RSVP. MVP sources: user-entered or basic hardcoded popular meetinghouses from public maps.churchofjesuschrist.org data; no scraping private info).
  - Private / invite-only (address hidden until confirmed RSVP "Going"; shown only to attendees).
Geocoding provider: Mapbox/Google Geocoding (privacy policy: queries logged minimally, no long-term PII association beyond EVENT). Address visibility logic enforced server-side on RSVP status. Updated in architecture and PR3.
- My Stuff: RSVPs, Hosted events, Past attendance history.
- Basic Social: View limited public profile of other users (interests, bio, mutual events). In-app messaging only between mutual confirmed attendees or opt-in "open to chat".
- Notifications: Push for "New events near you matching your interests" (uses Location Data Lifecycle: coarse city or client-side geofencing; explicit consent required; "hide location" disables), RSVP confirmations, reminders 1 day/1 hour before.
- Search & Follow: By tag, location, or host.
- Moderation Basics: Report event or user; in-app guidelines. **Keyword + pattern filters (alcohol, tobacco, coffee/tea, dating language, immodest themes, prohibited substances) enforced at creation time; prominent standards banner.** (See PR3 for implementation timing.)

**Post-MVP (Phase 2+)**
- Advanced recurring events & series (auto-generate instances, manage series).
- Interest-based "Circles" (public or semi-public groups, distinct from Gospel Living private Circles).
- Photo sharing from events (opt-in).
- "Host reputation" / simple ratings (attendance reliability, not personality).
- Deeper integration hooks (e.g., "Add to my ward calendar" export or link to Activity Sharing pages).
- Offline map caching improvements, suggested activities based on 4-area goals.
- Leader tools (optional "promote to ward page" for verified coordinators).
- Better matching: "People near you with similar interests who are open to hangouts".

**Quantified MVP Targets**
- Default discovery radius: 15 miles (reasonable for many wards/stakes; adjustable).
- Initial cities: 2–3 metros with high LDS density + singles activity.
- Event visibility: Verified members only for MVP (to build trust and standards compliance); consider public web views later aligned with Activity Sharing spirit.
- Creation rate goal: Make hosting as easy as a Facebook event but with built-in standards guardrails.

### User Flows (High-Level)

1. **Onboard & Discover**:
   - Signup → Profile setup (interests + location critical) → See "Welcome to your new area — here are upcoming activities" (seeded + real).
   - Home screen: Personalized "This week near you" + map.

2. **Join Flow**:
   - Browse map/list → Apply filters → Tap card → View details (standards note always visible) → RSVP → Confirmation + push reminder + "Add to calendar".

3. **Create & Host Flow**:
   - Tap + → Select template or "Custom" → Fill wizard (location uses device picker or address search) → Preview (shows 4-area balance) → Publish (immediate or queued for light moderation in early days).
   - Host receives RSVPs; can message attendees or cancel. Publish subject to early keyword filters + standards check (enforced in PR3) and light review queue for new users/hosts.

4. **New Mover Special Flow**:
   - Detect new location or "new here" flag → Surface "Welcome / New in Town" tagged events + "Host a casual meetup" prompt.

5. **Singles Focus**:
   - Age/relationship filters surface relevant events without forcing singles wards. Optional "Singles-friendly" tag.

### High-Level Architecture

```mermaid
graph TD
    subgraph Mobile App
        A[Flutter Client<br/>Map + List + Create Wizard]
        B[Local Cache: Events, Profiles, Drafts<br/>Offline-first]
        C[Push Notifications Handler]
    end

    subgraph Backend
        D[Auth Service<br/>Email/Phone + Self-attest]
        E[User & Profile Store]
        F[Events + Geo Index<br/>Supabase + PostGIS]
        G[RSVP & Attendance]
        H[Moderation Queue + Reports]
        I[Push / Notification Service (FCM/APNs)]
    end

    subgraph External
        J[Maps SDK<br/>Google/Apple/Mapbox]
        K[Location Services<br/>Device GPS]
        N[Geocoding Service<br/>Mapbox/Google (privacy-reviewed, minimal logging)]
        L[App Store / Play Store]
        M[Optional: Link to calendar.churchofjesuschrist.org]
    end

    A -->|HTTPS + JWT| D
    A --> B
    A -->|Geo queries| F
    A --> J
    A --> K
    F -->|Geohash / radius queries| A
    Create -->|Geocode address| N
    H -->|Admin review| Moderators
    C <--> I
    A -.-> M
```

**Data Flow Notes**:
- Precise user home location never stored persistently (see Location Data Lifecycle and USER model). Server receives lat/lon + radius ephemerally for queries only (no long-term profile storage of coords). Coarse city (from profile or manual) may be stored for basic personalization. Event locations (host-provided) use lat/lon + address.
- Events are the primary entity for discovery.

### Data Models (Conceptual)

```mermaid
erDiagram
    USER ||--o{ EVENT : hosts
    USER ||--o{ RSVP : makes
    EVENT ||--o{ RSVP : has
    USER {
        string id PK
        string email
        string phone_hash
        string display_name
        string age_range
        string city  // coarse; approx city or zip only; NO precise lat/lon
        string optional_ward
        string optional_stake
        string[] interests
        string bio
        string avatar_url
        boolean is_verified_member
        timestamp created_at
        // Precise home coordinates are NEVER stored persistently for privacy.
        // Location supplied ephemerally at query time or as coarse city for profile.
    }
    EVENT {
        string id PK
        string host_id FK
        string title
        string description
        timestamp start_time
        timestamp end_time
        string address  // may be masked based on location_privacy and RSVP
        float lat
        float lon
        string location_type  // enum: public_venue | approx_neighborhood | meetinghouse_vicinity | private
        string location_privacy  // public | post_rsvp | host_approval | attendee_only
        string[] tags
        integer max_attendees
        number cost
        string visibility
        integer rsvp_count
        string status
        boolean is_recurring  // MVP minimal: true if series/recurring pattern
        string recurrence_note  // e.g. "Weekly Tuesdays" or "First Friday monthly"; full rule engine post-MVP
    }
    RSVP {
        string id PK
        string user_id FK
        string event_id FK
        string status
        string note
        timestamp created_at
    }
```

Additional: Reports (user_id, event_id, reason, status), NotificationLog, Interest taxonomy (fixed list derived from 4 areas + common ward activities).

### UI/UX Considerations
- **Tone & Visuals**: Clean, modern, uplifting. Palette: soft navy, sage green, warm neutrals (avoid bright party colors). Use simple icons representing the 4 areas + service. Typography: readable sans-serif. Warm, friendly microcopy ("Great choice — this looks like a wonderful way to connect!").
- **Navigation (Bottom Tab)**: Discover (Map/Feed toggle), Create (+ prominent), My Activities, Profile.
- **Cards**: Rich but scannable — date badge, distance, 3–4 tag pills, host thumbnail + "hosted by", RSVP count.
- **Standards Enforcement in UI**: Every create flow and event detail includes a visible "Wholesome Standards" callout. Descriptions are lightly prompted.
- **Accessibility & Mobile Realities**: Large tap targets, high contrast, support for screen readers. Handle location permission gracefully with explanations ("We use your location only to show activities within a distance you choose"). Support dark mode.
- **Empty States**: Encourage creation ("No events yet? Be the first to host a game night in your area!").
- **Onboarding**: 4–5 screens max, values-aligned ("Activities should strengthen faith, friendships, and personal growth across spiritual, social, physical, and intellectual areas.").

**Onboarding Flow Outline (Added for concreteness)**:
Screen 1: Welcome + values intro ("Find uplifting activities with people who share your faith... Build real friendships through wholesome hangouts aligned with gospel principles.").
Screen 2: Church membership attestation + phone verification + photo upload (required elements explained).
Screen 3: Profile basics (name, age range, bio, coarse city) + interests multi-select (4 areas with examples: Spiritual - scripture study; Social - game night; Physical - hike; Intellectual - family history).
Screen 4: Location & notifications consent ("Allow approximate location for 'near you' discovery and notifications? [toggle] We use coarse city or ephemeral GPS only; see Privacy.").
Screen 5: 4-area education + standards ("Events are tagged to help balance growth: [icons/checklist example]. All activities must be uplifting and Word of Wisdom compliant.").
**4-area balance preview in Create (UI spec)**: After tags selected, show "This activity covers: ✓ Spiritual (fireside) ✓ Social (fellowship) ✓ Physical (hike)  Intellectual (optional - add tag?)". Use simple checklist or 4 colored progress dots/icons. Sample copy in preview: "Great - this supports balanced development per the Children & Youth program!"
Fleshed out in PR2 (interests), PR3 (tags/balance), PR9 (refinements).

### Mobile Technology Choices
- **Cross-platform framework**: **Flutter** (recommended) or **React Native**. Flutter preferred for superior performance on maps, custom UI consistency across iOS/Android, and strong offline capabilities.
- **Backend**: Supabase (Postgres + PostGIS for accurate geo-radius queries, built-in auth, realtime, storage) or Firebase. Supabase chosen for relational strength and open-source alignment.
- **Maps & Location**: Google Maps / Apple Maps SDKs or Mapbox. Device location via official plugins. Always request "when in use" permission with clear rationale. Coarse location fallback. **Geocoding**: privacy-reviewed Mapbox/Google service; minimal logging policy; integrated in create flow for address -> lat/lon. Location privacy tiers (public/approx/post-RSVP/private) implemented server-side with masking. Meetinghouse "vicinity" uses user input or public maps data (no private directory access).
- **Offline**: Local SQLite / Hive cache for events within last viewed radius + user RSVPs. Draft events persist locally. Sync on reconnect. Map tile caching where SDK allows.
- **Notifications**: Firebase Cloud Messaging (FCM) + APNs. Topic + geo-targeted where possible. In-app notification center.
- **Auth & Security**: Email/password + social + phone verification. JWT sessions. Rate limiting on creation.
- **State Management**: Riverpod (Flutter) or equivalent.
- **App Distribution**: Standard App Store / Google Play. Age rating appropriate (likely 17+ or 12+ with clear family filters). Detailed privacy policy and data deletion flows required.
- **Analytics**: Privacy-respecting (event-level only; no PII). Primary: PostHog (self-hostable) or Supabase + custom events (preferred over Firebase Analytics to align with Supabase backend choice; Firebase only if unavoidable for push). Observability uses Sentry + structured logs.

---

## Key Decisions

1. **Positioning as complementary, not competitive**: Explicitly designed to fill gaps left by Member Tools, Gospel Living Circles, and new Activity Sharing pages (user-initiated casual events, cross-ward interest discovery). Rationale: Avoids conflict with official tools; leverages existing trust and adoption patterns. Research shows official tools are strong for assigned units but weak for organic peer connections.

2. **Primary focus on friendship/fellowship, explicitly non-dating**: No romantic features, matching algorithms, or "singles only" emphasis beyond optional filters. Rationale: Mutual exists for dating. Research repeatedly shows desire for "genuine friendships" and "wholesome peer connection" especially among singles who want social first.

3. **4-area tagging system as core categorization**: Every event tagged against Spiritual, Social, Physical, Intellectual + Fellowship/Service. Balance indicators in create/preview. Rationale: Directly from official Children & Youth program for cultural authenticity and to encourage well-rounded activities.

4. **Geo-radius discovery (default 15 miles) with optional ward/stake filters**: User location drives feed/map. Optional self-reported ward/stake for "same-stake" discovery without exposing directories. Rationale: Matches real travel realities and stake structures while allowing cross-ward relief for new movers/singles.

5. **Privacy model — data minimization + opt-in only**: No Church directory access or scraping. Precise user home location used ephemerally for queries only and never persisted in USER profile (coarse city/zip only if stored). Ward/stake disclosure fully optional. Attendee names hidden by default. Rationale: Research stresses "high privacy/safety sensitivity" and that "any app must not undermine church privacy norms around member data." See new Location Data Lifecycle subsection.

6. **Strengthened MVP verification (self-attestation + photo + phone + review queue)**: Mandatory phone verification + profile photo (required for activation) + explicit self-attestation with ban language. All new accounts/first-creations queued for light human review before full access. No direct integration with official membership records in MVP. Rationale: Self-attestation alone insufficient for "verified members only" model in high-trust faith community per research emphasis on safety/privacy. Photo + phone + review adds trust signals without directory scraping. Future optional "ward leader verified" or leader-vouch without exposing records. Updated Open Questions with MVP success criteria (e.g. monitor fake account rate <1% in beta).

7. **Flutter (preferred) + Supabase stack**: Chosen over React Native (dev speed) or native for cross-platform polish, offline support, and geo-query power. Rationale: Mobile realities (offline maps, location, push) are first-class. Enables rapid iteration for MVP while scaling. Diagram and tech references standardized to Flutter + Supabase/PostGIS (PostHog preferred for analytics).

8. **MVP limited to verified adults + high-density areas + 15mi radius**: Prioritizes critical mass and safety. Seeding via leaders and early adopters. Rationale: Research highlights retention/critical mass challenges in smaller communities and safety needs in mixed settings.

9. **Standards alignment built into product (not afterthought)**: Hard filters on creation (keywords), prominent UI guidelines, report mechanisms, "wholesome" tone in all copy. Rationale: Word of Wisdom, modesty, uplifting focus are non-negotiable for the target audience and to differentiate from general apps like Meetup.

10. **Lightweight "My Activities" history instead of full social graph**: Focus on participation over likes/follows. Profiles are minimal. Rationale: Keeps scope tight and privacy high; success metric is real-world attendance and friendships, not engagement theater.

---

## Alternatives Considered

1. **Deep integration with official Church systems vs. standalone complementary app**  
   **Alternative**: Build as an official extension, request API access to calendars/directories, or position for future acquisition/partnership.  
   **Tradeoffs**: Integration would provide instant credibility, real ward boundaries, and easier verification but introduces approval delays, scope creep, stricter privacy constraints, and risk of being deprioritized. Standalone allows fast MVP focused on the exact gap (casual cross-ward user events) and maintains independence.  
   **Decision**: Standalone with outward links to Activity Sharing pages. Revisit integration after proven traction and with Church invitation. Rationale grounded in current tool fragmentation and privacy realities.

2. **Fully public/open events (like Meetup) vs. verified-members-only**  
   **Alternative**: Make all events discoverable by anyone (including non-members) to maximize "love, share, and invite" potential.  
   **Tradeoffs**: Broader reach and missionary upside (aligns with recent Activity Sharing) but higher moderation burden, safety risks for singles/youth, and dilution of "like-minded people who share faith and values." Research shows core need is peer fellowship within the community.  
   **Decision**: Verified LDS members only for MVP (with clear future path to limited public views for specific leader-published events). Use visibility tiers later.

3. **React Native vs. Flutter vs. Web PWA + native shell**  
   **Alternative**: React Native for larger JS talent pool and faster initial prototypes; or web-first PWA to reduce app store friction.  
   **Tradeoffs**: RN has mature ecosystem for some libs; PWA is simplest to ship but poor for reliable push, background location, offline maps, and native map performance — critical for this use case. Flutter offers better UI consistency and performance for map-heavy + form-heavy flows.  
   **Decision**: Flutter primary recommendation. Allows high-quality offline and location experience matching research emphasis on "near you" mobile usage.

4. **No age/relationship filters vs. rich filtering**  
   **Alternative**: Keep everything "All ages" to simplify.  
   **Tradeoffs**: Simpler but fails high-pain segments (singles avoiding family events, parents wanting kid-appropriate).  
   **Decision**: Provide clear, optional filters while defaulting inclusive. Explicitly surface "family-friendly" and "singles-friendly" tags.

---

## Security & Privacy Considerations

This is one of the most critical sections. The app operates in a high-trust, geographically assigned faith community where privacy breaches or inappropriate exposure can have significant social and spiritual consequences.

### Core Principles
- **Data minimization**: Collect only what is required for the feature (precise location only for query radius; interests only for personalization).
- **User sovereignty**: Full delete account + data export. Granular controls (hide location, hide ward, opt-out of discovery).
- **No directory exposure**: Never import, scrape, or display full ward/stake membership lists. Optional self-reported ward is one-way and non-verified.
- **Ephemeral location handling**: Server receives coordinates + radius for queries; do not persist home addresses except where user explicitly creates a public event at that location.
- **Attendee privacy**: Default to aggregate counts only. Names visible only to confirmed attendees who have opted in or by mutual action.

### Location Data Lifecycle (Added to address review)
**Profile storage (persistent)**: 
- Only coarse-grained: `city` (user-entered or derived from manual zip/city selection) or rounded geohash (~5-10km precision buckets for basic "near you" relevance). NO precise lat/lon ever stored in USER record.
- Optional ward/stake for filtering (self-reported, non-verified).

**Query-time (ephemeral)**:
- When user opens Discover or enables notifications: client obtains precise device GPS (with permission), sends lat/lon + chosen radius to server for geo-radius query only. Server does not write the precise point to any persistent USER profile field. Query result cached briefly for session (minutes to hours, TTL).

**Notifications / "near you" push**:
- Coarse approach preferred: server uses stored city or last-known coarse bucket to subscribe user to relevant geo-topics or filter push payloads.
- Alternative: client-side geofencing (device computes "is event within my radius?" using cached event list + local GPS without sending precise home to server for every notification).
- "Hide location" toggle in profile: disables all geo-personalized notifications and discovery personalization (falls back to manual city or broad default feeds).
- Retention: Coarse location data rotated or deletable on user request. No long-term precise logs.
- Explicit consent: Separate toggle/checkbox during onboarding/profile for "Allow near-you notifications using my approximate location" (distinct from basic app location perm).

**Event locations**:
- Host-provided address + lat/lon are intentionally public to attendees (with tiers: see Event Location Handling).
- Geocoding: Uses privacy-reviewed provider (e.g. Mapbox or Google with no persistent query logging beyond necessary; policy documented). Results associated only with the EVENT record.

This lifecycle resolves prior contradictions between "ephemeral" claims and data model. Client-side storage for drafts/queries is encouraged. All location use logged for audit where server-processed. Updated in Data Models, Core Features, Architecture notes, and PR2.

### Authentication & Identity
- Strong password + **mandatory phone verification** + optional social sign-in.
- Self-attestation of membership with explicit legal language in terms and UI ("I affirm under penalty of community removal that I am a current, active or believing member of The Church of Jesus Christ of Latter-day Saints in good standing and will abide by all app standards and terms; false claims will result in permanent ban and may be reported."). Exact wording and consequences documented in Terms.
- **MVP verification robustness**: Profile photo required for full activation. All new signups (or at minimum first event creation) queued for light human review by initial moderation team before granting full "verified member" access to discovery, creation, and social features. This provides a basic barrier against non-members/trolls while remaining privacy-respecting (no Church record access).
- Rate limiting and anomaly detection on event creation and account creation (prevent spam).
- Future: Optional "verified host" program (long-term active members vouched by peers/leaders) without exposing underlying Church data. Leader-vouch flows possible later without directory exposure.

### Content & Standards Moderation
- Pre-creation keyword + pattern filters (alcohol, tobacco, coffee/tea references, immodest themes, dating-focused language, "drinks", "bar", "wine", "beer", "vape", "hookah", "cannabis", romantic/dating intent phrases). Implemented at create time.
- Prominent, non-dismissible standards banner in create and detail views.
- User reporting + easy block.
- Human review queue for first-time hosts **and new user accounts** (initially small trusted team). **Keyword enforcement and basic report flow advanced to creation PR.**
- Rapid takedown capability.
- Clear community guidelines in-app and in legal docs.

### Technical Protections
- All traffic over TLS.
- Data at rest encrypted.
- Row-level security in database (users can only see events within their query or their RSVPs).
- No PII in analytics events.
- Audit logging for moderation actions and data access.
- Regular security reviews.

### Compliance & Legal
- Clear, accessible Privacy Policy and Terms of Service (include age requirements, standards alignment, "not affiliated with The Church of Jesus Christ of Latter-day Saints" disclaimer prominently).
- Support data deletion requests ("right to be forgotten").
- COPPA/GDPR/CCPA considerations — strongly recommend 18+ for MVP.
- App store compliance: Family-friendly positioning, no misleading claims.
- Safety: In-app "Safety tips for attending activities" (meet in public, tell a friend, etc.). Two-person rule suggestions for certain events.
- Geographic sensitivity: Do not surface exact home addresses for private events. Event locations use tiered visibility (detailed in Proposed Design Event Location Handling); full addresses revealed appropriately (e.g. post-RSVP for private). No persistent user home coords.

**Trademark and Branding Analysis (Addressed per review):**
The Church of Jesus Christ of Latter-day Saints owns trademarks including "LDS", "Latter-day Saint(s)", related logos, and names associated with its programs. Third-party apps must not imply official affiliation or endorsement. Official guidelines (from Church IP resources) generally discourage use of "LDS" as the primary brand element in third-party products to avoid confusion; "Latter-day Saint" or descriptive phrases are sometimes more permissible when clearly disclaimed.
- **Decision for MVP**: Primary public name is "The Gathering". The name has positive LDS cultural resonance (gathering of Israel, gathering to Zion, fellowship) while remaining a neutral, independent brand. Avoid any "LDS" or "Latter-day" prefix or subtitle in primary branding and marketing materials. Use clear descriptive language such as "for members of The Church of Jesus Christ of Latter-day Saints" or "LDS community activities app".
- Explicit disclaimer in all app store listings, onboarding, footer, and legal docs: "The Gathering is an independent community tool and is not affiliated with, endorsed by, or sponsored by The Church of Jesus Christ of Latter-day Saints."
- PR10 will include: professional trademark search (USPTO + Church resources), legal review of name usage (including "The Gathering" in context of faith apps), and finalization of branding assets.
- Risk mitigation: Monitor for any Church feedback post-beta; easy rebrand path if needed (app name change is feasible pre-launch). "The Gathering" is expected to be lower risk than names containing "LDS" or "Latter-day".
- Added to Open Questions for ongoing legal clarity if needed.

### Faith-Community Specific Risks & Mitigations
- Risk of judgment or gossip: Minimal profiles; no "last attended" or activity scoring visible to others.
- Mixed-gender or singles events: Strong standards language; optional gender/age filters; host responsibility emphasized.
- New mover vulnerability: Welcome messaging + safety education.
- Leader involvement: Provide easy ways for bishops/RS presidents to be notified of or promote events without the app becoming an official channel.

---

## Observability

- **Product Analytics**: Privacy-preserving event tracking (event created, viewed, RSVPed, filters used, retention cohorts). Tools: PostHog (self-hostable) or Supabase + custom (primary; Firebase Analytics only as fallback). Key metrics: Events created/week, RSVP conversion, % of users with 1+ RSVPs in first 7 days, geographic coverage.
- **Technical**: Sentry (or equivalent) for crashes and errors. Backend structured logging (request IDs). Uptime monitoring.
- **Moderation Dashboard**: Private admin view of reports, flagged events, new user/host activity. Ability to hide/delete events quickly.
- **Health Metrics**: DAU/MAU (target improving retention), time-to-first-RSVP for new users, creation-to-attendance ratio, support ticket volume.
- **Feedback Loops**: In-app "How was this event?" (lightweight, post-event), "Suggest an improvement."
- **A/B Testing**: Limited initially (onboarding variants, filter defaults). Measure impact on activation.

---

## Rollout Plan

### Phase 0 — Validation (4–6 weeks)
- Internal prototype (Flutter + Supabase).
- Closed beta with 3–5 wards/stakes (recruit via personal networks + sympathetic leaders). Focus on new movers and singles groups.
- Collect qualitative feedback on authenticity, pain relief, privacy comfort.
- Refine standards language and moderation process.

### Phase 1 — MVP Beta (8–12 weeks)
- Limited public beta in 2–3 metros.
- Invite-only or "request access" + leader referral to build quality.
- Seed 20–30 high-quality starter events per area via volunteers.
- Iterate on creation flow, discovery relevance, notifications.
- Success criteria: >40% of beta users create or join at least one event; positive feedback on "feels LDS" and "helped me meet people."; **low standards violation rate (<1% of events flagged/removed); fake account rate <1% via review process**.

### Phase 2 — App Store Launch (target 3–4 months from start)
- Full public launch on iOS and Android in initial regions.
- Marketing: Targeted LDS Facebook/Instagram groups, r/latterdaysaints (respectful), stake newsletters (with leader permission), Activity Sharing page cross-promotion where appropriate, word-of-mouth from early users.
- Onboarding incentives: "Host your first event and earn a 'Pioneer Host' badge."
- Monitor for critical mass signals and spam.

### Phase 3 — Expansion & Maturation
- Add more metros and rural/stake-level discovery.
- Post-MVP features (recurring, groups, history).
- Explore light partnerships or links with Activity Sharing.
- Internationalization (Spanish first, following Church languages).
- Establish sustainable moderation (community + paid part-time).

### Success Metrics & Guardrails
- Primary: Real-world friendships formed (proxy: repeat attendees, user testimonials).
- Secondary: Consistent weekly active events in launch areas; low report rate (<1%).
- Guardrails: Zero tolerance for standards violations; rapid response to privacy complaints.

**Seeding Playbook (Added for rollout practicality)**:
- **Initial hosts recruitment (Phase 0/1)**: Target 5–10 volunteers per metro from: personal networks, sympathetic ward/stake leaders (via private outreach), YSA institute groups, mid-singles Facebook/Reddit communities, family ward RS/EQ counselors known for activity planning. Aim for mix of YSA, mid-singles, families.
- **Starter event templates** (drawn from research): 
  - "Welcome New Movers Hike" (Physical + Social; approx trailhead pin)
  - "FHE-style Game Night" (Social; recurring note "weekly")
  - "Service Project - Heart Attack or Neighborhood Cleanup" (Social/Service)
  - "Scripture Study & Potluck" (Spiritual + Social)
  - "Family History Night / Career Discussion" (Intellectual)
  - "Basketball or Outdoor Sports" (Physical)
  Quality bar: uplifting description, clear 4-area tags, standards-compliant title, public or post-RSVP location as appropriate, host provides contact safety note.
- **Incentives**: "Pioneer Host" in-app badge + shoutout in early comms; non-monetary recognition.
- **KPIs for expansion**: 50%+ of seeded events achieve 5+ RSVPs within 2 weeks; at least 3 recurring patterns emerging per area before widening radius or adding cities. If slow: fallback to 5-10mi radius or stake-focused manual invites.
- **Risk mitigation**: Pre-seed 20–30 events before beta open; monitor adoption weekly. Reference in PR9 (seeding tools/scripts). Contingency in Open Questions.

---

## Open Questions

1. **Verification strength**: MVP uses strengthened self-attestation (explicit ban language) + mandatory phone + required photo + light human review queue for new accounts/first creations. Is this sufficient long-term, or should there be a low-friction "ward leader confirmation" flow that still protects privacy? How to handle edge cases (recent converts, investigators, less-active members)? Beta success criteria: monitor and report fake/spam account rate (<1% target); refine based on Phase 0/1 data.
2. **Public visibility**: Should certain events eventually be visible to non-members (to support "love, share, and invite" like Activity Sharing), or stay strictly within the member community for safety and focus?
3. **Geographic model precision**: Default radius of 15 miles works in many U.S. areas but not all. How to handle stakes with large geographic spread or international contexts? Should optional stake-boundary data be incorporated later?
4. **Youth and families**: What is the right path for including families with children or youth activities? Requires parental consent, age gates, and possibly separate flows. When to tackle?
5. **Church relationship**: What is the desired (or possible) long-term relationship with the Church's digital teams? Could this become a recommended complementary tool, or must it remain fully independent?
6. **Sustainability**: Funding model? (Donations, small premium features for hosts, grants, eventual sponsorship?) How to fund moderation at scale?
7. **Feature creep risk**: How aggressively to push back on requests for directory-like features or official calendar sync that would change the app's character?

---

## PR Plan

The following breaks the work into concrete, independently reviewable pull requests ordered for logical dependencies and incremental value. Each PR should include tests, docs updates, and screenshots where relevant. Assume a monorepo or clear client/server split.

**PR1: Project bootstrap and foundational auth**  
Files/components: `app/` (Flutter project init or RN), `pubspec.yaml` / `package.json`, auth screens (email/phone signup/login + **mandatory phone verification**), Supabase/Firebase project setup + env, basic navigation shell, privacy policy + terms stub (including explicit attestation text and ban consequences), onboarding skeleton. **Backend infra: initial Supabase project, auth config (email/phone), basic RLS policies for users table, storage bucket + policies for avatars/photos, basic Reports/NotificationLog table stubs.**  
Dependencies: None.  
Description: Scaffolds the mobile app, sets up secure auth with self-attestation (explicit wording) + phone verification, basic profile storage, and legal docs. Includes location permission explanation screen and photo upload stub (enforced in PR2). **Verification queue stub and basic review flag in backend for new accounts**. **Deliverables include: supabase/config/, supabase/migrations/001_init_users_rls.sql, storage policies doc, FCM/APNs initial config notes (certs/keys in secure env).** Deliverable: Runnable app that lets a user sign up (with photo+phone+attest) and see limited home screen; full discovery/creation gated until review (enforced here and PR2). RLS and basic infra foundation laid.

**PR2: User profiles and interest model**  
Files: Profile creation/edit flow, interest taxonomy (hard-coded list derived from 4 areas + common tags), profile data model + backend schema, **required avatar upload + activation gate**, verification review flag enforcement.  
Dependencies: PR1.  
Description: Implements profile fields (display name, age range, bio, interests multi-select, optional ward/stake, coarse location city). **Photo required to unlock full verified access; initial signup review queue integration**. Ensures privacy notes are shown. Adds "My Profile" tab. Moves basic verification enforcement early for safe beta.

**PR3: Event data model, creation wizard, and basic persistence**  
Files: Event schema (Supabase migrations), create event screens (wizard with templates, tag picker, date/time, **location picker + privacy tier selector + geocoding integration**, recurring checkbox + recurrence_note), backend event CRUD + geo indexing setup, **keyword/pattern filter enforcement on create + standards banner UI + basic report submission**.  
Dependencies: PR1, PR2.  
Description: Core ability to create and store events with 4-area tagging, location (address + lat/lon + location_type + location_privacy + address masking logic), **minimal is_recurring + recurrence_note for MVP discoverability of recurring patterns (e.g. FHE-style from research)**, and standards reminder UI. **Explicit initial keyword filters (list: alcohol, tobacco, coffee/tea, "bar"/"drinks", dating phrases, immodest) + non-dismissible standards callout at creation.** Includes draft saving and basic report flow. First-host/new-user review queuing hooks. Geocoding integration and tiered visibility. **Specific infra: PostGIS extension enable (if Supabase Postgres), migrations/002_events_geo_rls.sql (full initial schema incl. Events + RSVPs + initial Reports), docs/RLS-policies.md, realtime subscriptions setup for RSVPs.** (Full moderation queue/dashboard in PR7.) This advances key safety to support safe early beta. (Full recurring series in PR11.)

**PR4: Discovery feed, map view, and filters**  
Files: Home/Discover screen, map integration (Google/Apple/Mapbox), list view, filter UI (distance, tags, date, age group, **basic recurring indicator/filter**), backend geo-radius query endpoints.  
Dependencies: PR3.  
Description: Users can browse events near their location. Default 15-mile radius with clear controls. Personalized "recommended for you" based on interests. Includes support for MVP minimal recurring fields. Location pins respect privacy tiers (exact vs approx). Geocoding results rendered.

**PR5: RSVP, My Activities, and notifications foundation**  
Files: RSVP model + flows, "My Activities" tab, push notification registration + basic event reminder sending (FCM/APNs), calendar export (ICS), **coarse geo topic / client geofence support per Location Data Lifecycle**.  
Dependencies: PR3, PR4.  
Description: Full join experience + reminders. Users see their going/maybe events. Backend supports push topics per event. **"Near you" notifications respect coarse storage / on-device computation and explicit consent; no persistent precise user home location.** "Hide location" support.

**PR6: Basic profiles, attendee visibility, and in-app messaging (limited)**  
Files: Public profile view (limited), attendee list (count + opt-in), simple chat between confirmed attendees or opt-in contacts. Block/report.  
Dependencies: PR2, PR5.  
Description: Enables light social connection without full social network. Privacy controls enforced.

**PR7: Moderation, standards enforcement, and admin tools**  
Files: Report flow enhancements, full moderation queue (admin dashboard or simple backend UI), event hide/delete, guidelines copy throughout, admin auth. **Admin access setup (supabase roles/RLS for mod users), dashboard UI.**  
Dependencies: PR3, PR5.  
Description: Full safety and standards guardrails + admin dashboard. Builds on early keyword/review in PR1/PR3. First-time host + new user review path fully operational. Admin can action reports quickly. Includes success metrics tracking for fake accounts. Completes infra from PR1 (e.g. storage, realtime if needed for queue).

**PR8: Offline support, caching, and polish**  
Files: Local event cache, offline map handling, draft persistence, improved empty states, loading skeletons, accessibility audit.  
Dependencies: PR4, PR5.  
Description: Makes the app usable without constant connectivity — critical for real-world use.

**PR9: Onboarding refinement, seeding tools, and analytics**  
Files: Improved onboarding with values education, admin seeding scripts or UI for initial events, basic analytics instrumentation (non-PII), metrics dashboard.  
Dependencies: PR1–PR5.  
Description: Drives activation and early critical mass. Includes "new mover" welcome experience. **Refines 4-area balance UI, consent screens, and education copy from MVP outline in UI/UX.**

**PR10: App store readiness, legal finalization, and beta distribution**  
Files: App icons, splash, store listings, full privacy policy/TOS with data deletion, age gates, final security review, TestFlight / internal testing tracks, beta access gating. **Includes trademark search report, final branding/disclaimer assets, map/geocoding/FCM API key management docs.**  
Dependencies: All prior.  
Description: Production-ready binaries and compliance artifacts for limited beta. Completes legal (trademark, name usage) and infra configs (keys, push certs).

**PR11: Post-MVP foundation (advanced recurring events + basic groups)**  
Files: Advanced recurring event model (series instances, editing), interest group creation (public/semi-public), follow interests.  
Dependencies: MVP complete (PR1–PR10).  
Description: Builds on MVP's minimal is_recurring/recurrence_note. First expansion for full recurring series management + groups.

**PR12: Expansion & integration hooks**  
Files: Multi-region support, optional links to Activity Sharing web pages, export to personal calendar improvements, initial Spanish localization strings.  
Dependencies: PR10+.  
Description: Prepares for broader rollout and complementarity with official tools.

---

*End of Design Document*

**References Incorporated**: Full research summary at `/tmp/lds-app-research-542ba855.md`, official Church structure and recent Activity Sharing resources (2025–2026), Children & Youth program documentation, documented user pain points from community sources, and best practices from location-based discovery apps adapted to LDS context.