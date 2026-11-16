import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/data/services/critic_chat_service.dart';
import 'package:groovd/data/services/deezer_api_service.dart';
import 'package:groovd/state/gemini_settings_provider.dart';
import 'package:groovd/state/review_providers.dart';
import 'package:groovd/state/wishlist_provider.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<MusicItem> albumAttachments;
  final bool hasPlayedScramble;
  final String? imagePath;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.albumAttachments = const [],
    this.hasPlayedScramble = false,
    this.imagePath,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    List<MusicItem>? albumAttachments,
    bool? hasPlayedScramble,
    String? imagePath,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      albumAttachments: albumAttachments ?? this.albumAttachments,
      hasPlayedScramble: hasPlayedScramble ?? this.hasPlayedScramble,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'albumAttachments': albumAttachments.map((a) => a.toMap()).toList(),
    'hasPlayedScramble': hasPlayedScramble,
    if (imagePath != null) 'imagePath': imagePath,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      albumAttachments: (json['albumAttachments'] as List?)
              ?.map((e) => MusicItem.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      hasPlayedScramble: json['hasPlayedScramble'] as bool? ?? false,
      imagePath: json['imagePath'] as String?,
    );
  }
}

class ConversationSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  const ConversationSession({
    required this.id,
    this.title = '',
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  ConversationSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  }) {
    return ConversationSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory ConversationSession.fromJson(Map<String, dynamic> json) {
    return ConversationSession(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      messages: (json['messages'] as List?)
              ?.map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m as Map)))
              .toList() ??
          const [],
    );
  }
}

class CriticChatState {
  final List<ConversationSession> sessions;
  final String activeSessionId;
  final bool isThinking;
  final bool isStreaming;
  final String? errorMessage;

  CriticChatState({
    List<ConversationSession>? sessions,
    String? activeSessionId,
    List<ChatMessage>? messages,
    this.isThinking = false,
    this.isStreaming = false,
    this.errorMessage,
  })  : sessions = sessions ??
            (messages != null
                ? [
                    ConversationSession(
                      id: activeSessionId ?? 'default_session',
                      createdAt: DateTime(2026),
                      updatedAt: DateTime(2026),
                      messages: messages,
                    )
                  ]
                : const []),
        activeSessionId = activeSessionId ??
            (sessions?.isNotEmpty == true
                ? sessions!.first.id
                : (messages != null ? 'default_session' : ''));

  ConversationSession? get activeSession {
    if (sessions.isEmpty) return null;
    return sessions.firstWhere(
      (s) => s.id == activeSessionId,
      orElse: () => sessions.first,
    );
  }

  List<ChatMessage> get messages => activeSession?.messages ?? const [];

  CriticChatState copyWith({
    List<ConversationSession>? sessions,
    String? activeSessionId,
    List<ChatMessage>? messages,
    bool? isThinking,
    bool? isStreaming,
    String? errorMessage,
    bool clearError = false,
  }) {
    List<ConversationSession>? updatedSessions = sessions;
    if (messages != null) {
      final currentSessions = sessions ?? this.sessions;
      final currentActiveId = activeSessionId ?? this.activeSessionId;
      updatedSessions = currentSessions.map((s) {
        if (s.id == currentActiveId) {
          return s.copyWith(messages: messages, updatedAt: DateTime.now());
        }
        return s;
      }).toList();
    }

    return CriticChatState(
      sessions: updatedSessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      isThinking: isThinking ?? this.isThinking,
      isStreaming: isStreaming ?? this.isStreaming,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CriticChatNotifier extends Notifier<CriticChatState> {
  static const String _storageKey = 'groovd_critic_sessions_v1';
  static const int maxSessions = 50;

  CriticChatService? _service;
  DeezerApiService _deezerService = DeezerApiService();
  String _lastApiKey = '';
  int _streamRequestId = 0;
  bool _isTestMode = false;

  @override
  CriticChatState build() {
    final initialSession = ConversationSession(
      id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
      title: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: const [],
    );
    _loadPersistedSessions();
    return CriticChatState(
      sessions: [initialSession],
      activeSessionId: initialSession.id,
    );
  }

  Future<void> _loadPersistedSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_isTestMode) return;
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw) as List;
        final loadedSessions = decoded
            .map((item) => ConversationSession.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        if (loadedSessions.isNotEmpty && !_isTestMode) {
          final activeId = prefs.getString('${_storageKey}_active') ?? loadedSessions.first.id;
          state = state.copyWith(
            sessions: loadedSessions,
            activeSessionId: loadedSessions.any((s) => s.id == activeId) ? activeId : loadedSessions.first.id,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _persistSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(state.sessions.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
      await prefs.setString('${_storageKey}_active', state.activeSessionId);
    } catch (_) {}
  }

  void setServiceForTesting(CriticChatService service) {
    _service = service;
    _lastApiKey = ref.read(geminiSettingsProvider).apiKey;
  }

  void setDeezerServiceForTesting(DeezerApiService service) {
    _deezerService = service;
  }

  void setSessionsForTesting(List<ConversationSession> sessions, {required String activeId}) {
    _isTestMode = true;
    state = state.copyWith(
      sessions: sessions,
      activeSessionId: activeId,
    );
  }

  Future<void> createNewSession() async {
    _streamRequestId++;
    _service?.resetChat();

    final newSession = ConversationSession(
      id: 'sess_${DateTime.now().millisecondsSinceEpoch}_${state.sessions.length}',
      title: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: const [],
    );

    var updatedSessions = [newSession, ...state.sessions];
    if (updatedSessions.length > maxSessions) {
      // Keep newSession at top, sort remainder by updatedAt descending, cap at maxSessions
      final otherSessions = updatedSessions.skip(1).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      updatedSessions = [newSession, ...otherSessions.take(maxSessions - 1)];
    }

    state = state.copyWith(
      sessions: updatedSessions,
      activeSessionId: newSession.id,
      clearError: true,
    );

    await _persistSessions();
  }

  Future<void> switchSession(String sessionId) async {
    if (state.activeSessionId == sessionId) return;
    final session = state.sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => state.sessions.first,
    );

    _streamRequestId++;
    _service?.rehydrateHistory(session.messages);

    state = state.copyWith(
      activeSessionId: session.id,
      clearError: true,
    );

    await _persistSessions();
  }

  Future<void> deleteSession(String sessionId) async {
    _streamRequestId++;
    _service?.resetChat();

    final remaining = state.sessions.where((s) => s.id != sessionId).toList();
    if (remaining.isEmpty) {
      state = state.copyWith(sessions: const [], activeSessionId: '');
      await createNewSession();
      return;
    }

    String newActiveId = state.activeSessionId;
    if (state.activeSessionId == sessionId) {
      newActiveId = remaining.first.id;
      _service?.rehydrateHistory(remaining.first.messages);
    }

    state = state.copyWith(
      sessions: remaining,
      activeSessionId: newActiveId,
    );

    await _persistSessions();
  }

  void clearChat() {
    _streamRequestId++;
    _service?.resetChat();
    final updated = state.sessions.map((s) {
      if (s.id == state.activeSessionId) {
        return s.copyWith(messages: const [], title: '');
      }
      return s;
    }).toList();
    state = state.copyWith(
      sessions: updated,
      isThinking: false,
      isStreaming: false,
      clearError: true,
    );
    _persistSessions();
  }

  void markScramblePlayed(String messageId) {
    final updated = state.messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(hasPlayedScramble: true);
      }
      return m;
    }).toList();
    state = state.copyWith(messages: updated);
    _persistSessions();
  }

  /// Inserts a proactive, taste-grounded in-character greeting if chat history is empty.
  void initProactiveGreeting() {
    if (state.messages.isNotEmpty) return;

    final currentUserId = ref.read(currentUserIdProvider);
    final userReviews = ref.read(userReviewsProvider(currentUserId)).asData?.value ?? const [];
    final wishlist = ref.read(wishlistProvider);

    String greeting;
    if (userReviews.isNotEmpty) {
      final latest = userReviews.first;
      greeting = 'GROOVD AI ONLINE. I see you recently gave "${latest.musicItemName}" a ${latest.rating.toStringAsFixed(1)}. What vinyl is on your turntable right now, or should I roast that score?';
    } else if (wishlist.isNotEmpty) {
      final topWant = wishlist.first.musicItem;
      greeting = 'GROOVD AI ONLINE. You have "${topWant.name}" sitting in your wantlist queue. Ready to dissect it, or looking for something deeper?';
    } else {
      greeting = 'GROOVD AI ONLINE. Record shelf inspection ready. Name an album, EP, or single and I will deliver an uncompromising critique.';
    }

    final botMsg = ChatMessage(
      id: 'greeting_${DateTime.now().millisecondsSinceEpoch}',
      text: greeting,
      isUser: false,
      timestamp: DateTime.now(),
      hasPlayedScramble: true, // Proactive greeting does not play scramble
    );

    state = state.copyWith(messages: [botMsg]);
    _persistSessions();
  }

  Future<void> sendMessage(
    String text, {
    String? imagePath,
    Uint8List? imageBytes,
  }) async {
    final query = text.trim();
    if (query.isEmpty && imagePath == null && imageBytes == null) return;
    if (state.isThinking || state.isStreaming) return;

    final effectivePrompt = query.isEmpty && (imagePath != null || imageBytes != null)
        ? 'Inspect and critique this music release or vinyl record setup.'
        : query;

    final geminiSettings = ref.read(geminiSettingsProvider);
    if (!geminiSettings.isConfigured || geminiSettings.apiKey.isEmpty) {
      state = state.copyWith(
        errorMessage: 'AI ACCESS KEY REQUIRED // CONFIGURE IN SETTINGS',
      );
      return;
    }

    final requestId = ++_streamRequestId;

    // Refresh service if API key changed or not yet created
    if (_service == null || _lastApiKey != geminiSettings.apiKey) {
      final currentUserId = ref.read(currentUserIdProvider);
      final userReviews = ref.read(userReviewsProvider(currentUserId)).asData?.value ?? const [];
      final wishlist = ref.read(wishlistProvider);

      final tasteContext = CriticChatService.buildTasteGroundingContext(
        reviews: userReviews,
        wishlist: wishlist,
      );

      _lastApiKey = geminiSettings.apiKey;
      _service = CriticChatService(
        apiKey: geminiSettings.apiKey,
        tasteContext: tasteContext,
      );
    }

    final userMsg = ChatMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      text: query,
      isUser: true,
      timestamp: DateTime.now(),
      hasPlayedScramble: true,
      imagePath: imagePath,
    );

    final botMsgId = 'bot_${DateTime.now().millisecondsSinceEpoch}';
    final botPlaceholder = ChatMessage(
      id: botMsgId,
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      hasPlayedScramble: false,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, botPlaceholder],
      isThinking: true,
      isStreaming: false,
      clearError: true,
    );

    try {
      final stream = _service!.sendMessageStream(
        effectivePrompt,
        imageBytes: imageBytes,
      );
      var accumulatedText = '';

      await for (final chunk in stream) {
        if (requestId != _streamRequestId) return;
        accumulatedText += chunk;

        final updatedMessages = state.messages.map((m) {
          if (m.id == botMsgId) {
            return m.copyWith(text: accumulatedText);
          }
          return m;
        }).toList();

        state = state.copyWith(
          messages: updatedMessages,
          isThinking: false,
          isStreaming: true,
        );
      }

      if (requestId != _streamRequestId) return;

      state = state.copyWith(
        isThinking: false,
        isStreaming: false,
      );

      await _persistSessions();

      // Trigger dynamic title generation if session has no title
      await _maybeGenerateSessionTitle(state.activeSessionId, query, accumulatedText);

      // Asynchronously resolve and attach album art if any releases are mentioned
      _resolveAlbumArtForMessage(botMsgId, accumulatedText, requestId);
    } catch (e) {
      if (requestId != _streamRequestId) return;
      final errorStr = e.toString().replaceFirst('Exception: ', '');
      final cleanMessages = state.messages
          .where((m) => m.id != botMsgId || m.text.isNotEmpty)
          .toList();

      state = state.copyWith(
        messages: cleanMessages,
        isThinking: false,
        isStreaming: false,
        errorMessage: errorStr.contains('429')
            ? 'RATE LIMIT REACHED (15 RPM) // WAIT A MOMENT'
            : errorStr,
      );
    }
  }

  Future<void> _maybeGenerateSessionTitle(String sessionId, String query, String reply) async {
    final session = state.sessions.firstWhere((s) => s.id == sessionId, orElse: () => state.sessions.first);
    if (session.title.trim().isNotEmpty) return;

    String generatedTitle = '';
    if (_service != null) {
      try {
        generatedTitle = await _service!.generateConversationTitle(query, reply);
      } catch (_) {}
    }

    if (generatedTitle.trim().isEmpty) {
      generatedTitle = fallbackExtractTitle(query);
    }

    if (generatedTitle.trim().isNotEmpty) {
      final updated = state.sessions.map((s) {
        if (s.id == sessionId) {
          return s.copyWith(title: generatedTitle.trim().toUpperCase());
        }
        return s;
      }).toList();
      state = state.copyWith(sessions: updated);
      await _persistSessions();
    }
  }

  /// Extracts 2-4 uppercase words from a user query as a robust fallback title.
  static String fallbackExtractTitle(String query) {
    var clean = query.trim().replaceAll(RegExp(r'[^\w\s]'), ' ');
    final stopWords = {
      'WHAT', 'DO', 'YOU', 'THINK', 'OF', 'ABOUT', 'CAN', 'TELL', 'ME',
      'THE', 'AND', 'IS', 'ARE', 'WAS', 'WERE', 'RECOMMEND', 'ROAST', 'MY',
      'IN', 'A', 'AN', 'SOME', 'ANY', 'FOR', 'ON', 'TASTE', 'GIVE', 'PLEASE'
    };
    final words = clean
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w.toUpperCase())
        .where((w) => !stopWords.contains(w))
        .take(3)
        .toList();

    if (words.isNotEmpty) {
      return words.join(' ');
    }
    final rawWords = clean.split(RegExp(r'\s+')).take(3).join(' ').toUpperCase();
    return rawWords.isNotEmpty ? rawWords : 'MUSIC CHAT';
  }

  Future<void> _resolveAlbumArtForMessage(String messageId, String text, int requestId) async {
    final titles = extractMentionedTitles(text);
    if (titles.isEmpty) return;

    final attachments = <MusicItem>[];
    final seenIds = <String>{};

    for (final title in titles) {
      if (requestId != _streamRequestId) return;
      try {
        final results = await _deezerService.search(title, limit: 1);
        if (results.isNotEmpty) {
          final item = results.first;
          if (item.coverUrl.isNotEmpty && seenIds.add(item.id)) {
            attachments.add(item);
          }
        }
      } catch (_) {}
    }

    if (attachments.isNotEmpty && requestId == _streamRequestId) {
      final updatedMessages = state.messages.map((m) {
        if (m.id == messageId) {
          return m.copyWith(albumAttachments: attachments);
        }
        return m;
      }).toList();
      state = state.copyWith(messages: updatedMessages);
      await _persistSessions();
    }
  }

  static List<String> extractMentionedTitles(String text) {
    final titles = <String>[];
    final boldPattern = RegExp(r'\*\*([^*]+)\*\*');
    for (final match in boldPattern.allMatches(text)) {
      final candidate = match.group(1)?.trim();
      if (candidate != null &&
          candidate.length >= 2 &&
          candidate.length <= 40 &&
          !candidate.contains(':') &&
          !candidate.toUpperCase().contains('THE VERDICT') &&
          !titles.contains(candidate)) {
        titles.add(candidate);
      }
    }
    if (titles.isEmpty) {
      final quotePattern = RegExp(r'"([^"]+)"');
      for (final match in quotePattern.allMatches(text)) {
        final candidate = match.group(1)?.trim();
        if (candidate != null &&
            candidate.length >= 2 &&
            candidate.length <= 40 &&
            !titles.contains(candidate)) {
          titles.add(candidate);
        }
      }
    }
    return titles.take(2).toList();
  }
}

final criticChatProvider =
    NotifierProvider<CriticChatNotifier, CriticChatState>(CriticChatNotifier.new);
