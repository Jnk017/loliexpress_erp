-- Clients read their notifications and record receipt. Delivery belongs to the server.
REVOKE ALL ON public.notification_queue FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT ON public.notification_queue TO authenticated;
GRANT UPDATE (read_at) ON public.notification_queue TO authenticated;

-- Backend triggers and service-role jobs continue to write the queue.
-- Keep the administrative insert policy for the incident escalation workflow.
DROP POLICY users_create_own_notifications ON public.notification_queue;
