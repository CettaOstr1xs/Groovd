import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/state/music_providers.dart';
import 'package:groovd/state/review_providers.dart';
import 'package:groovd/state/settings_provider.dart';
import 'package:groovd/presentation/widgets/brutalist_button.dart';
import 'package:groovd/presentation/widgets/review_card.dart';
import 'package:groovd/presentation/screens/detail/music_detail_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showSpotifySettings(BuildContext context, WidgetRef ref) {
    final settings = ref.read(spotifySettingsProvider);
    final idController = TextEditingController(text: settings.clientId);
    final secretController = TextEditingController(text: settings.clientSecret);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.borderBold, width: 2.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SPOTIFY API CONFIG', style: AppTypography.displaySmall()),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your Spotify Developer Client ID and Secret to stream live Spotify search and catalog data.',
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Text('SPOTIFY CLIENT ID', style: AppTypography.monoLabel(fontSize: 10)),
              const SizedBox(height: 6),
              TextField(
                controller: idController,
                style: AppTypography.bodyLarge(),
                decoration: const InputDecoration(hintText: 'Enter Client ID...'),
              ),
              const SizedBox(height: 14),
              Text('SPOTIFY CLIENT SECRET', style: AppTypography.monoLabel(fontSize: 10)),
              const SizedBox(height: 6),
              TextField(
                controller: secretController,
                obscureText: true,
                style: AppTypography.bodyLarge(),
                decoration: const InputDecoration(hintText: 'Enter Client Secret...'),
              ),
              const SizedBox(height: 20),
              BrutalistButton(
                label: 'SAVE & SYNC SPOTIFY',
                icon: Icons.save,
                isFullWidth: true,
                onPressed: () async {
                  await ref.read(spotifySettingsProvider.notifier).saveCredentials(
                        idController.text,
                        secretController.text,
                      );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'SPOTIFY CONFIGURATION SAVED',
                          style: AppTypography.monoBadge(color: AppColors.pureBlack),
                        ),
                        backgroundColor: AppColors.acidLime,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final userName = ref.watch(currentUserNameProvider);
    final userHandle = ref.watch(currentUserHandleProvider);
    final userReviewsAsync = ref.watch(userReviewsProvider(userId));
    final spotifySettings = ref.watch(spotifySettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('CRITIC DOSSIER', style: AppTypography.displaySmall()),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            tooltip: 'Spotify Settings',
            onPressed: () => _showSpotifySettings(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Persona Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border.symmetric(
                  horizontal: BorderSide(color: AppColors.border, width: 1.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.acidLime,
                          border: Border.all(color: AppColors.pureBlack, width: 2.0),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.pureBlack,
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'YOU',
                          style: AppTypography.monoBadge(
                            color: AppColors.pureBlack,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName.toUpperCase(),
                              style: AppTypography.displayMedium(fontSize: 20),
                            ),
                            Text(
                              userHandle,
                              style: AppTypography.monoLabel(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Data source status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: spotifySettings.isLiveMode ? AppColors.acidLime : AppColors.cyberCyan,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          spotifySettings.isLiveMode
                              ? 'DATA SOURCE: LIVE SPOTIFY API'
                              : 'DATA SOURCE: CURATED CATALOG (DEMO)',
                          style: AppTypography.monoBadge(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Statistics Grid
            userReviewsAsync.when(
              data: (reviews) {
                final totalLogged = reviews.length;
                final avgScore = totalLogged > 0
                    ? (reviews.fold<double>(0.0, (acc, r) => acc + r.rating) / totalLogged)
                    : 0.0;
                final perfectTens = reviews.where((r) => r.rating >= 9.5).length;

                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: 'LOGGED',
                          value: '$totalLogged',
                          accentColor: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatBox(
                          label: 'AVG SCORE',
                          value: avgScore > 0 ? avgScore.toStringAsFixed(1) : '—',
                          accentColor: AppColors.acidLime,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatBox(
                          label: 'PERFECT 10s',
                          value: '$perfectTens',
                          accentColor: AppColors.electricPink,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 80),
              error: (err, stack) => const SizedBox.shrink(),
            ),

            const Divider(),

            // Logged Reviews Feed
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MY LOGGED REVIEWS',
                    style: AppTypography.displaySmall(),
                  ),
                  userReviewsAsync.when(
                    data: (r) => Text(
                      '${r.length} ENTRIES',
                      style: AppTypography.monoLabel(fontSize: 10),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (err, stack) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            userReviewsAsync.when(
              data: (reviews) {
                if (reviews.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.music_note, size: 36, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'YOUR CRITIC LOG IS EMPTY',
                          style: AppTypography.monoBadge(color: AppColors.textPrimary, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Search any album or song and drop your first score and review!',
                          style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: reviews.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return ReviewCard(
                      review: review,
                      showItemHeader: true,
                      onLike: () {
                        ref.read(reviewControllerProvider).likeReview(review.id);
                      },
                      onTap: () async {
                        final item = await ref.read(spotifyRepositoryProvider).getItemById(review.musicItemId);
                        if (item != null && context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => MusicDetailScreen(item: item)),
                          );
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.acidLime),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Error loading reviews: $err'),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _StatBox({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.scoreLarge(color: accentColor),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.monoBadge(color: AppColors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
