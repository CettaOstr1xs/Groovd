import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groovd/presentation/widgets/artwork_download_modal.dart';

void main() {
  testWidgets('ArtworkDownloadModal renders Revision 2 visual hero layout without cyan tag', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  ArtworkDownloadModal.show(
                    context,
                    imageUrl: 'https://example.com/cover.jpg',
                    title: 'Dummy',
                    artist: 'Portishead',
                    year: '1994',
                    typeLabel: 'LP // ALBUM',
                  );
                },
                child: const Text('OPEN'),
              );
            },
          ),
        ),
      ),
    );

    // Tap to open modal
    await tester.tap(find.text('OPEN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify header
    expect(find.text('ARCHIVE DISPATCH // DOWNLOAD ARTWORK'), findsOneWidget);

    // Verify no X close button in header
    expect(find.byIcon(Icons.close), findsNothing);

    // Verify release metadata
    expect(find.text('DUMMY'), findsOneWidget);
    expect(find.text('PORTISHEAD'), findsOneWidget);
    expect(find.text('LP // ALBUM // 1994'), findsOneWidget);

    // Verify STRICTLY NO cyan tag exists
    expect(find.text('#HIGH_RES_MASTER'), findsNothing);
    expect(find.textContaining('CYAN'), findsNothing);

    // Verify absence of old CRT manifest lines & subtitle
    expect(find.textContaining('PICTURES/GROOVD (GALLERY)'), findsNothing);
    expect(find.textContaining('MASTER CDN ASSET'), findsNothing);
    expect(find.textContaining('Save high-resolution'), findsNothing);

    // Verify action buttons
    expect(find.text('SAVE TO GALLERY ?'), findsOneWidget);
    expect(find.text('CANCEL'), findsOneWidget);

    // Verify tapping CANCEL dismisses modal
    await tester.tap(find.text('CANCEL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ARCHIVE DISPATCH // DOWNLOAD ARTWORK'), findsNothing);
  });
}
