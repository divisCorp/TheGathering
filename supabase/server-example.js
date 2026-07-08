/**
 * Example server request handler using @supabase/server
 *
 * Install in a server/JS project:
 *   npm install @supabase/server
 *
 * Usage with a compatible server (e.g. Edge Functions, Workers, custom fetch handlers):
 *
 * The helper provides:
 * - ctx.supabase : RLS-scoped client (respects user auth + RLS policies)
 * - ctx.supabaseAdmin : Admin client that bypasses RLS (use carefully, for server-only ops)
 *
 * Auth modes:
 * - "user": requires valid user JWT (from logged-in client)
 * - "publishable": uses publishable/anon key
 * - "secret": uses service role secret key
 * - "none": no auth
 *
 * On Supabase Edge Functions, the env vars are automatically injected.
 * For non-"user" auth, you may need `verify_jwt = false` in supabase/config.toml for the function.
 */

import { withSupabase } from "@supabase/server";

export default {
  fetch: withSupabase({ auth: "user" }, async (req, ctx) => {
    const { data, error } = await ctx.supabase
      .from("profiles")
      .select("id, display_name, city, interests")
      .limit(10);

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    return Response.json({ profiles: data });
  }),
};

// Example using admin client (bypasses RLS - server only)
export const adminExample = withSupabase({ auth: "secret" }, async (_req, ctx) => {
  // Use ctx.supabaseAdmin for privileged operations
  const { data } = await ctx.supabaseAdmin
    .from("profiles")
    .select("*")
    .eq("is_verified_member", true);

  return Response.json(data);
});

// Example for a simple public (publishable) endpoint
export const publicStats = withSupabase({ auth: "publishable" }, async (_req, ctx) => {
  const { count } = await ctx.supabase
    .from("profiles")
    .select("*", { count: "exact", head: true });

  return Response.json({ totalProfiles: count });
});
