-- Migration: Account Management Enhancements (is_active, Security Helpers, and Policies)
-- Safe, idempotent migration for B-Zooginer

-- 1. Tambah kolom is_active pada bzooginer_profiles (default TRUE)
ALTER TABLE public.bzooginer_profiles
ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

UPDATE public.bzooginer_profiles
SET is_active = TRUE
WHERE is_active IS NULL;

-- 2. Perbarui helper functions agar hanya menganggap akun aktif sebagai superadmin / group_admin
CREATE OR REPLACE FUNCTION public.is_bzooginer_superadmin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.bzooginer_profiles
    WHERE id = auth.uid() AND role = 'superadmin' AND is_active = TRUE
  );
$$;

CREATE OR REPLACE FUNCTION public.is_bzooginer_group_admin(target_group_id integer)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.bzooginer_profiles
    WHERE id = auth.uid() AND role = 'group_admin' AND group_id = target_group_id AND is_active = TRUE
  );
$$;

-- 3. Policy INSERT dan DELETE untuk bzooginer_profiles oleh Superadmin
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'bzooginer_profiles'
      AND policyname = 'profiles_insert_superadmin'
  ) THEN
    CREATE POLICY "profiles_insert_superadmin"
    ON public.bzooginer_profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (public.is_bzooginer_superadmin());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'bzooginer_profiles'
      AND policyname = 'profiles_delete_superadmin'
  ) THEN
    CREATE POLICY "profiles_delete_superadmin"
    ON public.bzooginer_profiles
    FOR DELETE
    TO authenticated
    USING (public.is_bzooginer_superadmin());
  END IF;
END $$;
