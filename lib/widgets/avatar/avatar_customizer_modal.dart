import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/avatar_config.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';

class AvatarCustomizerModal extends StatefulWidget {
  final AvatarConfig initialConfig;
  final ValueChanged<AvatarConfig> onSave;

  const AvatarCustomizerModal({
    super.key,
    required this.initialConfig,
    required this.onSave,
  });

  static Future<AvatarConfig?> show(
    BuildContext context, {
    required AvatarConfig initialConfig,
    required ValueChanged<AvatarConfig> onSave,
  }) {
    return showModalBottomSheet<AvatarConfig>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AvatarCustomizerModal(
        initialConfig: initialConfig,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AvatarCustomizerModal> createState() => _AvatarCustomizerModalState();
}

class _AvatarCustomizerModalState extends State<AvatarCustomizerModal> {
  late AvatarConfig _currentConfig;
  int _selectedCategory = 0; // 0: Hair & Beard, 1: Eyes & Iris, 2: 3D Outfits, 3: Accessories, 4: Aura & Poses

  final List<int> _skinPalette = [
    0xFFFFD7B2,
    0xFFF5CBA7,
    0xFFE0AC69,
    0xFFC68642,
    0xFF8D5524,
    0xFF3D2314,
    0xFF00F0FF, // Alien Cyber
  ];

  final List<int> _hairPalette = [
    0xFF1C1427,
    0xFF2D1E12,
    0xFF5C3A21,
    0xFF00F0FF, // Cyan Neon
    0xFFFF2A85, // Pink Neon
    0xFFB026FF, // Purple
    0xFFFFD600, // Gold
    0xFF00FF9D, // Emerald
  ];

  final List<int> _outfitPalette = [
    0xFF6366F1, // Indigo
    0xFF00F0FF, // Cyan
    0xFFFF2A85, // Pink
    0xFF00FF9D, // Green
    0xFFFF6B00, // Orange
    0xFF1E293B, // Stealth Dark
    0xFFFFD700, // Cyber Gold
  ];

  @override
  void initState() {
    super.initState();
    _currentConfig = widget.initialConfig;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: AppColors.primaryNeon, width: 2),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: const Text(
                    'Snapchat 3D Avatar Studio 👾',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // 3D Orbit Interactive Stage Pedestal
          Container(
            height: 175,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  _currentConfig.glowColor.withOpacity(0.25),
                  AppColors.surfaceLight,
                  AppColors.surface,
                ],
                radius: 0.85,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.surfaceHover),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 12,
                  child: Container(
                    width: 140,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _currentConfig.glowColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: _currentConfig.glowColor.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                GamifiedAvatar(
                  config: _currentConfig,
                  size: 130,
                  showGlow: true,
                  enable3DInteraction: true,
                ),
                Positioned(
                  top: 10,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryNeon.withOpacity(0.4)),
                    ),
                    child: const Text(
                      '3D Touch Orbit 🔄',
                      style: TextStyle(fontSize: 10, color: AppColors.primaryNeon, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Category Bar
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryPill(0, '💇 Hair & Beard'),
                _buildCategoryPill(1, '👁️ Eyes & Iris'),
                _buildCategoryPill(2, '👕 3D Outfits'),
                _buildCategoryPill(3, '👑 Accessories'),
                _buildCategoryPill(4, '✨ Aura & Poses'),
              ],
            ),
          ),

          const Divider(color: AppColors.surfaceLight, height: 16),

          // Studio Customizer Category Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _buildCategoryContent(),
            ),
          ),

          // Action Save Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              border: Border(top: BorderSide(color: AppColors.surfaceHover, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _currentConfig = const AvatarConfig();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.surfaceHover),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Reset Model'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSave(_currentConfig);
                      Navigator.pop(context, _currentConfig);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNeon,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Save 3D Model ✨',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(int index, String label) {
    final isSelected = _selectedCategory == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNeon : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryNeon : AppColors.surfaceHover,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryContent() {
    switch (_selectedCategory) {
      case 0: // Hair & Beard
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('3D Sculpted Hairstyles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: HairStyle.values.map((style) {
                final isSelected = _currentConfig.hairStyle == style;
                return ChoiceChip(
                  label: Text(style.name.toUpperCase()),
                  selected: isSelected,
                  selectedColor: AppColors.primaryNeon,
                  backgroundColor: AppColors.surfaceLight,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  onSelected: (_) => setState(() => _currentConfig = _currentConfig.copyWith(hairStyle: style)),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Text('Hair Base Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Row(
              children: _hairPalette.map((colorHex) {
                final isSelected = _currentConfig.hairBaseColorHex == colorHex;
                return _buildColorCircle(
                  colorHex,
                  isSelected,
                  () => setState(() => _currentConfig = _currentConfig.copyWith(hairBaseColorHex: colorHex)),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Text('Neon Highlight Streak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Row(
              children: _hairPalette.map((colorHex) {
                final isSelected = _currentConfig.hairHighlightColorHex == colorHex;
                return _buildColorCircle(
                  colorHex,
                  isSelected,
                  () => setState(() => _currentConfig = _currentConfig.copyWith(hairHighlightColorHex: colorHex)),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Text('Facial Hair & Stubble', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FacialHair.values.map((fh) {
                final isSelected = _currentConfig.facialHair == fh;
                return ChoiceChip(
                  label: Text(fh.name.toUpperCase()),
                  selected: isSelected,
                  selectedColor: AppColors.primaryPurple,
                  backgroundColor: AppColors.surfaceLight,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  onSelected: (_) => setState(() => _currentConfig = _currentConfig.copyWith(facialHair: fh)),
                );
              }).toList(),
            ),
          ],
        );

      case 1: // Eyes & Iris
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Glowing 3D Iris Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: IrisColor.values.map((iris) {
                final isSelected = _currentConfig.irisColor == iris;
                return GestureDetector(
                  onTap: () => setState(() => _currentConfig = _currentConfig.copyWith(irisColor: iris)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryNeon.withOpacity(0.2) : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryNeon : AppColors.surfaceHover,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      iris.name.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: isSelected ? AppColors.primaryNeon : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Skin Undertone & Complexion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Row(
              children: _skinPalette.map((colorHex) {
                final isSelected = _currentConfig.skinColorHex == colorHex;
                return _buildColorCircle(
                  colorHex,
                  isSelected,
                  () => setState(() => _currentConfig = _currentConfig.copyWith(
                        skinColorHex: colorHex,
                        skinShadowHex: (colorHex - 0x1F2020),
                      )),
                );
              }).toList(),
            ),
          ],
        );

      case 2: // 3D Outfits
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('3D Cyber & Streetwear Wardrobe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: OutfitStyle.values.map((outfit) {
                final isSelected = _currentConfig.outfitStyle == outfit;
                return GestureDetector(
                  onTap: () => setState(() => _currentConfig = _currentConfig.copyWith(outfitStyle: outfit)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryNeon.withOpacity(0.2) : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryNeon : AppColors.surfaceHover,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      outfit.name.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isSelected ? AppColors.primaryNeon : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Outfit Primary Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Row(
              children: _outfitPalette.map((colorHex) {
                final isSelected = _currentConfig.outfitPrimaryColorHex == colorHex;
                return _buildColorCircle(
                  colorHex,
                  isSelected,
                  () => setState(() => _currentConfig = _currentConfig.copyWith(outfitPrimaryColorHex: colorHex)),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Text('Neon Trim / Accent Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Row(
              children: _outfitPalette.map((colorHex) {
                final isSelected = _currentConfig.outfitSecondaryColorHex == colorHex;
                return _buildColorCircle(
                  colorHex,
                  isSelected,
                  () => setState(() => _currentConfig = _currentConfig.copyWith(outfitSecondaryColorHex: colorHex)),
                );
              }).toList(),
            ),
          ],
        );

      case 3: // Accessories
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('3D Cyber Accessories & Wearables', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AvatarAccessory.values.map((acc) {
                final isSelected = _currentConfig.accessory == acc;
                return GestureDetector(
                  onTap: () => setState(() => _currentConfig = _currentConfig.copyWith(accessory: acc)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryNeon.withOpacity(0.2) : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryNeon : AppColors.surfaceHover,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      acc.name.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isSelected ? AppColors.primaryNeon : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );

      case 4: // Aura & Poses
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Particle Aura FX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AvatarAuraEffect.values.map((aura) {
                final isSelected = _currentConfig.auraEffect == aura;
                return ChoiceChip(
                  label: Text(aura.name.toUpperCase()),
                  selected: isSelected,
                  selectedColor: AppColors.primaryPurple,
                  backgroundColor: AppColors.surfaceLight,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  onSelected: (_) => setState(() => _currentConfig = _currentConfig.copyWith(auraEffect: aura)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Avatar Stance & 3D Pose', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AvatarPose.values.map((pose) {
                final isSelected = _currentConfig.pose == pose;
                return ChoiceChip(
                  label: Text(pose.name.toUpperCase()),
                  selected: isSelected,
                  selectedColor: AppColors.primaryNeon,
                  backgroundColor: AppColors.surfaceLight,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  onSelected: (_) => setState(() => _currentConfig = _currentConfig.copyWith(pose: pose)),
                );
              }).toList(),
            ),
          ],
        );
    }
  }

  Widget _buildColorCircle(int colorHex, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Color(colorHex),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(colorHex).withOpacity(0.8),
                    blurRadius: 10,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}
