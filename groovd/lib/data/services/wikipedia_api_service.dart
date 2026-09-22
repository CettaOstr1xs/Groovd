import 'dart:convert';
import 'package:http/http.dart' as http;

class WikipediaSummary {
  final String title;
  final String? description;
  final String extract;

  const WikipediaSummary({
    required this.title,
    this.description,
    required this.extract,
  });
}

class WikipediaApiService {
  final http.Client _client;
  final Map<String, WikipediaSummary?> _cache = {};

  WikipediaApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches a clean introductory summary and description for the given artist from Wikipedia's REST API.
  Future<WikipediaSummary?> getArtistSummary(String artistName) async {
    final clean = artistName.trim();
    if (clean.isEmpty) return null;

    final cacheKey = clean.toLowerCase();
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    // Try primary title first
    var summary = await _fetchSummary(clean);

    // If not found or is a disambiguation page, attempt musical disambiguation fallbacks
    if (summary == null || (summary.description?.toLowerCase().contains('disambiguation') ?? false)) {
      summary = await _fetchSummary('$clean (band)') ??
          await _fetchSummary('$clean (musician)') ??
          await _fetchSummary('$clean (singer)') ??
          await _fetchSummary('$clean (rapper)');
    }

    _cache[cacheKey] = summary;
    return summary;
  }

  Future<WikipediaSummary?> _fetchSummary(String title) async {
    try {
      final formattedTitle = Uri.encodeComponent(title.replaceAll(' ', '_'));
      final uri = Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/$formattedTitle');
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'GroovdMusicApp/1.0 (contact@groovd.app)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final type = data['type'] as String? ?? '';
        if (type == 'disambiguation') return null;

        final extract = data['extract'] as String? ?? '';
        if (extract.trim().isEmpty) return null;

        final desc = data['description'] as String?;
        final resTitle = data['title'] as String? ?? title;

        return WikipediaSummary(
          title: resTitle,
          description: desc,
          extract: extract,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
