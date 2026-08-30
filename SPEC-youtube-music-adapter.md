# Spec: youtube-music-adapter

## Objective

Define a clean-room, guest-only catalog boundary for exploring YouTube Music as a replaceable Yuzu backend without coupling feature UI, domain models, or playback to an undocumented upstream protocol.

This specification authorizes documentation, domain contracts, sanitized self-authored fixtures, and offline parser tests. It does not authorize live network requests. Live access requires the policy checkpoint in the roadmap because YouTube's current Terms restrict automated access without prior written permission.

## Scope

### Included

- Anonymous catalog operations for Home, Search, albums, artists, playlists, and continuation pages.
- Source-neutral domain contracts and typed catalog failures.
- An isolated transport/parser adapter that treats every upstream response as untrusted.
- Dependency injection that can select the fake provider or an experimental live provider without changing feature UI.
- Privacy disclosure for direct device-to-Google requests.

### Excluded

- Google sign-in, OAuth, account cookies, subscriptions, likes, uploads, comments, or account sync.
- Stream URL resolution, playback authorization, signature/cipher handling, or media download.
- Offline YouTube media, ad blocking, paid-feature bypasses, or restriction circumvention.
- Copying code, fixtures, request payloads, identifiers, assets, UI, or implementation structure from another client.

## Policy Position

Yuzu does not claim to use an official YouTube Music API. The proposed live transport would target an undocumented upstream surface and therefore has no stability, compatibility, or permission guarantee.

As reviewed on 2026-08-30:

- The YouTube Terms allow some browsing and searching without an account, but restrict automated access unless it falls within an enumerated exception or has prior written permission.
- The official YouTube Data API offers documented public search for videos, channels, and playlists, requires an API project/key, and is not a documented equivalent of the YouTube Music Home catalog or audio playback.
- YouTube API Services policies are the compliance baseline if Yuzu adopts an official API. They require clear privacy disclosures, secure handling, current data, and limits on storage; they also prohibit scraping and offline copies of audiovisual content.

These observations are engineering constraints, not legal advice. Before Task 15 sends any live request, the maintainer must explicitly select one of these paths:

1. Use an official API within its documented capabilities and policies.
2. Continue an unofficial guest-only experiment with acknowledged availability and policy risk.
3. Keep remote catalog access disabled and retain the fake provider.

## Architecture

```text
Home / Search / Detail UI
          |
          v
   CatalogProvider  <---------------- FakeCatalogProvider
          |
          v
 YouTubeMusicCatalogAdapter
     |              |
     v              v
 CatalogTransport  ResponseMapper
     |
     v
 fixed HTTPS upstream

PlaybackController -> StreamResolver -> PlaybackDriver
                         ^
                         |
                  separate future scope
```

The catalog path ends at stable Yuzu-owned metadata. It never returns playable URLs, playback headers, ciphers, account state, or transport DTOs. `StreamResolver` is a separate future contract and must not be implemented as part of catalog work.

The existing `MusicProvider` is the Milestone 0 implementation of the catalog-provider role. Keep that symbol during Task 14 so the transport work stays focused. If the project later adopts the clearer `CatalogProvider` name, perform one separately reviewed mechanical rename; do not maintain two competing contracts. Feature ViewModels depend only on this source-neutral catalog boundary.

## Contract Shape

The following Dart sketch is normative for responsibility and dependency direction; exact model names may be refined with tests in Tasks 14–19.

```dart
abstract interface class CatalogProvider {
  Future<CatalogPage<HomeSection>> fetchHome(CatalogRequest request);
  Future<SearchPage> search(SearchRequest request);
  Future<AlbumDetails> fetchAlbum(CatalogId id);
  Future<ArtistDetails> fetchArtist(CatalogId id);
  Future<PlaylistDetails> fetchPlaylist(CatalogId id);
  Future<CatalogPage<CatalogItem>> continuePage(ContinuationToken token);
}

abstract interface class StreamResolver {
  Future<ResolvedStream> resolve(TrackPlaybackRef track);
}
```

- `CatalogId`, `ContinuationToken`, request objects, pages, and failures are Yuzu-owned types.
- Continuation tokens are opaque, bounded, in-memory values. UI code may request the next page but must not parse or display a token.
- Returned collections are immutable and preserve upstream order unless the contract explicitly documents another order.
- New item kinds are additive. Unsupported kinds are ignored only at the mapper boundary and counted in sanitized diagnostics.

## Catalog Operations

| Operation | Minimum input | Domain output | Continuation |
|---|---|---|---|
| Home | locale and region defaults | ordered `HomeSection` values | optional per section/page |
| Search | trimmed query, locale, region | typed track/album/artist/playlist results | optional |
| Album | stable catalog ID | metadata and ordered tracks | optional |
| Artist | stable catalog ID | metadata, top tracks, and releases | optional |
| Playlist | stable catalog ID | metadata and ordered tracks | optional |
| Continue | opaque token plus operation context | one typed page | next token only |

Concrete undocumented route names, client identifiers, headers, and DTO fields belong only to `CatalogTransport` and `ResponseMapper`. They are not part of the domain contract or this specification's compatibility promise.

## Request and Data Flow

1. A ViewModel validates user input and calls `CatalogProvider`.
2. The adapter converts source-neutral input into a transport request.
3. The transport sends HTTPS only to an explicit host allowlist, with fixed methods, bounded request/response sizes, a timeout, and cancellation.
4. The transport rejects unexpected redirects, content types, status codes, and oversized bodies.
5. The mapper validates JSON shape and fields before constructing immutable domain models.
6. The adapter returns domain data or one typed `CatalogFailure`; raw DTOs never cross the adapter boundary.

Retries are bounded and apply only to transient failures. Schema failures, rejection, unavailable content, cancellation, and policy-disabled states are not retried automatically.

## Failure Taxonomy

Task 14 must model at least these machine-readable categories:

- `networkUnavailable`
- `timeout`
- `rateLimited`
- `upstreamRejected`
- `malformedResponse`
- `unsupportedSchema`
- `notFound`
- `unavailable`
- `cancelled`
- `policyDisabled`

Each failure records whether a manual retry is reasonable. User-facing copy remains Material 3 UI responsibility; transport errors, response fragments, internal endpoints, and stack traces are never displayed.

## Privacy and Security

### Data sent upstream

- Search text explicitly submitted by the user.
- Requested public catalog identifiers.
- Minimum locale, region, and protocol metadata required for the selected backend.
- Network metadata inherently visible to the upstream, including the user's IP address and basic connection/client information.

### Data not collected or persisted by the adapter

- Google credentials, OAuth tokens, account cookies, passwords, or account-linked identifiers.
- Search history, listening history, raw responses, temporary request URLs, or full request/response headers.
- Advertising identifiers, contacts, precise location, or analytics identifiers.

Search queries and public identifiers are potentially personal. Yuzu sends them only to fulfill the current request and does not log or persist them. Parsed remote metadata remains in memory for the active session unless a later persistence specification is explicitly approved. This adapter rule does not prohibit a separate, user-controlled local library or listening-history feature; such data must never be sent upstream by the catalog adapter.

If the upstream returns an anonymous visitor/session token required for a continuation, the adapter treats it as sensitive ephemeral state: process memory only, never committed, logged, placed in fixtures, or stored on disk. Account cookies and authenticated tokens are rejected.

Diagnostics may record only operation name, elapsed-time bucket, sanitized failure category, HTTP status class, and mapper/schema version. Values supplied by the user or upstream are excluded.

Before any live backend is enabled, Yuzu must expose an easily accessible privacy notice that explains what is sent to Google, that Google receives network/client metadata, and what Yuzu does not retain. It must link the YouTube Terms and Google Privacy Policy. If an official YouTube API is selected, the notice and consent flow must also satisfy the applicable YouTube API Services policies.

## Clean-Room Rules

- Use official platform documentation, behavior observed from Yuzu's own authorized test runs, and self-authored fixtures.
- Do not inspect, translate, port, or adapt another client's source, DTO classes, request builders, constants, tests, fixtures, assets, or UI.
- Test fixtures contain invented titles, artists, IDs, and URLs; they must not contain captured user or upstream payloads.
- Document independently observed failure modes without reproducing another project's implementation structure.

## Project Structure

```text
lib/domain/media/               Yuzu-owned media/catalog contracts and models
lib/data/youtube_music/         Experimental transport and response mapping
test/domain/media/              Contract tests
test/data/youtube_music/        Offline mapper/transport tests
test/fixtures/youtube_music/    Small, self-authored sanitized fixtures
docs/decisions/                 Policy and architecture decisions
```

Task 14 may adapt these paths to existing repository conventions, but transport DTOs must remain under `lib/data/youtube_music/` and never enter `lib/features/`.

## Commands

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test --coverage
flutter build apk --debug
```

No command in Task 13 or 14 should contact YouTube. Live manual verification begins only after the policy checkpoint and must be separately documented.

## Testing Strategy

- Contract tests prove fake and experimental providers satisfy identical domain behavior.
- Mapper tests use only self-authored fixtures and cover missing fields, new item kinds, invalid types, empty pages, malformed JSON, and continuation loops.
- Transport tests use a fake HTTP boundary and cover timeout, cancellation, status mapping, response-size limits, redirect rejection, and bounded retries.
- Unit and widget tests remain deterministic and network-free.
- A live smoke test, if later approved, is manual/opt-in and never part of the default test suite or CI.

## Boundaries

- Always: validate upstream data, use HTTPS and a host allowlist, minimize data, keep the fake provider, sanitize diagnostics, and preserve source-neutral domain contracts.
- Ask first: send a live request, add a dependency, persist remote metadata or anonymous session state, change provider contracts, or expand the upstream host allowlist.
- Never: use account credentials, copy reference-client implementation material, log user/upstream payloads, bypass restrictions, download YouTube media, or couple UI/playback to transport DTOs.

## Success Criteria

- Guest catalog scope and excluded account/playback behavior are explicit.
- `CatalogProvider` and `StreamResolver` responsibilities cannot be confused or implemented as one adapter.
- Supported catalog operations, trust boundaries, privacy handling, failure categories, and test strategy are concrete.
- Official and unofficial approaches are distinguished, with a policy checkpoint before live access.
- Task 14 can define offline contracts and fixtures without making a network request.

## Open Questions

- Which upstream path will the maintainer approve at the policy checkpoint: official API, acknowledged unofficial experiment, or no live backend?
- If an official API is selected, how will Yuzu handle quota and credentials without pretending an API key embedded in a distributed APK is secret?
- What official application ID will replace `dev.yuzu.yuzu` before public distribution?

## Sources

- [YouTube Terms of Service](https://www.youtube.com/static?template=terms)
- [YouTube API Services Terms of Service](https://developers.google.com/youtube/terms/api-services-terms-of-service)
- [YouTube API Services Developer Policies](https://developers.google.com/youtube/terms/developer-policies)
- [YouTube Data API: Search](https://developers.google.com/youtube/v3/docs/search/list)
- [Google Privacy Policy](https://policies.google.com/privacy)
