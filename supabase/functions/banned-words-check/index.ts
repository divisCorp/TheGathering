// Supabase Edge Function: Banned Words Check
// Deploy with: supabase functions deploy banned-words-check
// Use in client or as a trigger/hook for event creation.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const BANNED_WORDS = [
  "alcohol", "beer", "wine", "bar", "drinks", "tobacco", "vape", 
  "dating", "hookup", "hookah", "cannabis", "weed", "sex", "nude"
];

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!  // Use service key for server-side
  );

  const { title, description } = await req.json();

  const text = `${title} ${description || ""}`.toLowerCase();
  const hasBanned = BANNED_WORDS.some(word => text.includes(word));

  if (hasBanned) {
    return new Response(
      JSON.stringify({ 
        allowed: false, 
        reason: "Content contains prohibited words" 
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  }

  return new Response(
    JSON.stringify({ allowed: true }),
    { headers: { "Content-Type": "application/json" } }
  );
});