import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/presentation/screens/home/home_screen.dart';
import 'package:groovd/presentation/screens/search/search_screen.dart';
import 'package:groovd/presentation/screens/profile/profile_screen.dart';
import 'package:groovd/state/settings_provider.dart';

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
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Eagerly initialize and observe Spotify API settings
    ref.watch(spotifySettingsProvider);

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
              children: [
                // Sliding acid-lime indicator bar atop the selected tab
                AnimatedAlign(
                  alignment: Alignment(-1.0 + (_currentIndex * 1.0), -1.0),
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: FractionallySizedBox(
                    widthFactor: 1 / 3,
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
                    _buildNavItem(
                      index: 2,
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: 'DOSSIER',
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

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

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
                child: Icon(
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
