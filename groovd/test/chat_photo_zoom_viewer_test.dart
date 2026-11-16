import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groovd/presentation/widgets/chat_photo_zoom_viewer.dart';

void main() {
  Widget buildTestWidget({
    String? imagePath,
    Uint8List? imageBytes,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ChatPhotoZoomViewer(
          imagePath: imagePath,
          imageBytes: imageBytes,
        ),
      ),
    );
  }

  testWidgets('ChatPhotoZoomViewer renders InteractiveViewer and close button', (tester) async {
    // 1x1 transparent GIF bytes
    final dummyBytes = Uint8List.fromList([
      0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00,
      0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0x21,
      0xf9, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x2c, 0x00, 0x00,
      0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x01, 0x44,
      0x00, 0x3b,
    ]);

    await tester.pumpWidget(buildTestWidget(imageBytes: dummyBytes));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byKey(const Key('chat_photo_zoom_close_btn')), findsOneWidget);
    expect(find.text('GROOVD AI // INSPECTION'), findsOneWidget);
  });

  testWidgets('ChatPhotoZoomViewer tapping close button pops the screen', (tester) async {
    final dummyBytes = Uint8List.fromList([
      0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00,
      0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0x21,
      0xf9, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x2c, 0x00, 0x00,
      0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x01, 0x44,
      0x00, 0x3b,
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                ChatPhotoZoomViewer.show(context, imageBytes: dummyBytes);
              },
              child: const Text('OPEN'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatPhotoZoomViewer), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat_photo_zoom_close_btn')));
    await tester.pumpAndSettle();

    expect(find.byType(ChatPhotoZoomViewer), findsNothing);
  });

  testWidgets('ChatPhotoZoomViewer falls back to unavailable placeholder when file does not exist', (tester) async {
    await tester.pumpWidget(buildTestWidget(imagePath: '/non/existent/path/image.jpg'));
    await tester.pumpAndSettle();

    expect(find.text('PHOTO UNAVAILABLE'), findsOneWidget);
  });
}

