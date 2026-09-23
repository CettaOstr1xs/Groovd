import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/data/models/review.dart';
import 'package:groovd/data/services/spotify_mock_data.dart';
import 'package:groovd/presentation/screens/auth/login_screen.dart';
import 'package:groovd/presentation/screens/auth/register_screen.dart';
import 'package:groovd/presentation/screens/detail/music_detail_screen.dart';
import 'package:groovd/presentation/screens/lists/user_lists_screen.dart';
import 'package:groovd/presentation/screens/profile/adjust_avatar_screen.dart';
import 'package:groovd/presentation/screens/profile/all_rated_releases_screen.dart';
import 'package:groovd/presentation/screens/profile/logged_reviews_screen.dart';
import 'package:groovd/presentation/screens/review/review_detail_screen.dart';
import 'package:groovd/presentation/screens/wishlist/wishlist_screen.dart';
import 'package:groovd/presentation/widgets/album_art_card.dart';
import 'package:groovd/presentation/widgets/brutalist_button.dart';
import 'package:groovd/presentation/widgets/review_card.dart';
import 'package:groovd/state/auth_providers.dart';
import 'package:groovd/state/dossier_top_picks_provider.dart';
import 'package:groovd/state/music_providers.dart';
import 'package:groovd/state/review_providers.dart';
import 'package:groovd/state/user_lists_provider.dart';
import 'package:groovd/state/user_profile_provider.dart';
import 'package:groovd/state/wishlist_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showAvatarOptions(BuildContext context, WidgetRef ref) {
    final profile = ref.read(userProfileProvider);
    final hasCustomAvatar = profile.avatarPath != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.acidLime, width: 2.0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('CRITIC AVATAR // PHOTO', style: AppTypography.displaySmall()),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Select a photo from your gallery and adjust the crop & position to fit your dossier.',
              style: AppTypography.bodySmall(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            BrutalistButton(
              label: 'CHOOSE FROM GALLERY',
              icon: Icons.photo_library_outlined,
              isFullWidth: true,
              backgroundColor: AppColors.acidLime,
              textColor: AppColors.pureBlack,
              borderColor: AppColors.pureBlack,
              onPressed: () async {
                Navigator.of(ctx).pop();
                final rawFile = await ref
                    .read(userProfileProvider.notifier)
                    .pickRawImageFromGallery();
                if (rawFile != null && context.mounted) {
                  final croppedPath = await Navigator.of(context).push<String?>(
                    AdjustAvatarScreen.route(imageFile: rawFile),
                  );
                  if (croppedPath != null && context.mounted) {
                    await ref
                        .read(userProfileProvider.notifier)
                        .setCustomAvatar(croppedPath);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'CRITIC AVATAR UPDATED',
                            style: AppTypography.monoBadge(color: AppColors.pureBlack),
                          ),
                          backgroundColor: AppColors.acidLime,
                        ),
                      );
                    }
                  }
                }
              },
            ),
            if (hasCustomAvatar) ...[
              const SizedBox(height: 12),
              BrutalistButton(
                label: 'RE-ADJUST CURRENT PHOTO',
                icon: Icons.crop_outlined,
                isFullWidth: true,
                backgroundColor: AppColors.surfaceElevated,
                textColor: AppColors.cyberCyan,
                borderColor: AppColors.cyberCyan,
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final currentFile = File(profile.avatarPath!);
                  if (await currentFile.exists() && context.mounted) {
                    final croppedPath = await Navigator.of(context).push<String?>(
                      AdjustAvatarScreen.route(imageFile: currentFile),
                    );
                    if (croppedPath != null && context.mounted) {
                      await ref
                          .read(userProfileProvider.notifier)
                          .setCustomAvatar(croppedPath);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'CRITIC AVATAR REPOSITIONED',
                              style: AppTypography.monoBadge(color: AppColors.pureBlack),
                            ),
                            backgroundColor: AppColors.cyberCyan,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              BrutalistButton(
                label: 'REMOVE PHOTO // USE MONOGRAM',
                icon: Icons.delete_outline,
                isFullWidth: true,
                backgroundColor: AppColors.surfaceElevated,
                textColor: AppColors.vermillion,
                borderColor: AppColors.vermillion,
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await ref.read(userProfileProvider.notifier).removeAvatar();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'AVATAR RESET TO MONOGRAM',
                          style: AppTypography.monoBadge(color: AppColors.pureBlack),
                        ),
                        backgroundColor: AppColors.vermillion,
                      ),
                    );
                  }
                },
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showSettingsModal(BuildContext context, WidgetRef ref) {
    bool isDarkMode = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final profile = ref.watch(userProfileProvider);
            final isAuthenticated = ref.watch(isAuthenticatedProvider);

            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.borderBold, width: 2.0)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('SETTINGS', style: AppTypography.displaySmall()),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'APP PREFERENCES & PROFILE CUSTOMIZATION',
                      style: AppTypography.monoLabel(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Critic Identity Feature (Username & Handle)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        border: Border.all(color: AppColors.border, width: 1.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.badge_outlined,
                                    size: 18,
                                    color: AppColors.acidLime,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CRITIC IDENTITY',
                                    style: AppTypography.monoLabel(
                                      color: AppColors.textPrimary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  'GROOVD ID',
                                  style: AppTypography.monoBadge(
                                    color: AppColors.acidLime,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.acidLime,
                                  border: Border.all(color: AppColors.pureBlack, width: 1.5),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: profile.avatarPath != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(1),
                                        child: (profile.avatarPath!.startsWith('http://') || profile.avatarPath!.startsWith('https://'))
                                            ? Image.network(
                                                profile.avatarPath!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) => Center(
                                                  child: Text(
                                                    profile.userName.isNotEmpty ? profile.userName[0].toUpperCase() : 'C',
                                                    style: AppTypography.monoBadge(color: AppColors.pureBlack, fontSize: 13),
                                                  ),
                                                ),
                                              )
                                            : Image.file(
                                                File(profile.avatarPath!),
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) => Center(
                                                  child: Text(
                                                    profile.userName.isNotEmpty ? profile.userName[0].toUpperCase() : 'C',
                                                    style: AppTypography.monoBadge(color: AppColors.pureBlack, fontSize: 13),
                                                  ),
                                                ),
                                              ),
                                      )
                                    : Center(
                                        child: Text(
                                          profile.userName.isNotEmpty ? profile.userName[0].toUpperCase() : 'C',
                                          style: AppTypography.monoBadge(color: AppColors.pureBlack, fontSize: 13),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.userName.toUpperCase(),
                                      style: AppTypography.displaySmall(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      profile.userHandle,
                                      style: AppTypography.monoLabel(
                                        color: AppColors.textSecondary,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                    if (isAuthenticated) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: AppColors.acidLime,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            'CLOUD SYNC ACTIVE',
                                            style: AppTypography.monoBadge(
                                              color: AppColors.acidLime,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          BrutalistButton(
                            label: 'CHANGE USERNAME & HANDLE',
                            icon: Icons.edit_outlined,
                            backgroundColor: AppColors.surfaceElevated,
                            textColor: AppColors.textPrimary,
                            borderColor: AppColors.borderBold,
                            isSmall: true,
                            isFullWidth: true,
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showEditUsernameDialog(context, ref);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Header Banner Photo Feature
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        border: Border.all(color: AppColors.border, width: 1.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.panorama_outlined,
                                    size: 18,
                                    color: AppColors.acidLime,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'HEADER BANNER PHOTO',
                                    style: AppTypography.monoLabel(
                                      color: AppColors.textPrimary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  profile.backdropPath != null ? 'ACTIVE' : 'NONE',
                                  style: AppTypography.monoBadge(
                                    color: profile.backdropPath != null
                                        ? AppColors.acidLime
                                        : AppColors.textSecondary,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Display a cinematic widescreen background photo above your Critic Dossier banner.',
                            style: AppTypography.bodySmall(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (profile.backdropPath != null) ...[
                            Container(
                              height: 85,
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.borderBold, width: 1.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(1),
                                child: Image.file(
                                  File(profile.backdropPath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: BrutalistButton(
                                    label: 'CHANGE PHOTO',
                                    icon: Icons.photo_library_outlined,
                                    backgroundColor: AppColors.surfaceElevated,
                                    textColor: AppColors.textPrimary,
                                    borderColor: AppColors.borderBold,
                                    isSmall: true,
                                    onPressed: () async {
                                      final ok = await ref
                                          .read(userProfileProvider.notifier)
                                          .pickBackdropFromGallery();
                                      if (context.mounted && ok) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'HEADER BANNER UPDATED',
                                              style: AppTypography.monoBadge(color: AppColors.pureBlack),
                                            ),
                                            backgroundColor: AppColors.acidLime,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: BrutalistButton(
                                    label: 'REMOVE PHOTO',
                                    icon: Icons.delete_outline,
                                    backgroundColor: AppColors.surfaceElevated,
                                    textColor: AppColors.vermillion,
                                    borderColor: AppColors.vermillion,
                                    isSmall: true,
                                    onPressed: () async {
                                      await ref.read(userProfileProvider.notifier).removeBackdrop();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'HEADER BANNER REMOVED',
                                              style: AppTypography.monoBadge(color: AppColors.pureBlack),
                                            ),
                                            backgroundColor: AppColors.acidLime,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            BrutalistButton(
                              label: 'ADD BACKGROUND PHOTO',
                              icon: Icons.add_photo_alternate_outlined,
                              backgroundColor: AppColors.acidLime,
                              textColor: AppColors.pureBlack,
                              isFullWidth: true,
                              onPressed: () async {
                                final ok = await ref
                                    .read(userProfileProvider.notifier)
                                    .pickBackdropFromGallery();
                                if (context.mounted && ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'HEADER BANNER PHOTO APPLIED',
                                        style: AppTypography.monoBadge(color: AppColors.pureBlack),
                                      ),
                                      backgroundColor: AppColors.acidLime,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Critic Bio Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        border: Border.all(color: AppColors.border, width: 1.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.edit_note_outlined,
                                    size: 18,
                                    color: AppColors.cyberCyan,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CRITIC BIO // SELF-EXPRESSION',
                                    style: AppTypography.monoLabel(
                                      color: AppColors.textPrimary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profile.bio.isNotEmpty ? profile.bio : 'No bio set yet.',
                            style: AppTypography.bodySmall(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 14),
                          BrutalistButton(
                            label: 'EDIT BIO',
                            icon: Icons.edit,
                            backgroundColor: AppColors.surfaceElevated,
                            textColor: AppColors.textPrimary,
                            borderColor: AppColors.borderBold,
                            isSmall: true,
                            isFullWidth: true,
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showEditBioDialog(context, ref);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Appearance Theme Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        border: Border.all(color: AppColors.border, width: 1.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isDarkMode ? Icons.dark_mode : Icons.light_mode,
                                    size: 18,
                                    color: isDarkMode ? AppColors.acidLime : AppColors.cyberCyan,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'THEME MODE',
                                    style: AppTypography.monoLabel(
                                      color: AppColors.textPrimary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  isDarkMode ? 'DARK (ACTIVE)' : 'LIGHT MODE',
                                  style: AppTypography.monoBadge(
                                    color: isDarkMode ? AppColors.acidLime : AppColors.cyberCyan,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: BrutalistButton(
                                  label: 'DARK MODE',
                                  icon: Icons.dark_mode,
                                  backgroundColor: isDarkMode ? AppColors.acidLime : AppColors.surfaceElevated,
                                  textColor: isDarkMode ? AppColors.pureBlack : AppColors.textSecondary,
                                  borderColor: isDarkMode ? AppColors.pureBlack : AppColors.borderBold,
                                  isSmall: true,
                                  onPressed: () {
                                    setModalState(() => isDarkMode = true);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: BrutalistButton(
                                  label: 'LIGHT MODE',
                                  icon: Icons.light_mode,
                                  backgroundColor: !isDarkMode ? AppColors.cyberCyan : AppColors.surfaceElevated,
                                  textColor: !isDarkMode ? AppColors.pureBlack : AppColors.textSecondary,
                                  borderColor: !isDarkMode ? AppColors.pureBlack : AppColors.borderBold,
                                  isSmall: true,
                                  onPressed: () {
                                    setModalState(() => isDarkMode = false);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cloud Dossier / Authentication Section
                    Consumer(
                      builder: (ctx, cRef, _) {
                        final isAuth = cRef.watch(isAuthenticatedProvider);
                        final email = cRef.watch(currentUserEmailProvider);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            border: Border.all(
                              color: isAuth ? AppColors.acidLime : AppColors.border,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isAuth ? Icons.cloud_done : Icons.cloud_queue,
                                        size: 18,
                                        color: isAuth ? AppColors.acidLime : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'CLOUD DOSSIER // SYNC',
                                        style: AppTypography.monoLabel(
                                          color: AppColors.textPrimary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isAuth
                                          ? AppColors.acidLime.withValues(alpha: 0.15)
                                          : AppColors.surfaceElevated,
                                      border: Border.all(
                                        color: isAuth ? AppColors.acidLime : AppColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      isAuth ? 'ACTIVE' : 'OFFLINE',
                                      style: AppTypography.monoBadge(
                                        color: isAuth ? AppColors.acidLime : AppColors.textSecondary,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (isAuth) ...[
                                Text(
                                  'AUTHENTICATED CRITIC EMAIL:',
                                  style: AppTypography.monoLabel(
                                    color: AppColors.textMuted,
                                    fontSize: 9.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email ?? 'CRITIC DOSSIER SYNCED',
                                  style: AppTypography.bodySmall(
                                    color: AppColors.pureWhite,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your reviews, ratings, lists, and wantlist are actively synchronized with Cloud Firestore.',
                                  style: AppTypography.bodySmall(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                BrutalistButton(
                                  label: 'LOG OUT // DISCONNECT SESSION',
                                  icon: Icons.logout,
                                  backgroundColor: AppColors.surfaceElevated,
                                  textColor: AppColors.vermillion,
                                  borderColor: AppColors.vermillion,
                                  isSmall: true,
                                  isFullWidth: true,
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final authService = ref.read(authServiceProvider);
                                    final profileNotifier = ref.read(userProfileProvider.notifier);
                                    final wishlistNotifier = ref.read(wishlistProvider.notifier);
                                    final topPicksNotifier = ref.read(dossierTopPicksProvider.notifier);
                                    final userListsNotifier = ref.read(userListsProvider.notifier);
                                    final reviewRefreshNotifier = ref.read(reviewRefreshProvider.notifier);

                                    Navigator.of(context).pop();

                                    try {
                                      await authService.signOut();
                                    } catch (_) {}

                                    try {
                                      await profileNotifier.resetToGuest();
                                    } catch (_) {}

                                    try {
                                      await wishlistNotifier.resetToGuest();
                                    } catch (_) {}

                                    try {
                                      await topPicksNotifier.resetToGuest();
                                    } catch (_) {}

                                    try {
                                      await userListsNotifier.resetToGuest();
                                    } catch (_) {}

                                    ref.invalidate(userReviewsProvider);
                                    reviewRefreshNotifier.notifyChanged();

                                    messenger.showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppColors.pureBlack,
                                        content: Text(
                                          'SESSION TERMINATED // REVERTED TO LOCAL GUEST MODE',
                                          style: AppTypography.monoBadge(color: AppColors.acidLime),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ] else ...[
                                Text(
                                  'You are currently exploring in guest/offline mode. Register or log in to sync your reviews, ratings, wantlist, and curated lists across devices.',
                                  style: AppTypography.bodySmall(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: BrutalistButton(
                                        label: 'LOG IN',
                                        icon: Icons.login,
                                        backgroundColor: AppColors.acidLime,
                                        textColor: AppColors.pureBlack,
                                        borderColor: AppColors.pureBlack,
                                        isSmall: true,
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.of(context).push(LoginScreen.route());
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: BrutalistButton(
                                        label: 'REGISTER',
                                        icon: Icons.person_add_alt_1,
                                        backgroundColor: AppColors.surfaceElevated,
                                        textColor: AppColors.pureWhite,
                                        borderColor: AppColors.pureWhite,
                                        isSmall: true,
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.of(context).push(RegisterScreen.route());
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditUsernameDialog(BuildContext context, WidgetRef ref) {
    final profile = ref.read(userProfileProvider);
    final nameController = TextEditingController(text: profile.userName);
    final rawHandle = profile.userHandle.startsWith('@')
        ? profile.userHandle.substring(1)
        : profile.userHandle;
    final handleController = TextEditingController(text: rawHandle);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.acidLime, width: 2.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CRITIC IDENTITY', style: AppTypography.displaySmall()),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Customize your Groovd critic persona. Changes apply universally to all your reviews, dossier, and shared critiques.',
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Text(
                'DISPLAY NAME / USERNAME',
                style: AppTypography.monoBadge(color: AppColors.acidLime, fontSize: 10),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                maxLength: 30,
                textCapitalization: TextCapitalization.words,
                style: AppTypography.bodyLarge(),
                decoration: const InputDecoration(
                  hintText: 'e.g. CRITIC // YOU',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'GROOVD HANDLE',
                style: AppTypography.monoBadge(color: AppColors.cyberCyan, fontSize: 10),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: handleController,
                maxLength: 24,
                style: AppTypography.bodyLarge(),
                decoration: const InputDecoration(
                  prefixText: '@',
                  hintText: 'groovd_me',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 20),
              BrutalistButton(
                label: 'SAVE IDENTITY',
                icon: Icons.check,
                isFullWidth: true,
                onPressed: () async {
                  final newName = nameController.text.trim();
                  final rawH = handleController.text.trim().replaceAll('@', '').replaceAll(' ', '_');
                  if (newName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'USERNAME CANNOT BE EMPTY',
                          style: AppTypography.monoBadge(color: AppColors.pureBlack),
                        ),
                        backgroundColor: AppColors.vermillion,
                      ),
                    );
                    return;
                  }
                  final newHandle = '@${rawH.isEmpty ? "critic" : rawH}';

                  await ref.read(userProfileProvider.notifier).updateCriticIdentity(
                        name: newName,
                        handle: newHandle,
                      );

                  final userId = ref.read(userProfileProvider).userId;
                  await ref.read(reviewControllerProvider).updateUserIdentity(userId, newName, newHandle);

                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'CRITIC IDENTITY UPDATED',
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

  void _showEditBioDialog(BuildContext context, WidgetRef ref) {
    final currentBio = ref.read(userProfileProvider).bio;
    final controller = TextEditingController(text: currentBio);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.acidLime, width: 2.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CRITIC BIO', style: AppTypography.displaySmall()),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Express yourself! Set your musical taste, manifesto, or favorite sounds:',
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                maxLength: 180,
                autofocus: true,
                style: AppTypography.bodyLarge(),
                decoration: const InputDecoration(
                  hintText: 'Enter your bio or musical statement...',
                ),
              ),
              const SizedBox(height: 16),
              BrutalistButton(
                label: 'SAVE BIO',
                icon: Icons.check,
                isFullWidth: true,
                onPressed: () async {
                  final text = controller.text.trim();
                  await ref.read(userProfileProvider.notifier).updateBio(text);
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'BIO SAVED',
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

  void _showBackdropOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.acidLime, width: 2.0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HEADER BANNER', style: AppTypography.displaySmall()),
            const SizedBox(height: 6),
            Text(
              'Manage your cinematic header background photo.',
              style: AppTypography.bodySmall(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            BrutalistButton(
              label: 'CHANGE BACKGROUND PHOTO',
              icon: Icons.photo_library_outlined,
              isFullWidth: true,
              onPressed: () async {
                Navigator.of(ctx).pop();
                final ok = await ref.read(userProfileProvider.notifier).pickBackdropFromGallery();
                if (context.mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'HEADER BANNER UPDATED',
                        style: AppTypography.monoBadge(color: AppColors.pureBlack),
                      ),
                      backgroundColor: AppColors.acidLime,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            BrutalistButton(
              label: 'REMOVE BACKGROUND PHOTO',
              icon: Icons.delete_outline,
              backgroundColor: AppColors.surfaceElevated,
              textColor: AppColors.vermillion,
              borderColor: AppColors.vermillion,
              isFullWidth: true,
              onPressed: () async {
                Navigator.of(ctx).pop();
                await ref.read(userProfileProvider.notifier).removeBackdrop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'HEADER BANNER REMOVED',
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
      ),
    );
  }

  void _showTopPickSelector(
    BuildContext context,
    WidgetRef ref, {
    required bool isAlbum,
    required int slotIndex,
  }) {
    final searchController = TextEditingController();
    List<MusicItem> searchResults = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final userId = ref.read(currentUserIdProvider);
            final userReviews = ref.read(userReviewsProvider(userId)).value ?? [];

            // Reviewed items
            final reviewedCandidates = userReviews
                .where((r) => isAlbum ? r.itemType == 'album' : r.itemType == 'song')
                .map((r) => MusicItem(
                      id: r.musicItemId,
                      name: r.musicItemName,
                      artist: r.artistName,
                      type: isAlbum ? MusicType.album : MusicType.song,
                      coverUrl: r.coverUrl,
                      releaseDate: '',
                    ))
                .toList();

            // Curated catalogue candidates
            final curatedCandidates = isAlbum
                ? SpotifyMockData.trendingAlbums
                : SpotifyMockData.hotTracks;

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PIN RANK 0${slotIndex + 1} // ${isAlbum ? "ALBUM" : "SONG"}',
                            style: AppTypography.displaySmall(fontSize: 16),
                          ),
                          Text(
                            'CHOOSE FROM LOGGED REVIEWS OR CATALOG',
                            style: AppTypography.monoLabel(fontSize: 9, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search input
                  TextField(
                    controller: searchController,
                    style: AppTypography.headline(fontSize: 14),
                    cursorColor: AppColors.acidLime,
                    decoration: InputDecoration(
                      hintText: 'Search ${isAlbum ? "album" : "song"} to pin...',
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                searchController.clear();
                                setModalState(() {
                                  searchResults = [];
                                });
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (val) async {
                      if (val.trim().isEmpty) return;
                      setModalState(() => isSearching = true);
                      final res = await ref.read(spotifyRepositoryProvider).search(
                            val,
                            type: isAlbum ? MusicType.album : MusicType.song,
                          );
                      setModalState(() {
                        isSearching = false;
                        searchResults = res;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Selection list
                  Expanded(
                    child: isSearching
                        ? const Center(child: CircularProgressIndicator(color: AppColors.acidLime))
                        : searchResults.isNotEmpty
                            ? ListView.separated(
                                itemCount: searchResults.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final item = searchResults[idx];
                                  return _CandidateTile(
                                    item: item,
                                    onSelect: () async {
                                      await ref.read(dossierTopPicksProvider.notifier).pinItem(
                                            isAlbum: isAlbum,
                                            slotIndex: slotIndex,
                                            item: item,
                                          );
                                      if (context.mounted) Navigator.of(context).pop();
                                    },
                                  );
                                },
                              )
                            : ListView(
                                children: [
                                  if (reviewedCandidates.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        'FROM YOUR RECENT CRITIQUES',
                                        style: AppTypography.monoBadge(color: AppColors.acidLime, fontSize: 10),
                                      ),
                                    ),
                                    ...reviewedCandidates.map((item) => _CandidateTile(
                                          item: item,
                                          onSelect: () async {
                                            await ref.read(dossierTopPicksProvider.notifier).pinItem(
                                                  isAlbum: isAlbum,
                                                  slotIndex: slotIndex,
                                                  item: item,
                                                );
                                            if (context.mounted) Navigator.of(context).pop();
                                          },
                                        )),
                                    const Divider(height: 24),
                                  ],
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      'SUGGESTED CANON',
                                      style: AppTypography.monoBadge(color: AppColors.cyberCyan, fontSize: 10),
                                    ),
                                  ),
                                  ...curatedCandidates.map((item) => _CandidateTile(
                                        item: item,
                                        onSelect: () async {
                                          await ref.read(dossierTopPicksProvider.notifier).pinItem(
                                                isAlbum: isAlbum,
                                                slotIndex: slotIndex,
                                                item: item,
                                              );
                                          if (context.mounted) Navigator.of(context).pop();
                                        },
                                      )),
                                ],
                              ),
                  ),

                  const SizedBox(height: 8),
                  BrutalistButton(
                    label: 'CLEAR / UNPIN SLOT',
                    icon: Icons.delete_outline,
                    backgroundColor: AppColors.surfaceElevated,
                    textColor: AppColors.vermillion,
                    borderColor: AppColors.border,
                    isFullWidth: true,
                    onPressed: () async {
                      await ref.read(dossierTopPicksProvider.notifier).unpinItem(
                            isAlbum: isAlbum,
                            slotIndex: slotIndex,
                          );
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final currentUserEmail = ref.watch(currentUserEmailProvider);
    final userId = ref.watch(currentUserIdProvider);
    final userName = profile.userName;
    final userHandle = profile.userHandle;
    final userReviewsAsync = ref.watch(userReviewsProvider(userId));
    final topPicks = ref.watch(resolvedTopPicksProvider);

    userReviewsAsync.whenData((reviews) {
      if (reviews.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(wishlistProvider.notifier).removeReviewedItems(reviews);
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('CRITIC DOSSIER', style: AppTypography.displaySmall()),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music_outlined, color: AppColors.cyberCyan),
            tooltip: 'Curated Lists',
            onPressed: () => Navigator.of(context).push(UserListsScreen.route()),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline, color: AppColors.textPrimary),
            tooltip: 'Wantlist // Wishlist',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WishlistScreen()),
            ),
          ),
          IconButton(
            icon: Icon(
              isAuthenticated ? Icons.cloud_done : Icons.cloud_queue_outlined,
              color: isAuthenticated ? AppColors.acidLime : AppColors.textPrimary,
            ),
            tooltip: isAuthenticated ? 'Cloud Sync Active ($currentUserEmail)' : 'Log in / Cloud Sync',
            onPressed: () {
              if (isAuthenticated) {
                _showSettingsModal(context, ref);
              } else {
                Navigator.of(context).push(LoginScreen.route());
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            tooltip: 'Settings',
            onPressed: () => _showSettingsModal(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Backdrop Banner (Clean & Full Bleed)
            if (profile.backdropPath != null)
              GestureDetector(
                onTap: () => _showBackdropOptions(context, ref),
                child: Container(
                  width: double.infinity,
                  height: 165,
                  decoration: const BoxDecoration(
                    color: AppColors.pureBlack,
                    border: Border(
                      bottom: BorderSide(color: AppColors.borderBold, width: 2.0),
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(profile.backdropPath!),
                        width: double.infinity,
                        height: 165,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.1),
                              Colors.transparent,
                              AppColors.pureBlack.withValues(alpha: 0.65),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Interactive Profile Avatar with Camera Badge
                      GestureDetector(
                        onTap: () => _showAvatarOptions(context, ref),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
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
                              child: profile.avatarPath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(1),
                                      child: (profile.avatarPath!.startsWith('http://') || profile.avatarPath!.startsWith('https://'))
                                          ? Image.network(
                                              profile.avatarPath!,
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, err, stack) => Center(
                                                child: Text(
                                                  'YOU',
                                                  style: AppTypography.monoBadge(
                                                    color: AppColors.pureBlack,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Image.file(
                                              File(profile.avatarPath!),
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, err, stack) => Center(
                                                child: Text(
                                                  'YOU',
                                                  style: AppTypography.monoBadge(
                                                    color: AppColors.pureBlack,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                    )
                                  : Center(
                                      child: Text(
                                        'YOU',
                                        style: AppTypography.monoBadge(
                                          color: AppColors.pureBlack,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                            ),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: Container(
                                padding: const EdgeInsets.all(3.5),
                                decoration: BoxDecoration(
                                  color: AppColors.pureBlack,
                                  border: Border.all(color: AppColors.acidLime, width: 1.5),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 11,
                                  color: AppColors.acidLime,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Critic name & handle vertically centered on the middle side of avatar
                      Expanded(
                        child: InkWell(
                          onTap: () => _showEditUsernameDialog(context, ref),
                          borderRadius: BorderRadius.circular(2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      userName.toUpperCase(),
                                      style: AppTypography.displayMedium(fontSize: 20),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 13,
                                    color: AppColors.acidLime.withValues(alpha: 0.8),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
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
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // User Bio / Self-Expression below the avatar and name row
                  GestureDetector(
                    onTap: () => _showEditBioDialog(context, ref),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard.withValues(alpha: 0.7),
                        border: Border.all(color: AppColors.border, width: 1.0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              profile.bio.isNotEmpty
                                  ? profile.bio
                                  : 'Add your critic bio // express yourself...',
                              style: AppTypography.bodySmall(
                                color: profile.bio.isNotEmpty
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.edit_note,
                            size: 16,
                            color: AppColors.acidLime,
                          ),
                        ],
                      ),
                    ),
                  ),


                ],
              ),
            ),

            // Cloud Sync Prompt Banner (If in Guest Mode)
            if (!isAuthenticated)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    border: Border.all(color: AppColors.acidLime, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.acidLime,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.acidLime,
                              border: Border.all(color: AppColors.pureBlack, width: 1),
                            ),
                            child: Text(
                              'CLOUD BACKUP // GUEST MODE',
                              style: AppTypography.monoBadge(
                                color: AppColors.pureBlack,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.cloud_off_outlined, color: AppColors.acidLime, size: 18),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'BACK UP & SYNC YOUR CRITIC DOSSIER',
                        style: AppTypography.displaySmall(fontSize: 13, color: AppColors.pureWhite),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Retain your reviews, ratings, vinyl wantlist, and curated lists across devices with Cloud Firestore.',
                        style: AppTypography.bodySmall(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: BrutalistButton(
                              label: 'LOG IN',
                              icon: Icons.login,
                              backgroundColor: AppColors.acidLime,
                              textColor: AppColors.pureBlack,
                              borderColor: AppColors.pureBlack,
                              isSmall: true,
                              onPressed: () => Navigator.of(context).push(LoginScreen.route()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: BrutalistButton(
                              label: 'REGISTER',
                              icon: Icons.person_add_alt_1,
                              backgroundColor: AppColors.surfaceElevated,
                              textColor: AppColors.pureWhite,
                              borderColor: AppColors.pureWhite,
                              isSmall: true,
                              onPressed: () => Navigator.of(context).push(RegisterScreen.route()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Statistics Grid
            userReviewsAsync.when(
              data: (reviews) {
                final totalLogged = reviews.length;
                final avgScore = totalLogged > 0
                    ? (reviews.fold<double>(0.0, (acc, r) => acc + r.rating) / totalLogged)
                    : 0.0;
                final perfectTens = reviews.where((r) => r.rating >= 10.0).length;

                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            AllRatedReleasesScreen.route(),
                          ),
                          borderRadius: BorderRadius.circular(2),
                          child: _StatBox(
                            label: 'LOGGED',
                            value: '$totalLogged',
                            accentColor: AppColors.textPrimary,
                          ),
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
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            AllRatedReleasesScreen.route(
                              initialFilter: RatedFilter.perfect10s,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(2),
                          child: _StatBox(
                            label: 'PERFECT 10s',
                            value: '$perfectTens',
                            accentColor: AppColors.electricPink,
                          ),
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

            // Section: CRITIC'S CANON // TOP 3 ALBUMS & SONGS
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CRITIC\'S CANON',
                        style: AppTypography.displaySmall(),
                      ),
                      Text(
                        'YOUR HIGHEST RATED & PINNED RELEASES',
                        style: AppTypography.monoLabel(color: AppColors.textMuted, fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Top 3 Albums Podium
            _TopPicksPodiumSection(
              title: 'TOP 3 ALBUMS',
              badgeLabel: 'LP ARCHIVE',
              badgeColor: AppColors.acidLime,
              isAlbum: true,
              items: topPicks.topAlbums,
              onSelectSlot: (slot) => _showTopPickSelector(context, ref, isAlbum: true, slotIndex: slot),
            ),

            const SizedBox(height: 24),

            // Top 3 Songs Podium
            _TopPicksPodiumSection(
              title: 'TOP 3 SONGS // SINGLES',
              badgeLabel: 'HEAVY ROTATION',
              badgeColor: AppColors.cyberCyan,
              isAlbum: false,
              items: topPicks.topSongs,
              onSelectSlot: (slot) => _showTopPickSelector(context, ref, isAlbum: false, slotIndex: slot),
            ),

            const SizedBox(height: 24),
            const Divider(),

            // Section: RECENT ACTIVITY (Chronological Timeline of Scored Releases)
            _RecentActivitySection(
              reviews: userReviewsAsync.asData?.value ?? [],
            ),

            const SizedBox(height: 24),
            const Divider(),

            // Logged Written Reviews Header & Redirect Button
            InkWell(
              onTap: () => Navigator.of(context).push(
                LoggedReviewsScreen.route(),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MY LOGGED REVIEWS',
                      style: AppTypography.displaySmall(),
                    ),
                    userReviewsAsync.when(
                      data: (r) {
                        final count = r.where((review) => review.hasWrittenReview).length;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$count CRITIQUES',
                              style: AppTypography.monoLabel(fontSize: 10, color: AppColors.acidLime),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: AppColors.acidLime,
                            ),
                          ],
                        );
                      },
                      loading: () => const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                      error: (err, stack) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            userReviewsAsync.when(
              data: (reviews) {
                final writtenReviews = reviews.where((r) => r.hasWrittenReview).toList();
                if (writtenReviews.isEmpty) {
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
                        const Icon(Icons.rate_review_outlined, size: 36, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'NO WRITTEN REVIEWS LOGGED YET',
                          style: AppTypography.monoBadge(color: AppColors.textPrimary, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Drop your in-depth written impressions on any album or track to file it here.',
                          style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return _ReviewStackDeck(reviews: writtenReviews);
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

            const SizedBox(height: 24),

            // Critic Wantlist / Wishlist Shortcut Banner (Moved below My Logged Reviews)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _WishlistShortcutBanner(
                count: ref.watch(wishlistCountProvider),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WishlistScreen()),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Curated Lists Shortcut Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ListsShortcutBanner(
                count: ref.watch(userListsCountProvider),
                onTap: () => Navigator.of(context).push(
                  UserListsScreen.route(),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _TopPicksPodiumSection extends StatelessWidget {
  final String title;
  final String badgeLabel;
  final Color badgeColor;
  final bool isAlbum;
  final List<MusicItem?> items;
  final ValueChanged<int> onSelectSlot;

  const _TopPicksPodiumSection({
    required this.title,
    required this.badgeLabel,
    required this.badgeColor,
    required this.isAlbum,
    required this.items,
    required this.onSelectSlot,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 14,
                    color: badgeColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: AppTypography.monoLabel(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  badgeLabel,
                  style: AppTypography.monoBadge(color: badgeColor, fontSize: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < 3; i++) ...[
                Expanded(
                  child: _PodiumSlotCard(
                    rank: i + 1,
                    item: i < items.length ? items[i] : null,
                    isAlbum: isAlbum,
                    onTap: () {
                      final item = i < items.length ? items[i] : null;
                      if (item != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => MusicDetailScreen(item: item)),
                        );
                      } else {
                        onSelectSlot(i);
                      }
                    },
                    onLongPress: () => onSelectSlot(i),
                  ),
                ),
                if (i < 2) const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumSlotCard extends StatelessWidget {
  final int rank;
  final MusicItem? item;
  final bool isAlbum;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PodiumSlotCard({
    required this.rank,
    required this.item,
    required this.isAlbum,
    required this.onTap,
    required this.onLongPress,
  });

  Color get _rankColor {
    switch (rank) {
      case 1:
        return AppColors.acidLime;
      case 2:
        return AppColors.cyberCyan;
      case 3:
      default:
        return AppColors.electricPink;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border.all(
            color: item != null ? AppColors.border : AppColors.borderSubtle,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
              decoration: BoxDecoration(
                color: _rankColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0$rank',
                    style: AppTypography.monoBadge(
                      color: AppColors.pureBlack,
                      fontSize: 10,
                    ),
                  ),
                  Icon(
                    isAlbum ? Icons.album : Icons.music_note,
                    size: 11,
                    color: AppColors.pureBlack,
                  ),
                ],
              ),
            ),

            if (item != null) ...[
              // Artwork
              AspectRatio(
                aspectRatio: 1.0,
                child: AlbumArtCard(
                  imageUrl: item!.coverUrl,
                  showShadow: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item!.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.displaySmall(fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item!.artist.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.monoLabel(fontSize: 8, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Empty Slot
              AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  color: AppColors.surfaceElevated,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: _rankColor,
                        size: 24,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '+ PIN ${isAlbum ? "LP" : "SONG"}',
                        style: AppTypography.monoBadge(
                          color: AppColors.textSecondary,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'EMPTY // TAP TO PIN',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.monoLabel(fontSize: 8, color: AppColors.textMuted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  final MusicItem item;
  final VoidCallback onSelect;

  const _CandidateTile({
    required this.item,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      leading: AlbumArtCard(
        imageUrl: item.coverUrl,
        size: 44,
        showShadow: false,
      ),
      title: Text(
        item.name.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.headline(fontSize: 13),
      ),
      subtitle: Text(
        item.artist.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall(color: AppColors.textMuted, fontSize: 10),
      ),
      trailing: BrutalistButton(
        label: 'PIN',
        isSmall: true,
        backgroundColor: AppColors.acidLime,
        textColor: AppColors.pureBlack,
        onPressed: onSelect,
      ),
      onTap: onSelect,
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

class _RecentActivitySection extends StatelessWidget {
  final List<Review> reviews;

  const _RecentActivitySection({required this.reviews});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 14,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RECENT ACTIVITY',
                    style: AppTypography.monoLabel(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.of(context).push(
                  AllRatedReleasesScreen.route(),
                ),
                borderRadius: BorderRadius.circular(2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    border: Border.all(color: AppColors.acidLime.withValues(alpha: 0.6)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ALL ${reviews.length} RATED',
                        style: AppTypography.monoBadge(color: AppColors.acidLime, fontSize: 8),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.chevron_right, size: 12, color: AppColors.acidLime),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (reviews.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: [
                const Icon(Icons.history, color: AppColors.textMuted, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NO RECENT ACTIVITY RECORDED',
                        style: AppTypography.monoBadge(color: AppColors.textPrimary, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rate any album or single to start building your chronological timeline.',
                        style: AppTypography.bodySmall(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 98,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: reviews.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return _RecentActivityCard(review: review);
              },
            ),
          ),
      ],
    );
  }
}

class _RecentActivityCard extends ConsumerWidget {
  final Review review;

  const _RecentActivityCard({required this.review});

  Color get _scoreColor {
    if (review.rating >= 9.0) return AppColors.acidLime;
    if (review.rating >= 8.0) return AppColors.cyberCyan;
    if (review.rating >= 6.5) return AppColors.electricPink;
    if (review.rating >= 5.0) return const Color(0xFFFFB800);
    return AppColors.vermillion;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAlbum = review.itemType == 'album';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReviewDetailScreen(review: review),
          ),
        );
      },
      borderRadius: BorderRadius.circular(2),
      child: Container(
        width: 255,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          children: [
            AlbumArtCard(
              imageUrl: review.coverUrl,
              size: 74,
              showShadow: false,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: isAlbum ? AppColors.acidLime : AppColors.cyberCyan,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          isAlbum ? 'LP' : 'SONG',
                          style: AppTypography.monoBadge(color: AppColors.pureBlack, fontSize: 7.5),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        review.timeAgo,
                        style: AppTypography.monoLabel(fontSize: 8, color: AppColors.textMuted),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _scoreColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          review.scoreFormatted,
                          style: AppTypography.monoBadge(
                            color: AppColors.pureBlack,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.musicItemName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.displaySmall(fontSize: 11),
                  ),
                  Text(
                    review.artistName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.monoLabel(fontSize: 8, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(1.5),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      review.hasWrittenReview ? 'CRITIQUE' : 'RATING ONLY',
                      style: AppTypography.monoBadge(
                        color: review.hasWrittenReview ? AppColors.electricPink : AppColors.textMuted,
                        fontSize: 7.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistShortcutBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _WishlistShortcutBanner({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          border: Border.all(color: AppColors.acidLime, width: 1.5),
          borderRadius: BorderRadius.circular(2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.pureBlack,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.acidLime,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Icon(
                Icons.bookmark_outline,
                color: AppColors.pureBlack,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CRITIC WANTLIST // QUEUE',
                    style: AppTypography.displaySmall(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ALBUMS & TRACKS QUEUED TO SPIN',
                    style: AppTypography.monoLabel(color: AppColors.textSecondary, fontSize: 9),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '$count QUEUED',
                style: AppTypography.monoBadge(color: AppColors.acidLime, fontSize: 9),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ListsShortcutBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _ListsShortcutBanner({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          border: Border.all(color: AppColors.cyberCyan, width: 1.5),
          borderRadius: BorderRadius.circular(2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.pureBlack,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cyberCyan,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Icon(
                Icons.queue_music_outlined,
                color: AppColors.pureBlack,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURATED LISTS // ARCHIVES',
                    style: AppTypography.displaySmall(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'CUSTOM TRACK & ALBUM COLLECTIONS',
                    style: AppTypography.monoLabel(color: AppColors.textSecondary, fontSize: 9),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '$count ${count == 1 ? 'LIST' : 'LISTS'}',
                style: AppTypography.monoBadge(color: AppColors.cyberCyan, fontSize: 9),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ReviewStackDeck extends StatefulWidget {
  final List<Review> reviews;

  const _ReviewStackDeck({required this.reviews});

  @override
  State<_ReviewStackDeck> createState() => _ReviewStackDeckState();
}

class _ReviewStackDeckState extends State<_ReviewStackDeck> {
  int _currentIndex = 0;
  Timer? _timer;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _ReviewStackDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reviews.length != oldWidget.reviews.length) {
      if (_currentIndex >= widget.reviews.length) {
        _currentIndex = 0;
      }
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.reviews.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isHolding && mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.reviews.length;
        });
      }
    });
  }

  void _pauseTimer() {
    if (!_isHolding) {
      setState(() => _isHolding = true);
    }
  }

  void _resumeTimer() {
    if (_isHolding) {
      setState(() => _isHolding = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _openDetail(Review review) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewDetailScreen(review: review),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reviews.isEmpty) return const SizedBox.shrink();

    final activeReview = widget.reviews[_currentIndex % widget.reviews.length];
    final hasMultiple = widget.reviews.length > 1;
    // Illusion: exactly 3 cards stacked behind front card ONLY if user has more than 1 logged review
    final stackDepth = hasMultiple ? 3 : 0;

    const double stepX = 4.0;
    const double stepY = 5.0;
    final totalExtraX = stackDepth * stepX;
    final totalExtraY = stackDepth * stepY;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Deck Meta Controls Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'CARD ${(_currentIndex + 1).toString().padLeft(2, '0')} / ${widget.reviews.length.toString().padLeft(2, '0')}',
                      style: AppTypography.monoBadge(color: AppColors.acidLime, fontSize: 9),
                    ),
                  ),
                  if (hasMultiple) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _isHolding ? AppColors.electricPink.withValues(alpha: 0.15) : AppColors.surface,
                        border: Border.all(color: _isHolding ? AppColors.electricPink : AppColors.borderSubtle),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isHolding ? Icons.pause_circle_outline : Icons.autorenew,
                            size: 10,
                            color: _isHolding ? AppColors.electricPink : AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isHolding ? 'HOLDING // PAUSED' : 'AUTO-CYCLE 5S',
                            style: AppTypography.monoBadge(
                              color: _isHolding ? AppColors.electricPink : AppColors.textMuted,
                              fontSize: 7.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (hasMultiple)
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _currentIndex = (_currentIndex - 1 + widget.reviews.length) % widget.reviews.length;
                        });
                      },
                      borderRadius: BorderRadius.circular(2),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Icon(Icons.chevron_left, size: 14, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _currentIndex = (_currentIndex + 1) % widget.reviews.length;
                        });
                      },
                      borderRadius: BorderRadius.circular(2),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Icon(Icons.chevron_right, size: 14, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Stacked Card Pile Container with Illusion Behind Front Card
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20 + totalExtraX, totalExtraY + 12),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 3 illusion backdrop card layers stacked underneath
              if (stackDepth > 0)
                for (int i = stackDepth; i >= 1; i--)
                  Positioned.fill(
                    top: i * stepY,
                    left: i * stepX,
                    right: -(i * stepX),
                    bottom: -(i * stepY),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        border: Border.all(
                          color: AppColors.acidLime.withValues(alpha: (1.0 - (i - 1) * 0.22).clamp(0.45, 1.0)),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.pureBlack,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ),

              // Front Top Active Review Card
              GestureDetector(
                onTapDown: (_) => _pauseTimer(),
                onTapUp: (_) => _resumeTimer(),
                onTapCancel: () => _resumeTimer(),
                onLongPressStart: (_) => _pauseTimer(),
                onLongPressEnd: (_) => _resumeTimer(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  transitionBuilder: (child, animation) {
                    final slideIn = Tween<Offset>(
                      begin: const Offset(0.04, 0.03),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: slideIn,
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<String>('${activeReview.id}_$_currentIndex'),
                    child: Consumer(
                      builder: (context, ref, _) {
                        return ReviewCard(
                          review: activeReview,
                          showItemHeader: true,
                          onLike: () {
                            ref.read(reviewControllerProvider).likeReview(activeReview.id);
                          },
                          onTap: () => _openDetail(activeReview),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

