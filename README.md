<div align="center">

# Space Explorer — iOS

**A production-grade SwiftUI app for exploring NASA's universe of imagery.**

Browse the Astronomy Picture of the Day archive, explore raw photos from Mars rovers, save your favorites, and zoom into the cosmos — all in a stunning dark space-themed UI.

[![iOS](https://img.shields.io/badge/iOS-17%2B-000000?style=flat&logo=apple)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-FA7343?style=flat&logo=swift)](https://swift.org/)
[![Xcode](https://img.shields.io/badge/Xcode-15%2B-147EFB?style=flat&logo=xcode)](https://developer.apple.com/xcode/)
[![CI](https://github.com/Aliipou/SpaceWeather-iOS/actions/workflows/ci.yml/badge.svg)](https://github.com/Aliipou/SpaceWeather-iOS/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-55%2B_cases-brightgreen?style=flat)](SpaceExplorerTests/)

Android companion: [Space-Explorer (Kotlin)](https://github.com/Aliipou/Space-Explorer)

</div>

---

## Features

### Astronomy Picture of the Day (APOD)
- **Random mode** — 20 random entries from NASA's full archive
- **Recent mode** — last 30 days in reverse chronological order
- **Live search** — debounced, matches title and explanation
- Hero transition (matchedGeometryEffect) → detail view
- Full-screen pinch-to-zoom (1×–5×, double-tap toggle)
- Share sheet, open HD image in browser
- Copyright attribution

### Mars Rover Photos
- Four rovers: **Curiosity**, **Perseverance**, **Opportunity**, **Spirit**
- Filter by Martian **sol** or **Earth date** and **camera type**
- Lazy photo grid, full detail view per photo
- Full-screen tap-to-zoom

### Favorites — CoreData persisted
- Heart any APOD photo, persists across app restarts
- CoreData + `NSFetchedResultsController` for live updates
- Swipe-to-delete, clear all with confirmation
- Available fully offline

### Push Notifications
- Daily APOD reminder at configurable time
- Background fetch via `BGAppRefreshTask` — notifies when new photo arrives
- Tapping notification deep-links directly to APOD tab

### Deep Linking
- Full URL scheme: `spaceexplorer://`
- `spaceexplorer://apod/2024-01-15` → opens that specific date
- `spaceexplorer://mars/curiosity` → Mars tab with rover pre-selected
- `spaceexplorer://favorites` / `spaceexplorer://settings`

### Resilient Networking
- **Exponential backoff retry** with jitter (configurable `RetryPolicy`)
- Per-error retry eligibility (rate limit → don't retry; 5xx → retry)
- 500 MB disk cache + 100 MB memory cache via `URLCache`
- Live **network monitor** with offline banner

### Settings
- NASA API key management (30 → 1,000 req/hour)
- Toggle haptic feedback
- Configure notification time
- Clear caches

### Onboarding
- 4-page animated onboarding on first launch
- Star field background, spring dot indicator

---

## Architecture

```
SpaceExplorer/
│
├── SpaceExplorerApp.swift          # @main, URLCache, appearance, BGTask registration
├── ContentView.swift               # Onboarding gate + TabView + deep-link routing
│
├── Models/
│   ├── AstronomyPicture.swift
│   ├── MarsPhoto.swift
│   └── AppError.swift              # Typed errors + isRetryable flag
│
├── Networking/
│   ├── NASAService.swift           # actor, async/await, retry-wrapped
│   ├── NetworkMonitor.swift        # NWPathMonitor, @Published
│   └── RetryPolicy.swift           # Exponential backoff with jitter
│
├── Persistence/
│   ├── PersistenceController.swift # NSPersistentContainer, background context
│   ├── SpaceExplorer.xcdatamodeld  # CoreData model: FavoriteEntity, SearchHistoryEntity
│   └── FavoriteEntity+Extensions.swift  # to/from domain, fetch requests
│
├── Notifications/
│   ├── NotificationManager.swift   # UNUserNotificationCenter, delegate
│   └── BackgroundTaskManager.swift # BGAppRefreshTask, schedule + handle
│
├── DeepLink/
│   └── DeepLinkHandler.swift       # URL scheme parser, @Published pendingLink
│
├── ViewModels/
│   ├── APODViewModel.swift         # @MainActor, search, load modes
│   ├── MarsViewModel.swift         # @MainActor, query state
│   └── FavoritesStore.swift        # @MainActor, CoreData-backed
│
├── Views/
│   ├── APOD/                       # APODListView, APODCardView, APODDetailView, FullScreenImageView
│   ├── Mars/                       # MarsRoverView, MarsPhotoDetailView
│   ├── Favorites/                  # FavoritesView
│   ├── Settings/                   # SettingsView
│   ├── Onboarding/                 # OnboardingView
│   └── Shared/                     # SpaceTheme, StarFieldView, CachedAsyncImage, ErrorView
│
└── Utils/
    ├── Constants.swift
    ├── ImageCache.swift            # actor NSCache
    ├── HapticFeedback.swift
    └── DateFormatters.swift
```

### Design Patterns

| Concern | Solution |
|---|---|
| State management | MVVM — `ObservableObject` + `@Published` |
| Concurrency | `actor` + `async/await` throughout |
| Dependency injection | `NASAServiceProtocol` — real vs mock in tests |
| Shared state | `@EnvironmentObject` (Favorites, Network, DeepLink, Notifications) |
| Persistence | CoreData (favorites) + URLCache (HTTP) + NSCache (images) |
| Navigation | `NavigationStack` + `matchedGeometryEffect` |
| Resilience | `RetryPolicy` with exponential backoff + jitter |
| Deep linking | `onOpenURL` + `DeepLinkHandler` with tab routing |
| Background work | `BGAppRefreshTask` + push notifications |

---

## CI/CD

GitHub Actions runs on every push to `master`/`main`/`develop` and every pull request:

```
.github/workflows/ci.yml
  ├── build-and-test  →  xcodebuild test on iPhone 15 Pro (iOS 17.5)
  └── lint            →  SwiftLint with project rules
```

Results published as workflow artifacts. Build badge in README updates automatically.

---

## Requirements

| Requirement | Version |
|---|---|
| Xcode | 15.0+ |
| iOS deployment target | 17.0+ |
| Swift | 5.9 |
| Dependencies | **None** — pure URLSession, SwiftUI, CoreData, BackgroundTasks |

---

## Quick Start

```bash
git clone https://github.com/Aliipou/SpaceWeather-iOS.git
cd SpaceWeather-iOS
open SpaceExplorer.xcodeproj
```

Select **iPhone 15 Pro** simulator → **⌘R**

**Optional:** Add your free NASA API key at [api.nasa.gov](https://api.nasa.gov/) via **Settings → API Key** to increase rate limit from 30 to 1,000 req/hour.

---

## Deep Link Examples

```bash
# Open from terminal (simulator)
xcrun simctl openurl booted "spaceexplorer://apod"
xcrun simctl openurl booted "spaceexplorer://apod/2024-01-15"
xcrun simctl openurl booted "spaceexplorer://mars/curiosity"
xcrun simctl openurl booted "spaceexplorer://favorites"
xcrun simctl openurl booted "spaceexplorer://settings"
```

---

## Running Tests

```bash
# Xcode
⌘U

# Command line
xcodebuild test \
  -scheme SpaceExplorer \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.5' \
  -resultBundlePath TestResults.xcresult
```

---

## Test Coverage

**12 test files · 55+ test cases** — zero third-party test frameworks.

### Unit Tests

| File | Cases | What's tested |
|---|---|---|
| `AstronomyPictureTests` | 9 | Model logic, JSON decoding, URL selection, date formatting |
| `APODViewModelTests` | 10 | Loading, errors, retry, search filter, mode switching |
| `MarsViewModelTests` | 7 | Loading, errors, defaults, camera list |
| `FavoritesStoreTests` | 6 | Toggle, ordering, remove, clear |
| `AppErrorTests` | 8 | Descriptions, recovery suggestions, SF symbols, equality |
| `MarsPhotoTests` | 6 | JSON decoding, rover metadata, URL validity |
| `DateFormattersTests` | 5 | ISO round-trip, display format, date ranges |
| `NASAServiceSecurityTests` | 6 | No hardcoded keys, HTTPS only, no leaks, sanitization |

### Integration Tests

| File | Cases | What's tested |
|---|---|---|
| `RetryPolicyTests` | 7 | Exponential backoff, jitter, max attempts, non-retryable errors |
| `DeepLinkHandlerTests` | 12 | All URL patterns, invalid input, tab index mapping, consume |
| `PersistenceTests` | 6 | CoreData CRUD, round-trip, isolation, sort order |
| `NotificationManagerTests` | 4 | Category strings, notification names, deep-link from notification |

---

## API Reference

All data from [NASA Open APIs](https://api.nasa.gov/) — no third-party services.

```
GET https://api.nasa.gov/planetary/apod
  ?api_key=KEY&count=20&thumbs=true

GET https://api.nasa.gov/planetary/apod
  ?api_key=KEY&start_date=2024-01-01&end_date=2024-01-31

GET https://api.nasa.gov/mars-photos/api/v1/rovers/{rover}/photos
  ?api_key=KEY&sol=1000&camera=FHAZ
```

**Rovers:** `curiosity` · `perseverance` · `opportunity` · `spirit`

---

## Security

- No API keys committed — `DEMO_KEY` fallback only, real keys in `UserDefaults`
- HTTPS enforced via `NSAppTransportSecurity` whitelist in `Info.plist`
- Zero third-party SDKs — no supply-chain risk
- `javascript:` and non-HTTPS URLs rejected before display
- Typed `AppError` enum prevents raw server errors reaching the UI
- Background fetch isolated via `BGTaskScheduler` — no unbounded network usage

---

## Performance

| Technique | Detail |
|---|---|
| `LazyVStack` / `LazyVGrid` | Renders only visible cells |
| `URLCache` | 500 MB disk — repeat fetches are free |
| `actor NSCache` | 50 MB in-memory image cache |
| Exponential backoff | Prevents hammering a degraded API |
| Debounced search | 300 ms — no API calls on each keystroke |
| `BGAppRefreshTask` | Content updated while app is backgrounded |
| `@MainActor` ViewModels | All UI updates on main thread, zero data races |

---

## License

MIT

---

## Related

- [Space-Explorer (Android/Kotlin)](https://github.com/Aliipou/Space-Explorer)
- [NASA Open APIs](https://api.nasa.gov/)
