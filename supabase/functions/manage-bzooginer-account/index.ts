// Supabase Edge Function: manage-bzooginer-account
// Securely manage user credentials (username, email, password) by verified Superadmin only

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const USERNAME_REGEX = /^[a-z0-9_]{3,24}$/;

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
  // 1. Handle CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  // 2. Enforce POST Method
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Metode HTTP tidak diizinkan. Gunakan POST." }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    // Environment sanity check - never fallback service role key into client
    if (!supabaseUrl || !supabaseAnonKey || !serviceRoleKey) {
      console.error("Missing required server environment variables.");
      return new Response(
        JSON.stringify({ error: "Konfigurasi server belum lengkap." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Extract & Validate Bearer Token
    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return new Response(
        JSON.stringify({ error: "Header Authorization tidak ditemukan atau format tidak valid." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    const token = authHeader.replace("Bearer ", "").trim();
    if (!token) {
      return new Response(
        JSON.stringify({ error: "Token akses kosong." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Verify JWT Signature & Identity using caller client (anon key only)
    const callerClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
      auth: { persistSession: false },
    });

    const { data: { user: callerUser }, error: callerError } = await callerClient.auth.getUser(token);
    if (callerError || !callerUser) {
      console.warn("JWT verification failed:", callerError?.message);
      return new Response(
        JSON.stringify({ error: "Sesi tidak valid atau telah kedaluwarsa. Silakan login kembali." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Initialize Server Admin Client (Service Role Key isolated to server-side only)
    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    // 6. Verify Caller Authorization in bzooginer_profiles
    const { data: callerProfile, error: profileErr } = await adminClient
      .from("bzooginer_profiles")
      .select("role, username")
      .eq("id", callerUser.id)
      .single();

    if (profileErr || !callerProfile || callerProfile.role !== "superadmin") {
      console.warn(`Unauthorized access attempt by user ${callerUser.id} (${callerProfile?.role || 'no profile'})`);
      return new Response(
        JSON.stringify({ error: "Akses ditolak: Operasi administratif ini hanya diizinkan untuk Superadmin." }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 7. Parse & Validate Payload
    let body: any;
    try {
      body = await req.json();
    } catch {
      return new Response(
        JSON.stringify({ error: "Format body JSON tidak valid." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { action, targetUserId } = body;

    if (!targetUserId || !UUID_REGEX.test(targetUserId)) {
      return new Response(
        JSON.stringify({ error: "Format ID target akun tidak valid (harus UUID)." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 8. Verify Target User Exists
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

    // 9. Execute Actions with Safety Guardrails
    if (action === "update-username") {
      const rawUsername = body.newUsername;
      if (!rawUsername || typeof rawUsername !== "string") {
        return new Response(
          JSON.stringify({ error: "Username baru tidak boleh kosong." }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const newUsername = rawUsername.trim().toLowerCase();
      if (!USERNAME_REGEX.test(newUsername)) {
        return new Response(
          JSON.stringify({ error: "Username harus 3-24 karakter (huruf kecil a-z, angka 0-9, atau garis bawah _)." }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Safeguard: Do not rename superadmin master account
      if (targetProfile.role === "superadmin" && targetProfile.username === "superadmin" && newUsername !== "superadmin") {
        return new Response(
          JSON.stringify({ error: "Username akun master Superadmin tidak dapat diubah demi stabilitas sistem." }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Check username collision in bzooginer_profiles
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

      // Update email & metadata in Supabase Auth via Admin API
      const { error: authUpdateErr } = await adminClient.auth.admin.updateUserById(targetUserId, {
        email: newEmail,
        user_metadata: { username: newUsername },
      });

      if (authUpdateErr) {
        console.error("Auth update error:", authUpdateErr.message);
        return new Response(
          JSON.stringify({ error: "Gagal memperbarui data login di Supabase Auth." }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Update username in bzooginer_profiles
      const { error: profileUpdateErr } = await adminClient
        .from("bzooginer_profiles")
        .update({ username: newUsername })
        .eq("id", targetUserId);

      if (profileUpdateErr) {
        console.error("Profile update error:", profileUpdateErr.message);
        return new Response(
          JSON.stringify({ error: "Gagal menyinkronkan profil database." }),
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

      // Safeguard: If target is Superadmin, require explicit password to prevent accidental lockout
      if (targetProfile.role === "superadmin") {
        if (!tempPassword || typeof tempPassword !== "string" || tempPassword.trim().length < 8) {
          return new Response(
            JSON.stringify({ error: "Pengubahan kata sandi Superadmin wajib memasukkan kata sandi baru secara eksplisit (minimal 8 karakter)." }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }
        tempPassword = tempPassword.trim();
      } else {
        // Group Admin: Allow explicit password or generate strong temporary password
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
      }

      // Update password via Supabase Admin API
      const { error: pwErr } = await adminClient.auth.admin.updateUserById(targetUserId, {
        password: tempPassword,
      });

      if (pwErr) {
        console.error("Password update error:", pwErr.message);
        return new Response(
          JSON.stringify({ error: "Gagal mereset kata sandi pada sistem Auth." }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({
          success: true,
          message: `Kata sandi akun ${targetProfile.username} berhasil diperbarui.`,
          targetUserId,
          username: targetProfile.username,
          temporaryPassword: tempPassword,
          isGenerated,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );

    } else {
      return new Response(
        JSON.stringify({ error: `Aksi '${action}' tidak valid. Pilihan: 'update-username', 'reset-password'.` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  } catch (err: any) {
    console.error("Internal unhandled error in manage-bzooginer-account:", err);
    return new Response(
      JSON.stringify({ error: "Terjadi kesalahan internal pada server saat memproses akun." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
