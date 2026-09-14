import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:groovd/core/constants/spotify_config.dart';
import 'music_providers.dart';

class SpotifySettingsState {
  final String clientId;
  final String clientSecret;
  final bool isLiveMode;

  const SpotifySettingsState({
    this.clientId = '',
    this.clientSecret = '',
    this.isLiveMode = false,
  });

  SpotifySettingsState copyWith({
    String? clientId,
    String? clientSecret,
    bool? isLiveMode,
  }) {
    return SpotifySettingsState(
      clientId: clientId ?? this.clientId,
      clientSecret: clientSecret ?? this.clientSecret,
      isLiveMode: isLiveMode ?? this.isLiveMode,
    );
  }
}

class SpotifySettingsNotifier extends Notifier<SpotifySettingsState> {
  static const _clientIdKey = 'groovd_spotify_client_id';
  static const _clientSecretKey = 'groovd_spotify_client_secret';

  @override
  SpotifySettingsState build() {
    _loadCredentials();
    return const SpotifySettingsState();
  }

  Future<void> _loadCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString(_clientIdKey) ?? '';
      var secret = prefs.getString(_clientSecretKey) ?? '';

      // Fallback to SpotifyConfig if not set in SharedPreferences
      if (id.isEmpty && SpotifyConfig.clientId.isNotEmpty) {
        id = SpotifyConfig.clientId;
      }
      if (secret.isEmpty && SpotifyConfig.clientSecret.isNotEmpty) {
        secret = SpotifyConfig.clientSecret;
      }

      final isConfigured = id.trim().isNotEmpty && secret.trim().isNotEmpty;

      state = SpotifySettingsState(
        clientId: id,
        clientSecret: secret,
        isLiveMode: isConfigured,
      );

      if (isConfigured) {
        ref.read(spotifyApiServiceProvider).updateCredentials(id, secret);
      }
    } catch (_) {}
  }

  Future<void> saveCredentials(String id, String secret) async {
    final cleanId = id.trim();
    final cleanSecret = secret.trim();
    final isConfigured = cleanId.isNotEmpty && cleanSecret.isNotEmpty;

    state = state.copyWith(
      clientId: cleanId,
      clientSecret: cleanSecret,
      isLiveMode: isConfigured,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_clientIdKey, cleanId);
      await prefs.setString(_clientSecretKey, cleanSecret);
    } catch (_) {}

    ref.read(spotifyApiServiceProvider).updateCredentials(cleanId, cleanSecret);
    ref.invalidate(trendingAlbumsProvider);
    ref.invalidate(hotTracksProvider);
    ref.invalidate(searchResultsProvider);
  }
}

final spotifySettingsProvider =
    NotifierProvider<SpotifySettingsNotifier, SpotifySettingsState>(SpotifySettingsNotifier.new);
