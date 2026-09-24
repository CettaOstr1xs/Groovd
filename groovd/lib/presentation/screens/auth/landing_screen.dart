import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/services/auth_service.dart';
import 'package:groovd/presentation/screens/auth/login_screen.dart';
import 'package:groovd/presentation/screens/auth/register_screen.dart';
import 'package:groovd/presentation/widgets/brutalist_button.dart';
import 'package:groovd/state/auth_providers.dart';
import 'package:groovd/state/dossier_top_picks_provider.dart';
import 'package:groovd/state/onboarding_provider.dart';
import 'package:groovd/state/review_providers.dart';
import 'package:groovd/state/user_lists_provider.dart';
import 'package:groovd/state/user_profile_provider.dart';
import 'package:groovd/state/wishlist_provider.dart';

/// Data model for an album cover showcased in the animated background grid.
class _AlbumCoverSpec {
  final String title;
  final String artist;
  final String assetPath;
  final String coverUrl;
  final String? score;
  final Color fallbackColor;

  const _AlbumCoverSpec({
    required this.title,
    required this.artist,
    required this.assetPath,
    required this.coverUrl,
    this.score,
    required this.fallbackColor,
  });
}

/// Asset paths for all verified album covers bundled inside the app for instant, zero-delay rendering.
const List<String> kLandingCoverAssetPaths = [
  'assets/covers/blonde.jpg',
  'assets/covers/to_pimp_a_butterfly.jpg',
  'assets/covers/brat.jpg',
  'assets/covers/in_rainbows.jpg',
  'assets/covers/random_access_memories.jpg',
  'assets/covers/igor.jpg',
  'assets/covers/hit_me_hard_and_soft.jpg',
  'assets/covers/the_dark_side_of_the_moon.jpg',
  'assets/covers/currents.jpg',
  'assets/covers/ok_computer.jpg',
  'assets/covers/abbey_road.jpg',
  'assets/covers/after_hours.jpg',
  'assets/covers/nevermind.jpg',
  'assets/covers/rumours.jpg',
  'assets/covers/kid_a.jpg',
  'assets/covers/short_n_sweet.jpg',
  'assets/covers/am.jpg',
  'assets/covers/lover.jpg',
  'assets/covers/damn.jpg',
  'assets/covers/melodrama.jpg',
  'assets/covers/sos.jpg',
  'assets/covers/vespertine.jpg',
  'assets/covers/gemini_rights.jpg',
  'assets/covers/good_kid_maad_city.jpg',
  'assets/covers/channel_orange.jpg',
  'assets/covers/born_to_die.jpg',
  'assets/covers/the_bends.jpg',
  'assets/covers/is_this_it.jpg',
  'assets/covers/pure_heroine.jpg',
  'assets/covers/discovery.jpg',
  'assets/covers/flower_boy.jpg',
  'assets/covers/wwafawdwg.jpg',
  'assets/covers/wish_you_were_here.jpg',
  'assets/covers/lonerism.jpg',
  'assets/covers/starboy.jpg',
  'assets/covers/in_utero.jpg',
  'assets/covers/ctrl.jpg',
  'assets/covers/punisher.jpg',
  'assets/covers/unknown_pleasures.jpg',
];

/// 8 continuous tilted tracks filled with bundled, local album cover assets for instant zero-delay display.
/// Each line contains 6 curated albums: 4 original favorites + 2 brand-new unique additions (total 48 albums).
final List<List<_AlbumCoverSpec>> _kAlbumTracks = [
  // Track 0 (Left -> Right) - 6 Albums (+ Good Kid M.A.A.D City, Channel Orange)
  const [
    _AlbumCoverSpec(
      title: 'BLONDE',
      artist: 'FRANK OCEAN',
      assetPath: 'assets/covers/blonde.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b273c5649add07ed3720be9d5526',
      score: '10.0',
      fallbackColor: Color(0xFF556B2F),
    ),
    _AlbumCoverSpec(
      title: 'TO PIMP A BUTTERFLY',
      artist: 'KENDRICK LAMAR',
      assetPath: 'assets/covers/to_pimp_a_butterfly.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b273cdb645498cd3d8a2db4d05e1',
      score: '10.0',
      fallbackColor: Color(0xFF2C3E50),
    ),
    _AlbumCoverSpec(
      title: 'BRAT',
      artist: 'CHARLI XCX',
      assetPath: 'assets/covers/brat.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b273f88b43d15fd14e9525338b59',
      score: '9.2',
      fallbackColor: Color(0xFF8ACE00),
    ),
    _AlbumCoverSpec(
      title: 'IN RAINBOWS',
      artist: 'RADIOHEAD',
      assetPath: 'assets/covers/in_rainbows.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b273de3c04b5fc750b68899b20a9',
      score: '9.8',
      fallbackColor: Color(0xFFB71C1C),
    ),
    _AlbumCoverSpec(
      title: 'GOOD KID, M.A.A.D CITY',
      artist: 'KENDRICK LAMAR',
      assetPath: 'assets/covers/good_kid_maad_city.jpg',
      coverUrl: 'https://cdn-images.dzcdn.net/images/cover/b5be27644d505bad7bdb516fe4165475/500x500-000000-80-0-0.jpg',
      score: '10.0',
      fallbackColor: Color(0xFF9E9E9E),
    ),
    _AlbumCoverSpec(
      title: 'CHANNEL ORANGE',
      artist: 'FRANK OCEAN',
      assetPath: 'assets/covers/channel_orange.jpg',
      coverUrl: 'https://cdn-images.dzcdn.net/images/cover/d5e89d10e0129cf63c180907297f6424/500x500-000000-80-0-0.jpg',
      score: '9.8',
      fallbackColor: Color(0xFFE65100),
    ),
  ],

  // Track 1 (Right -> Left) - 6 Albums (+ Born To Die, The Bends)
  const [
    _AlbumCoverSpec(
      title: 'RANDOM ACCESS MEMORIES',
      artist: 'DAFT PUNK',
      assetPath: 'assets/covers/random_access_memories.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b2739b9b36b0e22870b9f542d937',
      score: '9.6',
      fallbackColor: Color(0xFF212121),
    ),
    _AlbumCoverSpec(
      title: 'IGOR',
      artist: 'TYLER, THE CREATOR',
      assetPath: 'assets/covers/igor.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b27330a635de2bb0caa4e26f6abb',
      score: '9.4',
      fallbackColor: Color(0xFFE91E63),
    ),
    _AlbumCoverSpec(
      title: 'HIT ME HARD AND SOFT',
      artist: 'BILLIE EILISH',
      assetPath: 'assets/covers/hit_me_hard_and_soft.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b27371d62ea7ea8a5be92d3c1f62',
      score: '9.1',
      fallbackColor: Color(0xFF0D47A1),
    ),
    _AlbumCoverSpec(
      title: 'THE DARK SIDE OF THE MOON',
      artist: 'PINK FLOYD',
      assetPath: 'assets/covers/the_dark_side_of_the_moon.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b273db216ca805faf5fe35df4ee6',
      score: '10.0',
      fallbackColor: Color(0xFF1B1B1B),
    ),
    _AlbumCoverSpec(
      title: 'BORN TO DIE',
      artist: 'LANA DEL REY',
      assetPath: 'assets/covers/born_to_die.jpg',
      coverUrl: 'https://cdn-images.dzcdn.net/images/cover/61665a396e987c2b5d44443efdb4c19a/500x500-000000-80-0-0.jpg',
      score: '9.0',
      fallbackColor: Color(0xFF37474F),
    ),
    _AlbumCoverSpec(
      title: 'THE BENDS',
      artist: 'RADIOHEAD',
      assetPath: 'assets/covers/the_bends.jpg',
      coverUrl: 'https://cdn-images.dzcdn.net/images/cover/b27f4da7e415b3c5836a0d0df13bc89f/500x500-000000-80-0-0.jpg',
      score: '9.5',
      fallbackColor: Color(0xFFB71C1C),
    ),
  ],

  // Track 2 (Left -> Right) - 6 Albums (+ Is This It, Pure Heroine)
  const [
    _AlbumCoverSpec(
      title: 'CURRENTS',
      artist: 'TAME IMPALA',
      assetPath: 'assets/covers/currents.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b2739e1cfc756886ac782e363d79',
      score: '9.3',
      fallbackColor: Color(0xFF4A148C),
    ),
    _AlbumCoverSpec(
      title: 'OK COMPUTER',
      artist: 'RADIOHEAD',
      assetPath: 'assets/covers/ok_computer.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b273c8b444df094279e70d0ed856',
      score: '10.0',
      fallbackColor: Color(0xFF455A64),
    ),
    _AlbumCoverSpec(
      title: 'ABBEY ROAD',
      artist: 'THE BEATLES',
      assetPath: 'assets/covers/abbey_road.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b273dc30583ba717007b00cceb25',
      score: '10.0',
      fallbackColor: Color(0xFF3E2723),
    ),
    _AlbumCoverSpec(
      title: 'AFTER HOURS',
      artist: 'THE WEEKND',
      assetPath: 'assets/covers/after_hours.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b2738863bc11d2aa12b54f5aeb36',
      score: '9.1',
      fallbackColor: Color(0xFF880E4F),
    ),
    _AlbumCoverSpec(
      title: 'IS THIS IT',
      artist: 'THE STROKES',
      assetPath: 'assets/covers/is_this_it.jpg',
      coverUrl: 'https://cdn-images.dzcdn.net/images/cover/8410292ef43cbfd3763f0d57e4dfcb68/500x500-000000-80-0-0.jpg',
      score: '9.7',
      fallbackColor: Color(0xFF212121),
    ),
    _AlbumCoverSpec(
      title: 'PURE HEROINE',
      artist: 'LORDE',
      assetPath: 'assets/covers/pure_heroine.jpg',
      coverUrl: 'https://cdn-images.dzcdn.net/images/cover/5fc8a52936e788ee5ae2a4c1737be2e6/500x500-000000-80-0-0.jpg',
      score: '9.4',
      fallbackColor: Color(0xFF212121),
    ),
  ],

  // Track 3 (Right -> Left) - 6 Albums (+ Discovery, Flower Boy)
  const [
    _AlbumCoverSpec(
      title: 'NEVERMIND',
      artist: 'NIRVANA',
      assetPath: 'assets/covers/nevermind.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b273fbc71c99f9c1296c56dd51b6',
      score: '9.9',
      fallbackColor: Color(0xFF0277BD),
    ),
    _AlbumCoverSpec(
      title: 'RUMOURS',
      artist: 'FLEETWOOD MAC',
      assetPath: 'assets/covers/rumours.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b273e52a59a28efa4773dd2bfe1b',
      score: '9.9',
      fallbackColor: Color(0xFF4E342E),
    ),
    _AlbumCoverSpec(
      title: 'KID A',
      artist: 'RADIOHEAD',
      assetPath: 'assets/covers/kid_a.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b2736c7112082b63beefffe40151',
      score: '9.8',
      fallbackColor: Color(0xFF263238),
    ),
    _AlbumCoverSpec(
      title: 'SHORT N\' SWEET',
      artist: 'SABRINA CARPENTER',
      assetPath: 'assets/covers/short_n_sweet.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b273fd8d7a8d96871e791cb1f626',
      score: '8.8',
      fallbackColor: Color(0xFF1E88E5),
    ),
    _AlbumCoverSpec(
      title: 'DISCOVERY',
      artist: 'DAFT PUNK',
      assetPath: 'assets/covers/discovery.jpg',
      coverUrl: 'https://cdn-images.dzcdn.net/images/cover/3be8952402ff6078696c7017684df62e/500x500-000000-80-0-0.jpg',
      score: '9.9',
      fallbackColor: Color(0xFF1565C0),
    ),
    _AlbumCoverSpec(
      title: 'FLOWER BOY',
      artist: 'TYLER, THE CREATOR',
      assetPath: 'assets/covers/flower_boy.jpg',
      coverUrl: 'https://cdn-images.dzcdn.net/images/cover/ebaa07119ff3360bfa7c7d41334c9f13/500x500-000000-80-0-0.jpg',
      score: '9.3',
      fallbackColor: Color(0xFFF57F17),
    ),
  ],

  // Track 4 (Left -> Right) - 6 Albums (+ When We All Fall Asleep..., Wish You Were Here)
  const [
    _AlbumCoverSpec(
      title: 'AM',
      artist: 'ARCTIC MONKEYS',
      assetPath: 'assets/covers/am.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b2734ae1c4c5c45aabe565499163',
      score: '9.0',
      fallbackColor: Color(0xFF212121),
    ),
    _AlbumCoverSpec(
      title: 'LOVER',
      artist: 'TAYLOR SWIFT',
      assetPath: 'assets/covers/lover.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b273e787cffec20aa2a396a61647',
      score: '8.9',
      fallbackColor: Color(0xFFF48FB1),
    ),
    _AlbumCoverSpec(
      title: 'DAMN.',
      artist: 'KENDRICK LAMAR',
      assetPath: 'assets/covers/damn.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b2738b52c6b9bc4e43d873869699',
      score: '9.7',
      fallbackColor: Color(0xFFB71C1C),
    ),
    _AlbumCoverSpec(
      title: 'MELODRAMA',
      artist: 'LORDE',
      assetPath: 'assets/covers/melodrama.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b273f8553e18a11209d4becd0336',
      score: '9.5',
      fallbackColor: Color(0xFF1565C0),
    ),
    _AlbumCoverSpec(
      title: 'WHEN WE ALL FALL ASLEEP...',
      artist: 'BILLIE EILISH',
      assetPath: 'assets/covers/wwafawdwg.jpg',
      coverUrl: 'https://cdn-images.dzcdn.net/images/cover/a4639908cfd09d311915ea0842e47c0d/500x500-000000-80-0-0.jpg',
      score: '9.2',
      fallbackColor: Color(0xFFE0E0E0),
    ),
    _AlbumCoverSpec(
      title: 'WISH YOU WERE HERE',
      artist: 'PINK FLOYD',
      assetPath: 'assets/covers/wish_you_were_here.jpg',
      coverUrl: 'https://cdn-images.dzcdn.net/images/cover/f0dc8d312674e7978d38ca587b1c3e1e/500x500-000000-80-0-0.jpg',
      score: '10.0',
      fallbackColor: Color(0xFF455A64),
    ),
  ],

  // Track 5 (Right -> Left) - 6 Albums (+ Lonerism, Starboy)
  const [
    _AlbumCoverSpec(
      title: 'SOS',
      artist: 'SZA',
      assetPath: 'assets/covers/sos.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b273bc18bdade69ec5ef0bb25b17',
      score: '9.2',
      fallbackColor: Color(0xFF0277BD),
    ),
    _AlbumCoverSpec(
      title: 'VESPERTINE',
      artist: 'BJÖRK',
      assetPath: 'assets/covers/vespertine.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b2735c081511ab5779f399233349',
      score: '9.8',
      fallbackColor: Color(0xFF37474F),
    ),
    _AlbumCoverSpec(
      title: 'BLONDE',
      artist: 'FRANK OCEAN',
      assetPath: 'assets/covers/blonde.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b273c5649add07ed3720be9d5526',
      score: '10.0',
      fallbackColor: Color(0xFF556B2F),
    ),
    _AlbumCoverSpec(
      title: 'IN RAINBOWS',
      artist: 'RADIOHEAD',
      assetPath: 'assets/covers/in_rainbows.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b273de3c04b5fc750b68899b20a9',
      score: '9.8',
      fallbackColor: Color(0xFFB71C1C),
    ),
    _AlbumCoverSpec(
      title: 'LONERISM',
      artist: 'TAME IMPALA',
      assetPath: 'assets/covers/lonerism.jpg',
      coverUrl: 'https://cdn-images.dzcdn.net/images/cover/9079fef0ce51e2b5e1a3bc8917e8c3ae/500x500-000000-80-0-0.jpg',
      score: '9.6',
      fallbackColor: Color(0xFF2E7D32),
    ),
    _AlbumCoverSpec(
      title: 'STARBOY',
      artist: 'THE WEEKND',
      assetPath: 'assets/covers/starboy.jpg',
      coverUrl: 'https://cdn-images.dzcdn.net/images/cover/b41c6183e8b15d65421abf08d0df627c/500x500-000000-80-0-0.jpg',
      score: '8.9',
      fallbackColor: Color(0xFFC2185B),
    ),
  ],

  // Track 6 (Left -> Right) - 6 Albums (+ In Utero, Ctrl)
  const [
    _AlbumCoverSpec(
      title: 'TO PIMP A BUTTERFLY',
      artist: 'KENDRICK LAMAR',
      assetPath: 'assets/covers/to_pimp_a_butterfly.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b273cdb645498cd3d8a2db4d05e1',
      score: '10.0',
      fallbackColor: Color(0xFF2C3E50),
    ),
    _AlbumCoverSpec(
      title: 'RANDOM ACCESS MEMORIES',
      artist: 'DAFT PUNK',
      assetPath: 'assets/covers/random_access_memories.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b2739b9b36b0e22870b9f542d937',
      score: '9.6',
      fallbackColor: Color(0xFF212121),
    ),
    _AlbumCoverSpec(
      title: 'BRAT',
      artist: 'CHARLI XCX',
      assetPath: 'assets/covers/brat.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b273f88b43d15fd14e9525338b59',
      score: '9.2',
      fallbackColor: Color(0xFF8ACE00),
    ),
    _AlbumCoverSpec(
      title: 'CURRENTS',
      artist: 'TAME IMPALA',
      assetPath: 'assets/covers/currents.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b2739e1cfc756886ac782e363d79',
      score: '9.3',
      fallbackColor: Color(0xFF4A148C),
    ),
    _AlbumCoverSpec(
      title: 'IN UTERO',
      artist: 'NIRVANA',
      assetPath: 'assets/covers/in_utero.jpg',
      coverUrl: 'https://cdn-images.dzcdn.net/images/cover/b1e2a5639b7bf26639d6b9efcdcf9b4a/500x500-000000-80-0-0.jpg',
      score: '9.7',
      fallbackColor: Color(0xFFFBC02D),
    ),
    _AlbumCoverSpec(
      title: 'CTRL',
      artist: 'SZA',
      assetPath: 'assets/covers/ctrl.jpg',
      coverUrl: 'https://cdn-images.dzcdn.net/images/cover/5f6ab58f869a8bfd09b695bc37c0eb89/500x500-000000-80-0-0.jpg',
      score: '9.5',
      fallbackColor: Color(0xFF33691E),
    ),
  ],

  // Track 7 (Right -> Left) - 6 Albums (+ Punisher, Unknown Pleasures)
  const [
    _AlbumCoverSpec(
      title: 'OK COMPUTER',
      artist: 'RADIOHEAD',
      assetPath: 'assets/covers/ok_computer.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b273c8b444df094279e70d0ed856',
      score: '10.0',
      fallbackColor: Color(0xFF455A64),
    ),
    _AlbumCoverSpec(
      title: 'ABBEY ROAD',
      artist: 'THE BEATLES',
      assetPath: 'assets/covers/abbey_road.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b273dc30583ba717007b00cceb25',
      score: '10.0',
      fallbackColor: Color(0xFF3E2723),
    ),
    _AlbumCoverSpec(
      title: 'KID A',
      artist: 'RADIOHEAD',
      assetPath: 'assets/covers/kid_a.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b2736c7112082b63beefffe40151',
      score: '9.8',
      fallbackColor: Color(0xFF263238),
    ),
    _AlbumCoverSpec(
      title: 'SHORT N\' SWEET',
      artist: 'SABRINA CARPENTER',
      assetPath: 'assets/covers/short_n_sweet.jpg',
      coverUrl: 'https://i.scdn.co/image/ab67616d0000b273fd8d7a8d96871e791cb1f626',
      score: '8.8',
      fallbackColor: Color(0xFF1E88E5),
    ),
    _AlbumCoverSpec(
      title: 'PUNISHER',
      artist: 'PHOEBE BRIDGERS',
      assetPath: 'assets/covers/punisher.jpg',
      coverUrl: 'https://cdn-images.dzcdn.net/images/cover/9079fef0ce51e2b5e1a3bc8917e8c3ae/500x500-000000-80-0-0.jpg',
      score: '9.6',
      fallbackColor: Color(0xFF1A237E),
    ),
    _AlbumCoverSpec(
      title: 'UNKNOWN PLEASURES',
      artist: 'JOY DIVISION',
      assetPath: 'assets/covers/unknown_pleasures.jpg',
      coverUrl: 'https://cdn-images.dzcdn.net/images/cover/f4b14d2e8b28a2a9bb415cfcd30282b0/500x500-000000-80-0-0.jpg',
      score: '9.8',
      fallbackColor: Color(0xFF000000),
    ),
  ],
];

/// An eye-catching, high-contrast Neo-Brutalist landing screen that introduces
/// Groovd to first-time guests.
///
/// The entire background is covered in 8 alternating horizontal tracks of real
/// album covers tilted counter-clockwise to the left, repeating infinitely.
/// The text and action buttons float directly on top like a bold concert poster
/// without any obstructive container box, allowing the album art collage to
/// visually fill the whole page from edge to edge.
class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _marqueeController;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 50),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm up image cache so covers appear immediately upon entrance
    for (final path in kLandingCoverAssetPaths) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  void dispose() {
    _marqueeController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final credential = await authService.signInWithGoogle();

      if (credential != null && mounted) {
        final user = credential.user;
        if (user != null) {
          await ref.read(userProfileProvider.notifier).syncWithFirebaseUser(user);
          await ref.read(wishlistProvider.notifier).syncForUser(user.uid);
          await ref.read(dossierTopPicksProvider.notifier).syncForUser(user.uid);
          await ref.read(userListsProvider.notifier).syncForUser(user.uid);
          ref.invalidate(userReviewsProvider);
          ref.read(reviewRefreshProvider.notifier).notifyChanged();
        }

        await ref.read(onboardingProvider.notifier).completeOnboarding();
        if (!mounted) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthService.getHumanReadableError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _openRegister() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (result == true && mounted) {
      await ref.read(onboardingProvider.notifier).completeOnboarding();
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _openLogin() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (result == true && mounted) {
      await ref.read(onboardingProvider.notifier).completeOnboarding();
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleContinueAsGuest() async {
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Tilted Alternating Album Cover Tracks (Fills 100% of Screen Edge-to-Edge)
          Positioned.fill(
            child: ClipRect(
              child: _TiltedAlbumRowsCanvas(
                animation: _marqueeController,
                screenHeight: size.height,
              ),
            ),
          ),

          // 2. Full-Screen Atmospheric Vignette & Legibility Scrim
          // Dark at top for status bar, open in upper-mid, rich dark at bottom for crisp button contrast
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      Colors.black.withValues(alpha: 0.30),
                      Colors.black.withValues(alpha: 0.70),
                      AppColors.background.withValues(alpha: 0.94),
                      AppColors.background,
                    ],
                    stops: const [0.0, 0.25, 0.55, 0.82, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 3. Floating Poster Display Content (No bottom container box)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Bar: System Pill & Guest Link
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.pureBlack.withValues(alpha: 0.85),
                            border: Border.all(color: AppColors.acidLime, width: 1.5),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                offset: Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.acidLime,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'ARCHIVE // V1.0.0',
                                style: AppTypography.monoBadge(
                                  color: AppColors.acidLime,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.pureBlack.withValues(alpha: 0.7),
                            border: Border.all(color: AppColors.border, width: 1.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: InkWell(
                            onTap: _handleContinueAsGuest,
                            child: Text(
                              'EXPLORE AS GUEST →',
                              style: AppTypography.monoLabel(
                                color: AppColors.acidLime,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Dominant Brand Display & Manifesto
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dominant Hero Title with Shadow
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'GROOVD',
                            style: AppTypography.displayMassive(
                              fontSize: 56,
                            ).copyWith(
                              letterSpacing: -2.5,
                              shadows: const [
                                Shadow(
                                  color: Colors.black,
                                  offset: Offset(0, 4),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(left: 4),
                            color: AppColors.acidLime,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'THE MUSIC CRITIC’S NOTEBOOK',
                        style: AppTypography.monoLabel(
                          color: AppColors.acidLime,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                        ).copyWith(
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ditch 5-star approximations. Score releases from 0.0 to 10.0, track your vinyl grail wantlist, and curate your definitive canon.',
                        style: AppTypography.bodyMedium(
                          color: AppColors.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ).copyWith(
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(0, 2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.vermillion.withValues(alpha: 0.2),
                        border: Border.all(color: AppColors.vermillion, width: 1.5),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.monoBadge(
                          color: AppColors.vermillion,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],

                  // Action 1: Create Critic Dossier (Register)
                  BrutalistButton(
                    label: 'CREATE CRITIC DOSSIER',
                    icon: Icons.person_add_outlined,
                    backgroundColor: AppColors.acidLime,
                    textColor: AppColors.pureBlack,
                    borderColor: AppColors.pureBlack,
                    isFullWidth: true,
                    onPressed: _openRegister,
                  ),

                  const SizedBox(height: 10),

                  // Action 2: Continue with Google
                  _buildGoogleButton(),

                  const SizedBox(height: 10),

                  // Action 3: Have an Account? Sign In
                  BrutalistButton(
                    label: 'HAVE AN ACCOUNT? SIGN IN',
                    icon: Icons.login,
                    backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.95),
                    textColor: AppColors.pureWhite,
                    borderColor: AppColors.border,
                    isFullWidth: true,
                    onPressed: _openLogin,
                  ),

                  const SizedBox(height: 12),

                  // Action 4: Guest Exploration Link
                  Center(
                    child: TextButton(
                      onPressed: _handleContinueAsGuest,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'EXPLORE AS GUEST // READ CATALOG →',
                        style: AppTypography.monoLabel(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton() {
    return InkWell(
      onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          border: Border.all(color: AppColors.pureBlack, width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: AppColors.pureBlack,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: _isGoogleLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.pureBlack,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.pureBlack, width: 1.5),
                      ),
                      child: const Center(
                        child: Text(
                          'G',
                          style: TextStyle(
                            color: AppColors.pureBlack,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'CONTINUE WITH GOOGLE',
                      style: AppTypography.buttonLabel(
                        color: AppColors.pureBlack,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Canvas rendering 8 alternating horizontal tracks of real album covers tilted
/// counter-clockwise to the left, repeating infinitely across the entire screen.
class _TiltedAlbumRowsCanvas extends StatelessWidget {
  final Animation<double> animation;
  final double screenHeight;

  const _TiltedAlbumRowsCanvas({
    required this.animation,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    const itemSize = 114.0;
    const itemSpacing = 12.0;
    const rowSpacing = 12.0;

    // Angle: -8.5 degrees tilt to the left (counter-clockwise)
    const tiltAngle = -8.5 * math.pi / 180;

    return Transform.rotate(
      angle: tiltAngle,
      alignment: Alignment.center,
      child: Transform.scale(
        // Scale up to 1.55 so the 8 tilted tracks comfortably bleed across all screen edges
        scale: 1.55,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int rowIndex = 0; rowIndex < _kAlbumTracks.length; rowIndex++) ...[
                _AlbumTrackRow(
                  items: _kAlbumTracks[rowIndex],
                  animation: animation,
                  // Alternating directions: even rows move left-to-right, odd rows move right-to-left
                  moveLeftToRight: rowIndex % 2 == 0,
                  cycles: rowIndex % 2 == 0 ? 2 : 3,
                  itemSize: itemSize,
                  itemSpacing: itemSpacing,
                ),
                const SizedBox(height: rowSpacing),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A single continuous horizontal track of album covers moving smoothly in one direction.
/// Uses periodic pattern wrapping so when the animation cycle repeats, the transition is
/// 100% mathematically seamless with zero visual hitch, jump, or stutter.
///
/// Pre-caches the tile strip once and wraps in a [RepaintBoundary] so the GPU merely blits
/// the existing texture without re-laying out or re-rendering individual album widgets.
class _AlbumTrackRow extends StatefulWidget {
  final List<_AlbumCoverSpec> items;
  final Animation<double> animation;
  final bool moveLeftToRight;
  final int cycles;
  final double itemSize;
  final double itemSpacing;

  const _AlbumTrackRow({
    required this.items,
    required this.animation,
    required this.moveLeftToRight,
    required this.cycles,
    required this.itemSize,
    required this.itemSpacing,
  });

  @override
  State<_AlbumTrackRow> createState() => _AlbumTrackRowState();
}

class _AlbumTrackRowState extends State<_AlbumTrackRow> {
  late final Widget _cachedTileStrip;
  late final double _patternWidth;

  @override
  void initState() {
    super.initState();
    _patternWidth = widget.items.length * (widget.itemSize + widget.itemSpacing);
    _cachedTileStrip = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Repeat 5 times (20 tiles) to guarantee generous edge-to-edge buffers on all screen widths
        for (int repeat = 0; repeat < 5; repeat++) ...[
          for (final spec in widget.items) ...[
            _AlbumCoverTile(spec: spec, size: widget.itemSize),
            SizedBox(width: widget.itemSpacing),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: widget.itemSize,
        child: OverflowBox(
          minWidth: 0,
          maxWidth: double.infinity,
          minHeight: widget.itemSize,
          maxHeight: widget.itemSize,
          alignment: Alignment.centerLeft,
          child: AnimatedBuilder(
            animation: widget.animation,
            builder: (context, child) {
              final t = (widget.animation.value * widget.cycles) % 1.0;
              final offset = t * _patternWidth;
              final dx = widget.moveLeftToRight
                  ? (offset - (2 * _patternWidth))
                  : (-offset - _patternWidth);

              return Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              );
            },
            child: _cachedTileStrip,
          ),
        ),
      ),
    );
  }
}

/// Individual album cover tile with Neo-Brutalist border, drop shadow, and score badge.
class _AlbumCoverTile extends StatelessWidget {
  final _AlbumCoverSpec spec;
  final double size;

  const _AlbumCoverTile({
    required this.spec,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: spec.fallbackColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.pureBlack, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0xCC000000),
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Local Bundled Cover Image with Network Fallback for Instant Zero-Delay Rendering
          Image.asset(
            spec.assetPath,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => CachedNetworkImage(
              imageUrl: spec.coverUrl,
              fit: BoxFit.cover,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              memCacheWidth: 250,
              memCacheHeight: 250,
              maxWidthDiskCache: 400,
              maxHeightDiskCache: 400,
              placeholder: (_, _) => _buildFallbackTile(),
              errorWidget: (_, _, _) => _buildFallbackTile(),
            ),
          ),

          // Glossy Vinyl Sleeve Gradient Sheen
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Rating score badge (if applicable)
          if (spec.score != null)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.acidLime,
                  border: Border.all(color: AppColors.pureBlack, width: 1.2),
                  borderRadius: BorderRadius.circular(1),
                ),
                child: Text(
                  spec.score!,
                  style: AppTypography.monoBadge(
                    color: AppColors.pureBlack,
                    fontSize: 8.5,
                  ),
                ),
              ),
            ),

          // Bottom Artist / Title Strip
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              color: AppColors.pureBlack.withValues(alpha: 0.75),
              child: Text(
                spec.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.monoLabel(
                  color: AppColors.pureWhite,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackTile() {
    return Container(
      color: spec.fallbackColor,
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 3),
              ),
              child: const Center(
                child: Icon(Icons.album, size: 18, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              spec.title,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.monoLabel(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
