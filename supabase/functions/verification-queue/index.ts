// Supabase Edge Function: Verification Queue
// This can be triggered on new user signup or profile creation.
// Deploy: supabase functions deploy verification-queue

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const { userId } = await req.json();

  if (!userId) {
    return new Response("Missing userId", { status: 400 });
  }

  // Example: Create a review task or flag the profile
  const { error } = await supabase
    .from("profiles")
    .update({ 
      verification_status: "pending_review",
      is_verified_member: false 
    })
    .eq("id", userId);

  if (error) {
    console.error(error);
    return new Response("Failed to queue", { status: 500 });
  }

  // In a real system, this could insert into a "review_queue" table
  // or send a notification to admins.

  return new Response(JSON.stringify({ 
    success: true, 
    message: "User queued for review" 
  }), {
    headers: { "Content-Type": "application/json" },
  });
});