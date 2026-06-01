import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async () => {
  const end = new Date();
  const start = new Date(end.getTime() - 24 * 60 * 60 * 1000);
  const { data, error } = await supabase
    .from("audit_logs")
    .select("*")
    .gte("created_at", start.toISOString())
    .lte("created_at", end.toISOString())
    .order("created_at", { ascending: true });
  if (error) return new Response(error.message, { status: 500 });

  const body = JSON.stringify({ start, end, audit_logs: data }, null, 2);
  const path = `forensic/daily-${end.toISOString().slice(0, 10)}.json`;
  const upload = await supabase.storage
    .from("erp-documents")
    .upload(path, new Blob([body], { type: "application/json" }), {
      upsert: true,
      contentType: "application/json",
    });
  if (upload.error) return new Response(upload.error.message, { status: 500 });

  return new Response(JSON.stringify({ path, count: data?.length ?? 0 }), {
    headers: { "Content-Type": "application/json" },
  });
});
