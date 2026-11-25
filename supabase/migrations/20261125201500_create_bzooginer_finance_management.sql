-- Migration: Phase 5 Financial Management & Accounting
-- Tables: bzooginer_finance_categories, bzooginer_product_costs, bzooginer_product_cost_history,
--         bzooginer_order_payments, bzooginer_finance_transactions, bzooginer_finance_audit_logs
-- RLS, Helper functions, Indexes, and Realtime Replication.
-- Safe, additive, idempotent migration.

-- 1. Helper function current_bzooginer_group_id() if not present
CREATE OR REPLACE FUNCTION public.current_bzooginer_group_id()
RETURNS integer
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT group_id FROM public.bzooginer_profiles
  WHERE id = auth.uid() AND is_active = TRUE
  LIMIT 1;
$$;

-- 2. Master Kategori Keuangan (bzooginer_finance_categories)
CREATE TABLE IF NOT EXISTS public.bzooginer_finance_categories (
  id SERIAL PRIMARY KEY,
  type TEXT NOT NULL CHECK (type IN ('revenue', 'expense', 'capital')),
  name TEXT NOT NULL,
  icon TEXT,
  is_default BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(type, name)
);

ALTER TABLE public.bzooginer_finance_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "finance_categories_select" ON public.bzooginer_finance_categories;
CREATE POLICY "finance_categories_select"
ON public.bzooginer_finance_categories
FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "finance_categories_admin_all" ON public.bzooginer_finance_categories;
CREATE POLICY "finance_categories_admin_all"
ON public.bzooginer_finance_categories
FOR ALL TO authenticated
USING (public.is_bzooginer_superadmin())
WITH CHECK (public.is_bzooginer_superadmin());

-- Isi kategori default jika belum ada
INSERT INTO public.bzooginer_finance_categories (type, name, icon) VALUES
  ('expense', 'Bahan baku', '🥩'),
  ('expense', 'Kemasan', '📦'),
  ('expense', 'Peralatan', '🍳'),
  ('expense', 'Transportasi', '🛵'),
  ('expense', 'Operasional', '⚙️'),
  ('expense', 'Promosi', '📢'),
  ('expense', 'Sewa', '🎪'),
  ('expense', 'Lain-lain', '📝'),
  ('capital', 'Modal Awal', '💰'),
  ('capital', 'Tambahan Modal', '💵'),
  ('revenue', 'Penjualan Langsung', '🛍️'),
  ('revenue', 'Pendapatan Tambahan', '✨'),
  ('revenue', 'Lain-lain', '🧾')
ON CONFLICT (type, name) DO NOTHING;

-- 3. HPP Produk per Grup (bzooginer_product_costs)
CREATE TABLE IF NOT EXISTS public.bzooginer_product_costs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id INTEGER NOT NULL,
  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  cost_per_unit NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (cost_per_unit >= 0),
  effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  username TEXT NOT NULL,
  UNIQUE (group_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_product_costs_group ON public.bzooginer_product_costs(group_id);

ALTER TABLE public.bzooginer_product_costs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "product_costs_select" ON public.bzooginer_product_costs;
CREATE POLICY "product_costs_select"
ON public.bzooginer_product_costs
FOR SELECT TO authenticated
USING (
  public.is_bzooginer_superadmin()
  OR public.is_bzooginer_group_admin(group_id)
);

DROP POLICY IF EXISTS "product_costs_insert" ON public.bzooginer_product_costs;
CREATE POLICY "product_costs_insert"
ON public.bzooginer_product_costs
FOR INSERT TO authenticated
WITH CHECK (
  public.is_bzooginer_superadmin()
  OR public.is_bzooginer_group_admin(group_id)
);

DROP POLICY IF EXISTS "product_costs_update" ON public.bzooginer_product_costs;
CREATE POLICY "product_costs_update"
ON public.bzooginer_product_costs
FOR UPDATE TO authenticated
USING (
  public.is_bzooginer_superadmin()
  OR public.is_bzooginer_group_admin(group_id)
)
WITH CHECK (
  public.is_bzooginer_superadmin()
  OR public.is_bzooginer_group_admin(group_id)
);

DROP POLICY IF EXISTS "product_costs_delete" ON public.bzooginer_product_costs;
CREATE POLICY "product_costs_delete"
ON public.bzooginer_product_costs
FOR DELETE TO authenticated
USING (public.is_bzooginer_superadmin());

-- Riwayat Perubahan HPP (bzooginer_product_cost_history)
CREATE TABLE IF NOT EXISTS public.bzooginer_product_cost_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cost_id UUID REFERENCES public.bzooginer_product_costs(id) ON DELETE CASCADE,
  group_id INTEGER NOT NULL,
  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  old_cost NUMERIC(12,2),
  new_cost NUMERIC(12,2) NOT NULL,
  effective_date DATE NOT NULL,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  changed_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  changed_by_username TEXT NOT NULL
);

ALTER TABLE public.bzooginer_product_cost_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cost_history_select" ON public.bzooginer_product_cost_history;
CREATE POLICY "cost_history_select"
ON public.bzooginer_product_cost_history
FOR SELECT TO authenticated
USING (
  public.is_bzooginer_superadmin()
  OR public.is_bzooginer_group_admin(group_id)
);

DROP POLICY IF EXISTS "cost_history_insert" ON public.bzooginer_product_cost_history;
CREATE POLICY "cost_history_insert"
ON public.bzooginer_product_cost_history
FOR INSERT TO authenticated
WITH CHECK (
  public.is_bzooginer_superadmin()
  OR public.is_bzooginer_group_admin(group_id)
);

-- 4. Pembayaran Pesanan PO (bzooginer_order_payments)
CREATE TABLE IF NOT EXISTS public.bzooginer_order_payments (
  id TEXT PRIMARY KEY,
  order_id TEXT NOT NULL REFERENCES public.bzooginer_orders(id) ON DELETE CASCADE,
  group_id INTEGER NOT NULL,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  payment_type TEXT NOT NULL DEFAULT 'cash' CHECK (payment_type IN ('full', 'dp', 'repayment', 'adjustment', 'cash')),
  payment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  notes TEXT,
  idempotency_key TEXT UNIQUE,
  is_historical_reconciliation BOOLEAN NOT NULL DEFAULT FALSE,
  recorded_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  recorded_by_username TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_payments_order ON public.bzooginer_order_payments(order_id);
CREATE INDEX IF NOT EXISTS idx_order_payments_group ON public.bzooginer_order_payments(group_id);
CREATE INDEX IF NOT EXISTS idx_order_payments_date ON public.bzooginer_order_payments(payment_date DESC);

ALTER TABLE public.bzooginer_order_payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "order_payments_select" ON public.bzooginer_order_payments;
CREATE POLICY "order_payments_select"
ON public.bzooginer_order_payments
FOR SELECT TO authenticated
USING (
  public.is_bzooginer_superadmin()
  OR public.is_bzooginer_group_admin(group_id)
);

DROP POLICY IF EXISTS "order_payments_insert" ON public.bzooginer_order_payments;
CREATE POLICY "order_payments_insert"
ON public.bzooginer_order_payments
FOR INSERT TO authenticated
WITH CHECK (
  public.is_bzooginer_superadmin()
  OR public.is_bzooginer_group_admin(group_id)
);

DROP POLICY IF EXISTS "order_payments_update" ON public.bzooginer_order_payments;
CREATE POLICY "order_payments_update"
ON public.bzooginer_order_payments
FOR UPDATE TO authenticated
USING (
  public.is_bzooginer_superadmin()
  OR public.is_bzooginer_group_admin(group_id)
)
WITH CHECK (
  public.is_bzooginer_superadmin()
  OR public.is_bzooginer_group_admin(group_id)
);

DROP POLICY IF EXISTS "order_payments_delete" ON public.bzooginer_order_payments;
CREATE POLICY "order_payments_delete"
ON public.bzooginer_order_payments
FOR DELETE TO authenticated
USING (public.is_bzooginer_superadmin());

-- 5. Transaksi Keuangan Kas: Pendapatan Manual, Pengeluaran, Modal (bzooginer_finance_transactions)
CREATE TABLE IF NOT EXISTS public.bzooginer_finance_transactions (
  id TEXT PRIMARY KEY,
  group_id INTEGER NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('revenue', 'expense', 'capital')),
  category TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  description TEXT NOT NULL DEFAULT '',
  receipt_url TEXT,
  recorded_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  recorded_by_username TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_finance_trx_group ON public.bzooginer_finance_transactions(group_id);
CREATE INDEX IF NOT EXISTS idx_finance_trx_type ON public.bzooginer_finance_transactions(type);
CREATE INDEX IF NOT EXISTS idx_finance_trx_date ON public.bzooginer_finance_transactions(transaction_date DESC);

ALTER TABLE public.bzooginer_finance_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "finance_transactions_select" ON public.bzooginer_finance_transactions;
CREATE POLICY "finance_transactions_select"
ON public.bzooginer_finance_transactions
FOR SELECT TO authenticated
USING (
  public.is_bzooginer_superadmin()
  OR public.is_bzooginer_group_admin(group_id)
);

DROP POLICY IF EXISTS "finance_transactions_insert" ON public.bzooginer_finance_transactions;
CREATE POLICY "finance_transactions_insert"
ON public.bzooginer_finance_transactions
FOR INSERT TO authenticated
WITH CHECK (
  public.is_bzooginer_superadmin()
  OR public.is_bzooginer_group_admin(group_id)
);

DROP POLICY IF EXISTS "finance_transactions_update" ON public.bzooginer_finance_transactions;
CREATE POLICY "finance_transactions_update"
ON public.bzooginer_finance_transactions
FOR UPDATE TO authenticated
USING (
  public.is_bzooginer_superadmin()
  OR public.is_bzooginer_group_admin(group_id)
)
WITH CHECK (
  public.is_bzooginer_superadmin()
  OR public.is_bzooginer_group_admin(group_id)
);

DROP POLICY IF EXISTS "finance_transactions_delete" ON public.bzooginer_finance_transactions;
CREATE POLICY "finance_transactions_delete"
ON public.bzooginer_finance_transactions
FOR DELETE TO authenticated
USING (public.is_bzooginer_superadmin());

-- 6. Log Audit Keuangan (bzooginer_finance_audit_logs)
CREATE TABLE IF NOT EXISTS public.bzooginer_finance_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type TEXT NOT NULL CHECK (entity_type IN ('transaction', 'payment', 'cost')),
  entity_id TEXT NOT NULL,
  group_id INTEGER NOT NULL,
  action TEXT NOT NULL DEFAULT 'CREATE',
  changes JSONB NOT NULL DEFAULT '[]'::jsonb,
  summary TEXT,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  changed_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  changed_by_username TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_finance_audit_group ON public.bzooginer_finance_audit_logs(group_id);
CREATE INDEX IF NOT EXISTS idx_finance_audit_entity ON public.bzooginer_finance_audit_logs(entity_id);
CREATE INDEX IF NOT EXISTS idx_finance_audit_date ON public.bzooginer_finance_audit_logs(changed_at DESC);

ALTER TABLE public.bzooginer_finance_audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "finance_audit_select" ON public.bzooginer_finance_audit_logs;
CREATE POLICY "finance_audit_select"
ON public.bzooginer_finance_audit_logs
FOR SELECT TO authenticated
USING (
  public.is_bzooginer_superadmin()
  OR public.is_bzooginer_group_admin(group_id)
);

DROP POLICY IF EXISTS "finance_audit_insert" ON public.bzooginer_finance_audit_logs;
CREATE POLICY "finance_audit_insert"
ON public.bzooginer_finance_audit_logs
FOR INSERT TO authenticated
WITH CHECK (
  public.is_bzooginer_superadmin()
  OR public.is_bzooginer_group_admin(group_id)
);

-- 7. Realtime Replication untuk tabel keuangan
ALTER TABLE public.bzooginer_finance_transactions REPLICA IDENTITY FULL;
ALTER TABLE public.bzooginer_order_payments REPLICA IDENTITY FULL;
ALTER TABLE public.bzooginer_product_costs REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'bzooginer_finance_transactions') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bzooginer_finance_transactions;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'bzooginer_order_payments') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bzooginer_order_payments;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'bzooginer_product_costs') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bzooginer_product_costs;
  END IF;
END $$;
