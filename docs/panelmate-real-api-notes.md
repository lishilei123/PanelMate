# PanelMate Real API Notes

- Project: `PanelMate`.
- Verified against a real 1Panel V2 server on `2026-04-06`.
- Account-password login behavior was re-checked against a real 1Panel V2 server on `2026-05-04`.
- API requests must use `scheme://host:port/api/v2/...`.
- Do not prepend the login-page path segment to `/api/v2/...`; that path is not the API base path.
- Some fields that looked empty in the mobile UI are genuinely empty in the current server payload, for example static websites without runtime info and apps without `webUI`.
- The client should prefer real non-empty fallback fields from the same payload and hide optional empty rows instead of rendering placeholder-heavy cards.
- The sampled server returned `topCPUItems = null` and `topMemItems = null` on `/api/v2/dashboard/current/all/all`, so missing process rows are currently an API payload reality, not a transport failure.

## Account-Password Login

- Before posting `/api/v2/core/auth/login`, call `/api/v2/core/auth/setting`.
- The setting response sets a `panel_public_key` cookie. Its value is URL-encoded Base64 text for an RSA public key PEM.
- `EntranceCode` must be sent as Base64 of the login-page entrance segment, not as the raw segment.
- Password payload must follow the 1Panel V2 web frontend format:

```text
RSA_PKCS1(AES_KEY):BASE64(IV):AES_CBC_PKCS7(password)
```

- `AES_KEY` is a random 16-byte value encoded as a 32-character hex string and used as the AES-256-CBC key bytes.
- Login currently uses `authMethod: "session"` because the sampled V2 server returned an empty `token` even when `authMethod: "jwt"` was requested.
- After successful login, persist `psession` and `pcsrftoken` from `Set-Cookie`; subsequent mutating requests must send `Cookie` and `X-CSRF-Token`.
- In Web debug mode, browsers cannot expose `Set-Cookie` or let client code set `Cookie` directly. The local proxy mirrors upstream `Set-Cookie` values as `X-PanelMate-Set-Cookie` and translates frontend `X-PanelMate-Cookie` values back to the real `Cookie` request header.
- If `/core/auth/setting` returns `needCaptcha: true`, load `/api/v2/core/auth/captcha`, show `imagePath`, then submit `captcha` and `captchaID` with `/core/auth/login`. If login returns `ErrCaptchaCode`, reload captcha and retry.
- MFA is not implemented in PanelMate yet. If login returns MFA status, the client should fail clearly instead of retrying silently.

## API Key Login

- API Key mode still uses `1Panel-Timestamp` and `1Panel-Token`.
- `1Panel-Token` is calculated as `md5("1panel" + apiKey + timestampSeconds)`.
