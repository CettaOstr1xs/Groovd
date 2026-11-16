import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/presentation/screens/chat/critic_chat_modal.dart';
import 'package:groovd/presentation/screens/detail/music_detail_screen.dart';
import 'package:groovd/presentation/widgets/groovd_markdown_text.dart';
import 'package:groovd/presentation/widgets/rating_spike_sign.dart';
import 'package:groovd/state/critic_chat_provider.dart';
import 'package:groovd/state/gemini_settings_provider.dart';

void main() {
  group('CriticChatModal', () {
    testWidgets('shows API key setup card when unconfigured without mascot', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('')),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CriticChatModal(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(RatingSpikeSign), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.bolt), findsNothing);
      expect(find.text('GROOVD AI'), findsOneWidget);
      expect(find.text('FREE AI API KEY REQUIRED'), findsOneWidget);
      expect(find.byKey(const Key('critic_chat_key_input')), findsOneWidget);
      expect(find.text('SAVE KEY'), findsOneWidget);
    });

    testWidgets('renders sleek header, starter chips and input field when configured', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('AIzaTestKey')),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CriticChatModal(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(RatingSpikeSign), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.bolt), findsNothing);
      expect(find.text('GROOVD AI'), findsWidgets);
      expect(find.text('ROAST MY TASTE'), findsOneWidget);
      expect(find.text('WANTLIST RECOMMENDATION'), findsOneWidget);
      expect(find.text('HELP DRAFT A TAKE'), findsOneWidget);
      expect(find.byKey(const Key('critic_chat_input_field')), findsOneWidget);
      expect(find.byKey(const Key('critic_chat_send_btn')), findsOneWidget);
    });

    testWidgets('renders starter chips directly above the bottom input bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('AIzaTestKey')),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CriticChatModal(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      final chipsFinder = find.text('ROAST MY TASTE');
      final inputFinder = find.byKey(const Key('critic_chat_input_field'));
      expect(chipsFinder, findsOneWidget);
      expect(inputFinder, findsOneWidget);

      final chipsPos = tester.getBottomLeft(chipsFinder);
      final inputPos = tester.getTopLeft(inputFinder);
      // Chips should be immediately above input field (within ~45px)
      expect(inputPos.dy - chipsPos.dy, inInclusiveRange(0.0, 45.0));
    });

    testWidgets('renders GROOVD AI branding and no model names in header or empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('AIzaTestKey')),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CriticChatModal(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('GROOVD AI'), findsWidgets);
      expect(find.textContaining('GEMINI 3.5'), findsNothing);
      expect(find.textContaining('GEMINI 1.5'), findsNothing);
      expect(find.textContaining('FLASH'), findsNothing);
    });

    testWidgets('renders redesigned header actions (history and new convo) and removes reload and close', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('AIzaTestKey')),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CriticChatModal(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Old buttons must be completely removed
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);

      // New buttons must be present
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Initially empty conversation has blank subtitle (no 'ONLINE' text)
      expect(find.text('ONLINE'), findsNothing);
    });

    testWidgets('displays uppercase conversation title in header when session title is set', (WidgetTester tester) async {
      final sessionWithTitle = ConversationSession(
        id: 'sess_titled',
        title: '90S SHOEGAZE ESSENTIALS',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('AIzaTestKey')),
            criticChatProvider.overrideWith(
              () => _MockCriticChatNotifier(
                const [],
                initialSessions: [sessionWithTitle],
                initialActiveSessionId: 'sess_titled',
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CriticChatModal(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('90S SHOEGAZE ESSENTIALS'), findsOneWidget);
    });

    testWidgets('renders message history correctly with user and bot bubbles', (WidgetTester tester) async {
      final initialMessages = [
        ChatMessage(
          id: '1',
          text: 'What do you think of Kid A?',
          isUser: true,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: '2',
          text: 'A landmark in electronic alienation and art rock reinvention.',
          isUser: false,
          timestamp: DateTime.now(),
          hasPlayedScramble: true,
          albumAttachments: const [
            MusicItem(
              id: 'album_1',
              name: 'KID A',
              artist: 'RADIOHEAD',
              type: MusicType.album,
              coverUrl: '',
              releaseDate: '2000',
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('AIzaTestKey')),
            criticChatProvider.overrideWith(() => _MockCriticChatNotifier(initialMessages)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CriticChatModal(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('What do you think of Kid A?'), findsOneWidget);
      expect(find.text('A landmark in electronic alienation and art rock reinvention.', findRichText: true), findsOneWidget);
      expect(find.byType(GroovdMarkdownText), findsOneWidget);
      expect(find.text('KID A'), findsOneWidget);
      expect(find.text('RADIOHEAD'), findsOneWidget);
    });

    testWidgets('shows decoding placeholder during streaming and does not leak partial text before scramble', (WidgetTester tester) async {
      final streamingMessages = [
        ChatMessage(
          id: 'u1',
          text: 'Give me your take',
          isUser: true,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: 'b1',
          text: 'This is partial streamed text from model',
          isUser: false,
          timestamp: DateTime.now(),
          hasPlayedScramble: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('AIzaTestKey')),
            criticChatProvider.overrideWith(
              () => _MockStreamingCriticChatNotifier(streamingMessages),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CriticChatModal(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Decoding placeholder must be visible
      expect(find.text('[DECODING GROOVD CRITIQUE...]'), findsOneWidget);
      // Partial text must NOT be visible yet
      expect(find.textContaining('This is partial streamed text'), findsNothing);
    });

    testWidgets('tapping album attachment navigates to MusicDetailScreen', (WidgetTester tester) async {
      final initialMessages = [
        ChatMessage(
          id: 'bot_1',
          text: 'Check out this release.',
          isUser: false,
          timestamp: DateTime.now(),
          hasPlayedScramble: true,
          albumAttachments: const [
            MusicItem(
              id: 'album_test_tap',
              name: 'IN RAINBOWS',
              artist: 'RADIOHEAD',
              type: MusicType.album,
              coverUrl: '',
              releaseDate: '2007',
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('AIzaTestKey')),
            criticChatProvider.overrideWith(() => _MockCriticChatNotifier(initialMessages)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CriticChatModal(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('IN RAINBOWS'), findsOneWidget);
      await tester.tap(find.text('IN RAINBOWS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(MusicDetailScreen), findsOneWidget);
    });

    testWidgets('renders photo attachment button at the corner left of input bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('AIzaTestKey')),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CriticChatModal(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      final attachBtn = find.byKey(const Key('critic_chat_attach_photo_btn'));
      final inputField = find.byKey(const Key('critic_chat_input_field'));
      final sendBtn = find.byKey(const Key('critic_chat_send_btn'));

      expect(attachBtn, findsOneWidget);
      expect(inputField, findsOneWidget);
      expect(sendBtn, findsOneWidget);

      // Verify attachBtn is positioned to the left of the input field
      final attachOffset = tester.getTopLeft(attachBtn);
      final inputOffset = tester.getTopLeft(inputField);
      expect(attachOffset.dx, lessThan(inputOffset.dx));
    });

    testWidgets('renders attached image in user bubble with tap-to-zoom target', (WidgetTester tester) async {
      final messagesWithPhoto = [
        ChatMessage(
          id: 'msg_user_photo',
          text: 'Rate my turntable setup',
          isUser: true,
          timestamp: DateTime.now(),
          hasPlayedScramble: true,
          imagePath: '/non/existent/test_deck.jpg',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('AIzaTestKey')),
            criticChatProvider.overrideWith(() => _MockCriticChatNotifier(messagesWithPhoto)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CriticChatModal(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Rate my turntable setup'), findsOneWidget);
      expect(find.byKey(const Key('critic_chat_user_photo_msg_user_photo')), findsOneWidget);
    });

    testWidgets('tapping attach button opens picker sheet, selecting photo shows preview banner with X discard button, and tapping X removes it', (WidgetTester tester) async {
      final mockPicker = _MockImagePicker(
        XFile.fromData(
          Uint8List.fromList([
            0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00,
            0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0x21,
            0xf9, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x2c, 0x00, 0x00,
            0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x01, 0x44,
            0x00, 0x3b,
          ]),
          path: '/dummy/photo.gif',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('AIzaTestKey')),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: CriticChatModal(imagePicker: mockPicker),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Initially no preview banner
      expect(find.byKey(const Key('critic_chat_preview_photo')), findsNothing);

      // Tap attach button
      await tester.tap(find.byKey(const Key('critic_chat_attach_photo_btn')));
      await tester.pumpAndSettle();

      // Verify bottom sheet appeared with both options
      expect(find.text('ATTACH PHOTO FOR CRITIQUE'), findsOneWidget);
      expect(find.text('TAKE PHOTO'), findsOneWidget);
      expect(find.text('CHOOSE FROM GALLERY'), findsOneWidget);

      // Select gallery option
      await tester.tap(find.byKey(const Key('critic_chat_pick_gallery_btn')));
      await tester.pumpAndSettle();

      // Preview banner should now be visible with discard button
      expect(find.byKey(const Key('critic_chat_preview_photo')), findsOneWidget);
      expect(find.byKey(const Key('critic_chat_discard_photo_btn')), findsOneWidget);
      expect(find.text('ATTACHED FOR INSPECTION'), findsOneWidget);

      // Tap discard X button
      await tester.tap(find.byKey(const Key('critic_chat_discard_photo_btn')));
      await tester.pump();

      // Preview banner should now be removed
      expect(find.byKey(const Key('critic_chat_preview_photo')), findsNothing);
      expect(find.byKey(const Key('critic_chat_discard_photo_btn')), findsNothing);
    });
  });
}

class _MockImagePicker extends ImagePicker {
  final XFile? fileToReturn;
  _MockImagePicker(this.fileToReturn);

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    return fileToReturn;
  }
}

class _MockGeminiSettingsNotifier extends GeminiSettingsNotifier {
  final String _key;
  _MockGeminiSettingsNotifier(this._key);

  @override
  GeminiSettingsState build() {
    return GeminiSettingsState(
      apiKey: _key,
      isConfigured: _key.isNotEmpty,
    );
  }
}

class _MockCriticChatNotifier extends CriticChatNotifier {
  final List<ChatMessage> initialMessages;
  final List<ConversationSession>? initialSessions;
  final String? initialActiveSessionId;

  _MockCriticChatNotifier(
    this.initialMessages, {
    this.initialSessions,
    this.initialActiveSessionId,
  });

  @override
  CriticChatState build() {
    if (initialSessions != null) {
      return CriticChatState(
        sessions: initialSessions,
        activeSessionId: initialActiveSessionId,
      );
    }
    return CriticChatState(
      messages: initialMessages,
      isThinking: false,
      isStreaming: false,
    );
  }
}

class _MockStreamingCriticChatNotifier extends CriticChatNotifier {
  final List<ChatMessage> initialMessages;
  _MockStreamingCriticChatNotifier(this.initialMessages);

  @override
  CriticChatState build() {
    return CriticChatState(
      messages: initialMessages,
      isThinking: false,
      isStreaming: true,
    );
  }
}
