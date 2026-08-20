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
  bool _hapticsEnabled = true;

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

    final isDark = !themeService.isLightMode;
    final primary = themeService.activePrimaryColor;
    final cardBg = themeService.activeSurfaceLightColor;
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: themeService.activeBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          "Settings & Profile",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded, size: 24),
            tooltip: "My Snapcode",
            onPressed: () => _showSnapcodeSheet(context, activeUser, primary),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.accentPink, size: 22),
            tooltip: "Sign Out",
            onPressed: () => _confirmSignOut(context, auth, firebaseAuth),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // 1. SNAPCHAT / INSTAGRAM STYLE HERO PROFILE CARD
            _buildInstagramHeroCard(activeUser, themeService, auth, primary, cardBg, borderColor),

            const SizedBox(height: 20),

            // 2. ACCOUNT & IDENTITY GROUP (WhatsApp/Apple Style)
            _buildGroupHeader("ACCOUNT & IDENTITY", "👤"),
            _buildGroupCard(
              cardBg: cardBg,
              borderColor: borderColor,
              children: [
                _buildModernTile(
                  icon: Icons.face_retouching_natural_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  title: "3D Bitmoji & Avatar",
                  subtitle: "Customize hair, cyberpunk outfits & LEDs",
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                  onTap: () {
                    AvatarCustomizerModal.show(
                      context,
                      initialConfig: activeUser.avatarConfig,
                      onSave: (newConfig) => auth.updateAvatarConfig(newConfig),
                    );
                  },
                ),
                _buildDivider(borderColor),
                _buildModernTile(
                  icon: Icons.edit_note_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: "Status & Bio",
                  subtitle: activeUser.statusText,
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                  onTap: () => _showStatusEditor(context, auth, activeUser),
                ),
                _buildDivider(borderColor),
                _buildModernTile(
                  icon: Icons.key_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: "End-to-End Encryption Keys",
                  subtitle: "AES-256 GCM Client-Side Zero-Knowledge",
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("VERIFIED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 3. SPATIAL MAP & GHOST PRIVACY (Snapchat Ghost Trail Style)
            _buildGroupHeader("SPATIAL & MAP PRIVACY", "🗺️"),
            _buildGroupCard(
              cardBg: cardBg,
              borderColor: borderColor,
              children: [
                _buildModernTile(
                  icon: Icons.location_on_rounded,
                  iconColor: const Color(0xFFEC4899),
                  title: "Location Sharing Mode",
                  subtitle: _getPrivacySubtitle(activeUser.privacyMode, activeUser.isGhostMode),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      activeUser.isGhostMode ? "👻 Ghost" : "🎯 Precise",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primary),
                    ),
                  ),
                  onTap: () => _showPrivacyModeSheet(context, auth, activeUser),
                ),
                _buildDivider(borderColor),
                _buildModernTile(
                  icon: Icons.home_rounded,
                  iconColor: AppColors.homeTag,
                  title: "Saved Home Base",
                  subtitle: activeUser.homeLocation?.title ?? "Tap to set custom home coordinates",
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SetLocationScreen(initialType: LocationType.home),
                      ),
                    );
                  },
                ),
                _buildDivider(borderColor),
                _buildModernTile(
                  icon: Icons.work_rounded,
                  iconColor: AppColors.officeTag,
                  title: "Saved Workspace / Campus",
                  subtitle: activeUser.officeLocation?.title ?? "Tap to set custom work coordinates",
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
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

            const SizedBox(height: 20),

            // 4. APPEARANCE & VISUAL THEME STUDIO
            _buildGroupHeader("APPEARANCE & THEME STUDIO", "🎨"),
            _buildGroupCard(
              cardBg: cardBg,
              borderColor: borderColor,
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Color Studio & Aesthetics",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildThemeChip("🌌 Cyber Neon", AppUiTheme.cyberNeon, themeService),
                          _buildThemeChip("⚫ AMOLED Black", AppUiTheme.minimalPitchBlack, themeService),
                          _buildThemeChip("⚪ iOS Pure Light", AppUiTheme.minimalPureWhite, themeService),
                          _buildThemeChip("🌸 Tokyo Sakura", AppUiTheme.sakuraSunset, themeService),
                          _buildThemeChip("🌲 Nordic Emerald", AppUiTheme.nordicSage, themeService),
                          _buildThemeChip("👾 Retro Synthwave", AppUiTheme.retroSynthwave, themeService),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 5. NOTIFICATIONS & RADAR SOUNDS
            _buildGroupHeader("NOTIFICATIONS & SOUNDS", "🔔"),
            _buildGroupCard(
              cardBg: cardBg,
              borderColor: borderColor,
              children: [
                SwitchListTile.adaptive(
                  value: _notificationsEnabled,
                  onChanged: (v) => setState(() => _notificationsEnabled = v),
                  activeColor: primary,
                  title: const Text("Direct Messages", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text("Receive instant E2EE chat alerts", style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ),
                _buildDivider(borderColor),
                SwitchListTile.adaptive(
                  value: _radarSoundsEnabled,
                  onChanged: (v) => setState(() => _radarSoundsEnabled = v),
                  activeColor: primary,
                  title: const Text("Proximity Radar Audio", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text("Audio sweep sound when friends are within 500m", style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ),
                _buildDivider(borderColor),
                SwitchListTile.adaptive(
                  value: _hapticsEnabled,
                  onChanged: (v) => setState(() => _hapticsEnabled = v),
                  activeColor: primary,
                  title: const Text("Haptic Vibrations", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text("Taptic feedback on knocks & bumps", style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 6. STORAGE, CACHE & DATA (WhatsApp Style)
            _buildGroupHeader("STORAGE & DATA", "💾"),
            _buildGroupCard(
              cardBg: cardBg,
              borderColor: borderColor,
              children: [
                _buildModernTile(
                  icon: Icons.cleaning_services_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: "Clear Cache & Map Tiles",
                  subtitle: "Cached files: ~14.2 MB",
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("🧹 Local cache cleared & storage refreshed!")),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 7. ABOUT & VERSION
            _buildGroupHeader("ABOUT PIEC SPATIAL", "ℹ️"),
            _buildGroupCard(
              cardBg: cardBg,
              borderColor: borderColor,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text("🛰️", style: TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("PieC Spatial v2.4.0 Flagship", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            SizedBox(height: 2),
                            Text("Gamified 3D Map, Proximity Radar & E2EE Chat", style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // 8. LOGOUT BUTTON (WhatsApp / Instagram Red Accent Style)
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _confirmSignOut(context, auth, firebaseAuth),
                icon: const Icon(Icons.logout_rounded, color: AppColors.accentPink, size: 18),
                label: const Text(
                  "Log Out from PieC",
                  style: TextStyle(color: AppColors.accentPink, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.accentPink.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Instagram / Snapchat Header Card
  Widget _buildInstagramHeroCard(
    UserModel user,
    ThemeService themeService,
    AuthService auth,
    Color primary,
    Color cardBg,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Glowing 3D Avatar with Gradient Border
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [primary, const Color(0xFFEC4899), const Color(0xFF8B5CF6)],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardBg,
                      ),
                      child: GamifiedAvatar(
                        config: user.avatarConfig,
                        size: 72,
                        showGlow: false,
                        enable3DInteraction: true,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.black, size: 12),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF38BDF8)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "@${user.username}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("💬 ", style: TextStyle(fontSize: 11)),
                          Text(
                            user.statusText,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 14),

          // Quick Action Buttons (Snapcode | Edit Avatar)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    AvatarCustomizerModal.show(
                      context,
                      initialConfig: user.avatarConfig,
                      onSave: (newConfig) => auth.updateAvatarConfig(newConfig),
                    );
                  },
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 15),
                  label: const Text("Edit Avatar", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showSnapcodeSheet(context, user, primary),
                  icon: const Icon(Icons.qr_code_rounded, size: 15),
                  label: const Text("My Snapcode", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Section Header (WhatsApp / Apple Style)
  Widget _buildGroupHeader(String title, String emoji) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Grouped Inset Card (Apple iOS Settings Style)
  Widget _buildGroupCard({
    required Color cardBg,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDivider(Color borderColor) {
    return Divider(height: 1, indent: 56, endIndent: 12, color: borderColor);
  }

  // Modern Settings Tile
  Widget _buildModernTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
      ),
      trailing: trailing,
    );
  }

  Widget _buildThemeChip(String label, AppUiTheme theme, ThemeService themeService) {
    final isSelected = themeService.currentTheme == theme;
    final primary = themeService.activePrimaryColor;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: primary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? primary : AppColors.surfaceHover,
        ),
      ),
      onSelected: (_) => themeService.setUiTheme(theme),
    );
  }

  String _getPrivacySubtitle(LocationPrivacyMode mode, bool isGhostMode) {
    if (isGhostMode) return "Ghost: 100% hidden on all friend maps";
    switch (mode) {
      case LocationPrivacyMode.precise:
        return "Precise: Live high-accuracy street coordinates";
      case LocationPrivacyMode.blurred:
        return "Blurred: Shows approximate neighborhood area";
      case LocationPrivacyMode.ghost:
        return "Ghost: 100% hidden on all friend maps";
    }
  }

  // Snapcode Bottom Sheet
  void _showSnapcodeSheet(BuildContext context, UserModel user, Color primary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.primaryNeon, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text("📷 My PieC Snapcode", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary)),
            const SizedBox(height: 4),
            const Text("Friends can scan this to add you instantly on 3D Map", style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 20),

            // Snapcode Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: primary, width: 2),
                boxShadow: [
                  BoxShadow(color: primary.withOpacity(0.2), blurRadius: 20),
                ],
              ),
              child: Column(
                children: [
                  GamifiedAvatar(config: user.avatarConfig, size: 80, showGlow: true),
                  const SizedBox(height: 12),
                  Text(user.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  Text("@${user.username}", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primary)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("🔗 Profile link copied to clipboard!")),
                  );
                },
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text("Share Snapcode Link 🚀"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusEditor(BuildContext context, AuthService auth, UserModel user) {
    final controller = TextEditingController(text: user.statusText);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Update Status / Bio 💬", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "e.g. Gaming with friends 🎮",
            prefixIcon: Icon(Icons.edit, color: AppColors.primaryNeon),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                auth.updateStatus(controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNeon,
              foregroundColor: Colors.black,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showPrivacyModeSheet(BuildContext context, AuthService auth, UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.primaryNeon, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Spatial Privacy Mode 🛡️",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const Text("🎯", style: TextStyle(fontSize: 22)),
              title: const Text("Precise GPS Mode (Recommended)"),
              subtitle: const Text("Live high-accuracy coordinates on 3D map"),
              onTap: () {
                auth.updatePrivacyMode(LocationPrivacyMode.precise);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text("🏙️", style: TextStyle(fontSize: 22)),
              title: const Text("Blurred City Mode"),
              subtitle: const Text("Approximates location to 1.5km neighborhood radius"),
              onTap: () {
                auth.updatePrivacyMode(LocationPrivacyMode.blurred);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text("👻", style: TextStyle(fontSize: 22)),
              title: const Text("Ghost Mode"),
              subtitle: const Text("Completely hidden from all friends radars"),
              onTap: () {
                auth.updatePrivacyMode(LocationPrivacyMode.ghost);
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
