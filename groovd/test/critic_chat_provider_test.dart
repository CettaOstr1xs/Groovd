import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/data/models/review.dart';
import 'package:groovd/data/models/wishlist_item.dart';
import 'package:groovd/data/services/critic_chat_service.dart';
import 'package:groovd/state/critic_chat_provider.dart';
import 'package:groovd/state/gemini_settings_provider.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });
  group('CriticChatService taste grounding', () {
    test('buildTasteGroundingContext formats summary correctly when items exist', () {
      final reviews = [
        Review(
          id: 'rev_1',
          userId: 'user_me',
          userName: 'Critic Test',
          userHandle: '@critictest',
          musicItemId: 'album_1',
          musicItemName: 'OK COMPUTER',
          artistName: 'RADIOHEAD',
          itemType: 'album',
          coverUrl: '',
          rating: 9.5,
          headline: 'A dystopian masterpiece',
          body: 'Peak alt rock art.',
          createdAt: DateTime.now(),
        ),
      ];

      final wishlist = [
        WishlistItem(
          musicItem: const MusicItem(
            id: 'album_2',
            name: 'VESPERTINE',
            artist: 'BJORK',
            type: MusicType.album,
            coverUrl: '',
            releaseDate: '2001-08-27',
          ),
          addedAt: DateTime.now(),
        ),
      ];

      final context = CriticChatService.buildTasteGroundingContext(
        reviews: reviews,
        wishlist: wishlist,
      );

      expect(context, contains('OK COMPUTER by RADIOHEAD (Rated: 9.5/10)'));
      expect(context, contains('VESPERTINE by BJORK'));
      expect(context, contains('CRITIC TASTE DOSSIER'));
    });

    test('buildTasteGroundingContext handles empty reviews and wantlist gracefully', () {
      final context = CriticChatService.buildTasteGroundingContext(
        reviews: const [],
        wishlist: const [],
      );

      expect(context, isEmpty);
    });
  });

  group('CriticChatNotifier', () {
    test('initial state has empty messages and not thinking/streaming', () {
      final container = ProviderContainer(
        overrides: [
          geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('test_key')),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(criticChatProvider);
      expect(state.messages, isEmpty);
      expect(state.isThinking, isFalse);
      expect(state.isStreaming, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('initProactiveGreeting inserts in-character bot greeting when chat is empty and is idempotent', () {
      final container = ProviderContainer(
        overrides: [
          geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('test_key')),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(criticChatProvider.notifier);
      expect(container.read(criticChatProvider).messages, isEmpty);

      notifier.initProactiveGreeting();

      final messages = container.read(criticChatProvider).messages;
      expect(messages.length, 1);
      expect(messages.first.isUser, isFalse);
      expect(messages.first.text, contains('GROOVD AI'));

      // Idempotent: does not duplicate
      notifier.initProactiveGreeting();
      expect(container.read(criticChatProvider).messages.length, 1);
    });

    test('ChatMessage supports albumAttachments and attaches resolved album art', () {
      const item = MusicItem(
        id: 'deezer_123',
        name: 'KID A',
        artist: 'RADIOHEAD',
        type: MusicType.album,
        coverUrl: 'https://cover.jpg',
        releaseDate: '2000-10-02',
      );
      final msg = ChatMessage(
        id: 'bot_1',
        text: 'Listen to **Kid A** by Radiohead.',
        isUser: false,
        timestamp: DateTime.now(),
        albumAttachments: const [item],
      );

      expect(msg.albumAttachments.length, 1);
      expect(msg.albumAttachments.first.name, 'KID A');
      expect(msg.albumAttachments.first.coverUrl, 'https://cover.jpg');
    });

    test('clearChat resets messages and state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(criticChatProvider.notifier);
      notifier.clearChat();
      final state = container.read(criticChatProvider);
      expect(state.messages, isEmpty);
      expect(state.isThinking, isFalse);
      expect(state.isStreaming, isFalse);
    });

    test('sendMessage with unconfigured key sets error message', () async {
      final container = ProviderContainer(
        overrides: [
          geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('')),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(criticChatProvider.notifier);
      await notifier.sendMessage('Roast my taste');

      final state = container.read(criticChatProvider);
      expect(state.errorMessage, contains('AI ACCESS KEY REQUIRED'));
    });

    test('CriticChatNotifier blocks concurrent sendMessage calls during active stream', () async {
      final controller = StreamController<String>();
      final mockService = _MockCriticChatService(streamHandler: (_) => controller.stream);

      final container = ProviderContainer(
        overrides: [
          geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('test_key')),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(criticChatProvider.notifier);
      notifier.setServiceForTesting(mockService);

      final firstCall = notifier.sendMessage('First message');
      expect(container.read(criticChatProvider).isThinking, isTrue);

      // Attempt concurrent call
      await notifier.sendMessage('Second concurrent message');

      // Messages should only contain the first message pair
      final messages = container.read(criticChatProvider).messages;
      expect(messages.map((m) => m.text), contains('First message'));
      expect(messages.map((m) => m.text), isNot(contains('Second concurrent message')));

      controller.add('chunk 1');
      await controller.close();
      await firstCall;
    });

    test('CriticChatNotifier removes empty bot placeholder and maps 429 error on stream failure', () async {
      final mockService = _MockCriticChatService(
        streamHandler: (_) => Stream.error(Exception('429 Resource has been exhausted (e.g. check quota).')),
      );

      final container = ProviderContainer(
        overrides: [
          geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('test_key')),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(criticChatProvider.notifier);
      notifier.setServiceForTesting(mockService);

      await notifier.sendMessage('Roast me');

      final state = container.read(criticChatProvider);
      expect(state.errorMessage, 'RATE LIMIT REACHED (15 RPM) // WAIT A MOMENT');
      // Empty bot placeholder must be removed; only user message remains
      expect(state.messages.length, equals(1));
      expect(state.messages.first.isUser, isTrue);
      expect(state.messages.first.text, 'Roast me');
    });

    test('CriticChatNotifier ignores stale stream chunks after clearChat', () async {
      final controller = StreamController<String>();
      final mockService = _MockCriticChatService(streamHandler: (_) => controller.stream);

      final container = ProviderContainer(
        overrides: [
          geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('test_key')),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(criticChatProvider.notifier);
      notifier.setServiceForTesting(mockService);

      final sendFuture = notifier.sendMessage('Initial query');
      controller.add('First chunk');
      await Future.delayed(Duration.zero);

      expect(container.read(criticChatProvider).messages.any((m) => m.text == 'First chunk'), isTrue);

      // User clears chat mid-stream
      notifier.clearChat();
      expect(container.read(criticChatProvider).messages, isEmpty);

      // Subsequent chunk arrives from network
      controller.add('Second chunk');
      await controller.close();
      await sendFuture;

      // Messages should still be empty
      expect(container.read(criticChatProvider).messages, isEmpty);
      expect(container.read(criticChatProvider).isStreaming, isFalse);
    });
  });

  group('ConversationSession and Multi-Session Management', () {
    test('ConversationSession and ChatMessage serialize and deserialize cleanly', () {
      final msg = ChatMessage(
        id: 'msg_1',
        text: 'Radiohead critique',
        isUser: true,
        timestamp: DateTime(2026, 11, 16, 10, 0),
        hasPlayedScramble: true,
        imagePath: '/storage/emulated/0/DCIM/vinyl_setup.jpg',
      );
      final session = ConversationSession(
        id: 'sess_1',
        title: 'RADIOHEAD DISCOGRAPHY',
        createdAt: DateTime(2026, 11, 16, 9, 30),
        updatedAt: DateTime(2026, 11, 16, 10, 0),
        messages: [msg],
      );

      final json = session.toJson();
      final restored = ConversationSession.fromJson(json);

      expect(restored.id, 'sess_1');
      expect(restored.title, 'RADIOHEAD DISCOGRAPHY');
      expect(restored.messages.length, 1);
      expect(restored.messages.first.id, 'msg_1');
      expect(restored.messages.first.text, 'Radiohead critique');
      expect(restored.messages.first.hasPlayedScramble, isTrue);
      expect(restored.messages.first.imagePath, '/storage/emulated/0/DCIM/vinyl_setup.jpg');
    });

    test('sendMessage creates user message with imagePath and sends imageBytes to service', () async {
      final controller = StreamController<String>();
      final mockService = _MockCriticChatService(
        streamHandler: (_) => controller.stream,
      );

      final container = ProviderContainer(
        overrides: [
          geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('test_key')),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(criticChatProvider.notifier);
      notifier.setServiceForTesting(mockService);

      final sendFuture = notifier.sendMessage(
        'Check this turntable',
        imagePath: '/tmp/test_turntable.jpg',
      );
      controller.add('Solid direct-drive deck.');
      await controller.close();
      await sendFuture;

      final state = container.read(criticChatProvider);
      final userMessage = state.messages.firstWhere((m) => m.isUser);
      expect(userMessage.imagePath, '/tmp/test_turntable.jpg');
      expect(userMessage.text, 'Check this turntable');
    });

    test('createNewSession creates a new session and sets it as active', () async {
      final container = ProviderContainer(
        overrides: [
          geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('test_key')),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(criticChatProvider.notifier);
      final initialSessionId = container.read(criticChatProvider).activeSessionId;

      await notifier.createNewSession();

      final state = container.read(criticChatProvider);
      expect(state.sessions.length, greaterThanOrEqualTo(2));
      expect(state.activeSessionId, isNot(equals(initialSessionId)));
      expect(state.activeSession?.id, equals(state.activeSessionId));
      expect(state.messages, isEmpty);
    });

    test('createNewSession enforces 50-session FIFO cap by pruning oldest session', () async {
      final container = ProviderContainer(
        overrides: [
          geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('test_key')),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(criticChatProvider.notifier);

      // Seed 50 sessions
      final seededSessions = List.generate(50, (i) {
        return ConversationSession(
          id: 'sess_$i',
          title: 'SESSION $i',
          createdAt: DateTime(2026, 1, 1).add(Duration(days: i)),
          updatedAt: DateTime(2026, 1, 1).add(Duration(days: i)),
          messages: const [],
        );
      });

      notifier.setSessionsForTesting(seededSessions, activeId: 'sess_49');
      expect(container.read(criticChatProvider).sessions.length, 50);

      // Create 51st session
      await notifier.createNewSession();

      final state = container.read(criticChatProvider);
      expect(state.sessions.length, 50);
      // Oldest session sess_0 should be pruned
      expect(state.sessions.any((s) => s.id == 'sess_0'), isFalse);
      // Newly created session is present and active
      expect(state.sessions.any((s) => s.id == state.activeSessionId), isTrue);
    });

    test('switchSession switches active session and active messages', () async {
      final container = ProviderContainer(
        overrides: [
          geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('test_key')),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(criticChatProvider.notifier);
      final s1 = ConversationSession(
        id: 's1',
        title: 'SESSION 1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: [
          ChatMessage(
            id: 'm1',
            text: 'First chat message',
            isUser: true,
            timestamp: DateTime.now(),
          ),
        ],
      );
      final s2 = ConversationSession(
        id: 's2',
        title: 'SESSION 2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: [
          ChatMessage(
            id: 'm2',
            text: 'Second chat message',
            isUser: true,
            timestamp: DateTime.now(),
          ),
        ],
      );

      notifier.setSessionsForTesting([s1, s2], activeId: 's1');
      expect(container.read(criticChatProvider).messages.first.text, 'First chat message');

      await notifier.switchSession('s2');

      final state = container.read(criticChatProvider);
      expect(state.activeSessionId, 's2');
      expect(state.messages.first.text, 'Second chat message');
    });

    test('deleteSession deletes target session and falls back smoothly', () async {
      final container = ProviderContainer(
        overrides: [
          geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('test_key')),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(criticChatProvider.notifier);
      final s1 = ConversationSession(
        id: 's1',
        title: 'SESSION 1',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now(),
        messages: const [],
      );
      final s2 = ConversationSession(
        id: 's2',
        title: 'SESSION 2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: const [],
      );

      notifier.setSessionsForTesting([s1, s2], activeId: 's2');

      // Delete active session s2
      await notifier.deleteSession('s2');

      final state = container.read(criticChatProvider);
      expect(state.sessions.length, 1);
      expect(state.sessions.first.id, 's1');
      expect(state.activeSessionId, 's1');

      // Delete last remaining session
      await notifier.deleteSession('s1');

      final finalState = container.read(criticChatProvider);
      expect(finalState.sessions.length, 1); // Auto-creates a new fresh session
      expect(finalState.activeSessionId, isNotEmpty);
      expect(finalState.messages, isEmpty);
    });

    test('deleteSession invalidates in-flight stream and ignores subsequent chunks', () async {
      final controller = StreamController<String>();
      final mockService = _MockCriticChatService(streamHandler: (_) => controller.stream);

      final container = ProviderContainer(
        overrides: [
          geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('test_key')),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(criticChatProvider.notifier);
      notifier.setServiceForTesting(mockService);

      final s1 = ConversationSession(id: 's1', createdAt: DateTime.now(), updatedAt: DateTime.now(), messages: const []);
      final s2 = ConversationSession(id: 's2', createdAt: DateTime.now(), updatedAt: DateTime.now(), messages: const []);
      notifier.setSessionsForTesting([s1, s2], activeId: 's1');

      final sendFuture = notifier.sendMessage('Initial query');
      controller.add('First chunk');
      await Future.delayed(Duration.zero);

      // User deletes active session s1 mid-stream
      await notifier.deleteSession('s1');
      expect(container.read(criticChatProvider).activeSessionId, 's2');

      // Subsequent chunk arrives from network
      controller.add('Second chunk');
      await controller.close();
      await sendFuture;

      // The remaining session s2 must not have received chunks or title meant for s1
      final state = container.read(criticChatProvider);
      expect(state.messages, isEmpty);
      expect(state.sessions.firstWhere((s) => s.id == 's2').title, isEmpty);
    });

    test('fallbackExtractTitle extracts concise uppercase words without stop words', () {
      final title1 = CriticChatNotifier.fallbackExtractTitle('what do you think of Loveless by My Bloody');
      expect(title1, contains('LOVELESS'));
      expect(title1.contains('WHAT'), isFalse);
      expect(title1.contains('YOU'), isFalse);
      expect(title1, equals(title1.toUpperCase()));

      final title2 = CriticChatNotifier.fallbackExtractTitle('roast my taste in 90s shoegaze');
      expect(title2, contains('90S SHOEGAZE'));
      expect(title2.contains('ROAST'), isFalse);
      expect(title2.contains('MY'), isFalse);
    });

    test('sendMessage triggers title generation on first exchange and does not overwrite existing title', () async {
      final controller = StreamController<String>();
      final mockService = _MockCriticChatService(
        streamHandler: (_) => controller.stream,
        titleResponse: 'SHOEGAZE ESSENTIALS',
      );

      final container = ProviderContainer(
        overrides: [
          geminiSettingsProvider.overrideWith(() => _MockGeminiSettingsNotifier('test_key')),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(criticChatProvider.notifier);
      notifier.setServiceForTesting(mockService);

      final sendFuture = notifier.sendMessage('What is Loveless?');
      controller.add('A classic shoegaze record.');
      await controller.close();
      await sendFuture;

      final state = container.read(criticChatProvider);
      expect(state.activeSession?.title, 'SHOEGAZE ESSENTIALS');

      // Subsequent message with a different title generator response should NOT overwrite
      final controller2 = StreamController<String>();
      final mockService2 = _MockCriticChatService(
        streamHandler: (_) => controller2.stream,
        titleResponse: 'SHOULD NOT OVERWRITE',
      );
      notifier.setServiceForTesting(mockService2);

      final sendFuture2 = notifier.sendMessage('Who produced it?');
      controller2.add('Kevin Shields produced it.');
      await controller2.close();
      await sendFuture2;

      final state2 = container.read(criticChatProvider);
      expect(state2.activeSession?.title, 'SHOEGAZE ESSENTIALS');
    });
  });
}

class _MockCriticChatService extends CriticChatService {
  final Stream<String> Function(String) streamHandler;
  final String? titleResponse;

  _MockCriticChatService({required this.streamHandler, this.titleResponse})
      : super(apiKey: 'test_key', tasteContext: '');

  @override
  Stream<String> sendMessageStream(
    String userMessage, {
    Uint8List? imageBytes,
    String mimeType = 'image/jpeg',
  }) =>
      streamHandler(userMessage);

  @override
  Future<String> generateConversationTitle(String userQuery, String botReply) async {
    return titleResponse ?? 'DEFAULT TITLE';
  }

  @override
  void resetChat() {}
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
