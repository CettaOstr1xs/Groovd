import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/artist.dart';
import '../../../data/models/music_item.dart';
import '../../../state/artist_providers.dart';
import '../detail/music_detail_screen.dart';

enum DiscographyFilter { all, albums, singles }

class ArtistDetailScreen extends ConsumerStatefulWidget {
  final String artistIdOrName;
  final String? initialArtistName;

  const ArtistDetailScreen({
    super.key,
    required this.artistIdOrName,
    this.initialArtistName,
  });

  @override
  ConsumerState<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends ConsumerState<ArtistDetailScreen> {
  DiscographyFilter _filter = DiscographyFilter.all;
  bool _isGridView = true;

  Future<void> _openSpotify(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 9.0) return AppColors.acidLime;
    if (score >= 8.0) return AppColors.cyberCyan;
    if (score >= 6.5) return AppColors.electricPink;
    if (score >= 5.0) return const Color(0xFFFFB800);
    return AppColors.vermillion;
  }

  @override
  Widget build(BuildContext context) {
    final artistAsync = ref.watch(artistDetailProvider(widget.artistIdOrName));
    final topTracksAsync = ref.watch(artistTopTracksProvider(widget.artistIdOrName));
    final discographyAsync = ref.watch(artistDiscographyProvider(widget.artistIdOrName));
    final artistName = artistAsync.asData?.value?.name ?? widget.initialArtistName ?? widget.artistIdOrName;
    final statsAsync = ref.watch(artistCareerStatsProvider(artistName));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('ARTIST DOSSIER', style: AppTypography.displaySmall()),
        actions: [
          artistAsync.maybeWhen(
            data: (artist) => artist != null && artist.spotifyUrl.isNotEmpty
                ? IconButton(
                    tooltip: 'Open in Spotify',
                    icon: const Icon(Icons.open_in_new, size: 20),
                    onPressed: () => _openSpotify(artist.spotifyUrl),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: artistAsync.when(
        data: (artist) {
          if (artist == null) {
            return _buildNotFoundState();
          }
          return _buildContent(artist, topTracksAsync, discographyAsync, statsAsync);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.acidLime),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.vermillion),
                const SizedBox(height: 12),
                Text('COULD NOT LOAD ARTIST DOSSIER', style: AppTypography.headline(color: AppColors.vermillion)),
                const SizedBox(height: 6),
                Text(err.toString(), style: AppTypography.bodyMedium(color: AppColors.textMuted), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('ARTIST NOT FOUND', style: AppTypography.headline(color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text(
              'No catalog or archive entry matches "${widget.artistIdOrName}".',
              style: AppTypography.bodyMedium(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    Artist artist,
    AsyncValue<List<MusicItem>> topTracksAsync,
    AsyncValue<List<MusicItem>> discographyAsync,
    AsyncValue<ArtistCareerStats> statsAsync,
  ) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. Hero Header Section
        _buildHeroSection(artist),

        const Divider(),

        // 2. Groovd Career Critique Bar
        _buildCareerStatsBar(statsAsync),

        // 3. Wikipedia Biographical Briefing Card
        if (artist.bio != null && artist.bio!.trim().isNotEmpty) ...[
          const Divider(),
          _buildBiographyCard(artist),
        ],

        const Divider(),

        // 4. Essential In Rotation (Top Tracks)
        _buildTopTracksSection(topTracksAsync),

        const Divider(),

        // 5. Complete Discography Archive
        _buildDiscographySection(discographyAsync),

        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildHeroSection(Artist artist) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artist Portrait with Neo-Brutalist Frame and Drop Shadow
              Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  border: Border.all(color: AppColors.pureBlack, width: 2),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.pureBlack,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(1),
                  child: artist.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: artist.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(color: AppColors.surfaceCard),
                          errorWidget: (_, _, _) => const Icon(Icons.person, size: 48, color: AppColors.textMuted),
                        )
                      : const Icon(Icons.person, size: 48, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(width: 18),
              // Name, Tagline, and Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verified Badge Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.acidLime,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: AppColors.pureBlack, width: 1.5),
                      ),
                      child: Text(
                        'ARTIST // ARCHIVE',
                        style: AppTypography.monoBadge(
                          color: AppColors.pureBlack,
                          fontSize: 8.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      artist.name.toUpperCase(),
                      style: AppTypography.displayMassive().copyWith(fontSize: 26, height: 1.1),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (artist.shortDescription != null && artist.shortDescription!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        artist.shortDescription!.toUpperCase(),
                        style: AppTypography.monoLabel(
                          color: AppColors.cyberCyan,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Follower & Popularity Metrics
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (artist.followers > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    border: Border.all(color: AppColors.border, width: 1.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_alt_outlined, size: 13, color: AppColors.textPrimary),
                      const SizedBox(width: 5),
                      Text(
                        artist.formattedFollowers,
                        style: AppTypography.monoBadge(color: AppColors.textPrimary, fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
              if (artist.popularity > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    border: Border.all(color: AppColors.border, width: 1.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, size: 14, color: Color(0xFFFFB800)),
                      const SizedBox(width: 4),
                      Text(
                        'ROTATION INDEX ${artist.popularity}%',
                        style: AppTypography.monoBadge(color: AppColors.textPrimary, fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          if (artist.genres.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: artist.genres.map((g) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '#${g.toUpperCase()}',
                    style: AppTypography.monoBadge(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCareerStatsBar(AsyncValue<ArtistCareerStats> statsAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, size: 16, color: AppColors.acidLime),
              const SizedBox(width: 6),
              Text(
                'GROOVD CRITIC CAREER STATS',
                style: AppTypography.monoLabel(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          statsAsync.when(
            data: (stats) {
              final scoreColor = stats.averageScore > 0 ? _getScoreColor(stats.averageScore) : AppColors.textMuted;
              return Column(
                children: [
                  Row(
                    children: [
                      // Career Score Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            border: Border.all(color: AppColors.border, width: 1.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CAREER SCORE', style: AppTypography.monoLabel(fontSize: 8.5, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    stats.averageScore > 0 ? stats.averageScore.toStringAsFixed(1) : '—.—',
                                    style: AppTypography.scoreMedium(color: scoreColor),
                                  ),
                                  const SizedBox(width: 3),
                                  Text('/10', style: AppTypography.monoLabel(fontSize: 9, color: AppColors.textMuted)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Total Community Critiques
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            border: Border.all(color: AppColors.border, width: 1.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('COMMUNITY LOGS', style: AppTypography.monoLabel(fontSize: 8.5, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text(
                                '${stats.totalCommunityReviews}',
                                style: AppTypography.headline(color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Your Rated Releases
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            border: Border.all(color: AppColors.border, width: 1.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('YOU RATED', style: AppTypography.monoLabel(fontSize: 8.5, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text(
                                '${stats.userRatedCount} / ${stats.totalReleasesCount}',
                                style: AppTypography.headline(color: AppColors.cyberCyan),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (stats.communityFavoriteTitle != null && stats.communityFavoriteScore != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: AppColors.acidLime),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'HIGHEST RATED // ${stats.communityFavoriteTitle!.toUpperCase()}',
                              style: AppTypography.monoBadge(color: AppColors.textPrimary, fontSize: 9.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getScoreColor(stats.communityFavoriteScore!),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              stats.communityFavoriteScore!.toStringAsFixed(1),
                              style: AppTypography.monoBadge(color: AppColors.pureBlack, fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
            loading: () => Container(
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildBiographyCard(Artist artist) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.feed_outlined, size: 14, color: AppColors.acidLime),
                      const SizedBox(width: 6),
                      Text(
                        'ARCHIVE BRIEFING // BIOGRAPHY',
                        style: AppTypography.monoBadge(color: AppColors.acidLime, fontSize: 9.5),
                      ),
                    ],
                  ),
                  Text(
                    'SOURCE // WIKIPEDIA',
                    style: AppTypography.monoLabel(fontSize: 8.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                artist.bio!,
                style: AppTypography.bodyMedium(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTracksSection(AsyncValue<List<MusicItem>> topTracksAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department, size: 16, color: AppColors.vermillion),
                  const SizedBox(width: 6),
                  Text(
                    'ESSENTIAL IN ROTATION',
                    style: AppTypography.monoLabel(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                'TOP TRACKS',
                style: AppTypography.monoLabel(fontSize: 9, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          topTracksAsync.when(
            data: (tracks) {
              if (tracks.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: Text('NO TOP TRACKS CATALOGUED', style: AppTypography.monoLabel(color: AppColors.textMuted)),
                  ),
                );
              }
              final displayTracks = tracks.take(5).toList();
              return Column(
                children: List.generate(displayTracks.length, (index) {
                  final track = displayTracks[index];
                  final rank = (index + 1).toString().padLeft(2, '0');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MusicDetailScreen(item: track),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          children: [
                            Text(
                              rank,
                              style: AppTypography.monoBadge(
                                color: index == 0 ? AppColors.acidLime : AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Album Art
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                border: Border.all(color: AppColors.pureBlack),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(1),
                                child: track.coverUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: track.coverUrl,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, _, _) => const Icon(Icons.music_note, size: 16, color: AppColors.textMuted),
                                      )
                                    : const Icon(Icons.music_note, size: 16, color: AppColors.textMuted),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.name.toUpperCase(),
                                    style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (track.formattedDuration.isNotEmpty)
                                    Text(
                                      track.formattedDuration,
                                      style: AppTypography.monoLabel(fontSize: 9.5, color: AppColors.textMuted),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
            loading: () => Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscographySection(AsyncValue<List<MusicItem>> discographyAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DISCOGRAPHY',
                style: AppTypography.monoLabel(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              // Grid vs List Toggle
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.grid_view,
                      size: 18,
                      color: _isGridView ? AppColors.acidLime : AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _isGridView = true),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.view_agenda_outlined,
                      size: 18,
                      color: !_isGridView ? AppColors.acidLime : AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _isGridView = false),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Segmented Filter Pills
          discographyAsync.maybeWhen(
            data: (items) {
              final albumsCount = items.where((i) => i.isAlbum).length;
              final singlesCount = items.where((i) => i.isSong).length;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterPill('ALL (${items.length})', DiscographyFilter.all),
                    const SizedBox(width: 8),
                    _buildFilterPill('STUDIO LPS ($albumsCount)', DiscographyFilter.albums),
                    const SizedBox(width: 8),
                    _buildFilterPill('SINGLES & EPS ($singlesCount)', DiscographyFilter.singles),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          discographyAsync.when(
            data: (items) {
              final filtered = items.where((i) {
                if (_filter == DiscographyFilter.albums) return i.isAlbum;
                if (_filter == DiscographyFilter.singles) return i.isSong;
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: Text('NO RELEASES IN THIS CATEGORY', style: AppTypography.monoLabel(color: AppColors.textMuted)),
                  ),
                );
              }

              return _isGridView ? _buildDiscographyGrid(filtered) : _buildDiscographyList(filtered);
            },
            loading: () => Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            error: (err, _) => Center(
              child: Text('Failed to load discography: $err', style: AppTypography.monoLabel(color: AppColors.vermillion)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label, DiscographyFilter filter) {
    final isSelected = _filter == filter;
    return InkWell(
      onTap: () => setState(() => _filter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.acidLime : AppColors.surfaceElevated,
          border: Border.all(
            color: isSelected ? AppColors.acidLime : AppColors.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: AppTypography.monoBadge(
            color: isSelected ? AppColors.pureBlack : AppColors.textSecondary,
            fontSize: 9.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDiscographyGrid(List<MusicItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MusicDetailScreen(item: item)),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // True 1:1 Square Cover Art
              AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    border: Border.all(color: AppColors.border, width: 1.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(1),
                    child: item.coverUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.coverUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => const Center(child: Icon(Icons.album, color: AppColors.textMuted)),
                          )
                        : const Center(child: Icon(Icons.album, color: AppColors.textMuted)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.name.toUpperCase(),
                style: AppTypography.monoBadge(color: AppColors.textPrimary, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.formattedYear,
                    style: AppTypography.monoLabel(fontSize: 9, color: AppColors.textMuted),
                  ),
                  Text(
                    item.isAlbum ? 'LP' : 'SINGLE',
                    style: AppTypography.monoBadge(
                      color: item.isAlbum ? AppColors.acidLime : AppColors.cyberCyan,
                      fontSize: 7.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscographyList(List<MusicItem> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MusicDetailScreen(item: item)),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    border: Border.all(color: AppColors.pureBlack),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(1),
                    child: item.coverUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.coverUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => const Icon(Icons.album, color: AppColors.textMuted),
                          )
                        : const Icon(Icons.album, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: item.isAlbum ? AppColors.acidLime : AppColors.cyberCyan,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              item.isAlbum ? 'LP' : 'SINGLE',
                              style: AppTypography.monoBadge(color: AppColors.pureBlack, fontSize: 8),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.formattedYear,
                            style: AppTypography.monoLabel(fontSize: 9.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.name.toUpperCase(),
                        style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }
}
