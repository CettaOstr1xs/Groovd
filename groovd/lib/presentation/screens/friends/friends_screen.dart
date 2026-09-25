import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/friend_profile.dart';
import 'package:groovd/state/friends_provider.dart';
import 'package:groovd/presentation/screens/review/review_detail_screen.dart';
import 'package:groovd/presentation/widgets/brutalist_button.dart';
import 'package:groovd/presentation/widgets/critic_avatar.dart';
import 'package:groovd/presentation/widgets/review_card.dart';
import 'friend_profile_screen.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const FriendsScreen({super.key, this.initialTabIndex = 0});

  static Route route({int initialTabIndex = 0}) {
    return MaterialPageRoute(
      builder: (_) => FriendsScreen(initialTabIndex: initialTabIndex),
    );
  }

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final followingAsync = ref.watch(followingListProvider);
    final followingList = followingAsync.value ?? [];
    final searchQuery = ref.watch(criticSearchQueryProvider);
    final searchedCriticsAsync = ref.watch(searchedCriticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'CRITIC CIRCLE',
          style: AppTypography.displaySmall(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.acidLime),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, size: 13, color: AppColors.acidLime),
                const SizedBox(width: 5),
                Text(
                  '${followingList.length} FOLLOWING',
                  style: AppTypography.monoBadge(
                    color: AppColors.acidLime,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subheader label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'ALLIES // SOCIAL FEED & CRITIC DISCOVERY',
              style: AppTypography.monoLabel(
                color: AppColors.textMuted,
                fontSize: 9,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              cursorColor: AppColors.acidLime,
              style: AppTypography.bodyMedium(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search critics by name or @handle...',
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(criticSearchQueryProvider.notifier).clear();
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                ref.read(criticSearchQueryProvider.notifier).update(val);
              },
            ),
          ),

          const SizedBox(height: 12),

          // If searching, show search results
          if (searchQuery.trim().isNotEmpty) ...[
            Expanded(
              child: searchedCriticsAsync.when(
                data: (results) {
                  if (results.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'NO CRITICS FOUND MATCHING "$searchQuery"',
                          style: AppTypography.monoBadge(color: AppColors.textMuted),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final critic = results[index];
                      return _CriticListTile(
                        critic: critic,
                        onTap: () {
                          Navigator.of(context).push(FriendProfileScreen.route(critic));
                        },
                        onToggleFollow: () {
                          ref.read(followingListProvider.notifier).toggleFollow(critic);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.acidLime),
                ),
                error: (err, _) => Center(
                  child: Text('Search error: $err'),
                ),
              ),
            ),
          ] else ...[
            // Tab Selector
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1.5),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.acidLime,
                indicatorWeight: 3.0,
                labelColor: AppColors.acidLime,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: AppTypography.monoLabel(fontSize: 10, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'ACTIVITY FEED'),
                  Tab(text: 'MY CIRCLE'),
                  Tab(text: 'DISCOVER'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _FriendsFeedTab(
                    onDiscoverTap: () => _tabController.animateTo(2),
                  ),
                  _MyCircleTab(
                    onDiscoverTap: () => _tabController.animateTo(2),
                  ),
                  const _DiscoverCriticsTab(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FriendsFeedTab extends ConsumerWidget {
  final VoidCallback onDiscoverTap;

  const _FriendsFeedTab({required this.onDiscoverTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(friendsFeedProvider);

    return feedAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 44, color: AppColors.textMuted),
                  const SizedBox(height: 14),
                  Text(
                    'YOUR CIRCLE IS QUIET',
                    style: AppTypography.headline(fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Follow music critics and friends to tune in to their live critiques and release scores.',
                    style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  BrutalistButton(
                    label: '+ DISCOVER CRITICS',
                    icon: Icons.person_add_outlined,
                    onPressed: onDiscoverTap,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          itemCount: reviews.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final review = reviews[index];
            return ReviewCard(
              review: review,
              showItemHeader: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReviewDetailScreen(review: review),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.acidLime),
      ),
      error: (err, _) => Center(
        child: Text('Error loading feed: $err'),
      ),
    );
  }
}

class _MyCircleTab extends ConsumerWidget {
  final VoidCallback onDiscoverTap;

  const _MyCircleTab({required this.onDiscoverTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingAsync = ref.watch(followingListProvider);

    return followingAsync.when(
      data: (following) {
        if (following.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_outlined, size: 44, color: AppColors.textMuted),
                  const SizedBox(height: 14),
                  Text(
                    'NO CRITICS IN YOUR CIRCLE',
                    style: AppTypography.headline(fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Explore active community tastemakers and follow other critics to build your inner circle.',
                    style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  BrutalistButton(
                    label: 'BROWSE DISCOVER TAB',
                    icon: Icons.explore_outlined,
                    onPressed: onDiscoverTap,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          itemCount: following.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final critic = following[index];
            return _CriticListTile(
              critic: critic,
              onTap: () {
                Navigator.of(context).push(FriendProfileScreen.route(critic));
              },
              onToggleFollow: () {
                ref.read(followingListProvider.notifier).toggleFollow(critic);
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.acidLime),
      ),
      error: (err, _) => Center(
        child: Text('Error: $err'),
      ),
    );
  }
}

class _DiscoverCriticsTab extends ConsumerWidget {
  const _DiscoverCriticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestedAsync = ref.watch(suggestedCriticsProvider);

    return suggestedAsync.when(
      data: (critics) {
        if (critics.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 40, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'NO OTHER CRITICS FOUND',
                    style: AppTypography.monoBadge(color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'All registered community critics are currently in your circle.',
                    style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'COMMUNITY CRITICS // DISCOVER',
                style: AppTypography.monoBadge(color: AppColors.cyberCyan, fontSize: 10),
              ),
            ),
            for (final critic in critics) ...[
              _CriticListTile(
                critic: critic,
                onTap: () {
                  Navigator.of(context).push(FriendProfileScreen.route(critic));
                },
                onToggleFollow: () {
                  ref.read(followingListProvider.notifier).toggleFollow(critic);
                },
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.acidLime),
      ),
      error: (err, _) => Center(
        child: Text('Error: $err'),
      ),
    );
  }
}

class _CriticListTile extends ConsumerWidget {
  final FriendProfile critic;
  final VoidCallback onTap;
  final VoidCallback onToggleFollow;

  const _CriticListTile({
    required this.critic,
    required this.onTap,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowing = ref.watch(isFollowingProvider(critic.userId));
    final followsYou = ref.watch(isFollowerOfCurrentUserProvider(critic.userId));

    final followLabel = isFollowing
        ? '✓ FOLLOWING'
        : (followsYou ? '+ FOLLOW BACK' : '+ FOLLOW');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border.all(
            color: isFollowing ? AppColors.acidLime.withValues(alpha: 0.7) : AppColors.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          children: [
            CriticAvatar(
              avatarPath: critic.avatarPath,
              fallbackInitial: critic.userName,
              size: 44,
              borderColor: isFollowing ? AppColors.acidLime : AppColors.cyberCyan,
              borderRadius: 2,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    critic.userName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headline(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          critic.formattedHandle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.monoLabel(fontSize: 10, color: AppColors.cyberCyan),
                        ),
                      ),
                      if (followsYou) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            border: Border.all(color: AppColors.acidLime.withValues(alpha: 0.6), width: 0.8),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            'FOLLOWS YOU',
                            style: AppTypography.monoLabel(
                              fontSize: 7.5,
                              color: AppColors.acidLime,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (critic.bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      critic.bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            BrutalistButton(
              label: followLabel,
              isSmall: true,
              backgroundColor: isFollowing ? AppColors.surfaceElevated : AppColors.acidLime,
              textColor: isFollowing ? AppColors.acidLime : AppColors.pureBlack,
              borderColor: isFollowing ? AppColors.acidLime : AppColors.pureBlack,
              onPressed: onToggleFollow,
            ),
          ],
        ),
      ),
    );
  }
}
