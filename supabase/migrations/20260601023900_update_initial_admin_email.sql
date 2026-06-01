-- Replace the initial development admin email with the active owner mailbox.
-- The password is intentionally not changed here; use Supabase Auth password
-- reset or the Dashboard to rotate it after deployment.

UPDATE auth.users
SET email = 'eaglejnk@gmail.com',
    email_confirmed_at = COALESCE(email_confirmed_at, now()),
    updated_at = now(),
    raw_user_meta_data = jsonb_set(
        COALESCE(raw_user_meta_data, '{}'::jsonb),
        '{full_name}',
        '"Administrateur LoliExpress"',
        true
    )
WHERE email = 'admin@loliexpress.com';

UPDATE public.user_profiles
SET email = 'eaglejnk@gmail.com',
    full_name = COALESCE(NULLIF(full_name, ''), 'Administrateur LoliExpress'),
    is_active = true,
    updated_at = now()
WHERE email = 'admin@loliexpress.com'
  AND role = 'admin';

UPDATE public.notification_queue
SET recipient_email = 'eaglejnk@gmail.com'
WHERE recipient_email = 'admin@loliexpress.com';
