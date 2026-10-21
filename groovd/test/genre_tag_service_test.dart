import 'package:flutter_test/flutter_test.dart';
import 'package:groovd/data/services/genre_tag_service.dart';

void main() {
  group('GenreTagService', () {
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
  });
}
