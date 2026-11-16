# GROOVD // ARCHIVE

> **UNCOMPROMISING MUSIC CRITIQUE. NEO-BRUTALIST DESIGN. AUTONOMOUS AI CRITIC. DUAL CATALOG SYNC.**

[![Flutter](https://img.shields.io/badge/Flutter-3.13+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod_v3-blueviolet?style=for-the-badge)](https://riverpod.dev)
[![Spotify Web API](https://img.shields.io/badge/Spotify-Web_API_v1-1DB954?style=for-the-badge&logo=spotify&logoColor=black)](https://developer.spotify.com)
[![Deezer API](https://img.shields.io/badge/Deezer-Catalog_API-FF0055?style=for-the-badge)](https://developers.deezer.com)
[![Design](https://img.shields.io/badge/Aesthetic-Neo--Brutalist-CCFF00?style=for-the-badge&labelColor=000000)](https://github.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-FF0055?style=for-the-badge)](https://flutter.dev)

---

## // OVERVIEW

**Groovd** is an editorial music rating, cataloging, and critique platform inspired by underground physical zines, brutalist print typography, and high-contrast digital media.

Unlike generic streaming clients, Groovd treats music critique as physical media: zero soft blurs, zero generic rounded corners, raw thick black borders, vivid neon accents, and a hyper-tactile 60fps micro-interaction system. Groovd integrates dual catalog engines, an uncompromising resident AI music critic with multimodal vision, track-by-track scoring with spike badge insignias, a Wantlist with Sonic Roulette, and community tastemaker discovery.

---

## // CORE CAPABILITIES

### [01] DUAL-CATALOG MUSIC DISCOVERY (SPOTIFY & DEEZER)
- **Global Search**: Debounced live querying across albums, EPs, singles, and individual tracks.
- **Deep Tracklist Inspection**: Full album metadata, track sequences, durations, and release credits.
- **Deezer Resilient Fallback**: Automatic recovery for catalog gaps, sequential track numbering, artwork resolution, and transliterated international artist names.
- **1-Tap Streaming Link**: Instant deep-linking from any album or track into streaming playback.
- **Fail-Safe Offline Mode**: Bundled mock catalog ensuring smooth offline browsing and instant startup.

### [02] GROOVD AI // RESIDENT MUSIC CRITIC
- **Autonomous Editorial Persona**: Sharp, knowledgeable, underground music critic with an uncompromising zine personality.
- **Multimodal Vision Input**: Attach photos of vinyl setups, turntable gear, physical records, or album art from camera or gallery for direct visual evaluation.
- **Interactive Photo Zoom Viewer**: Pinch-to-zoom and double-tap inspection viewer for attached gear and record images.
- **Dynamic Scramble Decode**: 60fps retro scramble text decoder animation that streams replies before resolving cleanly into styled markdown.
- **Typography & Markdown Engine**: Custom brutalist markdown parser rendered in Space Mono typography with rich embedded album recommendation cards.
- **Conversation Archive & Live Search**: Multi-turn sessions persisted locally with real-time in-header search across session titles and message contents.
- **Keyboard-Adaptive Architecture**: Seamless view-inset handling keeping inputs and controls elevated and accessible above the software keyboard.

### [03] UNCOMPROMISING REVIEW DISPATCH
- **10.0 Decimal Rating Scale**: Fine-tuned scoring from 0.0 to 10.0 with dynamic tier descriptors (MASTERPIECE, CRITIC'S ESSENTIAL, SOLID ROTATION, MIXED FEELINGS, CRITICAL SKIP).
- **Tactile Review Modal**: Interactive brutalist slider with haptic ticks, live score scale bounce, and hard drop-shadows.
- **Editorial Vibe Tags**: Categorize releases with tags like `#PRODUCTION_HEAVEN`, `#MELANCHOLIC`, `#RAW_ENERGY`, `#OVERRATED`.
- **Differentiated Critiques**: Distinguish full written editorial reviews from quick numerical ratings.

### [04] TRACKLIST SCORING & RATING SPIKE SYSTEM
- **Track-by-Track Ratings**: Score individual tracks with a real-time running average calculating the overall release score.
- **Interlude Exclusions**: Flag skits and interludes so non-musical tracks do not artificially skew album consensus.
- **Rating Spike Insignia**: Custom geometric indicator:
  - Hollow 4-point spike for scores <= 6.0
  - Solid 4-point spike for scores 6.1 - 9.4
  - 8-point super-spike for scores 9.5 - 10.0 (Masterpieces)
- **Shareable Scorecard Cards**: Animated story-ready scorecard deck with zoom intro sequence and exportable summary.
- **Adaptive Title Typography**: Automatic layout adjustments preventing layout breaks on long single-word titles.

### [05] WANTLIST & SONIC ROULETTE
- **Catalog Wantlist**: Grid (3x3 album covers) and detailed list viewing modes for your vinyl queue and listen-later pile.
- **Sonic Roulette**: Neo-brutalist animated tumbler roll dock that randomly picks your next listen, filtering by LP or Song.
- **Automatic Wantlist Pruning**: Items in your wantlist automatically resolve and archive upon review submission.

### [06] SOCIAL DOSSIER & TASTEMAKER NETWORK
- **Critic Dossier**: Personal critic profile with top pinned picks, favorite genres, bio, and review statistics.
- **Suggested Tastemakers Feed**: Discover other active critics with shared taste profiles.
- **Friend Profiles**: Explore other critics' podium top picks, curated custom lists, wantlists, and review logs.
- **Relationship Mechanics**: Follow, unfollow, and reciprocal follow-back indicators.

### [07] HYBRID CLOUD & OFFLINE-FIRST ARCHITECTURE
- **Cloud Backup**: Firebase Firestore hybrid synchronization for reviews, top picks, and user dossiers.
- **Offline Resilience**: Full local persistence using SharedPreferences and local repositories with automatic cloud reconciliation.
- **Guest-to-Cloud Transition**: Smooth onboarding allowing local-first usage with instant cloud sync upgrade.

---

## // NEO-BRUTALIST DESIGN SYSTEM

Groovd adheres to a strict, uncompromising neo-brutalist design system:

| Token | Hex Code | Visual | Purpose |
| :--- | :--- | :--- | :--- |
| **Pure Black** | `#0A0A0A` | [ # ] | Primary dark background, bold 2.0px borders, hard drop shadows |
| **Acid Lime** | `#CCFF00` | [ # ] | Primary highlight, action buttons, 9.0+ ratings, active tab indicators |
| **Electric Pink** | `#FF0055` | [ # ] | Secondary accent, interactive hearts, critique tags |
| **Cyber Cyan** | `#00F0FF` | [ # ] | Singles badge, secondary highlights, 8.0+ ratings |
| **Vermillion** | `#FF3B30` | [ # ] | Critical skip score badge, warning states, destructive actions |
| **Surface Dark** | `#141414` | [ # ] | Card surfaces and elevated containers with hard-edge framing |

**Typography**:
- Headers & Display: `GoogleFonts.spaceGrotesk` (bold, geometric, uncompromising)
- Metadata & Technical: `GoogleFonts.jetBrainsMono`
- AI Critic & Dialogue: `GoogleFonts.spaceMono`

---

## // PROJECT ARCHITECTURE

Built with **Flutter** and **Riverpod** following a feature-first modular architecture:

```
groovd/
├── android/               # Android native runner and Gradle configuration
├── ios/                   # iOS native workspace
├── lib/
│   ├── core/
│   │   ├── constants/     # API configs and system constants
│   │   └── theme/         # AppColors, AppTypography, BrutalistTheme
│   ├── data/
│   │   ├── models/        # MusicItem, Review, Track, ChatMessage, Session models
│   │   ├── repositories/  # Spotify, Deezer, and Review repository implementations
│   │   └── services/      # SpotifyApiService, CriticChatService, DeezerApiService
│   ├── presentation/
│   │   ├── navigation/    # MainNavigationScreen with animated brutalist tab bar
│   │   ├── screens/
│   │   │   ├── home/      # Zine header, infinite marquee, trending releases
│   │   │   ├── search/    # Debounced search and LP/Single filters
│   │   │   ├── detail/    # Hero artwork, full tracklist, reviews, spike badges
│   │   │   ├── profile/   # Critic Dossier, stats, pinned podium, settings
│   │   │   ├── friends/   # Suggested Tastemakers and Friend Profiles
│   │   │   ├── wishlist/  # Wantlist 3x3 grid and Sonic Roulette roll dock
│   │   │   ├── chat/      # CriticChatModal, CriticHistorySheet, archive search
│   │   │   └── review/    # Tactile review modal with haptic score slider
│   │   └── widgets/       # BrutalistButton, RatingSpikeSign, ScrambleText, ChatPhotoZoomViewer
│   ├── state/             # Riverpod providers (chat, music, review, settings)
│   └── main.dart          # Application entry point
└── test/                  # 200+ unit and widget test suite
```

---

## // GETTING STARTED

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

3. **Configure API Keys (Optional)**:
   - Spotify API credentials can be configured inside the app via **DOSSIER -> Settings** or in `lib/core/constants/spotify_config.dart`.
   - AI Critic API keys can be entered directly at runtime via **DOSSIER -> Settings** without recompiling.

4. **Run the application**:
   ```bash
   flutter run
   ```

---

## // TESTING & VERIFICATION

Groovd includes 200+ comprehensive automated tests covering data parsing, state flows, and UI widgets:

```bash
# Run all automated tests
flutter test

# Verify code formatting and analyze lint rules
flutter analyze
```

---

## // KEY DEPENDENCIES

- **State Management**: [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod)
- **Motion & Animations**: [`flutter_animate`](https://pub.dev/packages/flutter_animate), [`animations`](https://pub.dev/packages/animations)
- **Typography**: [`google_fonts`](https://pub.dev/packages/google_fonts)
- **Networking & Caching**: [`http`](https://pub.dev/packages/http), [`cached_network_image`](https://pub.dev/packages/cached_network_image)
- **Persistence & Cloud**: [`shared_preferences`](https://pub.dev/packages/shared_preferences), [`cloud_firestore`](https://pub.dev/packages/cloud_firestore), [`firebase_core`](https://pub.dev/packages/firebase_core)
- **Media & Deep Linking**: [`image_picker`](https://pub.dev/packages/image_picker), [`url_launcher`](https://pub.dev/packages/url_launcher)

---

## // LICENSE

Distributed under the MIT License. See `LICENSE` for more information.

---

<p align="center">
  <b>GROOVD // ARCHIVE</b> -- UNCOMPROMISING CRITIQUE
</p>
