import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/user_music_list.dart';
import 'package:groovd/presentation/widgets/brutalist_button.dart';
import 'package:groovd/state/user_lists_provider.dart';
import 'create_edit_list_modal.dart';
import 'list_detail_screen.dart';

class UserListsScreen extends ConsumerWidget {
  const UserListsScreen({super.key});

  static Route<void> route() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const UserListsScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.06, 0.0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 320),
    );
  }

  void _openCreateModal(BuildContext context) {
    CreateEditListModal.show(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(userListsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('CURATED LISTS', style: AppTypography.displaySmall()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.cyberCyan),
            tooltip: 'Create New List',
            onPressed: () => _openCreateModal(context),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Header Action Banner
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EDITORIAL COLLECTIONS',
                        style: AppTypography.monoLabel(fontSize: 10, color: AppColors.cyberCyan),
                      ),
                      Text(
                        '${lists.length} ${lists.length == 1 ? 'ARCHIVE' : 'ARCHIVES'}',
                        style: AppTypography.monoBadge(color: AppColors.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'PERSONAL CANONS & THEMATIC LISTS',
                    style: AppTypography.displayMedium(fontSize: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Group your favorite albums, deep cuts, and genre discoveries into custom editorial lists.',
                    style: AppTypography.bodySmall(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  BrutalistButton(
                    label: '+ CREATE NEW LIST',
                    icon: Icons.add,
                    isFullWidth: true,
                    backgroundColor: AppColors.cyberCyan,
                    textColor: AppColors.pureBlack,
                    borderColor: AppColors.pureBlack,
                    onPressed: () => _openCreateModal(context),
                  ),
                ],
              ),
            ),
          ),

          // Lists view or Empty state
          if (lists.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Icon(
                          Icons.queue_music_outlined,
                          size: 48,
                          color: AppColors.cyberCyan,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'NO CURATED LISTS YET',
                        style: AppTypography.displaySmall(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first custom list to assemble your top picks, genre rotations, or desert-island albums.',
                        style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      BrutalistButton(
                        label: 'START YOUR FIRST ARCHIVE',
                        isSmall: true,
                        backgroundColor: AppColors.cyberCyan,
                        textColor: AppColors.pureBlack,
                        borderColor: AppColors.pureBlack,
                        onPressed: () => _openCreateModal(context),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final list = lists[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ListSummaryCard(list: list)
                          .animate()
                          .fadeIn(duration: 250.ms, delay: (index * 40).ms)
                          .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
                    );
                  },
                  childCount: lists.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ListSummaryCard extends ConsumerWidget {
  final UserMusicList list;

  const _ListSummaryCard({required this.list});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final covers = list.previewCoverUrls;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ListDetailScreen(listId: list.id),
        ),
      ),
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          border: Border.all(color: AppColors.borderBold, width: 1.5),
          borderRadius: BorderRadius.circular(2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.pureBlack,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2x2 Mosaic Collage Thumbnail
            _ListArtCollage(covers: covers),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          list.summaryLabel.toUpperCase(),
                          style: AppTypography.monoBadge(
                            color: AppColors.cyberCyan,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.textMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 140),
                        color: AppColors.surface,
                        onSelected: (val) {
                          if (val == 'edit') {
                            CreateEditListModal.show(context, existingList: list);
                          } else if (val == 'delete') {
                            ref.read(userListsProvider.notifier).deleteList(list.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'LIST DELETED',
                                  style: AppTypography.monoBadge(color: AppColors.pureBlack),
                                ),
                                backgroundColor: AppColors.vermillion,
                              ),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('EDIT DETAILS'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('DELETE LIST', style: TextStyle(color: AppColors.vermillion)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    list.title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.displaySmall(fontSize: 16),
                  ),
                  if (list.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      list.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListArtCollage extends StatelessWidget {
  final List<String> covers;

  const _ListArtCollage({required this.covers});

  @override
  Widget build(BuildContext context) {
    const double size = 76.0;

    if (covers.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(2),
        ),
        child: const Icon(Icons.music_note, color: AppColors.textMuted, size: 28),
      );
    }

    if (covers.length < 4) {
      // Single artwork banner
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.pureBlack, width: 1.5),
          borderRadius: BorderRadius.circular(2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: CachedNetworkImage(
            imageUrl: covers.first,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: AppColors.surfaceCard),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 20),
          ),
        ),
      );
    }

    // 2x2 Grid Mosaic for 4+ items
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.pureBlack, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _singleThumb(covers[0])),
                  Expanded(child: _singleThumb(covers[1])),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _singleThumb(covers[2])),
                  Expanded(child: _singleThumb(covers[3])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _singleThumb(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: AppColors.surfaceCard),
      errorWidget: (context, url, error) => Container(color: AppColors.surfaceCard),
    );
  }
}
