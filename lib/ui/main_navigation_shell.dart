import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design_system/app_colors.dart';
import 'today/today_screen.dart';
import 'sleep/sleep_screen.dart';
import 'insights/insights_screen.dart';
import 'food/food_screen.dart';
import 'more/more_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TodayScreen(),
    SleepScreen(),
    InsightsScreen(),
    FoodScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(20, 0, 20, 10 + (bottomInset > 0 ? bottomInset : 10)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xE60B1326) // Deep midnight glass
                    : const Color(0xEBFFFFFF),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(0, Icons.grid_view_rounded, isDark),
                  _navItem(1, Icons.nightlight_round, isDark),
                  _navItem(2, Icons.insights_rounded, isDark),
                  _navItem(3, Icons.restaurant_rounded, isDark),
                  _navItem(4, Icons.person_rounded, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, bool isDark) {
    final isSelected = _currentIndex == index;
    final activeBg = isDark ? const Color(0xFF222A3E) : const Color(0xFFE2E8F0);
    final activeIconColor = isDark ? Colors.white : AppColors.primaryBlue;
    final inactiveIconColor = isDark ? const Color(0xFF8E909A) : const Color(0xFF717786);

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          HapticFeedback.selectionClick();
          setState(() {
            _currentIndex = index;
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: isSelected ? 52 : 44,
        height: isSelected ? 52 : 44,
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isSelected && isDark
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            icon,
            size: isSelected ? 24 : 22,
            color: isSelected ? activeIconColor : inactiveIconColor,
          ),
        ),
      ),
    );
  }
}
