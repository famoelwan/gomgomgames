# Jumjum V5 — Cloudflare R2 setup

R2 is the object/file store for the published question payloads (question text, choices, answers, explanations) and media. It is not a relational database and does not replace D1. D1 retains IDs, searchable metadata, player state, progress, anti-repeat records and relational constraints.

## Create the bucket

1. Open Cloudflare Dashboard → R2 Object Storage.
2. Create a bucket named `jumjum-assets` (or another available lowercase name).
3. Keep it private. Do not enable public access for player uploads or private media.
4. Use the Standard storage class for the free 10 GB-month allowance.
5. Do not create API tokens for the browser.

## Add the Pages binding

After the bucket exists:
1. Open Workers & Pages → your Pages project `jumjum-v5`.
2. Open Settings → Functions → R2 bucket bindings.
3. Add a binding named `ASSETS` and select `jumjum-assets`.
4. Add the same binding to the production environment and preview environment only if both are needed.
5. Save and redeploy.

The repository's `wrangler.toml` can later declare the same binding for local development and repeatable configuration. Do not add a bucket binding until the bucket name and account are confirmed.

## Access rules

- Keep the bucket private.
- Route downloads and uploads through Pages Functions.
- Authorize each request against the verified Firebase identity and D1 metadata.
- Store question-bank content in versioned, compact JSON/NDJSON shards partitioned by audience, age band and category. Do not expose unpublished drafts or answer keys in public buckets.
- Keep shard manifests and publication status in D1 so the server can serve only approved content.
- Generate object keys on the server; do not let clients choose arbitrary bucket paths.
- Enforce file size and content-type allow-lists.
- Never place R2 access keys in frontend code, GitHub, screenshots or chat.

## Verify

After binding is saved, the next deployment can run a server-only health check that confirms the binding exists without revealing bucket contents or credentials.
