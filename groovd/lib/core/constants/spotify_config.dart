/// Spotify Web API configuration.
///
/// You can paste your credentials directly here, OR enter them
/// within the app under DOSSIER -> Settings (gear icon).
class SpotifyConfig {
  SpotifyConfig._();

  /// Paste your Spotify Client ID here:
  static const String clientId = '4cf83c2b597b4b16a332e231a21fb9d3';

  /// Paste your Spotify Client Secret here:
  static const String clientSecret = '1c572e4231e04103b58f61e101304164';

  static bool get isConfigured =>
      clientId.trim().isNotEmpty && clientSecret.trim().isNotEmpty;
}
