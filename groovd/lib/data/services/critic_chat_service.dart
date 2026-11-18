import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:groovd/core/constants/gemini_config.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/data/models/review.dart';
import 'package:groovd/data/models/wishlist_item.dart';
import 'package:groovd/state/critic_chat_provider.dart';

/// Service wrapping Google Gemini for the Groovd AI Critic.
class CriticChatService {
  final String apiKey;
  final String tasteContext;
  GenerativeModel? _model;
  ChatSession? _chatSession;

  CriticChatService({
    required this.apiKey,
    this.tasteContext = '',
  }) {
    _initModel();
  }

  void _initModel() {
    if (apiKey.trim().isEmpty) return;

    final systemInstruction = StringBuffer();
    systemInstruction.writeln(
      'You are THE GROOVD CRITIC, the resident sharp-witted music journalist and tastemaker for the Groovd music critic notebook mobile app.',
    );
    systemInstruction.writeln(
      'You speak with encyclopedic music knowledge spanning indie rock, hip-hop, electronic, metal, jazz, pop, and underground subgenres.',
    );
    systemInstruction.writeln(
      'Tone: Concise, witty, opinionated, culturally sharp, and slightly cynical. You appreciate bold artistic choices, question mainstream consensus, and hate lazy production.',
    );
    systemInstruction.writeln(
      'Format: Keep your responses punchy and readable on a phone screen. Use short paragraphs and bold text for artist/album titles. Avoid long walls of text.',
    );
    systemInstruction.writeln(
      'VISION & VISUAL INSPECTION: When the user attaches an image, inspect it closely. Critique vinyl record sleeves, turntable setups, audio equipment, vinyl pressings, gig flyers, or album artwork with acute audio-cultural critique and technical precision. Maintain strict zero emojis.',
    );
    systemInstruction.writeln(
      'CRITICAL FORMATTING RULE: Absolutely NEVER use emojis or emoticons under any circumstances. Strict zero emojis.',
    );

    if (tasteContext.trim().isNotEmpty) {
      systemInstruction.writeln('\nUSER TASTE PROFILE:\n$tasteContext');
    }

    _model = GenerativeModel(
      model: GeminiConfig.modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(systemInstruction.toString()),
    );

    _chatSession = _model?.startChat();
  }

  /// Builds a taste grounding snapshot from the user\'s local reviews and wantlist.
  static String buildTasteGroundingContext({
    required List<Review> reviews,
    required List<WishlistItem> wishlist,
  }) {
    if (reviews.isEmpty && wishlist.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.writeln('=== CRITIC TASTE DOSSIER ===');

    if (reviews.isNotEmpty) {
      buffer.writeln('Recent Rated Releases:');
      final recentReviews = reviews.take(6);
      for (final r in recentReviews) {
        final headlineStr = r.headline.isNotEmpty ? ' - "${r.headline}"' : '';
        buffer.writeln('- ${r.musicItemName} by ${r.artistName} (Rated: ${r.rating.toStringAsFixed(1)}/10)$headlineStr');
      }

      final avgScore = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
      buffer.writeln('Average Critic Rating: ${avgScore.toStringAsFixed(1)}/10 across ${reviews.length} releases.');
    }

    if (wishlist.isNotEmpty) {
      buffer.writeln('\nCurrent Wantlist Queue:');
      final recentWish = wishlist.take(6);
      for (final w in recentWish) {
        buffer.writeln('- ${w.musicItem.name} by ${w.musicItem.artist}');
      }
    }

    return buffer.toString().trim();
  }

  /// Builds a structured taste grounding prompt instructing Gemini to recommend albums.
  static String buildRecommendationGroundingPrompt({
    required List<Review> reviews,
    List<MusicItem> topAlbums = const [],
    List<WishlistItem> wishlist = const [],
  }) {
    final buffer = StringBuffer();
    buffer.writeln('=== GROOVD CRITIC TASTE DOSSIER ===');

    // High rated and recent albums
    final albumReviews = reviews.where((r) => r.itemType == 'album' || r.itemType == 'ep').toList();
    if (albumReviews.isNotEmpty) {
      buffer.writeln('User\'s Highest Rated Albums:');
      // Sort by rating descending
      final sortedByRating = List<Review>.from(albumReviews)
        ..sort((a, b) => b.rating.compareTo(a.rating));
      for (final r in sortedByRating.take(8)) {
        final tagStr = r.tags.isNotEmpty ? ' [Tags: ${r.tags.join(', ')}]' : '';
        buffer.writeln('- "${r.musicItemName}" by ${r.artistName} (Score: ${r.rating.toStringAsFixed(1)}/10)$tagStr');
      }
    } else if (topAlbums.isEmpty) {
      buffer.writeln('User is initiating their personal canon. Recommend 7-8 quintessential underground essentials across diverse genres (art rock, shoegaze, trip hop, post-punk, electronic).');
    }

    if (topAlbums.isNotEmpty) {
      buffer.writeln('\nPinned Critic\'s Canon Top Albums:');
      for (final alb in topAlbums) {
        buffer.writeln('- "${alb.name}" by ${alb.artist}');
      }
    }

    if (wishlist.isNotEmpty) {
      buffer.writeln('\nActive Wantlist:');
      for (final w in wishlist.take(8)) {
        buffer.writeln('- "${w.musicItem.name}" by ${w.musicItem.artist}');
      }
    }

    // Exclusion list
    final excludedTitles = <String>{};
    for (final r in reviews) {
      excludedTitles.add('"${r.musicItemName}" by ${r.artistName}');
    }
    for (final w in wishlist) {
      excludedTitles.add('"${w.musicItem.name}" by ${w.musicItem.artist}');
    }
    for (final a in topAlbums) {
      excludedTitles.add('"${a.name}" by ${a.artist}');
    }

    if (excludedTitles.isNotEmpty) {
      buffer.writeln('\nDO NOT recommend any of the following already known/rated/queued releases:');
      for (final item in excludedTitles.take(30)) {
        buffer.writeln('- $item');
      }
    }

    buffer.writeln('''

INSTRUCTIONS:
You are GROOVD AI, an uncompromising underground music critic. Recommend 7-8 exceptional, relevant albums (LPs or EPs) that expand the user's personal canon. STRICTLY NO individual tracks, songs, or standalone singles. Recommend ONLY complete albums or EPs.
Provide output STRICTLY as a raw JSON array of objects. Each object must have these exact keys:
- "title": Album title (string)
- "artist": Artist name (string)
- "reasoning": 1 sharp, punchy sentence explaining why this release fits their taste (string, brutalist zine tone, zero emojis)
- "vibe_tag": An uppercase brutalist hashtag like #POST_PUNK_ESSENTIAL, #DARK_SHOEGAZE, #RAW_NOISE (string)

Return JSON only. No markdown formatting, no code fences, no introductory or concluding text.
''');

    return buffer.toString().trim();
  }

  /// Formats message text and optional image bytes into a Gemini [Content] object.
  static Content formatMessageContent(
    String message, {
    Uint8List? imageBytes,
    String mimeType = 'image/jpeg',
  }) {
    if (imageBytes != null && imageBytes.isNotEmpty) {
      return Content.multi([
        TextPart(message),
        DataPart(mimeType, imageBytes),
      ]);
    }
    return Content.text(message);
  }

  /// Sends a message and streams incoming response tokens.
  Stream<String> sendMessageStream(
    String message, {
    Uint8List? imageBytes,
    String mimeType = 'image/jpeg',
  }) async* {
    if (_chatSession == null) {
      _initModel();
      if (_chatSession == null) {
        throw Exception('GEMINI API KEY REQUIRED // CONFIGURE IN SETTINGS');
      }
    }

    final content = formatMessageContent(
      message,
      imageBytes: imageBytes,
      mimeType: mimeType,
    );

    final stream = _chatSession!.sendMessageStream(content);
    await for (final response in stream) {
      final text = response.text;
      if (text != null && text.isNotEmpty) {
        yield text;
      }
    }
  }

  /// Resets the conversation session.
  void resetChat() {
    _initModel();
  }

  /// Rehydrates the chat session from existing messages with role sanitization.
  void rehydrateHistory(List<ChatMessage> messages) {
    if (_model == null) {
      _initModel();
      if (_model == null) return;
    }
    final sanitized = sanitizeHistoryForGemini(messages);
    _chatSession = _model?.startChat(history: sanitized);
  }

  /// Sanitizes messages for Gemini SDK:
  /// - Strips leading bot messages (such as proactive greetings).
  /// - Ensures first turn is a user turn.
  /// - Strictly alternates user and model turns.
  static List<Content> sanitizeHistoryForGemini(List<ChatMessage> messages) {
    final history = <Content>[];
    bool expectingUser = true;

    for (final m in messages) {
      final promptText = m.text.trim().isNotEmpty
          ? m.text.trim()
          : (m.imagePath != null && m.imagePath!.isNotEmpty
              ? 'Inspect and critique this music release or vinyl record setup.'
              : '');
      if (promptText.isEmpty) continue;

      if (expectingUser) {
        if (m.isUser) {
          history.add(Content.text(promptText));
          expectingUser = false;
        }
      } else {
        if (!m.isUser) {
          history.add(Content.model([TextPart(promptText)]));
          expectingUser = true;
        }
      }
    }

    if (!expectingUser && history.isNotEmpty) {
      history.removeLast();
    }

    return history;
  }

  /// Generates a concise 2-4 word uppercase title summarizing the music conversation topic.
  Future<String> generateConversationTitle(String userQuery, String botReply) async {
    if (_model == null) return '';
    try {
      final prompt = 'Generate a 2 to 4 word uppercase title summarizing this music query/conversation. '
          'Strict rules: Return ONLY the title text. Absolutely no punctuation, no quotes, no markdown, and no emojis.\n'
          'Query: "$userQuery"\n'
          'Reply summary: "${botReply.length > 100 ? botReply.substring(0, 100) : botReply}"';
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      if (text.isEmpty) return '';
      // Sanitize punctuation and keep under 30 characters
      final sanitized = text.replaceAll(RegExp(r'[^\w\s]'), '').trim().toUpperCase();
      final words = sanitized.split(RegExp(r'\s+')).take(4).join(' ');
      return words;
    } catch (_) {
      return '';
    }
  }
}
