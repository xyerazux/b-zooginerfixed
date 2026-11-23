// Supabase Edge Function: manage-bzooginer-account
// Securely manage user credentials (username, email, password) by Superadmin only

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function generateStrongPassword(length = 14): string {
  const chars = "abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%&*";
  let res = "";
  const buf = new Uint8Array(length);
  crypto.getRandomValues(buf);
  for (let i = 0; i < length; i++) {
    res += chars[buf[i] % chars.length];
  }
  return res;
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(
        JSON.stringify({ error: "Server configuration missing required environment variables." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Verify Caller Authentication via JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return new Response(
        JSON.stringify({ error: "Missing or invalid Authorization header." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    const token = authHeader.replace("Bearer ", "").trim();

    // Client with caller's token for auth verification
    const callerClient = createClient(supabaseUrl, supabaseAnonKey || serviceRoleKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
      auth: { persistSession: false },
    });

    const { data: { user: callerUser }, error: callerError } = await callerClient.auth.getUser(token);
    if (callerError || !callerUser) {
      return new Response(
        JSON.stringify({ error: "Session tidak valid atau sudah kedaluwarsa. Silakan login kembali." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Client with Service Role Key for Admin Operations & Role Check
    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    // Verify caller is superadmin in bzooginer_profiles
    const { data: callerProfile, error: profileErr } = await adminClient
      .from("bzooginer_profiles")
      .select("role, username")
      .eq("id", callerUser.id)
      .single();

    if (profileErr || !callerProfile || callerProfile.role !== "superadmin") {
      return new Response(
        JSON.stringify({ error: "Akses ditolak: Operasi ini hanya diizinkan untuk Superadmin." }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Parse Request Payload
    const body = await req.json();
    const { action, targetUserId } = body;

    if (!targetUserId) {
      return new Response(
        JSON.stringify({ error: "Target user ID wajib disertakan." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Verify target user exists in bzooginer_profiles
    const { data: targetProfile, error: targetProfileErr } = await adminClient
      .from("bzooginer_profiles")
      .select("id, username, role, group_id")
      .eq("id", targetUserId)
      .single();

    if (targetProfileErr || !targetProfile) {
      return new Response(
        JSON.stringify({ error: "Target akun tidak ditemukan di database." }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Handle Actions
    if (action === "update-username") {
      const rawUsername = body.newUsername;
      if (!rawUsername || typeof rawUsername !== "string") {
        return new Response(
          JSON.stringify({ error: "Username baru tidak boleh kosong." }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
      const newUsername = rawUsername.trim().toLowerCase();
      if (!/^[a-z0-9_]{3,24}$/.test(newUsername)) {
        return new Response(
          JSON.stringify({ error: "Username harus 3-24 karakter (huruf kecil, angka, atau garis bawah)." }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Check duplicate in bzooginer_profiles
      const { data: existingUser } = await adminClient
        .from("bzooginer_profiles")
        .select("id")
        .eq("username", newUsername)
        .neq("id", targetUserId)
        .maybeSingle();

      if (existingUser) {
        return new Response(
          JSON.stringify({ error: `Username '${newUsername}' sudah digunakan akun lain.` }),
          { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const newEmail = `${newUsername}@example.com`;

      // Update Supabase Auth user email
      const { error: authUpdateErr } = await adminClient.auth.admin.updateUserById(targetUserId, {
        email: newEmail,
        user_metadata: { username: newUsername },
      });
      if (authUpdateErr) {
        return new Response(
          JSON.stringify({ error: `Gagal memperbarui Auth email: ${authUpdateErr.message}` }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Update profile record in bzooginer_profiles
      const { error: profileUpdateErr } = await adminClient
        .from("bzooginer_profiles")
        .update({ username: newUsername })
        .eq("id", targetUserId);

      if (profileUpdateErr) {
        return new Response(
          JSON.stringify({ error: `Gagal memperbarui profil: ${profileUpdateErr.message}` }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({
          success: true,
          message: `Username akun berhasil diubah menjadi '${newUsername}' (${newEmail}).`,
          targetUserId,
          username: newUsername,
          email: newEmail,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );

    } else if (action === "reset-password") {
      let tempPassword = body.newPassword;
      let isGenerated = false;

      if (!tempPassword || typeof tempPassword !== "string" || tempPassword.trim().length === 0) {
        tempPassword = generateStrongPassword(14);
        isGenerated = true;
      } else {
        tempPassword = tempPassword.trim();
        if (tempPassword.length < 6) {
          return new Response(
            JSON.stringify({ error: "Kata sandi minimal 6 karakter." }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }
      }

      // Update password in Supabase Auth via Admin API
      const { error: pwErr } = await adminClient.auth.admin.updateUserById(targetUserId, {
        password: tempPassword,
      });

      if (pwErr) {
        return new Response(
          JSON.stringify({ error: `Gagal mereset kata sandi: ${pwErr.message}` }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({
          success: true,
          message: `Kata sandi akun ${targetProfile.username} berhasil direset.`,
          targetUserId,
          username: targetProfile.username,
          temporaryPassword: tempPassword,
          isGenerated,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );

    } else {
      return new Response(
        JSON.stringify({ error: `Aksi '${action}' tidak dikenali. Pilihan: 'update-username', 'reset-password'.` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message || "Terjadi kesalahan internal server." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
