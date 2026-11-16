import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groovd/presentation/screens/chat/critic_history_sheet.dart';
import 'package:groovd/state/critic_chat_provider.dart';

void main() {
  testWidgets('CriticHistorySheet renders session list with titles, counts, and active badge', (WidgetTester tester) async {
    final s1 = ConversationSession(
      id: 'sess_1',
      title: 'SHOEGAZE ESSENTIALS',
      createdAt: DateTime(2026, 11, 16, 9, 0),
      updatedAt: DateTime(2026, 11, 16, 9, 30),
      messages: [
        ChatMessage(id: 'm1', text: 'Loveless critique', isUser: true, timestamp: DateTime.now()),
        ChatMessage(id: 'm2', text: 'Classic album.', isUser: false, timestamp: DateTime.now()),
      ],
    );
    final s2 = ConversationSession(
      id: 'sess_2',
      title: 'RADIOHEAD RANKINGS',
      createdAt: DateTime(2026, 11, 15, 14, 0),
      updatedAt: DateTime(2026, 11, 15, 14, 20),
      messages: [
        ChatMessage(id: 'm3', text: 'Rank Radiohead', isUser: true, timestamp: DateTime.now()),
      ],
    );

    final mockNotifier = _MockHistoryCriticChatNotifier([s1, s2], activeId: 'sess_1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          criticChatProvider.overrideWith(() => mockNotifier),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CriticHistorySheet(),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('CONVERSATION ARCHIVE'), findsOneWidget);
    expect(find.text('SHOEGAZE ESSENTIALS'), findsOneWidget);
    expect(find.text('RADIOHEAD RANKINGS'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('2 MESSAGES'), findsOneWidget);
    expect(find.text('1 MESSAGE'), findsOneWidget);

    // Verify close icon is removed and search button is present
    expect(find.byKey(const Key('critic_history_search_btn')), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('tapping search button morphs header into search input, and tapping back exits', (WidgetTester tester) async {
    final s1 = ConversationSession(
      id: 'sess_1',
      title: 'SHOEGAZE ESSENTIALS',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: const [],
    );

    final mockNotifier = _MockHistoryCriticChatNotifier([s1], activeId: 'sess_1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          criticChatProvider.overrideWith(() => mockNotifier),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CriticHistorySheet(),
          ),
        ),
      ),
    );

    await tester.pump();

    // Default state: Title visible, search button visible, search input not visible
    expect(find.text('CONVERSATION ARCHIVE'), findsOneWidget);
    expect(find.byKey(const Key('critic_history_search_btn')), findsOneWidget);
    expect(find.byKey(const Key('critic_history_search_input')), findsNothing);

    // Tap search button
    await tester.tap(find.byKey(const Key('critic_history_search_btn')));
    await tester.pump();

    // Search active: Title hidden, search input visible with hint, close/back button visible
    expect(find.text('CONVERSATION ARCHIVE'), findsNothing);
    expect(find.byKey(const Key('critic_history_search_input')), findsOneWidget);
    expect(find.text('SEARCH ARCHIVE...'), findsOneWidget);
    expect(find.byKey(const Key('critic_history_close_search_btn')), findsOneWidget);

    // Tap back button to exit search
    await tester.tap(find.byKey(const Key('critic_history_close_search_btn')));
    await tester.pump();

    // Restores default state
    expect(find.text('CONVERSATION ARCHIVE'), findsOneWidget);
    expect(find.byKey(const Key('critic_history_search_btn')), findsOneWidget);
    expect(find.byKey(const Key('critic_history_search_input')), findsNothing);
  });

  testWidgets('tapping session card switches session and dismisses sheet', (WidgetTester tester) async {
    final s1 = ConversationSession(
      id: 'sess_1',
      title: 'SESSION 1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: const [],
    );
    final s2 = ConversationSession(
      id: 'sess_2',
      title: 'SESSION 2',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: const [],
    );

    final mockNotifier = _MockHistoryCriticChatNotifier([s1, s2], activeId: 'sess_1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          criticChatProvider.overrideWith(() => mockNotifier),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CriticHistorySheet.show(context),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    expect(find.text('SESSION 2'), findsOneWidget);
    await tester.tap(find.text('SESSION 2'));
    await tester.pumpAndSettle();

    expect(mockNotifier.lastSwitchedSessionId, 'sess_2');
    // Sheet is dismissed
    expect(find.text('CONVERSATION ARCHIVE'), findsNothing);
  });

  testWidgets('tapping delete icon triggers session deletion', (WidgetTester tester) async {
    final s1 = ConversationSession(
      id: 'sess_1',
      title: 'SESSION 1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: const [],
    );

    final mockNotifier = _MockHistoryCriticChatNotifier([s1], activeId: 'sess_1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          criticChatProvider.overrideWith(() => mockNotifier),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CriticHistorySheet(),
          ),
        ),
      ),
    );

    await tester.pump();

    final deleteFinder = find.byIcon(Icons.delete_outline);
    expect(deleteFinder, findsOneWidget);

    await tester.tap(deleteFinder);
    await tester.pump();

    expect(mockNotifier.lastDeletedSessionId, 'sess_1');
  });

  testWidgets('filters sessions in real time by title and by message body, and shows empty query state', (WidgetTester tester) async {
    final s1 = ConversationSession(
      id: 'sess_1',
      title: 'SHOEGAZE ESSENTIALS',
      createdAt: DateTime(2026, 11, 16, 9, 0),
      updatedAt: DateTime(2026, 11, 16, 9, 30),
      messages: [
        ChatMessage(id: 'm1', text: 'Loveless critique', isUser: true, timestamp: DateTime.now()),
      ],
    );
    final s2 = ConversationSession(
      id: 'sess_2',
      title: '90S ROCK DISCUSSIONS',
      createdAt: DateTime(2026, 11, 15, 14, 0),
      updatedAt: DateTime(2026, 11, 15, 14, 20),
      messages: [
        ChatMessage(id: 'm2', text: 'Have you heard Stratosphere by Duster?', isUser: true, timestamp: DateTime.now()),
      ],
    );

    final mockNotifier = _MockHistoryCriticChatNotifier([s1, s2], activeId: 'sess_1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          criticChatProvider.overrideWith(() => mockNotifier),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CriticHistorySheet(),
          ),
        ),
      ),
    );

    await tester.pump();

    // Both sessions visible initially
    expect(find.text('SHOEGAZE ESSENTIALS'), findsOneWidget);
    expect(find.text('90S ROCK DISCUSSIONS'), findsOneWidget);

    // Open search
    await tester.tap(find.byKey(const Key('critic_history_search_btn')));
    await tester.pump();

    // 1. Search by title ("shoegaze")
    await tester.enterText(find.byKey(const Key('critic_history_search_input')), 'shoegaze');
    await tester.pump();

    expect(find.text('SHOEGAZE ESSENTIALS'), findsOneWidget);
    expect(find.text('90S ROCK DISCUSSIONS'), findsNothing);

    // 2. Search by message content ("Duster" - only inside sess_2 message, not in its title)
    await tester.enterText(find.byKey(const Key('critic_history_search_input')), 'Duster');
    await tester.pump();

    expect(find.text('90S ROCK DISCUSSIONS'), findsOneWidget);
    expect(find.text('SHOEGAZE ESSENTIALS'), findsNothing);

    // 3. Search with no matches
    await tester.enterText(find.byKey(const Key('critic_history_search_input')), 'Polka');
    await tester.pump();

    expect(find.text('NO ARCHIVES MATCHING "POLKA"'), findsOneWidget);
    expect(find.text('SHOEGAZE ESSENTIALS'), findsNothing);
    expect(find.text('90S ROCK DISCUSSIONS'), findsNothing);

    // 4. Tap clear button
    await tester.tap(find.byKey(const Key('critic_history_clear_search_btn')));
    await tester.pump();

    // Restores both
    expect(find.text('SHOEGAZE ESSENTIALS'), findsOneWidget);
    expect(find.text('90S ROCK DISCUSSIONS'), findsOneWidget);
  });

  testWidgets('sheet insets above keyboard and keeps search input above keyboard viewInsets', (WidgetTester tester) async {
    final s1 = ConversationSession(
      id: 'sess_1',
      title: 'SHOEGAZE ESSENTIALS',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: const [],
    );

    final mockNotifier = _MockHistoryCriticChatNotifier([s1], activeId: 'sess_1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          criticChatProvider.overrideWith(() => mockNotifier),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CriticHistorySheet.show(context),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    // Now simulate keyboard opening (320 logical pixels)
    const keyboardLogicalHeight = 320.0;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboardLogicalHeight * tester.view.devicePixelRatio);
    await tester.pump();

    // Open search
    await tester.tap(find.byKey(const Key('critic_history_search_btn')));
    await tester.pump();

    // Verify search input is present
    final searchInputFinder = find.byKey(const Key('critic_history_search_input'));
    expect(searchInputFinder, findsOneWidget);

    final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final searchBottom = tester.getBottomLeft(searchInputFinder).dy;
    expect(searchBottom, lessThan(screenHeight - keyboardLogicalHeight));

    // Reset view insets
    tester.view.resetViewInsets();
  });
}

class _MockHistoryCriticChatNotifier extends CriticChatNotifier {
  final List<ConversationSession> initialSessions;
  final String activeId;
  String? lastSwitchedSessionId;
  String? lastDeletedSessionId;

  _MockHistoryCriticChatNotifier(this.initialSessions, {required this.activeId});

  @override
  CriticChatState build() {
    return CriticChatState(
      sessions: initialSessions,
      activeSessionId: activeId,
      isThinking: false,
      isStreaming: false,
    );
  }

  @override
  Future<void> switchSession(String sessionId) async {
    lastSwitchedSessionId = sessionId;
    state = state.copyWith(activeSessionId: sessionId);
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    lastDeletedSessionId = sessionId;
    final remaining = state.sessions.where((s) => s.id != sessionId).toList();
    state = state.copyWith(
      sessions: remaining,
      activeSessionId: remaining.isNotEmpty ? remaining.first.id : '',
    );
  }
}
