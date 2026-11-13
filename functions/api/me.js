import { verifyFirebaseRequest } from "../_shared/firebase-auth.js";

function json(body, status = 200) {
  return Response.json(body, {
    status,
    headers: { "Cache-Control": "no-store" }
  });
}

function textArg(value) {
  return { type: "text", value };
}

export async function onRequestGet({ request, env }) {
  const identity = await verifyFirebaseRequest(request, env.FIREBASE_PROJECT_ID);
  if (!identity.ok) {
    return json({ ok: false, error: identity.error }, identity.status);
  }

  try {
    const rawUrl = env.TURSO_URL?.trim();
    const authToken = env.TURSO_AUTH_TOKEN?.trim();
    if (!rawUrl || !authToken) {
      return json({ ok: false, error: "player_storage_not_configured" }, 503);
    }

    const dbUrl = new URL(rawUrl);
    if (
      dbUrl.protocol !== "libsql:" ||
      !dbUrl.hostname.endsWith(".turso.io") ||
      dbUrl.username ||
      dbUrl.password
    ) {
      return json({ ok: false, error: "player_storage_not_configured" }, 503);
    }

    const response = await fetch(`https://${dbUrl.hostname}/v3/pipeline`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${authToken}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        baton: null,
        requests: [
          {
            type: "execute",
            stmt: {
              sql: "INSERT OR IGNORE INTO player_profiles (firebase_uid) VALUES (?)",
              args: [textArg(identity.uid)]
            }
          },
          {
            type: "execute",
            stmt: {
              sql: "SELECT firebase_uid, display_name, avatar_key, locale, created_at, updated_at FROM player_profiles WHERE firebase_uid = ? LIMIT 1",
              args: [textArg(identity.uid)]
            }
          },
          { type: "close" }
        ]
      })
    });

    if (!response.ok) {
      return json({ ok: false, error: "player_storage_unavailable" }, 503);
    }

    const payload = await response.json();
    const results = payload?.results;
    if (
      !Array.isArray(results) ||
      results[0]?.type !== "ok" ||
      results[1]?.type !== "ok" ||
      results[1]?.response?.type !== "execute"
    ) {
      return json({ ok: false, error: "player_storage_unavailable" }, 503);
    }

    const rows = results[1].response.result?.rows || [];
    if (!rows.length) {
      return json({ ok: false, error: "player_profile_unavailable" }, 503);
    }

    const values = rows[0].map((column) => column.value);
    return json({
      ok: true,
      player: {
        uid: values[0],
        displayName: values[1],
        avatarKey: values[2] ?? null,
        locale: values[3],
        createdAt: values[4],
        updatedAt: values[5]
      }
    });
  } catch {
    return json({ ok: false, error: "player_storage_unavailable" }, 503);
  }
}
