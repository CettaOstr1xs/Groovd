import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/data/models/critic_recommendation_item.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/presentation/widgets/critic_recommendations_shelf.dart';
import 'package:groovd/state/critic_recommendations_provider.dart';

void main() {
  testWidgets('CriticRecommendationsShelf always appears and shows terminal loader when empty/loading', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          criticRecommendationsProvider.overrideWith(() => _MockRecommendationsNotifier(
            const CriticRecommendationsState(
              items: [],
              isLoading: true,
              hasSufficientRatings: true,
            ),
          )),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CriticRecommendationsShelf(),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text("CRITIC'S RADAR"), findsOneWidget);
    expect(find.text('> GROOVD_AI // GENERATING PICKS...'), findsOneWidget);
  });

  testWidgets('CriticRecommendationsShelf displays error state and retry prompt when empty and not loading', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          criticRecommendationsProvider.overrideWith(() => _MockRecommendationsNotifier(
            const CriticRecommendationsState(
              items: [],
              isLoading: false,
              hasSufficientRatings: true,
              errorMessage: 'OFFLINE',
            ),
          )),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CriticRecommendationsShelf(),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text("CRITIC'S RADAR"), findsOneWidget);
    expect(find.textContaining('TAP REROLL TO RETRY'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('CriticRecommendationsShelf renders horizontal cards when recommendations exist', (tester) async {
    final item = const MusicItem(
      id: 'rec_dummy',
      name: 'Dummy',
      artist: 'Portishead',
      coverUrl: '',
      releaseDate: '1994',
      type: MusicType.album,
    );

    final rec = CriticRecommendationItem(
      item: item,
      reasoning: 'Trip-hop milestone with haunting atmospheric textures.',
      vibeTag: '#TRIP_HOP_CANON',
      generatedAt: DateTime(2026, 11, 17),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          criticRecommendationsProvider.overrideWith(() => _MockRecommendationsNotifier(
            CriticRecommendationsState(
              items: [rec],
              hasSufficientRatings: true,
            ),
          )),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CriticRecommendationsShelf(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text("CRITIC'S RADAR"), findsOneWidget);
    expect(find.text('#TRIP_HOP_CANON'), findsNothing);
    expect(find.text('DUMMY'), findsOneWidget);
    expect(find.text('PORTISHEAD'), findsOneWidget);
    expect(find.text('REROLL'), findsOneWidget);
  });

  testWidgets('Tapping recommendation card opens elaboration modal with scramble text and archive redirect', (tester) async {
    final item = const MusicItem(
      id: 'rec_dummy',
      name: 'Dummy',
      artist: 'Portishead',
      coverUrl: '',
      releaseDate: '1994',
      type: MusicType.album,
      genres: ['Trip Hop', 'Downtempo'],
    );

    final rec = CriticRecommendationItem(
      item: item,
      reasoning: 'Trip-hop milestone with haunting atmospheric textures and uncompromising sound design.',
      vibeTag: '#TRIP_HOP_CANON',
      generatedAt: DateTime(2026, 11, 17),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          criticRecommendationsProvider.overrideWith(() => _MockRecommendationsNotifier(
            CriticRecommendationsState(
              items: [rec],
              hasSufficientRatings: true,
            ),
          )),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CriticRecommendationsShelf(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap the recommendation card
    await tester.tap(find.text('DUMMY'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Option A Vinyl Slipcase & CRT elaboration modal elements
    expect(find.text('CRITIC DISPATCH // CANON RECOM'), findsOneWidget);
    expect(find.text('> GROOVD_AI // TASTE_DECODE_LOG'), findsOneWidget);
    expect(find.text('LP // ALBUM // 1994'), findsOneWidget);
    expect(find.text('DECODE: 2.0S'), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.text('#TRIP HOP'), findsOneWidget);
    expect(find.text('INSPECT RECORD IN ARCHIVE →'), findsOneWidget);
    expect(find.text('DISMISS ✕'), findsOneWidget);

    // Let 2s scramble animation settle
    await tester.pumpAndSettle();
    expect(find.textContaining('Trip-hop milestone with haunting atmospheric textures'), findsWidgets);
  });
}

class _MockRecommendationsNotifier extends CriticRecommendationsNotifier {
  final CriticRecommendationsState initialState;

  _MockRecommendationsNotifier(this.initialState);

  @override
  CriticRecommendationsState build() {
    return initialState;
  }

  @override
  Future<void> refreshRecommendations({bool forceReroll = false}) async {}
}
