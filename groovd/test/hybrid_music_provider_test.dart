import 'package:flutter_test/flutter_test.dart';
import 'package:groovd/core/constants/spotify_config.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/data/services/deezer_api_service.dart';
import 'package:groovd/data/services/spotify_api_service.dart';
import 'package:groovd/data/services/spotify_repository.dart';

void main() {
  group('Hybrid Music Provider & Failover Tests', () {
    late SpotifyApiService spotifyApi;
    late DeezerApiService deezerApi;
    late SpotifyRepository hybridRepo;

    setUp(() {
      spotifyApi = SpotifyApiService(
        clientId: SpotifyConfig.clientId,
        clientSecret: SpotifyConfig.clientSecret,
      );
      deezerApi = DeezerApiService();
      hybridRepo = SpotifyRepository(
        apiService: spotifyApi,
        deezerService: deezerApi,
        enableLiveCatalog: true,
      );
    });

    test('Searching "moonworld playground" finds Tokyo Shoegazer Moonworld Playground album from Spotify', () async {
      final results = await hybridRepo.search('moonworld playground', type: MusicType.album);
      expect(results, isNotEmpty);

      // Verify that Moonworld Playground by Tokyo Shoegazer is found
      final moonworld = results.firstWhere(
        (item) => item.name.toLowerCase().contains('moonworld playground'),
      );
      expect(moonworld.name, contains('Moonworld Playground'));
      expect(moonworld.artist.toLowerCase(), contains('tokyo shoegazer'));
      expect(moonworld.id, equals('4LC9YNAQ271h2hj4U2MDzU'));
    });

    test('Artist discography for Tokyo Shoegazer includes Moonworld Playground from merged catalog', () async {
      final discography = await hybridRepo.getArtistDiscography('Tokyo Shoegazer');
      expect(discography, isNotEmpty);

      final hasMoonworld = discography.any((a) => a.name.toLowerCase().contains('moonworld playground'));
      expect(hasMoonworld, isTrue);

      final hasRemains = discography.any((a) => a.name.toLowerCase().contains('remains'));
      expect(hasRemains, isTrue);
    });

    test('getItemById loads full 9-track tracklist for Moonworld Playground Spotify album ID', () async {
      final item = await hybridRepo.getItemById('4LC9YNAQ271h2hj4U2MDzU');
      expect(item, isNotNull);
      expect(item!.name, contains('Moonworld Playground'));
      expect(item.tracks.length, equals(9));
      expect(item.tracks.first.name, equals('Felicette'));
      expect(item.tracks.last.name, equals('Destroy'));
    });

    test('Circuit breaker trips and routes failover to Spotify when Deezer is degraded', () async {
      // Manually trip Deezer circuit breaker to simulate Deezer outage
      hybridRepo.deezerBreaker.tripManually(const Duration(minutes: 5));
      expect(hybridRepo.isDeezerActive, isFalse);
      expect(hybridRepo.isSpotifyActive, isTrue);

      // Search should still succeed by seamlessly querying Spotify
      final results = await hybridRepo.search('moonworld playground');
      expect(results, isNotEmpty);
      expect(results.first.name, contains('Moonworld Playground'));
    });

    test('Circuit breaker trips and routes failover to Deezer when Spotify is degraded', () async {
      // Manually trip Spotify circuit breaker to simulate Spotify outage
      hybridRepo.spotifyBreaker.tripManually(const Duration(minutes: 5));
      expect(hybridRepo.isSpotifyActive, isFalse);
      expect(hybridRepo.isDeezerActive, isTrue);

      // Search should still succeed by seamlessly querying Deezer
      final results = await hybridRepo.search('slowdive');
      expect(results, isNotEmpty);
      expect(results.any((r) => r.artist.toLowerCase().contains('slowdive')), isTrue);
    });
  });
}
