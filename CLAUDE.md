# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Native iOS SwiftUI app for tracking movies and TV shows. Part of the movie_tracker monorepo — see `../CLAUDE.md` for full-stack context. The backend runs at `http://localhost:3000/api` during development.

## Build & Run

Open `WatchTracker/WatchTracker.xcodeproj` in Xcode. The only external dependency is **Supabase Swift (v2.5.1+)** via SPM — Xcode resolves it automatically.

The Xcode project uses `PBXFileSystemSynchronizedRootGroup`, so **any `.swift` file added anywhere under `WatchTracker/WatchTracker/` is automatically included in the target** — no need to edit `project.pbxproj`.

No linting tools are configured.

## Tests

Unit tests live in `WatchTracker/WatchTrackerTests/`, mirroring the source tree (`Core/…`, `Features/…`), plus `Mocks/` for test doubles and `Support/` for infrastructure (`Tags`, `TestFixtures`, `StubURLProtocol`, `ImmediateClock`). They use **Swift Testing** (`@Suite` / `@Test` / `#expect`) — never XCTest. The test target is also a `PBXFileSystemSynchronizedRootGroup`, so new test files are picked up automatically.

```bash
./scripts/test.sh                                  # whole suite + coverage report
./scripts/test.sh WatchTrackerTests/EndpointTests  # one suite
DEVICE="iPhone 15" ./scripts/test.sh               # different simulator
```

### Conventions

- Test names are backtick-quoted sentences: ``@Test func `posterURL uses the w342 TMDB size`()``
- Tag suites with `.tags(...)` from `Tags.swift` (`.model`, `.viewModel`, `.service`, `.pure`, `.async`)
- Use `@Test(arguments:)` for table-driven cases instead of repeating a test body
- Build models through `TestFixtures` (it decodes JSON, so private stored properties get populated)
- Never let a test touch the network, the disk, `UserDefaults.standard`, `UNUserNotificationCenter`, or PostHog. Inject the seam instead:
  - HTTP → `APIClient(session:tokenProvider:clock:)` with `StubURLProtocol.session(_:)`
  - A request that never lands → `StubURLProtocol.Stub.failing(_:)` with a `URLError.Code`
  - Debounce/retry delays → `ImmediateClock` (no real sleeping; assert on `clock.sleeps`)
  - Analytics → `AnalyticsTracking` / `MockAnalytics`
  - Notifications → `NotificationScheduling` / `MockNotificationScheduler`
  - Persistence → pass a `UserDefaults(suiteName:)` and tear it down
  - Files (`WatchlistStore`, `MutationOutbox`) → `InMemoryArchive`, which is already the default
  - Connectivity → `PreviewNetworkMonitor(isOnline:)`
  - Time → inject `now`/`calendar` (see `UpcomingViewModel`)

ViewModel dependencies are injected via init with production defaults, so adding a seam never changes a View call-site.

## Project Structure

All source lives under `WatchTracker/WatchTracker/`:

```
App/                          # Lifecycle + resources
  WatchTrackerApp, AppContainer, AppTabView, AppStartup, SplashView, Config
  Resources/                  # Assets.xcassets, Localizable.xcstrings

Core/                         # everything here is used by 2+ features
  Network/                    # APIClient (actor), Endpoint enum, APIError, RequestBodies
  Models/
    Media/                    # MediaDetail (+Genre/Credits/CastMember/WatchProvider*),
                              #   MediaType, Episode (+Season), StreamingProvider
    Watchlist/                # WatchItem, WatchlistStatus, ContinueWatchingItem (+NextEpisode),
                              #   UpcomingItem (+UpcomingEpisode), EpisodeWatchedResponse
    User/                     # ProfileStats, AppAppearance
  Services/                   # API services — each protocol, its live impl and its
                              #   Preview double all live in one file
                              #   Auth, Discover, MediaDetail, Watchlist, Profile,
                              #   Export, Import, AI (+ AIPromptBuilder), PreviewLibrary
  Infrastructure/
    Analytics/                # AnalyticsTracking, AnalyticsService, AnalyticsEvent
    Notifications/            # NotificationScheduling, NotificationService, NotificationDelegate
    Persistence/              # SearchHistoryManager, WatchlistStore, SupabaseManager
  Navigation/                 # AppRouter
  Localization/               # Strings.swift + Strings+<Feature>.swift
  Extensions/                 # Bundle+AppInfo, UIDevice+Hardware, Color+Extensions, Error+UserMessage

Components/                   # global UI — only what 2+ features use
  ErrorStateView, SkeletonView, PressedButtonStyle,
  SectionHeaderView, MediaRowSection, PosterCardView

Features/<Feature>/           # AI, Auth, Data, Detail, Discover, Home, Profile, Watching
  Models/                     # types only this feature uses
  Services/                   # logic only this feature uses (parsers, builders)
  ViewModels/
  Views/                      # navigable screens only — one per file
  Components/                 # every other View belonging to the feature
```

Every feature follows the same five-folder shape; create only the folders you actually need.

## Architecture

MVVM with feature-based modules.

**Data flow:** `AppContainer` → Views (`@State var viewModel`) → ViewModels (`@Observable`) → Services → `APIClient`

### Composition root — MANDATORY

`App/AppContainer.swift` is the **only** place a concrete dependency is named. It builds
every service, the router, the watchlist cache and every ViewModel, and it is created once
in `WatchTrackerApp.init` and passed down. It is deliberately not a singleton.

```swift
@MainActor @Observable final class AppContainer {   // @Observable only so `.environment(_:)` accepts it
    let auth: any AuthServiceProtocol
    let router: AppRouter
    let startup: AppStartup
    // every service is `private` — a View that could reach one is one edit from calling it
    func makeWatchlistViewModel() -> WatchlistViewModel { ... }
}
```

Two compositions: `AppContainer.live` (real services) and `AppContainer.preview` (the
`Preview…Service` doubles, so a canvas render never reaches the backend or the keychain).

**How a screen gets it.** Two forms, and the choice is mechanical:

| Situation | Form |
|---|---|
| The parent already holds the container (tab roots, one known call site) | `init(container:)`, then `_viewModel = State(wrappedValue: container.makeXViewModel())` |
| The screen is reachable from many call sites (`MediaDetailView`, `PersonView`, `BrowseGridView`) | `@Environment(AppContainer.self)` + an optional `@State` view model built in `.task` |

**Rules that keep it from eroding:**

1. **No ViewModel init may default a dependency to a concrete type or a `.shared`.** Every
   collaborator is required, and the container is the only thing that can supply them.
   Value seams (`UserDefaults`, `Calendar`, `Clock`, `now`) may still be defaulted.
2. **No View constructs a service, calls the network, or captures an analytics event.**
   Analytics a View triggers (a link tap) goes back through its ViewModel.
3. **No ViewModel calls `URLSession` or a backend SDK directly** — that always goes through
   its injected service.
4. `#Preview` blocks use `AppContainer.preview` (or a `Preview…Service`), never a live one.

Verify all four with:

```bash
grep -rn "\.shared" WatchTracker --include="*.swift" \
  | grep -v "URLSession.shared\|UIApplication.shared\|PostHogSDK.shared\|URLCache.shared" \
  | grep -v "App/AppContainer.swift" | grep -v "static let shared"
grep -rn "Service()\|AnalyticsService\.\|URLSession" WatchTracker/Features/*/Views \
  WatchTracker/Features/*/Components WatchTracker/Components
```

The first should only report `APIClient.supabaseTokenProvider`, which is `APIClient`'s own
default token source; the second should be empty apart from `PreviewAuthService()` in previews.

### Networking

`APIClient` is an `actor` singleton that handles all HTTP. It auto-injects the Supabase bearer token into every request and converts between snake_case JSON and camelCase Swift. Endpoints are defined as a type-safe `Endpoint` enum — add new API routes there.

Its timeouts are short on purpose (15s per request, 45s per resource) and `send(_:)` retries
**reads only** — a dropped connection or a 5xx gets two more attempts with a growing backoff,
a 429 gets one honouring `Retry-After`. Writes are never retried: the backend has no
idempotency keys, so a retried POST is a duplicate row.

### Offline — MANDATORY

The app is expected to work on a weak connection and to stay usable on none. Four rules, and
every one of them exists because breaking it produced a bug:

1. **Classify the failure before reacting to it.** `error.isConnectivityFailure`
   (`Core/Extensions/Error+Connectivity.swift`) separates "the request never left the device"
   from "the server answered no". Never branch on the `APIError` case for this.
2. **A failed refresh must never take content off the screen.** ViewModels report through
   `LoadFailure`: `.blocking` only when there is nothing to show, `.stale` (a `NoticeBanner`
   above the content) whenever cached content is on screen. Skeletons follow the same rule —
   `isLoading && items.isEmpty`, never `isLoading` alone.
3. **A write that fails on connectivity is queued, not reverted.** The optimistic change
   stands and the write goes to `MutationOutbox`; only a write the *server* refused rolls
   back and raises an error. `AppTabView` drains the queue through
   `AppContainer.syncPendingMutations()` when connectivity returns, before the screens refetch.
4. **Only Supabase may end a session.** `error.indicatesLostSession` is the single test, and
   `APIClient.supabaseTokenProvider` throws rather than sending an unauthenticated request
   when the token cannot be refreshed — an anonymous request earns a 401, and a 401 signs the
   user out, which turned "lost signal" into "logged out".

`NetworkMonitor` (`Core/Network/`) is advisory only: every request is still attempted and
every failure still handled. It drives the offline banner, the queue drain and the
refetch-on-reconnect, nothing else. `WatchlistStore` and `MutationOutbox` persist through
`FileArchiving` — `JSONFileArchive` in `AppContainer.live`, `InMemoryArchive` (the default)
everywhere else, so no test or preview writes to disk.

### Auth

`AuthService` (in `Core/Services/`) is `@Observable` like everything else — there is **no `@EnvironmentObject` anywhere in the app**. It's created in `WatchTrackerApp`, injected at the root with `.environment(authService)`, and read via `@Environment(AuthService.self)` in `AppTabView`. `AuthView`, `ForgotPasswordView`, and `ProfileView` instead take `auth: any AuthServiceProtocol` in their `init`, which is the seam tests use. It gates the entire UI (authenticated users see `AppTabView`, others see `AuthView`) and listens to Supabase auth state changes in real-time.

### Services

`Core/Services/` holds the services that talk to a backend — `WatchlistService`, `DiscoverService`,
`MediaDetailService`, `ProfileService`, `ImportService`, `ExportService` (thin wrappers translating
domain operations into `Endpoint` cases), `AuthService` (Supabase), plus `AIService` (on-device
`FoundationModels`). Each one declares its own protocol at the top of its file, so the contract and
the implementation stay together. Only give a type a protocol when it crosses a real boundary like
this — never an internal domain struct that has just one implementation.

Each file also carries a **`Preview<X>Service`** — an offline double serving `PreviewLibrary`
fixtures, used by `AppContainer.preview` and therefore by every `#Preview`. It lives beside the
protocol for the same reason the live impl does.

`WatchlistStore` owns the shared watchlist cache **and the policy for when it is stale** —
`replace(with:)`, `invalidate()`, `clear()` and `refresh(using:)`. Its properties are
`private(set)`: no ViewModel refetches-and-writes-both-fields by hand, which is what three of
them used to do.

Everything that is *not* a service lives elsewhere: `SupabaseManager` (shared `SupabaseClient`
singleton) in `Core/Infrastructure/Persistence/`, `AppRouter` in `Core/Navigation/`, and analytics,
notifications, and `UserDefaults` persistence under `Core/Infrastructure/`.

## Key Conventions

- ViewModels are `@Observable @MainActor final class`, never `ObservableObject`
- **Observable state is `private(set)`.** The only writable properties are the ones a View
  genuinely binds to: text fields, pickers, sheet/alert flags. Anything else changes through a
  method named for the user's action. Every ViewModel now holds to this; the writable
  properties left in the app are exactly the bindings — `selectedFilter`, `query`,
  `selectedType`/`selectedYear`, the auth text fields, `userInput` and the sheet flags.
- **Mutually exclusive situations are an enum, not loose flags.** `Detail` and `Discover` are the
  reference: `MediaDetailState`, `SeasonState`, `FeedState`. Write new screens this way. Keep a
  separate boolean only for work that is genuinely *concurrent* with the screen load — an
  in-flight write (`isSubmittingRating`, `pendingEpisodes`), never as a second way to say "loading"
- **Give a screen a ViewModel only when it earns one**: an async flow, a domain-to-presentation
  transform, validation/error handling, or 2+ service dependencies. A View that only formats and
  displays a value keeps its own `@State` instead. A ViewModel never imports SwiftUI beyond simple
  value types (`Color`, `Image`) and never holds a reference back to its View.
- Views call async ViewModel methods via `.task { }` modifier
- Parallel fetches use `async let` pattern (see `DiscoverView`)
- Loading/error states follow a consistent `isLoading` / `errorMessage` pattern in every ViewModel
- **User-facing error text always comes from `error.userFacingMessage`**, never
  `error.localizedDescription` — the extension is what turns a dropped connection into
  localized copy instead of a raw `NSURLError` string
- Custom brand colors defined in `Color+Extensions.swift` — use `Color.brandPrimary`, `.brandSecondary`, `.brandAccent`
- Image loading uses `AsyncImage` with `SkeletonView` placeholders — no third-party image library
- Five-tab navigation: Home (watchlist), Watching, Discover (search/trending), AI (suggestions), Profile

## Where does a new file go?

Two rules decide almost everything.

**Rule 1 — `Views/` is only for navigable screens.** A screen is something you reach through a
`NavigationLink`, a `.sheet`, or a tab. One screen per file. *Every other `View` goes in
`Components/`*, no matter its size. `StatsView` is a screen (it owns a `navigationTitle`);
`WatchlistCardView` is not.

**Rule 2 — `Core/` is only for what 2+ features use.** One consumer means it lives inside that
feature. This applies to components, models, and pure helpers alike — which is why there is no
`Core/Utilities/`: a folder that accepts anything becomes the next dumping ground.

Then, by kind:

| What you're adding | Where it goes |
|---|---|
| A screen | `Features/<X>/Views/` |
| Any other View | `Features/<X>/Components/`, or global `Components/` once a **second** feature uses it |
| A model used by one feature | `Features/<X>/Models/` |
| A model used by 2+ features | `Core/Models/<Media\|Watchlist\|User>/` |
| Pure logic owned by one feature (parser, builder, renderer) | `Features/<X>/Services/` |
| An API service | `Core/Services/` — **protocol, live impl and `Preview…` double all in one file** |
| A ViewModel factory | `AppContainer` — nothing else may build one |
| A cross-cutting concern (analytics, notifications, persistence) | `Core/Infrastructure/<Concern>/` |
| An `extension` on a system type | `Core/Extensions/`, named `Type+Concern.swift`, one type per file |
| Localization keys | `Core/Localization/Strings+<Feature>.swift` |

### Naming and file hygiene

- **One file = one concept**, not necessarily one type. `MediaDetail.swift` legitimately holds
  `Genre`, `Credits`, and `CastMember` — they are one cohesive payload. But the file's name must be
  the name of its **primary type**. A `SettingsRow.swift` that declares no `SettingsRow` is an
  organization bug.
- A type used by exactly one type in the same file should be `private`. Response envelopes scoped to
  a single service (`WatchedEpisodesResponse` in `MediaDetailService`) belong there, private — not
  promoted to `Core/Models/`.
- Banned suffixes for new files: `Support`, `Helpers`, `Utils`, `Manager`, and plural `...Models`.
  Each one is a request for a junk drawer. Name the concept instead.
- Existing components are inconsistent about the `View` suffix (`PosterCardView` vs
  `AISuggestionCard`). For **new** components: screens end in `View`, sub-components are named for
  what they are (`WatchingRow`, `ProfileAccountCard`).

### Promotion and demotion

A component moves to global `Components/` the moment it gains a second real caller — and moves back
down when it loses one. Reaching sideways into another feature's `Components/` folder is the signal
that something needs promoting. Current global components and their consumers:

| Component | Used by |
|---|---|
| `SkeletonView` | AI, Detail, Discover, Profile, Watching |
| `ErrorStateView` | AI, Detail, Discover, Home, Profile |
| `PressedButtonStyle` | AI, Detail, Discover, Home |
| `MediaRowSection` | Discover, Detail |
| `SectionHeaderView` | Discover, and `MediaRowSection` itself |
| `PosterCardView` | Discover, and `MediaRowSection` itself |

Do not merge visually-similar rows from different features into a generic component unless the
caller ergonomics stay clean.

## Localization — MANDATORY

**Never hardcode user-facing strings in Swift code.** All user-visible text must come from `Localizable.xcstrings` via the typesafe `Strings` enum in `Core/Localization/` (`Strings.swift` declares the namespace; the keys live in `Strings+<Feature>.swift`).

### Rules

1. **Any `Text("...")`, `Label("...", ...)`, `Button("...") { }`, navigation title, placeholder, or accessibility label that shows user-facing copy must reference `Strings.<Section>.<key>`** — not a literal string.
2. When adding new copy:
   - Add the key to `Localizable.xcstrings` (Xcode's String Catalog editor handles translations).
   - Add a matching accessor in the matching `Core/Localization/Strings+<Feature>.swift` under the appropriate nested enum (create a new file if the feature doesn't have one).
   - Use `String(localized: "section.key")` inside the accessor; keys must match the xcstrings file exactly.
   - For parameterized strings use a `static func` that interpolates into `String(localized:)` (see `Strings.Watching.episodeLabel(season:episode:)` for the pattern).
3. **`Text(verbatim: ...)` is ONLY for data coming from the API** (movie titles, episode names, user input) — never for static UI copy. API data is already user-provided content and should not be re-localized.
4. **Exception: branding.** The literal app name `"WatchTracker"` and the tagline in `AuthBrandingHeader` are brand assets, intentionally not localized.
5. **Never commit Portuguese, English, or any literal language strings directly in Swift.** If you see `Text("Continuar Assistindo")` or `Label("Ver detalhes", ...)`, that's a bug — fix it by adding the key to the catalog and routing through `Strings`.

### Examples

```swift
// ❌ Wrong — hardcoded literal
Text("Continue Watching")
Button("Sign In") { }
.navigationTitle("Discover")

// ✅ Right — routed through the catalog
Text(Strings.Home.continueWatching)
Button(Strings.Auth.signIn) { }
.navigationTitle(Strings.Discover.title)

// ✅ Right — verbatim is fine for API data
Text(verbatim: movie.title)
Text(verbatim: episode.name)

// ✅ Right — parameterized
Text(Strings.Watching.episodeLabel(season: 1, episode: 3))
```

When you spot existing violations while working nearby, fix them in the same change rather than leaving them.
