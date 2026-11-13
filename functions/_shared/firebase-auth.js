// Firebase ID-token verification for Cloudflare Pages Functions.
// Verifies signatures and standard Firebase Secure Token claims before trusting a UID.

let jwksCache = null;
let jwksExpiresAt = 0;

function decodeBase64Url(value) {
  const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
  const padded = normalized + "=".repeat((4 - (normalized.length % 4)) % 4);
  const binary = atob(padded);
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}

function decodeJsonPart(value) {
  return JSON.parse(new TextDecoder().decode(decodeBase64Url(value)));
}

async function getSigningKeys() {
  if (jwksCache && Date.now() < jwksExpiresAt) return jwksCache;

  const response = await fetch(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com"
  );
  if (!response.ok) throw new Error("Firebase signing keys unavailable");

  const body = await response.json();
  if (!Array.isArray(body.keys)) throw new Error("Invalid Firebase signing keys");

  const cacheControl = response.headers.get("Cache-Control") || "";
  const maxAge = Number(cacheControl.match(/max-age=(\d+)/i)?.[1] || 300);
  jwksCache = body.keys;
  jwksExpiresAt = Date.now() + Math.max(60, Math.min(maxAge, 3600)) * 1000;
  return jwksCache;
}

export async function verifyFirebaseRequest(request, projectId) {
  if (!projectId || !/^[a-z0-9-]+$/.test(projectId)) {
    return { ok: false, status: 503, error: "authentication_not_configured" };
  }

  const authorization = request.headers.get("Authorization") || "";
  const match = authorization.match(/^Bearer\s+([^\s]+)$/i);
  if (!match) return { ok: false, status: 401, error: "missing_bearer_token" };

  try {
    const parts = match[1].split(".");
    if (parts.length !== 3) throw new Error("Malformed token");

    const header = decodeJsonPart(parts[0]);
    const claims = decodeJsonPart(parts[1]);
    if (header.alg !== "RS256" || typeof header.kid !== "string") {
      throw new Error("Unsupported token header");
    }

    const now = Math.floor(Date.now() / 1000);
    if (
      claims.aud !== projectId ||
      claims.iss !== `https://securetoken.google.com/${projectId}` ||
      typeof claims.sub !== "string" ||
      claims.sub.length < 1 ||
      claims.sub.length > 128 ||
      !Number.isFinite(claims.exp) ||
      !Number.isFinite(claims.iat) ||
      !Number.isFinite(claims.auth_time) ||
      claims.exp <= now - 60 ||
      claims.iat > now + 60 ||
      claims.auth_time > now + 60
    ) {
      throw new Error("Invalid Firebase token claims");
    }

    const jwks = await getSigningKeys();
    const jwk = jwks.find((key) => key.kid === header.kid && key.kty === "RSA");
    if (!jwk) throw new Error("Unknown Firebase signing key");

    const publicKey = await crypto.subtle.importKey(
      "jwk",
      jwk,
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["verify"]
    );
    const valid = await crypto.subtle.verify(
      "RSASSA-PKCS1-v1_5",
      publicKey,
      decodeBase64Url(parts[2]),
      new TextEncoder().encode(`${parts[0]}.${parts[1]}`)
    );
    if (!valid) throw new Error("Invalid Firebase token signature");

    return { ok: true, uid: claims.sub, claims };
  } catch {
    return { ok: false, status: 401, error: "invalid_firebase_token" };
  }
}
