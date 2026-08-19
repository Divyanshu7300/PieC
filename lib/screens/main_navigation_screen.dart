import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/core/services/theme_service.dart';
import 'package:piec/screens/chat/chat_list_screen.dart';
import 'package:piec/screens/map/world_map_screen.dart';
import 'package:piec/screens/profile/profile_screen.dart';
import 'package:provider/provider.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onVisitOnMap(UserModel friend) {
    setState(() {
      _currentIndex = 0; // Switch to Map tab
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    final List<Widget> screens = [
      const WorldMapScreen(),
      ChatListScreen(onVisitOnMap: _onVisitOnMap),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: themeService.activeBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: themeService.activeSurfaceColor,
          border: Border(
            top: BorderSide(
              color: themeService.isLightMode
                  ? const Color(0xFFE2E8F0)
                  : AppColors.surfaceLight,
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, 'World Map', '🗺️', Icons.map_rounded, themeService),
                _buildNavItem(1, 'E2EE Chats', '💬', Icons.chat_bubble_rounded, themeService),
                _buildNavItem(2, 'My Identity', '👾', Icons.person_rounded, themeService),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, String emoji, IconData icon, ThemeService themeService) {
    final isSelected = _currentIndex == index;
    final primaryColor = themeService.activePrimaryColor;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: primaryColor.withOpacity(0.45), width: 1.2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
