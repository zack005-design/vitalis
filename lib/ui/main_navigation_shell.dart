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

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      bottomNavigationBar: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: bottomInset > 0 ? bottomInset : 24,
            left: 24,
            right: 24,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x99000000) // Deep translucent black
                      : const Color(0xB3FFFFFF), // Frosted white
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.1) 
                        : Colors.black.withValues(alpha: 0.05),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(0, Icons.grid_view_rounded, isDark),
                    _navItem(1, Icons.bedtime_rounded, isDark),
                    _navItem(2, Icons.insights_rounded, isDark),
                    _navItem(3, Icons.restaurant_rounded, isDark),
                    _navItem(4, Icons.person_rounded, isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  static const List<String> _navLabels = [
    'Today',
    'Sleep',
    'Insights',
    'Food',
    'More',
  ];

  Widget _navItem(int index, IconData icon, bool isDark) {
    final isSelected = _currentIndex == index;
    final label = _navLabels[index];
    
    // Premium color palette for the nav items
    final activeBg = isDark 
        ? Colors.white.withValues(alpha: 0.15) 
        : AppColors.primaryBlue.withValues(alpha: 0.1);
    final activeIconColor = isDark ? Colors.white : AppColors.primaryBlue;
    final inactiveIconColor = isDark 
        ? Colors.white.withValues(alpha: 0.4) 
        : Colors.black.withValues(alpha: 0.4);

    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      hint: isSelected ? 'Currently selected tab' : 'Double tap to switch to $label tab',
      child: GestureDetector(
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 16.0 : 12.0,
            vertical: 12.0,
          ),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? activeIconColor : inactiveIconColor,
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: activeIconColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
