import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/location_point.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/core/services/auth_service.dart';
import 'package:piec/core/services/theme_service.dart';
import 'package:piec/screens/auth/login_screen.dart';
import 'package:piec/screens/map/set_location_screen.dart';
import 'package:piec/widgets/avatar/avatar_customizer_modal.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  final List<String> _statusPresets = const [
    'At Home chilling 🍕',
    'In Office working 💼',
    'Gaming with squad 🎮',
    'At Cafe sipping brew ☕',
    'Driving on highway 🚗',
    'Sleeping / DND 😴',
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Spatial Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.accentPink),
            tooltip: 'Logout',
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar Showcase Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: themeService.isLightMode
                    ? const LinearGradient(
                        colors: [Colors.white, Color(0xFFF1F5F9)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : AppColors.cardGradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: themeService.activePrimaryColor.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeService.activePrimaryColor.withOpacity(0.15),
                    blurRadius: 20,
                  )
                ],
              ),
              child: Column(
                children: [
                  GamifiedAvatar(
                    config: user.avatarConfig,
                    size: 100,
                    showGlow: true,
                    enable3DInteraction: true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: themeService.isLightMode
                          ? const Color(0xFF0F172A)
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: TextStyle(
                      fontSize: 14,
                      color: themeService.activePrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () {
                      AvatarCustomizerModal.show(
                        context,
                        initialConfig: user.avatarConfig,
                        onSave: (newConfig) {
                          auth.updateAvatarConfig(newConfig);
                        },
                      );
                    },
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                    label: const Text('Customize 3D Avatar 🎨'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeService.activeSurfaceLightColor,
                      foregroundColor: themeService.activePrimaryColor,
                      side: BorderSide(color: themeService.activePrimaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // UI Theme & Aesthetics Studio Card (6 Presets)
            _buildSectionCard(
              themeService,
              title: 'App UI Theme & Aesthetic 🎨',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose your preferred visual experience:',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),

                  // 6 Rich Theme Cards Grid
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildThemeCard(
                              '⚪ Minimal White',
                              'Apple iOS Clean',
                              const Color(0xFFF8FAFC),
                              const Color(0xFF007AFF),
                              AppUiTheme.minimalPureWhite,
                              themeService,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildThemeCard(
                              '⚫ Pitch Black',
                              'OLED Stealth Mode',
                              Colors.black,
                              Colors.white,
                              AppUiTheme.minimalPitchBlack,
                              themeService,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildThemeCard(
                              '🌌 Cyber Neon',
                              'Futuristic High-Tech',
                              const Color(0xFF0B0D17),
                              const Color(0xFF00F0FF),
                              AppUiTheme.cyberNeon,
                              themeService,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildThemeCard(
                              '🌸 Sakura Sunset',
                              'Pastel Tokyo Glow',
                              const Color(0xFF160924),
                              const Color(0xFFFF2A85),
                              AppUiTheme.sakuraSunset,
                              themeService,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildThemeCard(
                              '🌲 Nordic Sage',
                              'Forest & Calm Emerald',
                              const Color(0xFF0C1318),
                              const Color(0xFF10B981),
                              AppUiTheme.nordicSage,
                              themeService,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildThemeCard(
                              '👾 Retro 80s',
                              'Arcade Synthwave',
                              const Color(0xFF120524),
                              const Color(0xFFFF007F),
                              AppUiTheme.retroSynthwave,
                              themeService,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: AppColors.surfaceHover, height: 1),
                  const SizedBox(height: 14),

                  // Chat Bubble Style Selector
                  const Text(
                    'Chat Bubble Shape Style 💬',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildBubbleStyleChip('Curved (Snap)', 18, themeService),
                      const SizedBox(width: 8),
                      _buildBubbleStyleChip('Pill (iMessage)', 24, themeService),
                      const SizedBox(width: 8),
                      _buildBubbleStyleChip('Cyber (Block)', 8, themeService),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Map Style Selector Card
            _buildSectionCard(
              themeService,
              title: 'Default Real Map Style 🛰️',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildMapStyleChip('🛰️ Real Satellite Imagery', MapTileStyle.satellite, themeService),
                      _buildMapStyleChip('🌌 Dark Matter', MapTileStyle.darkMatter, themeService),
                      _buildMapStyleChip('🗺️ Standard Streets (OSM)', MapTileStyle.openStreetMap, themeService),
                      _buildMapStyleChip('🧭 Voyager Modern', MapTileStyle.voyager, themeService),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Live Status Changer
            _buildSectionCard(
              themeService,
              title: 'Current Status & Vibe ⚡',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _statusPresets.map((status) {
                      final isSelected = user.statusText == status;
                      return ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        selectedColor: themeService.activePrimaryColor,
                        backgroundColor: themeService.activeSurfaceLightColor,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? (themeService.isLightMode ? Colors.white : Colors.black)
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) => auth.updateStatus(status),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Location Pins (Home & Office)
            _buildSectionCard(
              themeService,
              title: 'Map Saved Places 📍',
              child: Column(
                children: [
                  _buildLocationTile(
                    context,
                    themeService,
                    emoji: '🏠',
                    title: user.homeLocation?.title ?? 'Home Base',
                    address: user.homeLocation?.address ?? 'Not configured yet',
                    color: AppColors.homeTag,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SetLocationScreen(
                            initialType: LocationType.home,
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(color: AppColors.surfaceLight, height: 16),
                  _buildLocationTile(
                    context,
                    themeService,
                    emoji: '💼',
                    title: user.officeLocation?.title ?? 'Workspace / Office',
                    address: user.officeLocation?.address ?? 'Not configured yet',
                    color: AppColors.officeTag,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SetLocationScreen(
                            initialType: LocationType.office,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Privacy & Ghost Mode Card
            _buildSectionCard(
              themeService,
              title: 'Privacy & Security 🛡️',
              child: Column(
                children: [
                  const Text(
                    'Location Sharing Precision',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose how precisely friends & family see your live coordinates on the map',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),

                  // 3-Tier Privacy Segmented Row
                  Row(
                    children: [
                      // 1. Precise
                      Expanded(
                        child: _buildPrivacyOption(
                          title: '🎯 Precise',
                          subtitle: 'Exact Street',
                          isSelected: user.privacyMode == LocationPrivacyMode.precise && !user.isGhostMode,
                          onTap: () {
                            auth.toggleGhostMode(false);
                            auth.updatePrivacyMode(LocationPrivacyMode.precise);
                          },
                          themeService: themeService,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 2. Blurred
                      Expanded(
                        child: _buildPrivacyOption(
                          title: '🏙️ Blurred',
                          subtitle: 'Area Only',
                          isSelected: user.privacyMode == LocationPrivacyMode.blurred && !user.isGhostMode,
                          onTap: () {
                            auth.toggleGhostMode(false);
                            auth.updatePrivacyMode(LocationPrivacyMode.blurred);
                          },
                          themeService: themeService,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 3. Ghost
                      Expanded(
                        child: _buildPrivacyOption(
                          title: '👻 Ghost',
                          subtitle: 'Hidden',
                          isSelected: user.isGhostMode || user.privacyMode == LocationPrivacyMode.ghost,
                          onTap: () {
                            auth.toggleGhostMode(true);
                            auth.updatePrivacyMode(LocationPrivacyMode.ghost);
                          },
                          themeService: themeService,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: AppColors.surfaceLight, height: 16),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeService.activeSurfaceLightColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield_rounded, color: AppColors.accentGreen),
                    ),
                    title: const Text(
                      'End-to-End Encryption',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'AES-256 Client-Side Zero Knowledge Protected',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    trailing: const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 20),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(
    String title,
    String subtitle,
    Color bgColor,
    Color accentColor,
    AppUiTheme theme,
    ThemeService themeService,
  ) {
    final isSelected = themeService.currentTheme == theme;

    return GestureDetector(
      onTap: () => themeService.setUiTheme(theme),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: themeService.activeSurfaceLightColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? themeService.activePrimaryColor : AppColors.surfaceHover,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor, width: 2),
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: themeService.activePrimaryColor, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubbleStyleChip(String label, int radius, ThemeService themeService) {
    final isSelected = themeService.bubbleCornerRadius == radius;
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(label, style: const TextStyle(fontSize: 11))),
        selected: isSelected,
        selectedColor: themeService.activePrimaryColor,
        backgroundColor: themeService.activeSurfaceLightColor,
        labelStyle: TextStyle(
          color: isSelected
              ? (themeService.isLightMode ? Colors.white : Colors.black)
              : AppColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
        onSelected: (_) => themeService.setBubbleRadius(radius),
      ),
    );
  }

  Widget _buildMapStyleChip(String label, MapTileStyle style, ThemeService themeService) {
    final isSelected = themeService.currentMapStyle == style;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: themeService.activePrimaryColor,
      backgroundColor: themeService.activeSurfaceLightColor,
      labelStyle: TextStyle(
        color: isSelected
            ? (themeService.isLightMode ? Colors.white : Colors.black)
            : AppColors.textSecondary,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (_) => themeService.setMapStyle(style),
    );
  }

  Widget _buildSectionCard(ThemeService themeService, {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: themeService.activeSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeService.isLightMode ? const Color(0xFFE2E8F0) : AppColors.surfaceLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: themeService.isLightMode ? const Color(0xFF0F172A) : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildLocationTile(
    BuildContext context,
    ThemeService themeService, {
    required String emoji,
    required String title,
    required String address,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    address,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_location_alt_rounded, color: themeService.activePrimaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeService themeService,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? themeService.activePrimaryColor.withOpacity(0.15)
              : themeService.activeSurfaceLightColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? themeService.activePrimaryColor : AppColors.surfaceHover,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? themeService.activePrimaryColor : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? themeService.activePrimaryColor : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
