// Public, read-only connectivity probe. It never returns database details or secrets.
export async function onRequestGet({ env }) {
  const fail = () =>
    Response.json(
      { ok: false, service: "jumjum-api", turso: "unavailable" },
      { status: 503, headers: { "Cache-Control": "no-store" } }
    );

  try {
    const rawUrl = env.TURSO_URL?.trim();
    const authToken = env.TURSO_AUTH_TOKEN?.trim();
    if (!rawUrl || !authToken) return fail();

    const dbUrl = new URL(rawUrl);
    if (
      dbUrl.protocol !== "libsql:" ||
      !dbUrl.hostname.endsWith(".turso.io") ||
      dbUrl.username ||
      dbUrl.password
    ) {
      return fail();
    }

    const endpoint = `https://${dbUrl.hostname}/v3/pipeline`;
    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${authToken}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        baton: null,
        requests: [
          { type: "execute", stmt: { sql: "SELECT 1 AS healthy" } },
          { type: "close" }
        ]
      })
    });

    if (!response.ok) return fail();

    const payload = await response.json();
    const first = payload?.results?.[0];
    if (first?.type !== "ok" || first?.response?.type !== "execute") {
      return fail();
    }

    return Response.json(
      {
        ok: true,
        service: "jumjum-api",
        turso: "connected"
      },
      { headers: { "Cache-Control": "no-store" } }
    );
  } catch {
    return fail();
  }
}
