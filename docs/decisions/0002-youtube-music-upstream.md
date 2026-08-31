# ADR 0002: Isolate guest YouTube Music catalog access

- Status: Accepted for an isolated unofficial guest experiment
- Date: 2026-08-30
- Live experiment approved: 2026-08-31

## Context

Yuzu needs music-specific Home, Search, album, artist, and playlist metadata without requiring a Google account. The current `MusicProvider` proves that feature UI can consume a replaceable catalog contract, but it does not define how an unofficial upstream is isolated or how policy, privacy, and schema failures are handled.

YouTube documents that some browsing and searching are available without an account. It also restricts automated access without prior written permission. An undocumented YouTube Music transport has no official compatibility contract and may stop working, reject requests, or create policy risk at any time.

The official YouTube Data API is documented and supports public search for videos, channels, and playlists through an API project and key. It is not documented as a replacement for the YouTube Music Home catalog, music-specific entity relationships, or stream resolution.

## Decision

- Treat the existing source-neutral `MusicProvider` as the catalog-provider boundary. Keep the symbol during Task 14; any later rename to `CatalogProvider` must be one mechanical migration rather than a parallel interface.
- Keep `StreamResolver` separate. Catalog code never returns playable URLs, media headers, cipher data, account state, or playback transport DTOs.
- Permit Task 14 to define contracts, sanitized self-authored fixtures, fake transports, parsers, and typed failures without contacting YouTube.
- Record the maintainer's 2026-08-31 approval of an acknowledged unofficial guest experiment for Tasks 15–19. This approval accepts availability and policy risk; it is not a claim of official support or permission from YouTube.
- Bootstrap public web-client configuration at runtime and keep it in process memory only. Do not hard-code, persist, log, or commit upstream API keys, cookies, visitor data, or response payloads.
- Restrict the experiment to guest-only, read-only catalog requests against the `music.youtube.com` HTTPS host. A requirement for account cookies, persistent visitor identity, device attestation, or additional hosts triggers a new review.
- Keep the fake provider as the deterministic test backend and operational fallback.
- Use guest-only, read-only behavior. Do not accept Google credentials, authenticated cookies, or account-linked tokens.
- Treat search queries, continuation tokens, anonymous visitor/session values, and all upstream responses as sensitive untrusted data. Do not persist or log them.
- Do not implement ad blocking, media download, paid-feature bypasses, or restriction circumvention.

## Policy and Privacy Rationale

- The general YouTube Terms are directly relevant to service access and currently restrict automated means without enumerated permission. This makes unofficial live access a high-risk, revocable dependency rather than a production guarantee.
- YouTube API Services terms and policies govern official API use. They require transparent privacy practices and secure data handling, and they prohibit scraping and offline audiovisual copies. They are a conservative baseline, not evidence that undocumented access is permitted.
- Direct device-to-upstream requests disclose network and client metadata to Google even without sign-in. Yuzu must disclose this before enabling a live backend.
- Data minimization is the default: request-time use only, in-memory metadata, no account data, no analytics identifier, and sanitized diagnostics.

This ADR records an engineering risk decision and is not legal advice.

## Alternatives Considered

### Official YouTube Data API only

- Advantages: documented contract, official credentials, quotas, policies, and deprecation path.
- Limitations: generic YouTube resources rather than a documented YouTube Music catalog; no direct audio-stream contract; requires an API project/key and compliance work. A key embedded in a distributed APK is recoverable and cannot be treated as a secret, so credential and quota-abuse handling need a separate design.
- Disposition: retained as a candidate at the policy checkpoint, not assumed to satisfy the product scope.

### Direct unofficial integration inside feature code

- Advantages: initially fewer layers.
- Limitations: leaks unstable DTOs and endpoint assumptions into UI, makes failure recovery inconsistent, and prevents replacing or disabling the backend.
- Disposition: rejected.

### Port a community client's adapter

- Advantages: faster apparent progress.
- Limitations: violates Yuzu's clean-room rule and imports unknown licensing, security, privacy, and architectural assumptions.
- Disposition: rejected.

### Keep only the fake provider

- Advantages: deterministic, offline, policy-safe, and testable.
- Limitations: does not deliver the intended live catalog.
- Disposition: retained as the fallback and as the required outcome if live access is not approved.

## Consequences

- Tasks 14–19 can evolve catalog behavior without changing feature UI.
- Task 14 remains network-free; Task 15 begins the explicitly approved, revocable live experiment.
- More mapping and contract code is required, but upstream changes remain localized.
- Guest results may be generic, locale-dependent, incomplete, rejected, or unavailable.
- A policy or upstream change can disable the experimental backend while the application continues with the fake provider.
- Account features, personalization, and playback resolution require separate specifications and decisions.

## Review Triggers

Revisit this decision before proceeding if:

- YouTube publishes an official YouTube Music API or grants written permission.
- The selected transport requires account cookies, OAuth, device attestation, persistent visitor identity, PO tokens, signature/cipher circumvention, or new hostnames.
- YouTube Terms, API policies, or privacy requirements materially change.
- The adapter cannot operate with bounded retries, sanitized logs, self-authored fixtures, or the fake-provider fallback.

## Sources

- [YouTube Terms of Service](https://www.youtube.com/static?template=terms)
- [YouTube API Services Terms of Service](https://developers.google.com/youtube/terms/api-services-terms-of-service)
- [YouTube API Services Developer Policies](https://developers.google.com/youtube/terms/developer-policies)
- [YouTube Data API: Search](https://developers.google.com/youtube/v3/docs/search/list)
- [Google Privacy Policy](https://policies.google.com/privacy)
