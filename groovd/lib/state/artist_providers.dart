import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/artist.dart';
import '../data/models/music_item.dart';
import 'music_providers.dart';
import 'review_providers.dart';

/// Provider for an artist profile with Wikipedia biography.
final artistDetailProvider = FutureProvider.family<Artist?, String>((ref, artistIdOrName) async {
  final repo = ref.watch(spotifyRepositoryProvider);
  return repo.getArtist(artistIdOrName);
});

/// Provider for an artist's top tracks.
final artistTopTracksProvider = FutureProvider.family<List<MusicItem>, String>((ref, artistIdOrName) async {
  final repo = ref.watch(spotifyRepositoryProvider);
  return repo.getArtistTopTracks(artistIdOrName);
});

/// Provider for an artist's complete discography.
final artistDiscographyProvider = FutureProvider.family<List<MusicItem>, String>((ref, artistIdOrName) async {
  final repo = ref.watch(spotifyRepositoryProvider);
  return repo.getArtistDiscography(artistIdOrName);
});

/// Career statistics for an artist computed from Groovd's review database.
class ArtistCareerStats {
  final double averageScore;
  final int totalCommunityReviews;
  final int userRatedCount;
  final int totalReleasesCount;
  final String? communityFavoriteTitle;
  final double? communityFavoriteScore;

  const ArtistCareerStats({
    required this.averageScore,
    required this.totalCommunityReviews,
    required this.userRatedCount,
    required this.totalReleasesCount,
    this.communityFavoriteTitle,
    this.communityFavoriteScore,
  });
}

/// Provider computing career stats for an artist across all community reviews and user ratings.
final artistCareerStatsProvider = FutureProvider.family<ArtistCareerStats, String>((ref, artistName) async {
  ref.watch(reviewRefreshProvider);
  final repo = ref.watch(reviewRepositoryProvider);
  final currentUserId = ref.watch(currentUserIdProvider);

  final lowerArtist = artistName.trim().toLowerCase();

  // Load all recent community reviews to aggregate stats
  final allReviews = await repo.getRecentReviews(limit: 200);
  final artistReviews = allReviews.where((r) {
    final rArtist = r.artistName.trim().toLowerCase();
    return rArtist.contains(lowerArtist) || lowerArtist.contains(rArtist);
  }).toList();

  // Load current user reviews
  final userReviews = await repo.getUserReviews(currentUserId);
  final userArtistReviews = userReviews.where((r) {
    final rArtist = r.artistName.trim().toLowerCase();
    return rArtist.contains(lowerArtist) || lowerArtist.contains(rArtist);
  }).toList();

  // Discography count
  final discography = await ref.watch(artistDiscographyProvider(artistName).future);
  final totalReleases = discography.length;

  // Calculate user rated releases: only count full albums and standalone singles/EP releases.
  // Individual songs/tracks rated from an album are excluded from this release badge.
  final ratedReleaseIds = <String>{};
  for (final r in userArtistReviews) {
    final isSongReview = r.itemType.toLowerCase() == 'song';
    if (isSongReview) {
      // Only count if it corresponds to an official standalone single/EP release in the discography
      final matchingSingle = discography.where((d) =>
        d.isSong && (d.id == r.musicItemId || d.name.trim().toLowerCase() == r.musicItemName.trim().toLowerCase())
      ).firstOrNull;

      if (matchingSingle != null) {
        ratedReleaseIds.add(matchingSingle.id);
      }
    } else {
      // Album or EP critique/rating
      final matchingAlbum = discography.where((d) =>
        (d.isAlbum || d.isEp) && (d.id == r.musicItemId || d.name.trim().toLowerCase() == r.musicItemName.trim().toLowerCase())
      ).firstOrNull;

      if (matchingAlbum != null) {
        ratedReleaseIds.add(matchingAlbum.id);
      } else {
        ratedReleaseIds.add(r.musicItemId.isNotEmpty ? r.musicItemId : r.musicItemName.toLowerCase());
      }
    }
  }
  final userRatedCount = ratedReleaseIds.length;

  if (artistReviews.isEmpty) {
    return ArtistCareerStats(
      averageScore: 0.0,
      totalCommunityReviews: 0,
      userRatedCount: userRatedCount,
      totalReleasesCount: totalReleases,
    );
  }

  final sum = artistReviews.fold<double>(0.0, (acc, r) => acc + r.rating);
  final avg = sum / artistReviews.length;

  // Find community favorite release
  artistReviews.sort((a, b) => b.rating.compareTo(a.rating));
  final fav = artistReviews.first;

  return ArtistCareerStats(
    averageScore: avg,
    totalCommunityReviews: artistReviews.length,
    userRatedCount: userRatedCount,
    totalReleasesCount: totalReleases,
    communityFavoriteTitle: fav.musicItemName,
    communityFavoriteScore: fav.rating,
  );
});
