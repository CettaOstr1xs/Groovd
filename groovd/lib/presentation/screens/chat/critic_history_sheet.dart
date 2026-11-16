import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/state/critic_chat_provider.dart';

/// Neo-Brutalist bottom sheet displaying past AI critic conversation sessions.
class CriticHistorySheet extends ConsumerStatefulWidget {
  const CriticHistorySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CriticHistorySheet(),
    );
  }

  @override
  ConsumerState<CriticHistorySheet> createState() => _CriticHistorySheetState();
}

class _CriticHistorySheetState extends ConsumerState<CriticHistorySheet> {
  bool _isSearching = false;
  String _searchQuery = '';
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _startSearch() {
    HapticFeedback.selectionClick();
    setState(() {
      _isSearching = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _stopSearch() {
    HapticFeedback.selectionClick();
    _searchFocusNode.unfocus();
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(criticChatProvider);
    final sessions = chatState.sessions;
    final activeId = chatState.activeSessionId;

    final query = _searchQuery.toLowerCase();
    final filteredSessions = query.isEmpty
        ? sessions
        : sessions.where((s) {
            final titleMatch = s.title.toLowerCase().contains(query);
            final messageMatch = s.messages.any((m) => m.text.toLowerCase().contains(query));
            return titleMatch || messageMatch;
          }).toList();

    final viewInsets = MediaQuery.viewInsetsOf(context);
    final screenSize = MediaQuery.sizeOf(context);
    final availableHeight = screenSize.height - viewInsets.bottom;
    final maxHeight = (availableHeight * 0.85).clamp(240.0, screenSize.height * 0.85);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppColors.pureBlack, width: 2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.pureBlack,
              offset: Offset(0, -4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
            child: _isSearching
                ? Row(
                    children: [
                      // Back Button
                      IconButton(
                        key: const Key('critic_history_close_search_btn'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.acidLime),
                        tooltip: 'EXIT SEARCH',
                        onPressed: _stopSearch,
                      ),
                      const SizedBox(width: 8),

                      // Search Input Field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.pureBlack,
                            border: Border.all(color: AppColors.acidLime, width: 1.5),
                          ),
                          child: TextField(
                            key: const Key('critic_history_search_input'),
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            style: AppTypography.monoLabel(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.2,
                            ),
                            decoration: InputDecoration(
                              hintText: 'SEARCH ARCHIVE...',
                              hintStyle: AppTypography.monoLabel(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim();
                              });
                            },
                          ),
                        ),
                      ),

                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          key: const Key('critic_history_clear_search_btn'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                          tooltip: 'CLEAR',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.acidLime,
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CONVERSATION ARCHIVE',
                        style: AppTypography.displaySmall(fontSize: 13.5),
                      ),
                      const Spacer(),
                      IconButton(
                        key: const Key('critic_history_search_btn'),
                        icon: const Icon(Icons.search, size: 20, color: AppColors.acidLime),
                        tooltip: 'SEARCH ARCHIVE',
                        onPressed: _startSearch,
                      ),
                    ],
                  ),
          ),

          const Divider(color: AppColors.pureBlack, height: 1, thickness: 1.5),

          // Session List
          Flexible(
            child: sessions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'NO ARCHIVED CONVERSATIONS',
                        style: AppTypography.monoLabel(color: AppColors.textMuted),
                      ),
                    ),
                  )
                : filteredSessions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'NO ARCHIVES MATCHING "${_searchQuery.toUpperCase()}"',
                            textAlign: TextAlign.center,
                            style: AppTypography.monoLabel(color: AppColors.textMuted),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        shrinkWrap: true,
                        itemCount: filteredSessions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final session = filteredSessions[index];
                      final isActive = session.id == activeId;
                      final titleText = session.title.trim().isNotEmpty
                          ? session.title.toUpperCase()
                          : 'UNTITLED SESSION // ${_formatDate(session.createdAt)}';

                      final messageCount = session.messages.where((m) => m.text.isNotEmpty).length;
                      final countLabel = messageCount == 1 ? '1 MESSAGE' : '$messageCount MESSAGES';

                      return InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref.read(criticChatProvider.notifier).switchSession(session.id);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.surfaceElevated : AppColors.surface,
                            borderRadius: BorderRadius.zero,
                            border: Border.all(
                              color: isActive ? AppColors.acidLime : AppColors.pureBlack,
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.pureBlack,
                                offset: Offset(3, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (isActive) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            margin: const EdgeInsets.only(right: 6),
                                            decoration: const BoxDecoration(
                                              color: AppColors.acidLime,
                                              borderRadius: BorderRadius.zero,
                                            ),
                                            child: Text(
                                              'ACTIVE',
                                              style: AppTypography.monoLabel(
                                                color: AppColors.pureBlack,
                                                fontSize: 8.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                        Expanded(
                                          child: Text(
                                            titleText,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.displaySmall(
                                              fontSize: 12,
                                              color: isActive ? AppColors.acidLime : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          countLabel,
                                          style: AppTypography.monoLabel(
                                            color: AppColors.textMuted,
                                            fontSize: 9,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '// ${_formatDate(session.updatedAt)}',
                                          style: AppTypography.monoLabel(
                                            color: AppColors.textMuted,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Delete button
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
                                tooltip: 'DELETE',
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  ref.read(criticChatProvider.notifier).deleteSession(session.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}

  static String _formatDate(DateTime dt) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final month = months[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $month $hour:$minute';
  }
}
