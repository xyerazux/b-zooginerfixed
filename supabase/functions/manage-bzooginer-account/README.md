# Supabase Edge Function: `manage-bzooginer-account`

Edge Function ini menyediakan operasi administratif aman untuk pengelolaan akun B-Zooginer oleh Superadmin menggunakan Supabase Auth Admin API di sisi server.

## Fitur
1. **Verifikasi Otorisasi Superadmin**:
   - Memvalidasi token JWT pemanggil dari header `Authorization: Bearer <token>`.
   - Memastikan pemanggil terdaftar dengan `role = 'superadmin'` di tabel `public.bzooginer_profiles`.
   - Menolak semua permintaan dari role non-superadmin (403 Forbidden).
2. **Pembaruan Username**:
   - Memperbarui email di `auth.users` sesuai konvensi `<username>@example.com`.
   - Memperbarui `username` di tabel `public.bzooginer_profiles`.
   - Menolak duplikasi username.
3. **Reset Kata Sandi Aman**:
   - Mengubah kata sandi pengguna langsung di `auth.users` menggunakan Supabase Admin API.
   - Jika kata sandi baru tidak diisi oleh Superadmin, sistem men-generate kata sandi acak yang kuat (14 karakter aman).
   - Kata sandi sementara hanya dikembalikan sekali di response JSON agar dapat dicatat oleh Superadmin, dan **tidak disimpan** di database aplikasi, localStorage, atau log frontend.

---

## Environment Variables yang Dibutuhkan
Edge Function ini memerlukan secrets berikut di Supabase Dashboard:
- `SUPABASE_URL`: URL project Supabase Anda (tersedia otomatis di runtime Supabase).
- `SUPABASE_ANON_KEY`: Public anon key (tersedia otomatis di runtime Supabase).
- `SUPABASE_SERVICE_ROLE_KEY`: Secret service role key dari project Supabase Anda (tersedia otomatis di runtime Supabase).

---

## Cara Deploy ke Supabase

Jalankan perintah Supabase CLI berikut dari root project:

```bash
# 1. Login ke Supabase CLI (jika belum)
npx supabase login

# 2. Link ke project Supabase Anda
npx supabase link --project-ref ngpbhllbbjwebarwgqjr

# 3. Deploy Edge Function
npx supabase functions deploy manage-bzooginer-account --no-verify-jwt
```

Catatan: Parameter `--no-verify-jwt` memungkinkan fungsi menangani verifikasi JWT di dalam kode function sendiri, sehingga dapat memberikan pesan error yang jelas bagi pengguna.

---

## Endpoint Payload

### 1. Ubah Username
**POST** `https://<project-ref>.supabase.co/functions/v1/manage-bzooginer-account`
Headers:
- `Authorization: Bearer <SUPERADMIN_ACCESS_TOKEN>`
- `Content-Type: application/json`

Body:
```json
{
  "action": "update-username",
  "targetUserId": "uuid-target-account",
  "newUsername": "admin_kel1_baru"
}
```

### 2. Reset Password
**POST** `https://<project-ref>.supabase.co/functions/v1/manage-bzooginer-account`
Headers:
- `Authorization: Bearer <SUPERADMIN_ACCESS_TOKEN>`
- `Content-Type: application/json`

Body:
```json
{
  "action": "reset-password",
  "targetUserId": "uuid-target-account",
  "newPassword": "OptionalNewPassword123" 
}
```
*(Jika `newPassword` dikosongkan, fungsi akan men-generate kata sandi sementara 14 karakter secara otomatis).*
