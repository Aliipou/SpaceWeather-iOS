<div align="center">

# Space Explorer — iOS

**A production-grade SwiftUI app for exploring NASA's universe of imagery.**

Browse the Astronomy Picture of the Day archive, explore raw photos from Mars rovers, save your favorites, and zoom into the cosmos — all in a stunning dark space-themed UI.

[![iOS](https://img.shields.io/badge/iOS-17%2B-000000?style=flat&logo=apple)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-FA7343?style=flat&logo=swift)](https://swift.org/)
[![Xcode](https://img.shields.io/badge/Xcode-15%2B-147EFB?style=flat&logo=xcode)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-40%2B_cases-brightgreen?style=flat)](SpaceExplorerTests/)

Android companion: [Space-Explorer (Kotlin)](https://github.com/Aliipou/Space-Explorer)

</div>

---

## Screenshots

| Explore | Detail | Mars Rover | Favorites |
|---|---|---|---|
| APOD grid with search | Full-screen hero + explanation | Photo grid + filters | Saved collection |

---

## Features

### Astronomy Picture of the Day (APOD)
- Browse NASA's full APOD archive — images and videos
- **Random mode**: 20 random entries from NASA's database
- **Recent mode**: last 30 days in reverse chronological order
- **Live search** across titles and explanations (debounced, instant)
- Tappable card → hero transition → detail view
- Full-screen pinch-to-zoom image viewer (1×–5×, double-tap to toggle)
- Share sheet (share URL + title)
- Open HD image or video in browser
- Copyright attribution display

### Mars Rover Photos
- Four rovers: **Curiosity**, **Perseverance**, **Opportunity**, **Spirit**
- Filter by **Martian sol** (stepper), **Earth date** (date picker), and **camera**
- Photo grid with lazy loading
- Full detail view: rover, camera, sol, Earth date, photo ID
- Full-screen tap-to-zoom for each photo

### Favorites
- Heart button on any APOD photo — instant local save
- Animated heart with spring feedback
- Favorites tab with badge count
- Swipe-to-delete individual entries
- Clear all with confirmation dialog
- Persisted via `UserDefaults` + `Codable` — survives app restart
- Available offline

### Settings
- Add your own NASA API key (increases rate limit from 30 → 1,000 req/hour)
- Get a free key link → `api.nasa.gov`
- Toggle haptic feedback
- Clear image/HTTP cache
- App version, build number, API docs link

### Onboarding
- 4-page animated onboarding on first launch
- Twinkling star field background
- Dot page indicator with spring animation
- Skips automatically on subsequent launches

### Infrastructure
- **Offline support** — URLCache (500 MB disk) serves stale responses when offline
- **Network monitor** — live banner when connection drops
- **In-memory image cache** — `NSCache` (50 MB) prevents re-fetching on scroll
- **Haptic feedback** — configurable, used on interactions and confirmations
- **Dark space theme** — enforced system-wide, never switches to light

---

## Architecture

```
SpaceExplorer/
│
├── SpaceExplorerApp.swift          # @main entry, URLCache + appearance setup
├── ContentView.swift               # Root: Onboarding gating + TabView
│
├── Models/
│   ├── AstronomyPicture.swift      # Codable, Identifiable, Hashable
│   ├── MarsPhoto.swift             # MarsPhoto, MarsCamera, MarsRoverInfo, MarsRover enum
│   └── AppError.swift              # Typed errors with descriptions + recovery suggestions
│
├── Networking/
│   ├── NASAService.swift           # actor NASAService: NASAServiceProtocol (async/await)
│   └── NetworkMonitor.swift        # NWPathMonitor wrapper, @Published isConnected
│
├── ViewModels/
│   ├── APODViewModel.swift         # @MainActor, search debounce, load modes
│   ├── MarsViewModel.swift         # @MainActor, sol/date/camera query state
│   └── FavoritesStore.swift        # Singleton @MainActor, Codable persistence
│
├── Views/
│   ├── APOD/
│   │   ├── APODListView.swift      # LazyVStack, search, skeleton loading, offline banner
│   │   ├── APODCardView.swift      # matchedGeometryEffect, FavoriteButton
│   │   ├── APODDetailView.swift    # Hero detail, action bar, share sheet
│   │   └── FullScreenImageView.swift  # Pinch + drag gestures, double-tap zoom
│   ├── Mars/
│   │   ├── MarsRoverView.swift     # Rover picker, LazyVGrid, filter sheet
│   │   └── MarsPhotoDetailView.swift  # Info rows, full-screen tap
│   ├── Favorites/
│   │   └── FavoritesView.swift     # List with swipe-delete, clear all
│   ├── Settings/
│   │   └── SettingsView.swift      # API key sheet, cache clear, links
│   ├── Onboarding/
│   │   └── OnboardingView.swift    # TabView pages, dot indicator, CTA
│   └── Shared/
│       ├── SpaceTheme.swift        # Colors, gradients, fonts, card modifier
│       ├── StarFieldView.swift     # 120-star animated parallax background
│       ├── CachedAsyncImage.swift  # AsyncImage wrapper + ImageShimmer placeholder
│       └── ErrorView.swift        # ErrorView + EmptyStateView components
│
└── Utils/
    ├── Constants.swift             # API config, rover data, cache sizes, UserDefaults keys
    ├── ImageCache.swift            # actor NSCache wrapper, cost-based eviction
    ├── HapticFeedback.swift        # UIImpact/Notification/Selection, respects user pref
    └── DateFormatters.swift        # ISO 8601 ↔ display string, date range helpers
```

### Design Patterns

| Concern | Solution |
|---|---|
| State management | MVVM — `ObservableObject` + `@Published` |
| Concurrency | Swift `async/await` + `actor` for thread-safe network + cache |
| Dependency injection | Protocol `NASAServiceProtocol` — swapped for mocks in tests |
| Shared environment | `@EnvironmentObject` for `FavoritesStore` + `NetworkMonitor` |
| Navigation | `NavigationStack` + `matchedGeometryEffect` hero transitions |
| Persistence | `URLCache` (HTTP) + `NSCache` (images) + `UserDefaults` (favorites, settings) |

---

## Requirements

| Requirement | Version |
|---|---|
| Xcode | 15.0+ |
| iOS deployment target | 17.0+ |
| Swift | 5.9 |
| Dependencies | None — pure `URLSession`, `SwiftUI`, `Network` |

---

## Quick Start

### 1. Clone

```bash
git clone https://github.com/Aliipou/SpaceWeather-iOS.git
cd SpaceWeather-iOS
```

### 2. Open in Xcode

```bash
open SpaceExplorer.xcodeproj
```

Or double-click `SpaceExplorer.xcodeproj` in Finder.

### 3. Run

Select **iPhone 15 Pro** simulator → **⌘R**

The app launches with the onboarding flow on first run. It uses `DEMO_KEY` by default (30 req/hour — enough for testing).

### 4. Add your NASA API key (optional but recommended)

Get a free key at [api.nasa.gov](https://api.nasa.gov/) — takes 10 seconds.

In the running app: **Settings tab → API Key → paste key → Save**

This increases your limit to **1,000 requests/hour**.

---

## Running Tests

### From Xcode
Press **⌘U** or go to **Product → Test**

### From command line

```bash
xcodebuild test \
  -scheme SpaceExplorer \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0' \
  -resultBundlePath TestResults.xcresult
```

---

## Test Coverage

**8 test files · 40+ test cases** — zero third-party test frameworks, pure `XCTest`.

### `AstronomyPictureTests` (8 cases)
| Test | What it verifies |
|---|---|
| `test_isImage_trueWhenMediaTypeIsImage` | `isImage` / `isVideo` computed properties |
| `test_isVideo_trueWhenMediaTypeIsVideo` | Video media type detection |
| `test_formattedCopyright_prependsSymbol` | `© ` prefix on copyright string |
| `test_shortExplanation_truncatesLongText` | 120-char truncation with `…` |
| `test_shortExplanation_doesNotTruncateShortText` | No-op on short text |
| `test_displayImageURL_prefersHdurl` | HD URL takes priority over SD |
| `test_displayImageURL_fallsBackToUrl_whenHdurlNil` | Fallback to `url` field |
| `test_jsonDecoding_snakeCaseKeys` | `media_type` → `mediaType`, `service_version` → `serviceVersion` |
| `test_formattedDate_returnsReadableString` | `2024-01-15` → `January 15, 2024` |

### `APODViewModelTests` (9 cases)
| Test | What it verifies |
|---|---|
| `test_load_populatesPictures_onSuccess` | Happy path: pictures set, error nil, isLoading false |
| `test_load_setsError_onNetworkFailure` | `.networkUnavailable` error propagation |
| `test_load_setsError_onRateLimit` | `.rateLimitExceeded` error propagation |
| `test_load_clearsError_onSuccessfulRetry` | Error cleared on successful subsequent load |
| `test_refresh_clearsPicturesFirst` | Pictures array emptied before reload |
| `test_switchMode_toRecent_callsDateRange` | Mode switch triggers date-range fetch |
| `test_switchMode_sameMode_doesNotReload` | No duplicate network call when mode unchanged |
| `test_filteredPictures_returnsAll_whenSearchTextEmpty` | Full list when search is blank |
| `test_filteredPictures_filtersBy_titleMatch` | Case-insensitive title search |
| `test_filteredPictures_returnsEmpty_whenNoMatch` | Empty result + `hasResults = false` |

### `MarsViewModelTests` (7 cases)
| Test | What it verifies |
|---|---|
| `test_load_populatesPhotos_onSuccess` | Photos array populated |
| `test_load_setsNoResultsError_whenEmpty` | Empty response → `.noResults` error |
| `test_load_setsNetworkError` | Network failure propagation |
| `test_defaultRover_isCuriosity` | Default rover selection |
| `test_defaultQueryMode_isSol` | Default query mode |
| `test_availableCameras_containsAll` | "All" always present in camera list |
| `test_refresh_clearsThenReloads` | Clears state before fresh fetch |

### `FavoritesStoreTests` (6 cases)
| Test | What it verifies |
|---|---|
| `test_toggle_addsFavorite` | First toggle saves item |
| `test_toggle_removesFavorite_whenAlreadyFavorited` | Second toggle removes item |
| `test_isFavorite_returnsFalse_whenNotFavorited` | Non-saved item returns false |
| `test_remove_atOffsets` | IndexSet removal |
| `test_clearAll_removesEverything` | Full wipe |
| `test_addingMultipleFavorites_maintainsOrder` | Latest favorite inserted at index 0 |

### `AppErrorTests` (8 cases)
| Test | What it verifies |
|---|---|
| `test_errorDescription_networkUnavailable` | Human-readable message present |
| `test_errorDescription_rateLimitExceeded` | Rate limit message |
| `test_errorDescription_invalidResponse_includesStatusCode` | Status code embedded in message |
| `test_recoverySuggestion_rateLimitExceeded_mentionsSettings` | Recovery directs to Settings |
| `test_systemImage_networkUnavailable` | `wifi.slash` SF Symbol |
| `test_systemImage_rateLimit` | `key.slash` SF Symbol |
| `test_systemImage_noResults` | `magnifyingglass` SF Symbol |
| `test_equality` | `Equatable` conformance across all cases |

### `MarsPhotoTests` (6 cases)
| Test | What it verifies |
|---|---|
| `test_jsonDecoding_fullPayload` | Full nested JSON with snake_case keys |
| `test_marsRover_isActive_curiosityTrue` | Active rover detection |
| `test_marsRover_isActive_opportunityFalse` | Completed mission detection |
| `test_marsRover_availableCameras_containsAll` | Camera list completeness for all rovers |
| `test_marsPhoto_imageURL_validURL` | HTTPS URL from `img_src` |
| `test_marsPhoto_formattedEarthDate` | Long date format (no raw dashes) |

### `DateFormattersTests` (5 cases)
| Test | What it verifies |
|---|---|
| `test_isoString_roundtrips` | `Date` → `"yyyy-MM-dd"` |
| `test_displayString_formatsReadably` | ISO → `"January 15, 2024"` |
| `test_displayString_returnsRaw_whenInvalidInput` | Graceful fallback on bad input |
| `test_dateRangeStrings_startBeforeEnd` | Start < End in generated range |
| `test_dateRangeStrings_correctInterval` | Correct day interval (7 days = 7) |

### `NASAServiceSecurityTests` (6 cases)
| Test | What it verifies |
|---|---|
| `test_apiKey_isNotHardcoded_inSource` | Fallback is `DEMO_KEY`, no real key embedded |
| `test_baseURL_usesHTTPS` | All API URLs use HTTPS scheme |
| `test_appError_rateLimitExceeded_doesNotLeakAPIKey` | Error messages don't leak secrets |
| `test_apiKeyStorage_usesUserDefaults_notPlainTextFile` | Key stored/retrieved via `UserDefaults` |
| `test_apodImageURL_rejectsJavaScriptScheme` | `javascript:` URLs don't produce valid display URLs |
| `test_favoritesPersistence_doesNotStoreAPIKeys` | Favorites and API key use separate storage keys |

---

## API Reference

All data comes from [NASA Open APIs](https://api.nasa.gov/) — no third-party services.

### Astronomy Picture of the Day

```
GET https://api.nasa.gov/planetary/apod
  ?api_key=YOUR_KEY
  &count=20               # random N entries
  &start_date=2024-01-01  # or date range
  &end_date=2024-01-31
  &thumbs=true            # include video thumbnails
```

### Mars Rover Photos

```
GET https://api.nasa.gov/mars-photos/api/v1/rovers/{rover}/photos
  ?api_key=YOUR_KEY
  &sol=1000               # Martian day
  &earth_date=2015-05-30  # or Earth date
  &camera=FHAZ            # optional camera filter
```

**Rovers:** `curiosity` · `perseverance` · `opportunity` · `spirit`

**Cameras:** `FHAZ` · `RHAZ` · `MAST` · `CHEMCAM` · `MAHLI` · `MARDI` · `NAVCAM` · `PANCAM`

---

## Security

- **No API keys committed** — `DEMO_KEY` is the only hardcoded value; real keys are stored in `UserDefaults` at runtime
- **HTTPS enforced** — `Info.plist` `NSAppTransportSecurity` whitelist only allows `api.nasa.gov` and `mars.nasa.gov`; all connections require TLS
- **No third-party SDKs** — zero supply-chain risk; only Apple frameworks used
- **Input validation** — `javascript:` and non-HTTPS URLs are rejected before display
- **Error messages sanitized** — typed `AppError` enum prevents raw server responses leaking to UI

---

## Performance

| Technique | Detail |
|---|---|
| `LazyVStack` / `LazyVGrid` | Only renders visible cells |
| `URLCache` | 500 MB disk cache — repeat fetches are free |
| `NSCache` (actor) | 50 MB in-memory image cache, cost-based eviction |
| `async/await` | Non-blocking network calls, no thread explosion |
| Debounced search | 300 ms debounce prevents API calls on every keystroke |
| `@MainActor` ViewModels | All UI updates guaranteed on main thread |

---

## Contributing

1. Fork the repo
2. Create a branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Run tests: **⌘U**
5. Push and open a PR

---

## License

MIT — see [LICENSE](LICENSE)

---

## Related

- [Space-Explorer (Android/Kotlin)](https://github.com/Aliipou/Space-Explorer) — the original Android companion app
- [NASA Open APIs](https://api.nasa.gov/) — free API portal
