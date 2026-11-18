import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/presentation/screens/detail/music_detail_screen.dart';
import 'package:groovd/presentation/widgets/artwork_zoom_viewer.dart';

void main() {
  const testItem = MusicItem(
    id: 'test_album_1',
    name: 'Dummy',
    artist: 'Portishead',
    coverUrl: 'https://example.com/cover.jpg',
    releaseDate: '1994',
    type: MusicType.album,
  );

  testWidgets('MusicDetailScreen download button opens ArtworkDownloadModal and cancels cleanly', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MusicDetailScreen(item: testItem),
        ),
      ),
    );

    await tester.pump();

    // Verify download icon button is present in AppBar
    final downloadButtonFinder = find.byTooltip('Download Artwork');
    expect(downloadButtonFinder, findsOneWidget);
    expect(find.byIcon(Icons.download_outlined), findsOneWidget);

    // Tap download button
    await tester.tap(downloadButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify modal is open
    expect(find.text('ARCHIVE DISPATCH // DOWNLOAD ARTWORK'), findsOneWidget);
    expect(find.text('SAVE TO GALLERY ?'), findsOneWidget);

    // Cancel modal
    await tester.tap(find.text('CANCEL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('ARCHIVE DISPATCH // DOWNLOAD ARTWORK'), findsNothing);
  });

  testWidgets('ArtworkZoomViewer save to gallery button opens ArtworkDownloadModal and cancels cleanly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ArtworkZoomViewer(
            imageUrl: 'https://example.com/cover.jpg',
            title: 'Dummy',
            artist: 'Portishead',
            heroTag: 'test_hero',
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Verify SAVE TO GALLERY button is present in bottom bar
    final saveButtonFinder = find.text('SAVE TO GALLERY');
    expect(saveButtonFinder, findsOneWidget);

    // Tap save button
    await tester.tap(saveButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify modal is open
    expect(find.text('ARCHIVE DISPATCH // DOWNLOAD ARTWORK'), findsOneWidget);
    expect(find.text('SAVE TO GALLERY ?'), findsOneWidget);

    // Cancel modal
    await tester.tap(find.text('CANCEL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('ARCHIVE DISPATCH // DOWNLOAD ARTWORK'), findsNothing);
  });
}
