-- Migration: Enable Supabase Realtime Publication for Orders and Groups
-- Safe, additive, idempotent migration for B-Zooginer Phase 3

-- 1. Atur REPLICA IDENTITY FULL agar payload event UPDATE dan DELETE menyertakan data lengkap
ALTER TABLE public.bzooginer_orders REPLICA IDENTITY FULL;
ALTER TABLE public.bzooginer_groups REPLICA IDENTITY FULL;

-- 2. Daftarkan tabel ke publikasi supabase_realtime secara idempotent
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'bzooginer_orders'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bzooginer_orders;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'bzooginer_groups'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bzooginer_groups;
  END IF;
END $$;
