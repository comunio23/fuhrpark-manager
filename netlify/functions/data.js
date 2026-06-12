import { getStore } from "@netlify/blobs";

export default async (req) => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  };

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  const auth = req.headers.get("authorization") || "";
  const token = auth.startsWith("Bearer ") ? auth.slice(7) : "";
  if (!process.env.FUHRPARK_TOKEN || token !== process.env.FUHRPARK_TOKEN) {
    return new Response("Unauthorized", { status: 401, headers: corsHeaders });
  }

  const store = getStore("fuhrpark");

  if (req.method === "GET") {
    const data = await store.get("fahrzeuge", { type: "json" });
    return Response.json(data || [], { headers: corsHeaders });
  }

  if (req.method === "POST") {
    const data = await req.json();
    await store.setJSON("fahrzeuge", data);
    return Response.json({ ok: true }, { headers: corsHeaders });
  }

  return new Response("Method not allowed", { status: 405 });
};

export const config = { path: "/api/data" };
