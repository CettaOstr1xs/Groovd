import 'package:flutter_test/flutter_test.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/data/services/genre_tag_service.dart';

void main() {
  group('GenreTagService & MusicItem Release Date Formatting', () {
    test('initializes and cleans/deduplicates tags appropriately', () async {
      final service = GenreTagService();

      // Test with Radiohead OK Computer
      final tags = await service.getTags(artist: 'Radiohead', title: 'OK Computer', isAlbum: true);
      expect(tags, isNotEmpty);
      expect(tags.any((t) => t.contains('ROCK')), isTrue);
      // Ensure noise tags like 'favorite' or years are filtered out
      expect(tags.any((t) => t == '1997'), isFalse);
      expect(tags.any((t) => t.toLowerCase().contains('favorite')), isFalse);
    });

    test('artist tag fallback resolves properly', () async {
      final service = GenreTagService();
      final artistTags = await service.getArtistTags('Tame Impala');
      expect(artistTags, isNotEmpty);
    });

    test('extracts verified original release date from MusicBrainz for Deathconsciousness', () async {
      final service = GenreTagService();
      final date = await service.getOriginalReleaseDate(
        artist: 'Have a Nice Life',
        title: 'Deathconsciousness',
      );
      expect(date, equals('2008-01-24'));
    });

    test('getTagsSync returns 0ms instant curated genres for iconic releases', () {
      final service = GenreTagService();
      final tags = service.getTagsSync(
        artist: 'Have a Nice Life',
        title: 'Deathconsciousness',
      );
      expect(tags, isNotEmpty);
      expect(tags, contains('SHOEGAZE'));
      expect(tags, contains('POST-PUNK'));
      expect(tags, contains('DARK AMBIENT'));
      expect(tags, contains('DRONE'));

      final date = service.getCachedReleaseDate('Have a Nice Life', 'Deathconsciousness');
      expect(date, equals('2008-01-24'));
    });

    test('generates canonical Firestore document IDs cleanly', () {
      final docId = GenreTagService.generateDocId('Have a Nice Life', 'Deathconsciousness');
      expect(docId, equals('have_a_nice_life__deathconsciousness'));

      final artistDocId = GenreTagService.generateArtistDocId('The Cure');
      expect(artistDocId, equals('artist__the_cure'));
    });

    test('MusicItem formats release dates with day, month, and year accurately', () {
      final item1 = MusicItem(
        id: '1',
        name: 'Test Album',
        artist: 'Test Artist',
        type: MusicType.album,
        coverUrl: '',
        releaseDate: '2023-10-05',
        genres: const [],
      );
      expect(item1.formattedReleaseDate, equals('5 OCTOBER 2023'));
      expect(item1.formattedReleaseDateCompact, equals('5 OCT 2023'));
      expect(item1.formattedYear, equals('2023'));

      final item2 = MusicItem(
        id: '2',
        name: 'Deathconsciousness',
        artist: 'Have a Nice Life',
        type: MusicType.album,
        coverUrl: '',
        releaseDate: '2008-01-24',
        genres: const [],
      );
      expect(item2.formattedReleaseDate, equals('24 JANUARY 2008'));
      expect(item2.formattedReleaseDateCompact, equals('24 JAN 2008'));
      expect(item2.formattedYear, equals('2008'));

      // Empty release date should not return fake 2024
      final item3 = MusicItem(
        id: '3',
        name: 'Unknown',
        artist: 'Unknown',
        type: MusicType.song,
        coverUrl: '',
        releaseDate: '',
        genres: const [],
      );
      expect(item3.formattedReleaseDate, isEmpty);
      expect(item3.formattedYear, isEmpty);
    });
  });
}
