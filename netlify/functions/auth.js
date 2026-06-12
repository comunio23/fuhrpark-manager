export default async (req) => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const { password } = await req.json();

  if (!process.env.FUHRPARK_PW || password !== process.env.FUHRPARK_PW) {
    return Response.json({ ok: false }, { status: 401, headers: corsHeaders });
  }

  return Response.json({ token: process.env.FUHRPARK_TOKEN }, { headers: corsHeaders });
};

export const config = { path: "/api/auth" };
