# Space Explorer — iOS

A production-grade iOS SwiftUI application for exploring NASA open data, rebuilt from the [Android original](https://github.com/Aliipou/Space-Explorer).

## Features

| Tab | What it does |
|-----|-------------|
| **Explore** | Browse NASA Astronomy Picture of the Day — random or last 30 days. Search, favorite, share, full-screen zoom. |
| **Mars** | Photos from Curiosity, Perseverance, Opportunity, and Spirit. Filter by sol, Earth date, and camera. |
| **Favorites** | Bookmarked photos stored locally, available offline. |
| **Settings** | Add your own NASA API key, toggle haptics, clear cache. |

## Requirements

- **Xcode 15+**
- **iOS 17+** (uses `symbolEffect`, `@AppStorage`, `async/await`)
- A free [NASA API key](https://api.nasa.gov/) (optional — `DEMO_KEY` works with rate limits)

## Setup

### 1. Clone

```bash
git clone https://github.com/Aliipou/Space-Explorer-iOS.git
cd Space-Explorer-iOS
```

### 2. Open in Xcode

Open `SpaceExplorer.xcodeproj` in Xcode 15 or later.

### 3. Add your NASA API key (optional)

Either:
- Run the app → **Settings** → tap **API Key** → paste your key, or
- Set it in Xcode: Product → Scheme → Edit Scheme → Arguments → `NASA_API_KEY`

`DEMO_KEY` allows 30 requests/hour — sufficient for testing.

### 4. Build & Run

Select a simulator (iPhone 15 Pro recommended) and press **⌘R**.

## Architecture

```
SpaceExplorer/
├── Models/               # Codable data models (AstronomyPicture, MarsPhoto, AppError)
├── Networking/           # Actor-based NASAService + NetworkMonitor
├── ViewModels/           # @MainActor ObservableObjects (APODViewModel, MarsViewModel, FavoritesStore)
├── Views/
│   ├── APOD/             # APODListView, APODCardView, APODDetailView, FullScreenImageView
│   ├── Mars/             # MarsRoverView, MarsPhotoDetailView, MarsFilterSheet
│   ├── Favorites/        # FavoritesView
│   ├── Settings/         # SettingsView
│   ├── Onboarding/       # OnboardingView
│   └── Shared/           # SpaceTheme, StarFieldView, CachedAsyncImage, ErrorView
└── Utils/                # Constants, ImageCache, HapticFeedback, DateFormatters
```

**Pattern:** MVVM with a clean service layer.  
**Concurrency:** Swift `async/await` with `actor`-isolated network client.  
**Persistence:** `URLCache` for HTTP responses · in-memory `NSCache` for images · `UserDefaults` + `Codable` for favorites.  
**UI:** SwiftUI-only, dark space theme, `matchedGeometryEffect` hero transitions, `LazyVStack`/`LazyVGrid` for performance.

## Running Tests

```bash
xcodebuild test -scheme SpaceExplorer -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

Or press **⌘U** in Xcode.

Test coverage:
- `AstronomyPictureTests` — model logic, JSON decoding
- `APODViewModelTests` — loading, error states, search filtering
- `MarsViewModelTests` — loading, error states, defaults
- `FavoritesStoreTests` — toggle, persistence, ordering
- `AppErrorTests` — error descriptions, recovery suggestions
- `DateFormattersTests` — formatting, round-trips, date ranges

## API

All data comes from [NASA Open APIs](https://api.nasa.gov/):

- `GET /planetary/apod` — Astronomy Picture of the Day
- `GET /mars-photos/api/v1/rovers/{rover}/photos` — Mars rover photos

No third-party dependencies. Pure URLSession.

## License

MIT
