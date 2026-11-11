export async function onRequestGet({ env }) {
  try {
    if (!env.DB) {
      return Response.json(
        { ok: false, service: "jumjum-api", reason: "D1 binding DB is missing" },
        { status: 503 }
      );
    }

    await env.DB.prepare("SELECT 1 AS healthy").first();

    return Response.json({
      ok: true,
      service: "jumjum-api",
      database: "connected"
    });
  } catch {
    return Response.json(
      { ok: false, service: "jumjum-api", database: "unavailable" },
      { status: 503 }
    );
  }
}
