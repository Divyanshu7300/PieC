import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/location_point.dart';
import 'package:piec/core/models/story_model.dart';
import 'package:piec/core/services/auth_service.dart';
import 'package:piec/core/services/squad_service.dart';
import 'package:piec/core/services/story_service.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';
import 'package:provider/provider.dart';

class CreateStoryModal extends StatefulWidget {
  const CreateStoryModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateStoryModal(),
    );
  }

  @override
  State<CreateStoryModal> createState() => _CreateStoryModalState();
}

class _CreateStoryModalState extends State<CreateStoryModal> {
  AvatarSceneType _selectedScene = AvatarSceneType.cafeCoffee;
  final TextEditingController _captionController = TextEditingController();

  String? _selectedMusic = 'Lo-Fi Tokyo Chill 🎵';
  bool _tagLocation = true;
  String? _selectedSquadId;
  int _expiryHours = 24;

  final List<String> _musicTracks = [
    'Lo-Fi Tokyo Chill 🎵',
    'Cyberpunk Neon Pulse 🎵',
    'Midnight Synth Drive 🎵',
    'Bass Boosted Workout 🎵',
    'Rainy Day Lo-Fi 🎵',
    'No Music',
  ];

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final squadService = Provider.of<SquadService>(context);
    final storyService = Provider.of<StoryService>(context);
    final currentUser = auth.currentUser;

    if (currentUser == null) return const SizedBox();

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: AppColors.primaryNeon, width: 2)),
      ),
      child: Column(
        children: [
          // Drag Handle
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
                const Text(
                  'Post 3D Spatial Story 👾✨',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live 3D Avatar Preview in Selected Scene
                  Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: _getSceneGradient(_selectedScene),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.primaryNeon.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          GamifiedAvatar(
                            config: currentUser.avatarConfig,
                            size: 100,
                            showGlow: true,
                            enable3DInteraction: true,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _getSceneTitle(_selectedScene),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 1. Choose 3D Avatar Scene
                  const Text('1. Choose 3D Avatar Mood Scene 🎭', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AvatarSceneType.values.map((scene) {
                      final isSelected = _selectedScene == scene;
                      return ChoiceChip(
                        label: Text(_getSceneTitle(scene)),
                        selected: isSelected,
                        selectedColor: AppColors.primaryNeon,
                        backgroundColor: AppColors.surfaceLight,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setState(() => _selectedScene = scene),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // 2. Story Caption
                  const Text('2. Add Story Caption 💬', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _captionController,
                    decoration: const InputDecoration(
                      hintText: 'What is happening right now...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Background Music Track
                  const Text('3. Background Vibe Music 🎵', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _musicTracks.map((track) {
                      final isSelected = _selectedMusic == track;
                      return ChoiceChip(
                        label: Text(track),
                        selected: isSelected,
                        selectedColor: AppColors.primaryPurple,
                        backgroundColor: AppColors.surfaceLight,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) => setState(() => _selectedMusic = track == 'No Music' ? null : track),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // 4. Spatial Map Geo-Drop Tag
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('📍 Pin Story on World Map (Geo-Drop)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text(
                      'Shows an animated glowing story bubble directly on the map for your friends',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    value: _tagLocation,
                    activeColor: AppColors.primaryNeon,
                    onChanged: (val) => setState(() => _tagLocation = val),
                  ),

                  const SizedBox(height: 12),

                  // 5. Expiry Timer
                  Row(
                    children: [
                      const Text('⏳ Expiry: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 10),
                      _buildExpiryChip('24 Hours', 24),
                      const SizedBox(width: 8),
                      _buildExpiryChip('6 Hours', 6),
                      const SizedBox(width: 8),
                      _buildExpiryChip('1-View Snap 💣', 1),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Post Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              border: Border(top: BorderSide(color: AppColors.surfaceHover)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  LocationPoint? loc;
                  if (_tagLocation) {
                    loc = currentUser.liveLocation ?? currentUser.homeLocation;
                  }

                  await storyService.postStory(
                    currentUser: currentUser,
                    sceneType: _selectedScene,
                    caption: _captionController.text.trim(),
                    musicTrack: _selectedMusic,
                    locationPoint: loc,
                    squadId: _selectedSquadId,
                    duration: Duration(hours: _expiryHours),
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('3D Spatial Story published to Map & Feed! 🚀✨')),
                    );
                  }
                },
                icon: const Icon(Icons.auto_awesome_rounded, color: Colors.black),
                label: const Text('Share to Spatial Story 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNeon,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryChip(String label, int hours) {
    final isSelected = _expiryHours == hours;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryNeon,
      backgroundColor: AppColors.surfaceLight,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (_) => setState(() => _expiryHours = hours),
    );
  }

  String _getSceneTitle(AvatarSceneType scene) {
    switch (scene) {
      case AvatarSceneType.cafeCoffee:
        return '☕ Cafe Brew & Chill';
      case AvatarSceneType.gamingRig:
        return '🎮 VR Gaming Matrix';
      case AvatarSceneType.carDrive:
        return '🚗 Night Highway Drive';
      case AvatarSceneType.pizzaLateNight:
        return '🍕 Late Night Slice';
      case AvatarSceneType.gymWorkout:
        return '🏋️ Beast Mode Gym';
      case AvatarSceneType.beachSunset:
        return '🏖️ Sunset Beach';
      case AvatarSceneType.chillLoFi:
      default:
        return '🎧 Lo-Fi Focus';
    }
  }

  Gradient _getSceneGradient(AvatarSceneType scene) {
    switch (scene) {
      case AvatarSceneType.cafeCoffee:
        return const LinearGradient(colors: [Color(0xFF3B1E08), Color(0xFF1A0E04)]);
      case AvatarSceneType.gamingRig:
        return const LinearGradient(colors: [Color(0xFF1E1035), Color(0xFF0B0D17)]);
      case AvatarSceneType.carDrive:
        return const LinearGradient(colors: [Color(0xFF1A0B2E), Color(0xFF0F041D)]);
      case AvatarSceneType.pizzaLateNight:
        return const LinearGradient(colors: [Color(0xFF3B0B14), Color(0xFF1F060A)]);
      case AvatarSceneType.gymWorkout:
        return const LinearGradient(colors: [Color(0xFF062A1E), Color(0xFF03140F)]);
      case AvatarSceneType.beachSunset:
        return const LinearGradient(colors: [Color(0xFF3B122D), Color(0xFF1F0A1A)]);
      case AvatarSceneType.chillLoFi:
      default:
        return const LinearGradient(colors: [Color(0xFF1A1A3A), Color(0xFF0C0C1F)]);
    }
  }
}
