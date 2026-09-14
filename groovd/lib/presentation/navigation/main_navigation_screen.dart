import 'package:flutter/material.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/presentation/screens/home/home_screen.dart';
import 'package:groovd/presentation/screens/search/search_screen.dart';
import 'package:groovd/presentation/screens/profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
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
            child: Row(
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
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
            border: isSelected
                ? const Border(
                    top: BorderSide(color: AppColors.acidLime, width: 3.0),
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.acidLime : AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTypography.monoBadge(
                  color: isSelected ? AppColors.white : AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
