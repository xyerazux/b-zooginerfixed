# Supabase Edge Function: `manage-bzooginer-account`

Edge Function ini menyediakan operasi administratif aman untuk pengelolaan akun B-Zooginer oleh Superadmin menggunakan Supabase Auth Admin API di sisi server.

## Arsitektur Keamanan Berlapis (Defense-in-Depth)

1. **Lapisan 1 (API Gateway)**:
   - Supabase Edge Functions memverifikasi validitas JWT secara default saat fungsi dideploy.
2. **Lapisan 2 (Verifikasi Kriptografis In-Code)**:
   - Kode fungsi membaca header `Authorization: Bearer <token>` dan memvalidasi keaslian token melalui `supabaseClient.auth.getUser(token)`.
   - Identitas pengguna (`callerUser.id`) diambil langsung dari hasil verifikasi token Auth server, bukan dari input payload body.
3. **Lapisan 3 (Verifikasi Role & Status Database)**:
   - Mengambil data profil pemanggil dari `public.bzooginer_profiles` menggunakan UUID terverifikasi.
   - Hanya pengguna dengan `role === 'superadmin'` dan `is_active === true` yang diizinkan melanjutkan. Admin kelompok langsung ditolak dengan `403 Forbidden`.
4. **Lapisan 4 (Perlindungan Akun Master & Pencegahan Lockout)**:
   - Username akun master `superadmin` dilindungi agar tidak dapat diubah atau dihapus.
   - Superadmin tidak dapat menonaktifkan atau menghapus akunnya sendiri.
   - Sistem mencegah penonaktifan atau penghapusan Superadmin aktif terakhir di sistem.
   - Reset kata sandi untuk akun Superadmin mewajibkan kata sandi baru dimasukkan secara eksplisit (minimal 8 karakter).
5. **Lapisan 5 (Sanitasi Error & Isolasi Secret)**:
   - `SUPABASE_SERVICE_ROLE_KEY` hanya diakses melalui environment runtime server Supabase (`Deno.env.get`) dan tidak pernah dikirim ke browser, HTML, JavaScript frontend, repository, atau response JSON.
   - Pesan error internal disanitasi sehingga tidak membocorkan struktur teknis database.

---

## Environment Variables yang Dibutuhkan

Edge Function ini memanfaatkan environment secrets standar yang disediakan otomatis oleh Supabase runtime:
- `SUPABASE_URL`: URL project Supabase Anda.
- `SUPABASE_ANON_KEY`: Public anon key project Anda.
- `SUPABASE_SERVICE_ROLE_KEY`: Service role key dari project Supabase Anda.

---

## Cara Deploy ke Supabase

Jalankan perintah berikut melalui terminal di root project:

```bash
# Deploy Edge Function dengan flag non-interaktif
npx supabase functions deploy manage-bzooginer-account --yes
```

---

## Payload Request

### 1. Tambah Akun Baru
**POST** `https://<project-ref>.supabase.co/functions/v1/manage-bzooginer-account`
Headers:
- `Authorization: Bearer <SUPERADMIN_ACCESS_TOKEN>`
- `Content-Type: application/json`

Body:
```json
{
  "action": "create-account",
  "username": "admin_kel6",
  "password": "PasswordAman123!",
  "role": "group_admin",
  "groupId": 6
}
```

### 2. Ubah Username
**POST** `https://<project-ref>.supabase.co/functions/v1/manage-bzooginer-account`
Headers:
- `Authorization: Bearer <SUPERADMIN_ACCESS_TOKEN>`
- `Content-Type: application/json`

Body:
```json
{
  "action": "update-username",
  "targetUserId": "UUID-TARGET-ACCOUNT",
  "newUsername": "admin_kel1_baru"
}
```

### 3. Ganti / Reset Kata Sandi
**POST** `https://<project-ref>.supabase.co/functions/v1/manage-bzooginer-account`
Headers:
- `Authorization: Bearer <SUPERADMIN_ACCESS_TOKEN>`
- `Content-Type: application/json`

Body (dengan kata sandi eksplisit):
```json
{
  "action": "reset-password",
  "targetUserId": "UUID-TARGET-ACCOUNT",
  "newPassword": "KataSandiBaruKuat123"
}
```

Body (generate kata sandi sementara otomatis untuk admin kelompok):
```json
{
  "action": "reset-password",
  "targetUserId": "UUID-TARGET-ACCOUNT"
}
```

### 4. Nonaktifkan / Aktifkan Kembali Akun
**POST** `https://<project-ref>.supabase.co/functions/v1/manage-bzooginer-account`
Headers:
- `Authorization: Bearer <SUPERADMIN_ACCESS_TOKEN>`
- `Content-Type: application/json`

Body:
```json
{
  "action": "toggle-active",
  "targetUserId": "UUID-TARGET-ACCOUNT",
  "isActive": false
}
```

### 5. Hapus Akun Permanen
**POST** `https://<project-ref>.supabase.co/functions/v1/manage-bzooginer-account`
Headers:
- `Authorization: Bearer <SUPERADMIN_ACCESS_TOKEN>`
- `Content-Type: application/json`

Body:
```json
{
  "action": "delete-account",
  "targetUserId": "UUID-TARGET-ACCOUNT"
}
```
