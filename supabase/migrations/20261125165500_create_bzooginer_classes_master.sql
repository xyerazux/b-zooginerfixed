-- Migration: Master Data Kelas (bzooginer_classes)
-- Safe, additive, idempotent migration for B-Zooginer Phase 2

-- 1. Buat tabel master data kelas jika belum ada
CREATE TABLE IF NOT EXISTS public.bzooginer_classes (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  grade TEXT NOT NULL DEFAULT '',
  major TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL DEFAULT 'Akademik',
  sort_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index untuk performa sorting dan filter
CREATE INDEX IF NOT EXISTS idx_bzooginer_classes_active_sort 
ON public.bzooginer_classes(is_active, sort_order);

-- 2. Aktifkan Row Level Security (RLS)
ALTER TABLE public.bzooginer_classes ENABLE ROW LEVEL SECURITY;

-- 3. Kebijakan RLS:
--    - Publik (anon & authenticated) dapat membaca daftar kelas aktif untuk keperluan dropdown PO
--    - Superadmin dapat mengelola (insert, update, delete) master data kelas
DROP POLICY IF EXISTS "classes_read_all" ON public.bzooginer_classes;
DROP POLICY IF EXISTS "classes_write_superadmin" ON public.bzooginer_classes;

CREATE POLICY "classes_read_all"
ON public.bzooginer_classes
FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "classes_write_superadmin"
ON public.bzooginer_classes
FOR ALL
TO authenticated
USING (public.is_bzooginer_superadmin())
WITH CHECK (public.is_bzooginer_superadmin());

-- 4. Initial Seed Data: 17 Kelas Akademik Standar (termasuk konsolidasi XI RPL 1) + Kategori Khusus
INSERT INTO public.bzooginer_classes (name, grade, major, category, sort_order, is_active)
VALUES
  -- Tingkat X
  ('X DKV 1', 'X', 'DKV', 'Akademik', 10, true),
  ('X DKV 2', 'X', 'DKV', 'Akademik', 20, true),
  ('X RPL 1', 'X', 'RPL', 'Akademik', 30, true),
  ('X RPL 2', 'X', 'RPL', 'Akademik', 40, true),
  ('X TKJ 1', 'X', 'TKJ', 'Akademik', 50, true),
  ('X TKJ 2', 'X', 'TKJ', 'Akademik', 60, true),
  ('X TKJ 3', 'X', 'TKJ', 'Akademik', 70, true),

  -- Tingkat XI (XI RPL & 11 rpl dikonsolidasi ke XI RPL 1 sesuai persetujuan)
  ('XI DKV 1', 'XI', 'DKV', 'Akademik', 80, true),
  ('XI DKV 2', 'XI', 'DKV', 'Akademik', 90, true),
  ('XI RPL 1', 'XI', 'RPL', 'Akademik', 100, true),
  ('XI TKJ 1', 'XI', 'TKJ', 'Akademik', 110, true),

  -- Tingkat XII
  ('XII DKV 1', 'XII', 'DKV', 'Akademik', 120, true),
  ('XII DKV 2', 'XII', 'DKV', 'Akademik', 130, true),
  ('XII RPL 1', 'XII', 'RPL', 'Akademik', 140, true),
  ('XII RPL 2', 'XII', 'RPL', 'Akademik', 150, true),
  ('XII TKJ 1', 'XII', 'TKJ', 'Akademik', 160, true),
  ('XII TKJ 2', 'XII', 'TKJ', 'Akademik', 170, true),

  -- Kategori Khusus & Fallback
  ('Guru / Staf', 'Khusus', 'Staf', 'Khusus', 180, true),
  ('Lainnya / Umum', 'Umum', 'Umum', 'Lainnya', 190, true)
ON CONFLICT (name) DO UPDATE SET
  grade = EXCLUDED.grade,
  major = EXCLUDED.major,
  category = EXCLUDED.category,
  sort_order = EXCLUDED.sort_order,
  is_active = EXCLUDED.is_active;
