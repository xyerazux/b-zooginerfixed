-- Migration: Order Edit Capabilities, Updated At Tracking, Audit Logs, and RLS Policies
-- Safe, additive, idempotent migration for B-Zooginer

-- 1. Tambah kolom updated_at pada public.bzooginer_orders jika belum ada
ALTER TABLE public.bzooginer_orders
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Set nilai default updated_at untuk baris yang sudah ada
UPDATE public.bzooginer_orders
SET updated_at = COALESCE(created_at, NOW())
WHERE updated_at IS NULL;

-- 2. Trigger otomatis pembaruan updated_at pada bzooginer_orders
CREATE OR REPLACE FUNCTION public.handle_bzooginer_order_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_bzooginer_order_updated_at ON public.bzooginer_orders;
CREATE TRIGGER trg_bzooginer_order_updated_at
BEFORE UPDATE ON public.bzooginer_orders
FOR EACH ROW
EXECUTE FUNCTION public.handle_bzooginer_order_updated_at();

-- 3. RLS UPDATE Policy untuk bzooginer_orders:
--    - Superadmin dapat mengedit pesanan apa pun
--    - Group Admin hanya dapat mengedit pesanan milik kelompoknya sendiri
--    - Mencegah perpindahan pesanan ke kelompok lain oleh Group Admin
DROP POLICY IF EXISTS "orders_update_authorized" ON public.bzooginer_orders;
DROP POLICY IF EXISTS "orders_update_superadmin_or_own" ON public.bzooginer_orders;
DROP POLICY IF EXISTS "orders_update_superadmin" ON public.bzooginer_orders;

CREATE POLICY "orders_update_authorized"
ON public.bzooginer_orders
FOR UPDATE
TO authenticated
USING (
  public.is_bzooginer_superadmin()
  OR public.is_bzooginer_group_admin(group_id)
)
WITH CHECK (
  public.is_bzooginer_superadmin()
  OR (
    public.is_bzooginer_group_admin(group_id)
    AND group_id = (SELECT p.group_id FROM public.bzooginer_profiles p WHERE p.id = auth.uid())
  )
);

-- 4. Tabel Audit Log Riwayat Perubahan Pesanan (bzooginer_order_audit_logs)
CREATE TABLE IF NOT EXISTS public.bzooginer_order_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id TEXT NOT NULL REFERENCES public.bzooginer_orders(id) ON DELETE CASCADE,
  group_id INTEGER NOT NULL,
  changed_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  changed_by_username TEXT NOT NULL,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  action TEXT NOT NULL DEFAULT 'UPDATE',
  changes JSONB NOT NULL DEFAULT '[]'::jsonb,
  summary TEXT
);

CREATE INDEX IF NOT EXISTS idx_bzooginer_order_audit_logs_order_id ON public.bzooginer_order_audit_logs(order_id);
CREATE INDEX IF NOT EXISTS idx_bzooginer_order_audit_logs_changed_at ON public.bzooginer_order_audit_logs(changed_at DESC);

-- Enable RLS pada audit logs
ALTER TABLE public.bzooginer_order_audit_logs ENABLE ROW LEVEL SECURITY;

-- Policy SELECT pada audit logs: Superadmin melihat semua, Group Admin hanya kelompoknya
DROP POLICY IF EXISTS "audit_logs_select_authorized" ON public.bzooginer_order_audit_logs;
CREATE POLICY "audit_logs_select_authorized"
ON public.bzooginer_order_audit_logs
FOR SELECT
TO authenticated
USING (
  public.is_bzooginer_superadmin()
  OR public.is_bzooginer_group_admin(group_id)
);

-- Policy INSERT pada audit logs: diizinkan untuk superadmin atau group admin pemilik kelompok
DROP POLICY IF EXISTS "audit_logs_insert_authorized" ON public.bzooginer_order_audit_logs;
CREATE POLICY "audit_logs_insert_authorized"
ON public.bzooginer_order_audit_logs
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_bzooginer_superadmin()
  OR public.is_bzooginer_group_admin(group_id)
);

-- 5. Trigger Otomatis Audit Trail pada bzooginer_orders
CREATE OR REPLACE FUNCTION public.trg_fn_audit_bzooginer_order()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_changes JSONB := '[]'::jsonb;
  v_username TEXT;
  v_caller_id UUID;
BEGIN
  v_caller_id := auth.uid();
  
  IF v_caller_id IS NOT NULL THEN
    SELECT username INTO v_username
    FROM public.bzooginer_profiles
    WHERE id = v_caller_id;
  END IF;

  IF v_username IS NULL OR v_username = '' THEN
    v_username := COALESCE(NEW.recorded_by, 'system');
  END IF;

  -- Evaluasi setiap kolom yang berpotensi diubah
  IF OLD.buyer_name IS DISTINCT FROM NEW.buyer_name THEN
    v_changes := v_changes || jsonb_build_object(
      'field', 'buyer_name',
      'label', 'Nama Pembeli',
      'old_value', to_jsonb(OLD.buyer_name),
      'new_value', to_jsonb(NEW.buyer_name)
    );
  END IF;

  IF OLD.buyer_class IS DISTINCT FROM NEW.buyer_class THEN
    v_changes := v_changes || jsonb_build_object(
      'field', 'buyer_class',
      'label', 'Kelas',
      'old_value', to_jsonb(OLD.buyer_class),
      'new_value', to_jsonb(NEW.buyer_class)
    );
  END IF;

  IF OLD.items IS DISTINCT FROM NEW.items THEN
    v_changes := v_changes || jsonb_build_object(
      'field', 'items',
      'label', 'Daftar Produk / Menu',
      'old_value', OLD.items,
      'new_value', NEW.items
    );
  END IF;

  IF OLD.total IS DISTINCT FROM NEW.total THEN
    v_changes := v_changes || jsonb_build_object(
      'field', 'total',
      'label', 'Total Pembayaran',
      'old_value', to_jsonb(OLD.total),
      'new_value', to_jsonb(NEW.total)
    );
  END IF;

  IF OLD.status IS DISTINCT FROM NEW.status THEN
    v_changes := v_changes || jsonb_build_object(
      'field', 'status',
      'label', 'Status Pembayaran',
      'old_value', to_jsonb(OLD.status),
      'new_value', to_jsonb(NEW.status)
    );
  END IF;

  IF OLD.note IS DISTINCT FROM NEW.note THEN
    v_changes := v_changes || jsonb_build_object(
      'field', 'note',
      'label', 'Catatan Pesanan',
      'old_value', to_jsonb(OLD.note),
      'new_value', to_jsonb(NEW.note)
    );
  END IF;

  -- Jika terdeteksi ada perubahan data, simpan riwayat perubahan
  IF jsonb_array_length(v_changes) > 0 THEN
    INSERT INTO public.bzooginer_order_audit_logs (
      order_id,
      group_id,
      changed_by_user_id,
      changed_by_username,
      changed_at,
      action,
      changes,
      summary
    ) VALUES (
      NEW.id,
      NEW.group_id,
      v_caller_id,
      v_username,
      NOW(),
      'UPDATE',
      v_changes,
      format('Pembaruan oleh @%s (%s kolom diubah)', v_username, jsonb_array_length(v_changes))
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_bzooginer_order ON public.bzooginer_orders;
CREATE TRIGGER trg_audit_bzooginer_order
AFTER UPDATE ON public.bzooginer_orders
FOR EACH ROW
EXECUTE FUNCTION public.trg_fn_audit_bzooginer_order();
