# GROOVD // ARCHIVE ⚡

> **UNCOMPROMISING MUSIC CRITIQUE. NEO-BRUTALIST DESIGN. SPOTIFY SYNC.**

[![Flutter](https://img.shields.io/badge/Flutter-3.13+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod_v3-blueviolet?style=for-the-badge)](https://riverpod.dev)
[![Spotify Web API](https://img.shields.io/badge/Spotify-Web_API_v1-1DB954?style=for-the-badge&logo=spotify&logoColor=black)](https://developer.spotify.com)
[![Design](https://img.shields.io/badge/Aesthetic-Neo--Brutalist-CCFF00?style=for-the-badge&labelColor=000000)](https://github.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-FF0055?style=for-the-badge)](https://flutter.dev)

---

## ⚡ Overview

**Groovd** is an editorial music rating and cataloging application inspired by underground physical zines, brutalist print typography, and modern digital critique platforms.

Unlike cookie-cutter streaming clients, Groovd treats music critique as high-contrast physical media: zero soft shadows, zero generic rounded cards, raw thick black borders, vivid neon accents, and a hyper-tactile 60fps micro-animation system.

---

## 💥 Features

### 🎧 Spotify Web API Catalog & Discography
- **Global Search**: Search albums, singles, EPs, and tracks with debounced live querying.
- **Full Album Inspection**: Dynamic fetching of tracklists with track numbers, durations, and release metadata.
- **Deep-linking**: Instant 1-tap jump from any album or track directly into Spotify.
- **Fail-Safe Offline Mode**: Bundled mock catalog ensuring seamless browsing even when offline or unconfigured.

### ✍️ Uncompromising Review Dispatch
- **10.0 Decimal Rating System**: Fine-tuned scoring from `0.0` to `10.0` with live descriptor badges (*"MASTERPIECE"*, *"CRITIC'S ESSENTIAL"*, *"CRITICAL SKIP"*).
- **Tactile Review Modal**: Real-time interactive slider with haptic ticks, live score scaling bounce, and dynamic glow shadows.
- **Editorial Tags**: Tag releases with vibe chips like `#PRODUCTION_HEAVEN`, `#MELANCHOLIC`, `#RAW_ENERGY`, and `#OVERRATED`.

### 🕹️ Neo-Brutalist Motion & Interaction Suite
- **Seamless Infinite Marquee**: 60fps continuous ticker banner scrolling custom editorial copy across the header.
- **Active Gliding Tab Navigation**: Sliding acid-lime indicator bar with icon bounce physics and fluid page transitions (`FadeThroughPageTransitionsBuilder`).
- **Elastic Heart Pops**: Custom spring animation sequence with electric-pink color shift and rolling counter for review likes.
- **Hero Artwork Zooms**: Smooth Hero transitions between home shelves, search listings, and detail header views.
- **Animated Score Progress Bar**: Tweened score meter that dynamically fills to the exact community consensus.
- **Cascading Staggered Reveals**: Smooth entrance animations for album shelves, rotation tracks, and community reviews via `flutter_animate`.

### 👤 Critic Dossier & Statistics
- **Personal Critic Identity**: Custom user handles, bios, and favorite genre tags.
- **Critic Archive**: Complete log of all your submitted reviews and community engagement.
- **Live In-App Configuration**: Update Spotify API credentials directly from the settings drawer without recompiling.

---

## 🎨 Design System & Palette

Groovd adheres to a strict, uncompromising neo-brutalist design system:

| Token | Hex Code | Visual | Purpose |
| :--- | :--- | :--- | :--- |
| **Pure Black** | `#0A0A0A` | `■` | Primary dark surface, bold 1.5–2.5px borders, hard drop shadows |
| **Acid Lime** | `#CCFF00` | `■` | Primary highlight, action buttons, 9.0+ ratings, active indicators |
| **Electric Pink** | `#FF0055` | `■` | Secondary accent, interactive hearts, live critique tags |
| **Cyber Cyan** | `#00F0FF` | `■` | Singles badge, secondary highlights, 8.0+ ratings |
| **Vermillion** | `#FF3B30` | `■` | Critical skip score badge, error states, warnings |
| **Surface Card** | `#141414` | `■` | Card and tile backgrounds with hard-edge framing |

**Typography**: Powered by `GoogleFonts.spaceGrotesk` for razor-sharp brutalist headings and `GoogleFonts.jetBrainsMono` for technical metadata, timestamps, and scores.

---

## 🏗️ Project Architecture

Built with **Flutter** and **Riverpod** following a feature-first clean architecture:

```
groovd/
├── android/               # Android native runner & Gradle configuration
├── ios/                   # iOS native workspace
├── lib/
│   ├── core/
│   │   ├── constants/     # SpotifyConfig and system constants
│   │   └── theme/         # BrutalistTheme, AppColors, AppTypography
│   ├── data/
│   │   ├── models/        # MusicItem, Review, Track models
│   │   ├── repositories/  # Spotify & Review repository interfaces & impls
│   │   └── services/      # SpotifyApiService & mock dataset
│   ├── presentation/
│   │   ├── navigation/    # MainNavigationScreen with animated tab bar
│   │   ├── screens/
│   │   │   ├── home/      # Zine header, marquee, trending, hot tracks
│   │   │   ├── search/    # Debounced search & filter chips (LP/Single)
│   │   │   ├── detail/    # Hero artwork, full tracklist, reviews
│   │   │   ├── profile/   # Critic Dossier, stats, and settings
│   │   │   └── review/    # Tactile modal with animated score slider
│   │   └── widgets/       # BrutalistButton, GiantScoreBadge, AlbumArtCard, MarqueeBanner
│   ├── state/             # Riverpod providers (music, review, search state)
│   └── main.dart          # App entry point
└── test/                  # Unit & widget test suite
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.13.3` or later)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / Xcode / VS Code with Flutter extension

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/<your-username>/Groovd.git
   cd Groovd/groovd
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Spotify API (Optional but Recommended)**:
   - Visit the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) and create an app.
   - Copy your **Client ID** and **Client Secret**.
   - Either configure them in `lib/core/constants/spotify_config.dart`:
     ```dart
     static const String clientId = 'YOUR_SPOTIFY_CLIENT_ID';
     static const String clientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET';
     ```
   - *Or* enter them inside the app via **DOSSIER (Profile) $\to$ Settings (Gear icon)** at runtime.

4. **Run the application**:
   ```bash
   flutter run
   ```

---

## 🧪 Testing & Code Quality

Groovd includes comprehensive unit and widget tests:

```bash
# Run all automated tests
flutter test

# Verify code formatting and lint rules
flutter analyze
```

---

## 📦 Key Dependencies

- **State Management**: [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod)
- **Motion & Animations**: [`flutter_animate`](https://pub.dev/packages/flutter_animate), [`animations`](https://pub.dev/packages/animations)
- **Typography**: [`google_fonts`](https://pub.dev/packages/google_fonts)
- **Networking & Caching**: [`http`](https://pub.dev/packages/http), [`cached_network_image`](https://pub.dev/packages/cached_network_image)
- **Persistence**: [`shared_preferences`](https://pub.dev/packages/shared_preferences), [`cloud_firestore`](https://pub.dev/packages/cloud_firestore)
- **Deep Linking**: [`url_launcher`](https://pub.dev/packages/url_launcher)

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

<p align="center">
  <b>GROOVD // 2026 ARCHIVE</b> • UNCOMPROMISING CRITIQUE
</p>
