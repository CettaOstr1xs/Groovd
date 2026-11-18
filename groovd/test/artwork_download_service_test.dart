import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:groovd/data/services/artwork_download_service.dart';

void main() {
  group('ArtworkDownloadService Tests', () {
    test('getHighResArtworkUrl upgrades Deezer URLs to 1000x1000 master resolution', () {
      const rawDeezerUrl = 'https://e-cdns-images.dzcdn.net/images/cover/1234567890/500x500-000000-80-0-0.jpg';
      final upgraded = ArtworkDownloadService.getHighResArtworkUrl(rawDeezerUrl);
      expect(upgraded, 'https://e-cdns-images.dzcdn.net/images/cover/1234567890/1000x1000-000000-80-0-0.jpg');

      const rawDeezerUrl250 = 'https://cdns-images.dzcdn.net/images/cover/abcdef/250x250.jpg';
      final upgraded250 = ArtworkDownloadService.getHighResArtworkUrl(rawDeezerUrl250);
      expect(upgraded250, 'https://cdns-images.dzcdn.net/images/cover/abcdef/1000x1000.jpg');
    });

    test('getHighResArtworkUrl preserves Spotify and other direct image URLs', () {
      const spotifyUrl = 'https://i.scdn.co/image/ab67616d0000b273c5649add07ed3720be9d5526';
      expect(ArtworkDownloadService.getHighResArtworkUrl(spotifyUrl), spotifyUrl);
      expect(ArtworkDownloadService.getHighResArtworkUrl(''), isEmpty);
    });

    test('sanitizeFileName strips illegal filesystem characters and spaces', () {
      final fileName = ArtworkDownloadService.sanitizeFileName(
        artist: 'AC/DC & The "Who"?',
        title: 'Who: Are You <Remastered>|2024*',
      );

      expect(fileName.contains('/'), isFalse);
      expect(fileName.contains('\\'), isFalse);
      expect(fileName.contains(':'), isFalse);
      expect(fileName.contains('*'), isFalse);
      expect(fileName.contains('?'), isFalse);
      expect(fileName.contains('"'), isFalse);
      expect(fileName.contains('<'), isFalse);
      expect(fileName.contains('>'), isFalse);
      expect(fileName.contains('|'), isFalse);
      expect(fileName.startsWith('Groovd_'), isTrue);
      expect(fileName.endsWith('.jpg'), isTrue);
    });

    test('sanitizeFileName truncates excessively long artist and title to prevent filesystem limit errors', () {
      final longArtist = 'A' * 120;
      final longTitle = 'B' * 120;
      final fileName = ArtworkDownloadService.sanitizeFileName(
        artist: longArtist,
        title: longTitle,
      );

      expect(fileName.length, lessThanOrEqualTo(150));
      expect(fileName.startsWith('Groovd_'), isTrue);
      expect(fileName.endsWith('.jpg'), isTrue);
    });

    test('downloadArtwork fetches bytes and saves via platform channel or local fallback', () async {
      final mockBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46]);
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('valid_cover.jpg')) {
          return http.Response.bytes(mockBytes, 200, headers: {'content-type': 'image/jpeg'});
        }
        return http.Response('Not Found', 404);
      });

      final service = ArtworkDownloadService(
        client: mockClient,
        customSaver: (bytes, fileName) async => '/mock/Pictures/Groovd/$fileName',
      );

      final successResult = await service.downloadArtwork(
        imageUrl: 'https://example.com/valid_cover.jpg',
        title: 'Dummy',
        artist: 'Portishead',
      );

      expect(successResult.isSuccess, isTrue);
      expect(successResult.fileName, contains('Portishead'));
      expect(successResult.fileName, contains('Dummy'));
      expect(successResult.errorMessage, isNull);

      final failureResult = await service.downloadArtwork(
        imageUrl: 'https://example.com/broken_cover.jpg',
        title: 'Broken',
        artist: 'Nobody',
      );

      expect(failureResult.isSuccess, isFalse);
      expect(failureResult.errorMessage, isNotNull);
    });

    test('downloadArtwork handles empty or invalid image URL gracefully', () async {
      final service = ArtworkDownloadService();
      final result = await service.downloadArtwork(
        imageUrl: '',
        title: 'Empty',
        artist: 'Unknown',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('EMPTY_URL'));
    });
  });
}
