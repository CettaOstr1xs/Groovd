import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/music_item.dart';
import '../../../data/models/review.dart';
import '../../../state/auth_providers.dart';
import '../../../state/music_providers.dart';
import '../../../state/review_providers.dart';
import '../../../state/user_profile_provider.dart';
import '../../widgets/album_art_card.dart';
import '../../widgets/brutalist_button.dart';
import '../../widgets/critic_avatar.dart';
import '../../widgets/giant_score_badge.dart';
import '../artist/artist_detail_screen.dart';
import '../detail/music_detail_screen.dart';
import 'instagram_story_modal.dart';
import 'write_review_modal.dart';

class ReviewDetailScreen extends ConsumerStatefulWidget {
  final Review review;

  const ReviewDetailScreen({super.key, required this.review});

  @override
  ConsumerState<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends ConsumerState<ReviewDetailScreen> {
  late Review _review;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _review = widget.review;
  }

  void _handleLike() {
    HapticFeedback.lightImpact();
    setState(() {
      _isLiked = !_isLiked;
      _review = _review.copyWith(
        likesCount: _review.likesCount + (_isLiked ? 1 : -1),
      );
    });
    ref.read(reviewControllerProvider).likeReview(_review.id);
  }

  void _shareReview() {
    final profile = ref.read(userProfileProvider);
    final isCurrentUser = _review.userId == profile.userId;
    final reviewToShare = isCurrentUser
        ? _review.copyWith(userName: profile.userName, userHandle: profile.userHandle)
        : _review;
    InstagramStoryModal.show(context, reviewToShare);
  }

  Future<void> _openEditReview() async {
    final itemType = _review.itemType == 'song'
        ? MusicType.song
        : (_review.itemType == 'ep' ? MusicType.ep : MusicType.album);
    MusicItem? item = await ref.read(spotifyRepositoryProvider).getItemById(
          _review.musicItemId,
          type: itemType,
        );

    item ??= MusicItem(
      id: _review.musicItemId,
      name: _review.musicItemName,
      artist: _review.artistName,
      type: itemType,
      coverUrl: _review.coverUrl,
      releaseDate: '',
    );

    if (!mounted) return;

    final updated = await WriteReviewModal.show(
      context,
      item,
      existingReview: _review,
    );

    if (updated != null && mounted) {
      setState(() {
        _review = updated;
      });
    }
  }

  Future<void> _openMusicDetail() async {
    final itemType = _review.itemType == 'song'
        ? MusicType.song
        : (_review.itemType == 'ep' ? MusicType.ep : MusicType.album);
    MusicItem? item = await ref.read(spotifyRepositoryProvider).getItemById(
          _review.musicItemId,
          type: itemType,
        );

    item ??= MusicItem(
      id: _review.musicItemId,
      name: _review.musicItemName,
      artist: _review.artistName,
      type: itemType,
      coverUrl: _review.coverUrl,
      releaseDate: '',
    );

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MusicDetailScreen(item: item!)),
      );
    }
  }

  Future<void> _confirmDeleteReview() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
            side: const BorderSide(color: AppColors.vermillion, width: 2),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.vermillion, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DELETE CRITIQUE',
                  style: AppTypography.displaySmall(color: AppColors.vermillion),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete your rating and critique for "${_review.musicItemName.toUpperCase()}"? This action cannot be undone.',
            style: AppTypography.bodyMedium(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'CANCEL',
                style: AppTypography.monoBadge(color: AppColors.textPrimary),
              ),
            ),
            BrutalistButton(
              label: 'DELETE',
              icon: Icons.delete_forever,
              backgroundColor: AppColors.vermillion,
              textColor: AppColors.pureBlack,
              isSmall: true,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final reviewName = _review.musicItemName;
      await ref.read(reviewControllerProvider).deleteReview(_review.id);
      if (mounted) {
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.pureBlack,
            content: Text(
              'CRITIQUE DELETED: ${reviewName.toUpperCase()}',
              style: AppTypography.monoBadge(color: AppColors.vermillion),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMMM d, yyyy').format(_review.createdAt);
    final profile = ref.watch(userProfileProvider);
    final authUser = ref.watch(authStateProvider).asData?.value;

    final isCurrentUser = _review.userId == profile.userId ||
        (authUser != null && _review.userId == authUser.uid) ||
        (_review.userId == 'user_me') ||
        (profile.userHandle != '@groovd_me' &&
            _review.userHandle.isNotEmpty &&
            _review.userHandle.toLowerCase() == profile.userHandle.toLowerCase());

    final authorName = isCurrentUser ? profile.userName : _review.userName;
    final authorHandle = isCurrentUser ? profile.userHandle : _review.userHandle;
    final avatarToUse = isCurrentUser ? profile.avatarPath : _review.userAvatarUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('CRITIQUE ARCHIVE', style: AppTypography.displaySmall()),
        actions: [
          if (isCurrentUser) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.acidLime, size: 20),
              tooltip: 'Edit Rating & Critique',
              onPressed: _openEditReview,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.vermillion, size: 20),
              tooltip: 'Delete Critique',
              onPressed: _confirmDeleteReview,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 20),
            tooltip: 'Share Critique',
            onPressed: _shareReview,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Music Release Card Header (Interactive link to album)
            InkWell(
              onTap: _openMusicDetail,
              borderRadius: BorderRadius.circular(2),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  border: Border.all(color: AppColors.border, width: 1.5),
                  borderRadius: BorderRadius.circular(2),
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
                    SizedBox(
                      width: 58,
                      height: 58,
                      child: AlbumArtCard(
                        imageUrl: _review.coverUrl,
                        showShadow: false,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _review.itemType == 'album'
                                      ? AppColors.acidLime
                                      : (_review.itemType == 'ep' ? AppColors.electricPink : AppColors.cyberCyan),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  _review.itemType == 'album'
                                      ? 'LP // ALBUM'
                                      : (_review.itemType == 'ep' ? 'EP // EXTENDED PLAY' : 'SINGLE // SONG'),
                                  style: AppTypography.monoBadge(color: AppColors.pureBlack, fontSize: 8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'VIEW ARCHIVE',
                                style: AppTypography.monoLabel(fontSize: 8, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _review.musicItemName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.displaySmall(fontSize: 14),
                          ),
                          const SizedBox(height: 1),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ArtistDetailScreen(
                                    artistIdOrName: _review.artistName,
                                    initialArtistName: _review.artistName,
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    _review.artistName.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.monoLabel(color: AppColors.cyberCyan, fontSize: 10),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward, size: 10, color: AppColors.cyberCyan),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Giant Score Badge Section
            GiantScoreBadge(score: _review.rating),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Critic Persona Profile Block
            Row(
              children: [
                CriticAvatar(
                  avatarPath: avatarToUse,
                  fallbackInitial: authorName,
                  size: 44,
                  borderColor: AppColors.pureBlack,
                  borderWidth: 2.0,
                  fallbackBgColor: isCurrentUser ? AppColors.acidLime : AppColors.surfaceElevated,
                  fallbackTextColor: isCurrentUser ? AppColors.pureBlack : AppColors.textPrimary,
                  borderRadius: 2,
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.pureBlack,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              authorName.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.displaySmall(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                            child: Text(
                              isCurrentUser ? 'YOU' : 'CRITIC',
                              style: AppTypography.monoBadge(color: AppColors.acidLime, fontSize: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$authorHandle • $formattedDate (${_review.timeAgo})',
                        style: AppTypography.monoLabel(color: AppColors.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Headline
            if (_review.headline.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(left: 14),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.acidLime, width: 3.5),
                  ),
                ),
                child: Text(
                  _review.headline.toUpperCase(),
                  style: AppTypography.displayMedium(fontSize: 20),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Body
            if (_review.body.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  border: Border.all(color: AppColors.border, width: 1.5),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  _review.body,
                  style: AppTypography.bodyMedium(
                    color: AppColors.textPrimary,
                  ).copyWith(height: 1.65),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Vibes & Custom Tags
            if (_review.tags.isNotEmpty) ...[
              Text(
                'VIBES & TAGS',
                style: AppTypography.monoLabel(fontSize: 10, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _review.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      border: Border.all(color: AppColors.borderBold),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      tag.toUpperCase(),
                      style: AppTypography.monoBadge(
                        color: AppColors.acidLime,
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Bottom Engagement Actions Row
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  // Like Button
                  InkWell(
                    onTap: _handleLike,
                    borderRadius: BorderRadius.circular(2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isLiked ? AppColors.electricPink.withValues(alpha: 0.15) : AppColors.surfaceCard,
                        border: Border.all(
                          color: _isLiked ? AppColors.electricPink : AppColors.border,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: AppColors.electricPink,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_review.likesCount}',
                            style: AppTypography.monoBadge(
                              color: _isLiked ? AppColors.electricPink : AppColors.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Instagram Story Share Button
                  InkWell(
                    onTap: _shareReview,
                    borderRadius: BorderRadius.circular(2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        border: Border.all(
                          color: AppColors.acidLime.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_stories,
                            color: AppColors.acidLime,
                            size: 17,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'STORY',
                            style: AppTypography.monoBadge(
                              color: AppColors.acidLime,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Full album link button
                  BrutalistButton(
                    label: 'GO TO ARCHIVE',
                    icon: Icons.album_outlined,
                    backgroundColor: AppColors.acidLime,
                    textColor: AppColors.pureBlack,
                    isSmall: true,
                    onPressed: _openMusicDetail,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
