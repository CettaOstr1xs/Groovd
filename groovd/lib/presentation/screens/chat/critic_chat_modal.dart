import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/presentation/screens/chat/critic_history_sheet.dart';
import 'package:groovd/presentation/screens/detail/music_detail_screen.dart';
import 'package:groovd/presentation/widgets/chat_photo_zoom_viewer.dart';
import 'package:groovd/presentation/widgets/groovd_markdown_text.dart';
import 'package:groovd/presentation/widgets/rating_spike_sign.dart';
import 'package:groovd/presentation/widgets/scramble_text.dart';
import 'package:groovd/state/critic_chat_provider.dart';
import 'package:groovd/state/gemini_settings_provider.dart';

/// Neo-Brutalist slide-up AI music critic chat session modal.
class CriticChatModal extends ConsumerStatefulWidget {
  final ImagePicker? imagePicker;
  const CriticChatModal({super.key, this.imagePicker});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CriticChatModal(),
    );
  }

  @override
  ConsumerState<CriticChatModal> createState() => _CriticChatModalState();
}

class _CriticChatModalState extends ConsumerState<CriticChatModal> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _keyInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  String? _attachedImagePath;
  Uint8List? _attachedImageBytes;

  late final AnimationController _entranceController;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _bodyOpacity;
  late final Animation<double> _bottomOpacity;
  late final Animation<Offset> _bottomSlide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _headerOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0.0, -0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    _bodyOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.85, curve: Curves.easeOut),
    );

    _bottomOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    _bottomSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    _entranceController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final geminiSettings = ref.read(geminiSettingsProvider);
        if (geminiSettings.isConfigured) {
          ref.read(criticChatProvider.notifier).initProactiveGreeting();
        }
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _textController.dispose();
    _keyInputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage([String? overrideText]) {
    final chatState = ref.read(criticChatProvider);
    if (chatState.isThinking || chatState.isStreaming) return;

    final query = overrideText ?? _textController.text;
    final imagePath = _attachedImagePath;
    final imageBytes = _attachedImageBytes;

    if (query.trim().isEmpty && imagePath == null && imageBytes == null) return;

    HapticFeedback.lightImpact();
    ref.read(criticChatProvider.notifier).sendMessage(
      query,
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
    if (overrideText == null) {
      _textController.clear();
    }
    setState(() {
      _attachedImagePath = null;
      _attachedImageBytes = null;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final geminiSettings = ref.watch(geminiSettingsProvider);
    final chatState = ref.watch(criticChatProvider);
    final insets = MediaQuery.viewInsetsOf(context);
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.86;

    // Auto-scroll when new messages arrive
    ref.listen(criticChatProvider.select((s) => s.messages.length), (previous, next) {
      _scrollToBottom();
    });

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderBold, width: 2.0),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.pureBlack,
            offset: Offset(0, -4),
            blurRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 6),
                width: 38,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.borderBold,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),

            // Header Row
            FadeTransition(
              opacity: _headerOpacity,
              child: SlideTransition(
                position: _headerSlide,
                child: _buildHeader(context, chatState),
              ),
            ),

            const Divider(color: AppColors.border, height: 1, thickness: 1),

            // Body: API Key Config Gate OR Chat Stream View
            Expanded(
              child: FadeTransition(
                opacity: _bodyOpacity,
                child: !geminiSettings.isConfigured
                    ? _buildKeySetupView(context)
                    : _buildChatContentView(chatState),
              ),
            ),

            // Bottom Starter Chips & Input Bar (only shown when configured)
            if (geminiSettings.isConfigured) ...[
              Padding(
                padding: EdgeInsets.only(bottom: insets.bottom),
                child: FadeTransition(
                  opacity: _bottomOpacity,
                  child: SlideTransition(
                    position: _bottomSlide,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStarterChips(),
                        if (_attachedImagePath != null || _attachedImageBytes != null)
                          _buildAttachedImagePreview(),
                        _buildInputBar(chatState),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CriticChatState chatState) {
    final title = chatState.activeSession?.title.trim().toUpperCase() ?? '';
    final subtitleText = chatState.isThinking
        ? 'THINKING...'
        : chatState.isStreaming
            ? 'CRITIQUING...'
            : title;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
      child: Row(
        children: [
          // Sleek Neo-Brutalist Icon Badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.acidLime,
              borderRadius: BorderRadius.zero,
              border: Border.all(
                color: AppColors.pureBlack,
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.pureBlack,
                  offset: Offset(1.5, 1.5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Center(
              child: RatingSpikeSign(
                rating: 10.0,
                size: 20,
                color: AppColors.pureBlack,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GROOVD AI',
                  style: AppTypography.displaySmall(fontSize: 14.5),
                ),
                if (subtitleText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.acidLime,
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          subtitleText,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.monoLabel(
                            color: chatState.isThinking || chatState.isStreaming
                                ? AppColors.acidLime
                                : AppColors.cyberCyan,
                            fontSize: 9.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Conversation History Button
          IconButton(
            icon: const Icon(Icons.history, size: 20, color: AppColors.textMuted),
            tooltip: 'CONVERSATION ARCHIVE',
            onPressed: () {
              HapticFeedback.lightImpact();
              _openHistorySheet(context);
            },
          ),

          // New Conversation Button
          IconButton(
            icon: const Icon(Icons.add, size: 22, color: AppColors.acidLime),
            tooltip: 'NEW CONVERSATION',
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(criticChatProvider.notifier).createNewSession();
            },
          ),
        ],
      ),
    );
  }

  void _openHistorySheet(BuildContext context) {
    CriticHistorySheet.show(context);
  }

  Widget _buildKeySetupView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: AppColors.acidLime, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.pureBlack,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.key, color: AppColors.acidLime, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'FREE AI API KEY REQUIRED',
                        style: AppTypography.displaySmall(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'To enable GROOVD AI with personalized taste grounding, please provide a free API key.\n\n'
                    '• 100% Free: 15 requests/min on Google AI Studio.\n'
                    '• Zero credit card required.\n'
                    '• Get your key at: aistudio.google.com',
                    style: AppTypography.bodySmall(fontSize: 11.5).copyWith(
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Key TextField
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.pureBlack,
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: TextField(
                      key: const Key('critic_chat_key_input'),
                      controller: _keyInputController,
                      obscureText: true,
                      style: AppTypography.monoLabel(fontSize: 12, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'PASTE API KEY HERE...',
                        hintStyle: AppTypography.monoLabel(fontSize: 11, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Save Button
                  GestureDetector(
                    key: const Key('critic_chat_save_key_btn'),
                    onTap: () {
                      final key = _keyInputController.text.trim();
                      if (key.isNotEmpty) {
                        HapticFeedback.heavyImpact();
                        ref.read(geminiSettingsProvider.notifier).saveApiKey(key);
                        ref.read(criticChatProvider.notifier).initProactiveGreeting();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: const BoxDecoration(
                        color: AppColors.acidLime,
                        borderRadius: BorderRadius.zero,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.pureBlack,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'SAVE KEY',
                          style: AppTypography.displaySmall(fontSize: 12).copyWith(
                            color: AppColors.pureBlack,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatContentView(CriticChatState chatState) {
    return Column(
      children: [
        // Error Banner if present
        if (chatState.errorMessage != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.vermillion.withValues(alpha: 0.12),
              border: const Border(
                bottom: BorderSide(color: AppColors.vermillion, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.vermillion, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    chatState.errorMessage!,
                    style: AppTypography.monoLabel(color: AppColors.vermillion, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Message Feed
        Expanded(
          child: chatState.messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  itemCount: chatState.messages.length,
                  itemBuilder: (context, index) {
                    final msg = chatState.messages[index];
                    return _buildMessageBubble(msg, chatState);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStarterChips() {
    final chips = [
      'ROAST MY TASTE',
      'WANTLIST RECOMMENDATION',
      'HELP DRAFT A TAKE',
      'SPIN OR SKIP?',
    ];

    return Container(
      height: 42,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        itemCount: chips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = chips[index];
          return GestureDetector(
            onTap: () => _handleSendMessage(label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: AppColors.borderBold, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.pureBlack,
                    offset: Offset(1.5, 1.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  label,
                  style: AppTypography.monoLabel(
                    color: AppColors.acidLime,
                    fontSize: 9.5,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.zero,
                border: Border.all(
                  color: AppColors.acidLime,
                  width: 2.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.pureBlack,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const RatingSpikeSign(
                rating: 10.0,
                size: 32,
                color: AppColors.acidLime,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'GROOVD AI',
              style: AppTypography.displaySmall(fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'AN UNCOMPROMISING AI MUSIC CRITIC NOTEBOOK.',
              textAlign: TextAlign.center,
              style: AppTypography.monoLabel(fontSize: 9.5, color: AppColors.acidLime),
            ),
            const SizedBox(height: 10),
            Text(
              'Ask for a deep-cut recommendation, request an objective roast of your recent ratings, or craft your next critique.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(fontSize: 11.5).copyWith(
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, CriticChatState chatState) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.cyberCyan, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.pureBlack,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (msg.imagePath != null && msg.imagePath!.isNotEmpty) ...[
                GestureDetector(
                  key: Key('critic_chat_user_photo_${msg.id}'),
                  onTap: () {
                    ChatPhotoZoomViewer.show(context, imagePath: msg.imagePath);
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: msg.text.trim().isNotEmpty ? 8 : 0),
                    constraints: const BoxConstraints(
                      maxWidth: 220,
                      maxHeight: 180,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pureBlack,
                      border: Border.all(color: AppColors.cyberCyan, width: 1),
                    ),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        _buildUserBubbleImage(msg.imagePath!),
                        Container(
                          padding: const EdgeInsets.all(4),
                          color: AppColors.pureBlack.withValues(alpha: 0.7),
                          child: const Icon(
                            Icons.zoom_in,
                            size: 14,
                            color: AppColors.cyberCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (msg.text.trim().isNotEmpty)
                Text(
                  msg.text,
                  style: AppTypography.monoLabel(
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.2,
                  ).copyWith(height: 1.4),
                ),
            ],
          ),
        ),
      );
    } else {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14, right: 30),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.pureBlack,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.acidLime, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.pureBlack,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const RatingSpikeSign(rating: 10.0, size: 14, color: AppColors.acidLime),
                  const SizedBox(width: 5),
                  Text(
                    'GROOVD AI',
                    style: AppTypography.monoBadge(color: AppColors.acidLime, fontSize: 9),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if ((chatState.isThinking || chatState.isStreaming) &&
                  msg.id == chatState.messages.lastOrNull?.id) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.acidLime,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '[DECODING GROOVD CRITIQUE...]',
                      style: AppTypography.monoLabel(
                        color: AppColors.acidLime,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ] else if (!msg.hasPlayedScramble) ...[
                ScrambleText(
                  text: msg.text,
                  duration: const Duration(milliseconds: 1000),
                  onComplete: () {
                    ref.read(criticChatProvider.notifier).markScramblePlayed(msg.id);
                  },
                ),
              ] else ...[
                GroovdMarkdownText(text: msg.text),
              ],

              // Attached Album Art Cards if any releases were mentioned
              if (msg.albumAttachments.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: msg.albumAttachments.map((item) {
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MusicDetailScreen(item: item),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(color: AppColors.acidLime, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.pureBlack,
                              offset: Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.coverUrl.isNotEmpty) ...[
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.pureBlack, width: 1),
                                ),
                                child: Image.network(
                                  item.coverUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.pureBlack,
                                    child: const Icon(Icons.album, size: 20, color: AppColors.textMuted),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.name.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.monoLabel(
                                      color: AppColors.white,
                                      fontSize: 10,
                                    ).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.artist.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.monoLabel(
                                      color: AppColors.textMuted,
                                      fontSize: 8.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      );
    }
  }

  Widget _buildUserBubbleImage(String path) {
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildMissingBubblePhoto(),
      );
    }
    return _buildMissingBubblePhoto();
  }

  Widget _buildMissingBubblePhoto() {
    return Container(
      width: 140,
      height: 90,
      color: AppColors.pureBlack,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 24),
            const SizedBox(height: 4),
            Text(
              'PHOTO',
              style: AppTypography.monoLabel(fontSize: 9, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachedImagePreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                key: const Key('critic_chat_preview_photo'),
                onTap: () {
                  ChatPhotoZoomViewer.show(
                    context,
                    imagePath: _attachedImagePath,
                    imageBytes: _attachedImageBytes,
                  );
                },
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.pureBlack,
                    border: Border.all(color: AppColors.acidLime, width: 1.5),
                  ),
                  child: _attachedImageBytes != null
                      ? Image.memory(
                          _attachedImageBytes!,
                          fit: BoxFit.cover,
                        )
                      : (_attachedImagePath != null
                          ? Image.file(
                              File(_attachedImagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image, color: AppColors.acidLime, size: 20),
                              ),
                            )
                          : const SizedBox.shrink()),
                ),
              ),
              Positioned(
                top: -10,
                right: -10,
                child: GestureDetector(
                  key: const Key('critic_chat_discard_photo_btn'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _attachedImagePath = null;
                      _attachedImageBytes = null;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.pureBlack,
                        border: Border.all(color: AppColors.acidLime, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: AppColors.acidLime,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ATTACHED FOR INSPECTION',
                  style: AppTypography.monoLabel(
                    color: AppColors.acidLime,
                    fontSize: 10,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'TAP TO ZOOM // X TO REMOVE',
                  style: AppTypography.monoLabel(
                    color: AppColors.textMuted,
                    fontSize: 8.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    HapticFeedback.selectionClick();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.pureBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.acidLime, width: 1.5),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ATTACH PHOTO FOR CRITIQUE',
                style: AppTypography.monoLabel(
                  color: AppColors.acidLime,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                key: const Key('critic_chat_pick_camera_btn'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.camera_alt_outlined, color: AppColors.acidLime, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        'TAKE PHOTO',
                        style: AppTypography.monoLabel(fontSize: 11, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                key: const Key('critic_chat_pick_gallery_btn'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_library_outlined, color: AppColors.acidLime, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        'CHOOSE FROM GALLERY',
                        style: AppTypography.monoLabel(fontSize: 11, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = widget.imagePicker ?? ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _attachedImagePath = picked.path;
          _attachedImageBytes = bytes;
        });
      }
    } catch (_) {
      // Graceful error handling
    }
  }

  Widget _buildInputBar(CriticChatState chatState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderBold, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          // Corner Left Photo Attachment Button
          GestureDetector(
            key: const Key('critic_chat_attach_photo_btn'),
            onTap: chatState.isThinking || chatState.isStreaming ? null : _pickImage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.pureBlack,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                size: 16,
                color: AppColors.acidLime,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Text Input Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.pureBlack,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: TextField(
                key: const Key('critic_chat_input_field'),
                controller: _textController,
                focusNode: _focusNode,
                style: AppTypography.monoLabel(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.2,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSendMessage(),
                decoration: InputDecoration(
                  hintText: 'ASK THE CRITIC...',
                  hintStyle: AppTypography.monoLabel(fontSize: 11, color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send Action Button
          GestureDetector(
            key: const Key('critic_chat_send_btn'),
            onTap: chatState.isThinking || chatState.isStreaming ? null : () => _handleSendMessage(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: chatState.isThinking || chatState.isStreaming
                    ? AppColors.surfaceElevated
                    : AppColors.acidLime,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: AppColors.pureBlack, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.pureBlack,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_upward,
                size: 16,
                color: chatState.isThinking || chatState.isStreaming
                    ? AppColors.textMuted
                    : AppColors.pureBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
