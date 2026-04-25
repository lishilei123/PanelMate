# PanelMate Real API Notes

- Project: `PanelMate`.
- Verified against a real 1Panel V2 server on `2026-04-06`.
- API requests must use `scheme://host:port/api/v2/...`.
- Do not prepend the login-page path segment to `/api/v2/...`; that path is not the API base path.
- Some fields that looked empty in the mobile UI are genuinely empty in the current server payload, for example static websites without runtime info and apps without `webUI`.
- The client should prefer real non-empty fallback fields from the same payload and hide optional empty rows instead of rendering placeholder-heavy cards.
- The sampled server returned `topCPUItems = null` and `topMemItems = null` on `/api/v2/dashboard/current/all/all`, so missing process rows are currently an API payload reality, not a transport failure.
