import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/presentation/screens/home/home_screen.dart';
import 'package:groovd/presentation/screens/search/search_screen.dart';
import 'package:groovd/presentation/screens/friends/friends_screen.dart';
import 'package:groovd/presentation/screens/profile/profile_screen.dart';
import 'package:groovd/presentation/screens/chat/critic_chat_modal.dart';
import 'package:groovd/state/settings_provider.dart';
import 'package:groovd/state/user_profile_provider.dart';
import '../widgets/critic_avatar.dart';
import '../widgets/rating_spike_sign.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    FriendsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Eagerly initialize and observe Spotify API settings
    ref.watch(spotifySettingsProvider);
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.015),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.borderBold, width: 2.0),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 62,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Sliding acid-lime indicator bar atop the selected tab (5 slots)
                Builder(
                  builder: (context) {
                    final slotIndex = _currentIndex < 2 ? _currentIndex : _currentIndex + 1;
                    return AnimatedAlign(
                      alignment: Alignment(-1.0 + (slotIndex * 0.5), -1.0),
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      child: FractionallySizedBox(
                        widthFactor: 1 / 5,
                        child: Container(
                          height: 3.0,
                          decoration: const BoxDecoration(
                            color: AppColors.acidLime,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.acidLime,
                                blurRadius: 6,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                Row(
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: Icons.dashboard_outlined,
                      activeIcon: Icons.dashboard,
                      label: 'DISPATCH',
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.search,
                      activeIcon: Icons.search,
                      label: 'SEARCH',
                    ),
                    _buildCriticNavButton(context),
                    _buildNavItem(
                      index: 2,
                      icon: Icons.people_outline,
                      activeIcon: Icons.people,
                      label: 'FRIENDS',
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: 'DOSSIER',
                      avatarPath: profile.avatarPath,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCriticNavButton(BuildContext context) {
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, -12),
        child: GestureDetector(
          key: const Key('nav_center_critic_btn'),
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.heavyImpact();
            CriticChatModal.show(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.acidLime,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: AppColors.pureBlack,
                    width: 2.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.pureBlack,
                      offset: Offset(2.0, 2.0),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Center(
                  child: RatingSpikeSign(
                    rating: 10.0,
                    size: 22,
                    color: AppColors.pureBlack,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'GROOVD AI',
                style: AppTypography.monoBadge(
                  color: AppColors.acidLime,
                  fontSize: 8.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    String? avatarPath,
  }) {
    final isSelected = _currentIndex == index;
    final hasCustomAvatar = avatarPath != null && avatarPath.trim().isNotEmpty;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (_currentIndex != index) {
            setState(() => _currentIndex = index);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: isSelected ? AppColors.surfaceElevated.withValues(alpha: 0.6) : Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: hasCustomAvatar
                    ? CriticAvatar(
                        avatarPath: avatarPath,
                        fallbackInitial: 'C',
                        size: 20,
                        borderWidth: 1.5,
                        borderColor: isSelected ? AppColors.acidLime : AppColors.borderBold,
                        borderRadius: 2,
                      )
                    : Icon(
                        isSelected ? activeIcon : icon,
                        color: isSelected ? AppColors.acidLime : AppColors.textMuted,
                        size: 20,
                      ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AppTypography.monoBadge(
                  color: isSelected ? AppColors.white : AppColors.textMuted,
                  fontSize: 10,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
