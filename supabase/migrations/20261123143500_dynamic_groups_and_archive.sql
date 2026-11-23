-- Migration: Dynamic Group Management and Archive Support
-- Safe, idempotent migration for B-Zooginer

-- 1. Tambah kolom is_active pada tabel bzooginer_groups (default true untuk semua kelompok)
ALTER TABLE public.bzooginer_groups
ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

-- 2. Trigger untuk memastikan hanya Superadmin yang boleh mengubah status is_active kelompok,
--    dan admin kelompok yang dinonaktifkan tidak boleh melakukan modifikasi data kelompok.
CREATE OR REPLACE FUNCTION public.check_bzooginer_group_update()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Validasi perubahan is_active: hanya Superadmin
  IF NEW.is_active IS DISTINCT FROM OLD.is_active THEN
    IF NOT public.is_bzooginer_superadmin() THEN
      RAISE EXCEPTION 'Hanya Superadmin yang berwenang mengubah status aktif/arsip kelompok.';
    END IF;
  END IF;

  -- Jika kelompok sedang tidak aktif dan bukan Superadmin, tolak modifikasi
  IF OLD.is_active = FALSE AND NEW.is_active = FALSE THEN
    IF NOT public.is_bzooginer_superadmin() THEN
      RAISE EXCEPTION 'Kelompok sedang dinonaktifkan (diarsipkan). Hubungi Superadmin.';
    END IF;
  END IF;

  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_bzooginer_group_update ON public.bzooginer_groups;
CREATE TRIGGER trg_bzooginer_group_update
BEFORE UPDATE ON public.bzooginer_groups
FOR EACH ROW
EXECUTE FUNCTION public.check_bzooginer_group_update();

-- 3. Trigger untuk memvalidasi pesanan baru hanya boleh dibuat untuk kelompok yang aktif
CREATE OR REPLACE FUNCTION public.check_bzooginer_order_active_group()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_is_active BOOLEAN;
BEGIN
  SELECT is_active INTO v_is_active
  FROM public.bzooginer_groups
  WHERE id = NEW.group_id;

  IF v_is_active IS NULL THEN
    RAISE EXCEPTION 'Kelompok dengan ID % tidak ditemukan.', NEW.group_id;
  ELSIF v_is_active = FALSE THEN
    RAISE EXCEPTION 'Kelompok ini sedang dinonaktifkan (diarsipkan) dan tidak dapat menerima pesanan baru.';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_bzooginer_order_active_group ON public.bzooginer_orders;
CREATE TRIGGER trg_bzooginer_order_active_group
BEFORE INSERT ON public.bzooginer_orders
FOR EACH ROW
EXECUTE FUNCTION public.check_bzooginer_order_active_group();

-- 4. Policy agar Superadmin dapat memperbarui group_id pada bzooginer_profiles
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'bzooginer_profiles'
      AND policyname = 'profiles_update_superadmin'
  ) THEN
    CREATE POLICY "profiles_update_superadmin"
    ON public.bzooginer_profiles
    FOR UPDATE
    TO authenticated
    USING (public.is_bzooginer_superadmin())
    WITH CHECK (public.is_bzooginer_superadmin());
  END IF;
END $$;
