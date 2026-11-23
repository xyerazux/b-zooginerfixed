-- Migration: Allow Group Admin to delete orders belonging to their own group
-- Superadmin retains global delete capability

DROP POLICY IF EXISTS "orders_delete_authorized" ON public.bzooginer_orders;
DROP POLICY IF EXISTS "orders_delete_superadmin" ON public.bzooginer_orders;

CREATE POLICY "orders_delete_authorized"
ON public.bzooginer_orders
FOR DELETE
TO authenticated
USING (
  public.is_bzooginer_superadmin()
  OR public.is_bzooginer_group_admin(group_id)
);
