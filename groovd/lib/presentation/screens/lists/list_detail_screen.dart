import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/data/models/user_music_list.dart';
import 'package:groovd/presentation/screens/detail/music_detail_screen.dart';
import 'package:groovd/presentation/widgets/album_art_card.dart';
import 'package:groovd/presentation/widgets/brutalist_button.dart';
import 'package:groovd/state/music_providers.dart';
import 'package:groovd/state/user_lists_provider.dart';
import 'create_edit_list_modal.dart';

class ListDetailScreen extends ConsumerStatefulWidget {
  final String listId;

  const ListDetailScreen({super.key, required this.listId});

  @override
  ConsumerState<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends ConsumerState<ListDetailScreen> {
  void _showAddMusicModal(BuildContext context, UserMusicList list) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMusicToListModal(listId: list.id),
    );
  }

  void _confirmDeleteList(BuildContext context, UserMusicList list) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: const BorderSide(color: AppColors.vermillion, width: 2.0),
        ),
        title: Text(
          'DELETE LIST ARCHIVE?',
          style: AppTypography.displaySmall(color: AppColors.vermillion),
        ),
        content: Text(
          'Are you sure you want to permanently delete "${list.title}"? This cannot be undone.',
          style: AppTypography.bodyMedium(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: AppTypography.monoBadge(color: AppColors.textSecondary),
            ),
          ),
          BrutalistButton(
            label: 'DELETE',
            isSmall: true,
            backgroundColor: AppColors.vermillion,
            textColor: AppColors.pureBlack,
            borderColor: AppColors.pureBlack,
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(userListsProvider.notifier).deleteList(list.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'LIST ARCHIVE DELETED',
                      style: AppTypography.monoBadge(color: AppColors.pureBlack),
                    ),
                    backgroundColor: AppColors.vermillion,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _shareList(UserMusicList list) {
    final buffer = StringBuffer();
    buffer.writeln('GROOVD // LIST: ${list.title.toUpperCase()}');
    if (list.description.isNotEmpty) {
      buffer.writeln(list.description);
    }
    buffer.writeln('---------------------------');
    for (int i = 0; i < list.items.length; i++) {
      final item = list.items[i];
      buffer.writeln('${(i + 1).toString().padLeft(2, '0')}. ${item.name} — ${item.artist}');
    }
    buffer.writeln('---------------------------');
    buffer.writeln('Curated on Groovd // Music Critique');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'LIST COPIED TO CLIPBOARD',
          style: AppTypography.monoBadge(color: AppColors.pureBlack),
        ),
        backgroundColor: AppColors.cyberCyan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(listByIdProvider(widget.listId));

    if (list == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('LIST ARCHIVE', style: AppTypography.displaySmall())),
        body: const Center(child: Text('List not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('CURATED ARCHIVE', style: AppTypography.displaySmall()),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary),
            tooltip: 'Share List',
            onPressed: () => _shareList(list),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
            tooltip: 'Edit List',
            onPressed: () => CreateEditListModal.show(context, existingList: list),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.vermillion),
            tooltip: 'Delete List',
            onPressed: () => _confirmDeleteList(context, list),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Header section
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
                  // Badges Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.cyberCyan,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'CURATED LIST',
                          style: AppTypography.monoBadge(color: AppColors.pureBlack, fontSize: 9),
                        ),
                      ),
                      Text(
                        list.summaryLabel.toUpperCase(),
                        style: AppTypography.monoLabel(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Giant List Title
                  Text(
                    list.title.toUpperCase(),
                    style: AppTypography.displayMedium(fontSize: 24),
                  ),

                  if (list.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      list.description,
                      style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Add Item Action Button
                  BrutalistButton(
                    label: '+ ADD ALBUM / SONG',
                    icon: Icons.add,
                    isFullWidth: true,
                    backgroundColor: AppColors.acidLime,
                    textColor: AppColors.pureBlack,
                    borderColor: AppColors.pureBlack,
                    onPressed: () => _showAddMusicModal(context, list),
                  ),
                ],
              ),
            ),
          ),

          // Items List / Empty State
          if (list.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.queue_music, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        'ARCHIVE IS EMPTY',
                        style: AppTypography.displaySmall(),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Search and add albums or tracks to begin crafting your curated sonic collection.',
                        style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      BrutalistButton(
                        label: '+ SEARCH RELEASES',
                        isSmall: true,
                        backgroundColor: AppColors.surfaceElevated,
                        textColor: AppColors.cyberCyan,
                        borderColor: AppColors.cyberCyan,
                        onPressed: () => _showAddMusicModal(context, list),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = list.items[index];
                    return Dismissible(
                      key: Key('list_item_${item.id}_$index'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: AppColors.vermillion,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete_outline, color: AppColors.pureBlack),
                      ),
                      onDismissed: (_) {
                        ref.read(userListsProvider.notifier).removeItemFromList(list.id, item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'REMOVED "${item.name.toUpperCase()}"',
                              style: AppTypography.monoBadge(color: AppColors.pureBlack),
                            ),
                            backgroundColor: AppColors.vermillion,
                          ),
                        );
                      },
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MusicDetailScreen(item: item),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
                          ),
                          child: Row(
                            children: [
                              // Order number
                              SizedBox(
                                width: 28,
                                child: Text(
                                  (index + 1).toString().padLeft(2, '0'),
                                  style: AppTypography.monoBadge(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Artwork
                              AlbumArtCard(
                                imageUrl: item.coverUrl,
                                size: 48,
                                heroTag: 'list_${list.id}_item_${item.id}_$index',
                              ),
                              const SizedBox(width: 14),

                              // Title & Artist
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodyLarge(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.artist.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.monoLabel(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Format badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: item.isAlbum ? AppColors.surfaceCard : AppColors.surfaceElevated,
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  item.isAlbum ? 'LP' : 'SONG',
                                  style: AppTypography.monoBadge(
                                    color: item.isAlbum ? AppColors.acidLime : AppColors.cyberCyan,
                                    fontSize: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Remove icon button
                              IconButton(
                                icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                                onPressed: () {
                                  ref
                                      .read(userListsProvider.notifier)
                                      .removeItemFromList(list.id, item.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: list.items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddMusicToListModal extends ConsumerStatefulWidget {
  final String listId;

  const _AddMusicToListModal({required this.listId});

  @override
  ConsumerState<_AddMusicToListModal> createState() => _AddMusicToListModalState();
}

class _AddMusicToListModalState extends ConsumerState<_AddMusicToListModal> {
  final TextEditingController _searchController = TextEditingController();
  List<MusicItem> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialSuggestions() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(spotifyRepositoryProvider);
      final trending = await repo.getTrendingAlbums();
      final tracks = await repo.getHotTracks();
      final combined = [...trending.take(5), ...tracks.take(5)];
      if (mounted) {
        setState(() {
          _results = combined;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      _loadInitialSuggestions();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(spotifyRepositoryProvider);
      final res = await repo.search(clean);
      if (mounted) {
        setState(() {
          _results = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final list = ref.watch(listByIdProvider(widget.listId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      margin: EdgeInsets.only(
        left: 8,
        right: 8,
        bottom: bottomInset > 0 ? bottomInset : 16,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.borderBold, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: AppColors.pureBlack,
            offset: Offset(6, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ADD RELEASES TO LIST', style: AppTypography.displaySmall()),
                    const SizedBox(height: 2),
                    Text(
                      'STREAM FROM SPOTIFY CATALOG',
                      style: AppTypography.monoLabel(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchController,
            style: AppTypography.bodyLarge(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search artist, album or track...',
              hintStyle: AppTypography.bodyMedium(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search, color: AppColors.acidLime),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _loadInitialSuggestions();
                      },
                    )
                  : null,
            ),
            onSubmitted: _performSearch,
            onChanged: (val) {
              if (val.isEmpty) _loadInitialSuggestions();
            },
          ),
          const SizedBox(height: 12),

          // Results / Suggestions
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.acidLime))
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          'NO RELEASES FOUND',
                          style: AppTypography.monoLabel(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          final alreadyInList = list?.items.any((i) => i.id == item.id) ?? false;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            leading: AlbumArtCard(imageUrl: item.coverUrl, size: 42),
                            title: Text(
                              item.name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyLarge(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${item.isAlbum ? 'LP' : 'SONG'} • ${item.artist.toUpperCase()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.monoLabel(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: alreadyInList
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      border: Border.all(color: AppColors.border),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      'ADDED',
                                      style: AppTypography.monoBadge(
                                        color: AppColors.textMuted,
                                        fontSize: 9,
                                      ),
                                    ),
                                  )
                                : BrutalistButton(
                                    label: '+ ADD',
                                    isSmall: true,
                                    backgroundColor: AppColors.acidLime,
                                    textColor: AppColors.pureBlack,
                                    borderColor: AppColors.pureBlack,
                                    onPressed: () async {
                                      final added = await ref
                                          .read(userListsProvider.notifier)
                                          .addItemToList(widget.listId, item);
                                      if (context.mounted && added) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'ADDED "${item.name.toUpperCase()}" TO ARCHIVE',
                                              style: AppTypography.monoBadge(
                                                color: AppColors.pureBlack,
                                              ),
                                            ),
                                            backgroundColor: AppColors.acidLime,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
