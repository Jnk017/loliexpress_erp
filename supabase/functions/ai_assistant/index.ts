import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

import { corsHeaders } from "../_shared/cors.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders });
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405, headers: corsHeaders });
  const authHeader = req.headers.get("Authorization") ?? "";
  const client = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: authUser, error } = await client.auth.getUser();
  if (error || !authUser.user) return new Response("Unauthorized", { status: 401, headers: corsHeaders });

  const body = await req.json().catch(() => ({}));
  const question = String(body.question ?? "").toLowerCase();
  const end = new Date();
  const start = new Date(end.getFullYear(), end.getMonth(), 1);

  let rpc = "get_admin_total_report";
  if (question.includes("vente") || question.includes("produit")) {
    rpc = "get_admin_sales_report";
  } else if (question.includes("dépense") || question.includes("achat") || question.includes("bénéfice")) {
    rpc = "get_admin_finance_report";
  } else if (question.includes("stock") || question.includes("créance") || question.includes("caisse") || question.includes("banque")) {
    rpc = "get_admin_operations_report";
  }

  const { data, error: rpcError } = await client.rpc(rpc, {
    p_start: start.toISOString(),
    p_end: end.toISOString(),
  });
  if (rpcError) return new Response(rpcError.message, { status: 403, headers: corsHeaders });

  const llmKey = Deno.env.get("OPENAI_API_KEY");
  if (llmKey) {
    const completion = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${llmKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini",
        messages: [
          { role: "system", content: "Tu es un analyste ERP. Réponds brièvement en français à partir du JSON fourni." },
          { role: "user", content: `Question: ${body.question}\nDonnées: ${JSON.stringify(data)}` },
        ],
      }),
    });
    if (completion.ok) {
      const json = await completion.json();
      const answer = json.choices?.[0]?.message?.content;
      if (answer) {
        return Response.json({ answer, data }, { headers: corsHeaders });
      }
    }
  }

  return Response.json({
    answer: `Voici les données disponibles pour votre question: ${JSON.stringify(data)}`,
    data,
  }, { headers: corsHeaders });
});
