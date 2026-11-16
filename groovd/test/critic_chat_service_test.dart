import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:groovd/data/services/critic_chat_service.dart';
import 'package:groovd/state/critic_chat_provider.dart';

void main() {
  group('CriticChatService multimodal content formatting', () {
    test('formatMessageContent returns Content.text when imageBytes is null or empty', () {
      final content = CriticChatService.formatMessageContent('What is Loveless?');
      expect(content.parts.length, 1);
      expect(content.parts.first, isA<TextPart>());
      expect((content.parts.first as TextPart).text, 'What is Loveless?');

      final emptyBytesContent = CriticChatService.formatMessageContent(
        'What is Loveless?',
        imageBytes: Uint8List(0),
      );
      expect(emptyBytesContent.parts.length, 1);
      expect(emptyBytesContent.parts.first, isA<TextPart>());
    });

    test('formatMessageContent returns Content.multi with TextPart and DataPart when imageBytes provided', () {
      final dummyBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      final content = CriticChatService.formatMessageContent(
        'Inspect this turntable',
        imageBytes: dummyBytes,
        mimeType: 'image/jpeg',
      );

      expect(content.parts.length, 2);
      expect(content.parts[0], isA<TextPart>());
      expect((content.parts[0] as TextPart).text, 'Inspect this turntable');
      expect(content.parts[1], isA<DataPart>());
      final dataPart = content.parts[1] as DataPart;
      expect(dataPart.mimeType, 'image/jpeg');
      expect(dataPart.bytes, dummyBytes);
    });
  });

  group('CriticChatService.sanitizeHistoryForGemini', () {
    test('returns empty list when messages list is empty', () {
      final sanitized = CriticChatService.sanitizeHistoryForGemini([]);
      expect(sanitized, isEmpty);
    });

    test('strips leading bot greeting and starts with first user message', () {
      final messages = [
        ChatMessage(
          id: 'bot_greeting',
          text: 'GROOVD AI ONLINE. Record shelf inspection ready.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: 'user_1',
          text: 'What do you think of Loveless?',
          isUser: true,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: 'bot_1',
          text: 'A landmark in guitar textures.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];

      final sanitized = CriticChatService.sanitizeHistoryForGemini(messages);

      expect(sanitized.length, 2);
      expect(sanitized[0].role, 'user');
      expect((sanitized[0].parts.first as TextPart).text, 'What do you think of Loveless?');
      expect(sanitized[1].role, 'model');
      expect((sanitized[1].parts.first as TextPart).text, 'A landmark in guitar textures.');
    });

    test('returns empty list if only bot greetings exist without any user messages', () {
      final messages = [
        ChatMessage(
          id: 'bot_greeting',
          text: 'GROOVD AI ONLINE. Ready for critique.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];

      final sanitized = CriticChatService.sanitizeHistoryForGemini(messages);
      expect(sanitized, isEmpty);
    });

    test('strictly alternates roles and discards invalid consecutive duplicates', () {
      final messages = [
        ChatMessage(id: 'u1', text: 'First user question', isUser: true, timestamp: DateTime.now()),
        ChatMessage(id: 'u2', text: 'Accidental second user question', isUser: true, timestamp: DateTime.now()),
        ChatMessage(id: 'b1', text: 'Bot answer to first', isUser: false, timestamp: DateTime.now()),
        ChatMessage(id: 'b2', text: 'Second bot follow-up', isUser: false, timestamp: DateTime.now()),
        ChatMessage(id: 'u3', text: 'Third user question', isUser: true, timestamp: DateTime.now()),
        ChatMessage(id: 'b3', text: 'Bot final answer', isUser: false, timestamp: DateTime.now()),
      ];

      final sanitized = CriticChatService.sanitizeHistoryForGemini(messages);

      expect(sanitized.length, 4);
      expect(sanitized[0].role, 'user');
      expect(sanitized[1].role, 'model');
      expect(sanitized[2].role, 'user');
      expect(sanitized[3].role, 'model');
    });

    test('removes trailing user turn that has not been answered by model yet', () {
      final messages = [
        ChatMessage(id: 'u1', text: 'What is OK Computer?', isUser: true, timestamp: DateTime.now()),
        ChatMessage(id: 'b1', text: 'A masterpiece.', isUser: false, timestamp: DateTime.now()),
        ChatMessage(id: 'u2', text: 'What about Kid A?', isUser: true, timestamp: DateTime.now()),
      ];

      final sanitized = CriticChatService.sanitizeHistoryForGemini(messages);

      // Trailing u2 removed so history ends on model, allowing next message to be user
      expect(sanitized.length, 2);
      expect(sanitized.last.role, 'model');
    });

    test('preserves user turns with empty text but attached imagePath using in-character fallback prompt', () {
      final messages = [
        ChatMessage(
          id: 'u1',
          text: '',
          isUser: true,
          timestamp: DateTime.now(),
          imagePath: '/path/to/vinyl.jpg',
        ),
        ChatMessage(
          id: 'b1',
          text: 'Nice direct drive turntable.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];

      final sanitized = CriticChatService.sanitizeHistoryForGemini(messages);

      expect(sanitized.length, 2);
      expect(sanitized[0].role, 'user');
      expect((sanitized[0].parts.first as TextPart).text, contains('Inspect and critique'));
      expect(sanitized[1].role, 'model');
      expect((sanitized[1].parts.first as TextPart).text, 'Nice direct drive turntable.');
    });
  });
}

