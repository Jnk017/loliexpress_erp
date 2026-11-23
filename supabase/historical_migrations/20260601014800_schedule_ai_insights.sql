DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'ai-insights-hourly') THEN
        PERFORM cron.unschedule('ai-insights-hourly');
    END IF;
END $$;

SELECT cron.schedule(
    'ai-insights-hourly',
    '15 * * * *',
    $$SELECT public.generate_ai_insights();$$
);
