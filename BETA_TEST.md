# The Gathering — Beta test (owner-operated)

You are the primary tester. I’m driving product & code; you provide human feedback and any Dashboard clicks I can’t do remotely.

## Live app
https://diviscorp.github.io/TheGathering/#/auth  

Hard refresh if the UI looks stale: **Cmd+Shift+R** (or private window).

---

## One-time Supabase setup (you — ~5 minutes)

Open [Supabase SQL Editor](https://supabase.com/dashboard/project/dhryaddmqbbgekezskpl/sql) and **run the entire file**:

`supabase/beta_setup.sql`

That creates:
- profile insert + public-read policies  
- `avatars` storage bucket + policies  
- `nearby_events` with lat/lon  
- `set_event_location` helper  

Then in **Authentication**:

1. **URL configuration**
   - Site URL: `https://diviscorp.github.io/TheGathering/`
   - Redirect URLs: `https://diviscorp.github.io/TheGathering/**`
2. **Providers → Email** (recommended for beta): turn **OFF “Confirm email”** so Sign Up → immediate session  
   - If you leave Confirm ON: check email/spam after Create Account, click link, then Sign In
3. Phone provider: optional for now (currently disabled)

---

## Your test script (20–30 min)

### A. Auth
1. Create Account with real email + password + phone (any E.164 e.g. `+18015551212`) + check attestation  
2. Expect either OTP step, “check email”, or direct entry  
3. Sign In works after confirm (if required)

### B. Profile
1. Profile tab → Edit  
2. Name, city, 3–5 interests, optional photo  
3. Save — should succeed  

### C. Discovery seed
1. Discover tab  
2. Allow location (or accept default SLC pin)  
3. If empty → **Load sample activities near me**  
4. Map pins + list should fill  
5. Tap an event → RSVP Going / Maybe  

### D. Create real event
1. Create tab → pick template “Hike” or “Game Night”  
2. Use current location  
3. Publish  
4. See it on Discover / My Activities  

### E. Report what only a human notices
- Confusing copy  
- Layout broken on your phone browser  
- Buttons that feel dead  
- Anything embarrassing before other people join  

Send feedback as: **steps → expected → actual → device/browser**.

---

## Optional SQL if discovery empties after a schema change
Run `supabase/shipping_rls_beta.sql` so signed-in users can always view active events + submit reports.

## New things to poke
- Event detail → **Add to calendar** (Google or copy ICS)  
- Event ⋮ menu → **Report activity**  
- Host: ⋮ → Edit / Cancel activity  
- My Activities → tap hosted/RSVP rows for detail  

## Known beta limits
- Web first (GitHub Pages); native stores later  
- Push notifications not done  
- Phone SMS often off until Twilio + Phone provider enabled  
- Realtime RSVP live-updates off (pull to refresh)  
- Not affiliated with The Church of Jesus Christ of Latter-day Saints  

---

## After you finish the SQL setup
Reply: **“SQL done”** (and whether email confirm is on or off).  
I’ll verify end-to-end against the API and keep shipping fixes from your notes.
