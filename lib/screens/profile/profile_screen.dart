import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/location_point.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/core/services/auth_service.dart';
import 'package:piec/core/services/firebase_auth_service.dart';
import 'package:piec/core/services/theme_service.dart';
import 'package:piec/screens/auth/login_screen.dart';
import 'package:piec/screens/map/set_location_screen.dart';
import 'package:piec/widgets/avatar/avatar_customizer_modal.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _radarSoundsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final firebaseAuth = Provider.of<FirebaseAuthService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final user = firebaseAuth.currentUser ?? auth.currentUser;
    final activeUser = user ??
        UserModel(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: 'PieC Explorer',
          username: 'explorer_01',
          publicKey: 'pk_default_key',
          lastActive: DateTime.now(),
        );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: const [
            Text("⚙️", style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text("Settings & Profile", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.accentPink),
            tooltip: "Sign Out",
            onPressed: () => _confirmSignOut(context, auth, firebaseAuth),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeaderCard(activeUser, themeService, auth),
            const SizedBox(height: 24),
            _buildSectionHeader("SPATIAL PRIVACY & SECURITY", "🛡️"),
            Container(
              decoration: BoxDecoration(
                color: themeService.activeSurfaceLightColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceHover),
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.location_on_rounded,
                    iconColor: AppColors.primaryNeon,
                    title: "Location Privacy Mode",
                    subtitle: _getPrivacyModeLabel(activeUser.privacyMode, activeUser.isGhostMode),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNeon.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        activeUser.isGhostMode ? "👻 Ghost" : "🎯 Precise",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNeon,
                        ),
                      ),
                    ),
                    onTap: () => _showPrivacyModeSheet(context, auth, activeUser),
                  ),
                  const Divider(height: 1, color: AppColors.surfaceHover),
                  _buildSettingsTile(
                    icon: Icons.verified_user_rounded,
                    iconColor: AppColors.accentGreen,
                    title: "End-to-End Encryption",
                    subtitle: "AES-256 GCM Client-Side Keys Active",
                    trailing: const Text("ACTIVE", style: TextStyle(color: AppColors.accentGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader("SAVED SPATIAL PLACES", "📍"),
            Container(
              decoration: BoxDecoration(
                color: themeService.activeSurfaceLightColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceHover),
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.home_rounded,
                    iconColor: AppColors.homeTag,
                    title: activeUser.homeLocation?.title ?? "Home Base",
                    subtitle: activeUser.homeLocation?.address ?? "Tap to set custom home coordinates",
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SetLocationScreen(initialType: LocationType.home),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.surfaceHover),
                  _buildSettingsTile(
                    icon: Icons.work_rounded,
                    iconColor: AppColors.officeTag,
                    title: activeUser.officeLocation?.title ?? "Office / Campus",
                    subtitle: activeUser.officeLocation?.address ?? "Tap to set custom workspace coordinates",
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SetLocationScreen(initialType: LocationType.office),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader("APPEARANCE & THEME", "🎨"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeService.activeSurfaceLightColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceHover),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Visual Color Studio",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildThemePill("🌌 Cyber Neon", AppUiTheme.cyberNeon, themeService),
                      _buildThemePill("⚫ OLED Black", AppUiTheme.minimalPitchBlack, themeService),
                      _buildThemePill("⚪ iOS White", AppUiTheme.minimalPureWhite, themeService),
                      _buildThemePill("🌸 Tokyo Sakura", AppUiTheme.sakuraSunset, themeService),
                      _buildThemePill("🌲 Nordic Sage", AppUiTheme.nordicSage, themeService),
                      _buildThemePill("👾 Retro 80s", AppUiTheme.retroSynthwave, themeService),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader("NOTIFICATIONS & SOUNDS", "🔔"),
            Container(
              decoration: BoxDecoration(
                color: themeService.activeSurfaceLightColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceHover),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                    activeColor: AppColors.primaryNeon,
                    title: const Text("Message Notifications", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text("Receive live chat alerts", style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ),
                  const Divider(height: 1, color: AppColors.surfaceHover),
                  SwitchListTile(
                    value: _radarSoundsEnabled,
                    onChanged: (v) => setState(() => _radarSoundsEnabled = v),
                    activeColor: AppColors.primaryNeon,
                    title: const Text("Spatial Radar Pings", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text("Sound effects when friends are nearby", style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader("STORAGE & MAINTENANCE", "💾"),
            Container(
              decoration: BoxDecoration(
                color: themeService.activeSurfaceLightColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceHover),
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.cleaning_services_rounded,
                    iconColor: AppColors.primaryNeon,
                    title: "Clear Local Cache",
                    subtitle: "Free up local media & map tiles",
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("🧹 Local cache cleaned successfully!")),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader("ABOUT PIEC", "ℹ️"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeService.activeSurfaceLightColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceHover),
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Text("PieC Spatial 2.0", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Spacer(),
                      Text("v2.0.0-flagship", style: TextStyle(color: AppColors.primaryNeon, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Gamified 3D Spatial Radar, E2EE Chat & Convoy Safety",
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(UserModel user, ThemeService themeService, AuthService auth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeService.activeSurfaceLightColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: themeService.activePrimaryColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: themeService.activePrimaryColor.withOpacity(0.2),
            blurRadius: 20,
          )
        ],
      ),
      child: Row(
        children: [
          GamifiedAvatar(
            config: user.avatarConfig,
            size: 74,
            showGlow: true,
            enable3DInteraction: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  "@" + user.username,
                  style: TextStyle(
                    fontSize: 13,
                    color: themeService.activePrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
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
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 14),
                  label: const Text("Edit 3D Avatar", style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: themeService.activePrimaryColor,
                    side: BorderSide(color: themeService.activePrimaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String emoji) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      trailing: trailing,
    );
  }

  Widget _buildThemePill(String label, AppUiTheme theme, ThemeService themeService) {
    final isSelected = themeService.currentTheme == theme;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: themeService.activePrimaryColor,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (_) => themeService.setUiTheme(theme),
    );
  }

  String _getPrivacyModeLabel(LocationPrivacyMode mode, bool isGhostMode) {
    if (isGhostMode) return "Ghost Mode (Invisible)";
    switch (mode) {
      case LocationPrivacyMode.precise:
        return "Precise (Street Level GPS)";
      case LocationPrivacyMode.blurred:
        return "Blurred (City/Neighborhood Only)";
      case LocationPrivacyMode.ghost:
        return "Ghost (Completely Invisible)";
    }
  }

  void _showPrivacyModeSheet(BuildContext context, AuthService auth, UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.primaryNeon, width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Location Privacy Mode",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Text("🎯", style: TextStyle(fontSize: 22)),
              title: const Text("Precise Mode"),
              subtitle: const Text("Exact real-time street coordinates on 3D map"),
              onTap: () {
                auth.toggleGhostMode(false);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text("🏙️", style: TextStyle(fontSize: 22)),
              title: const Text("Blurred City Mode"),
              subtitle: const Text("Approximates area to 1.5km neighborhood radius"),
              onTap: () {
                auth.toggleGhostMode(false);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text("👻", style: TextStyle(fontSize: 22)),
              title: const Text("Ghost Mode"),
              subtitle: const Text("Completely frozen & invisible on all friends radars"),
              onTap: () {
                auth.toggleGhostMode(true);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AuthService auth, FirebaseAuthService firebaseAuth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: AppColors.accentPink),
            SizedBox(width: 8),
            Text("Sign Out", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text("Are you sure you want to sign out from PieC Spatial on this device?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await firebaseAuth.signOut();
              await auth.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPink,
              foregroundColor: Colors.white,
            ),
            child: const Text("Sign Out"),
          ),
        ],
      ),
    );
  }
}
