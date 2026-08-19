import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/location_point.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/core/services/auth_service.dart';
import 'package:piec/core/services/chat_service.dart';
import 'package:piec/core/services/squad_service.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';
import 'package:provider/provider.dart';

class CreateSquadModal extends StatefulWidget {
  const CreateSquadModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateSquadModal(),
    );
  }

  @override
  State<CreateSquadModal> createState() => _CreateSquadModalState();
}

class _CreateSquadModalState extends State<CreateSquadModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _meetupTitleController = TextEditingController();
  final TextEditingController _meetupAddressController = TextEditingController();

  String _selectedEmoji = '🎮';
  bool _isTemporary = false;
  final List<String> _selectedFriendIds = [];

  final List<String> _emojis = ['🎮', '🏖️', '🍕', '🎓', '🚗', '💼', '⚽', '⛺', '🚀', '🔥'];

  @override
  void dispose() {
    _nameController.dispose();
    _meetupTitleController.dispose();
    _meetupAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final squadService = Provider.of<SquadService>(context);
    final auth = Provider.of<AuthService>(context);
    final currentUser = auth.currentUser;

    final friends = chatService.friends;

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
                const Text(
                  'Create Spatial Squad / Circle 👥',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
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
                  const Text(
                    'When active, the World Map will filter to show ONLY this squad members!',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),

                  // Emoji & Name Input Row
                  Row(
                    children: [
                      // Emoji Picker Dropdown Button
                      GestureDetector(
                        onTap: () => _showEmojiPicker(),
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primaryNeon),
                          ),
                          alignment: Alignment.center,
                          child: Text(_selectedEmoji, style: const TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'Squad Name (e.g. Goa Trip Crew)',
                            labelText: 'Squad Name',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Temporary Trip Mode Switch
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isTemporary
                            ? AppColors.accentPink.withOpacity(0.5)
                            : AppColors.surfaceHover,
                      ),
                    ),
                    child: SwitchListTile(
                      tileColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: const [
                          Text('⏳ Temporary Trip / Event Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      subtitle: const Text(
                        'Auto-expires in 24 hours (Location sharing stops automatically after the hangout)',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      value: _isTemporary,
                      activeColor: AppColors.accentPink,
                      onChanged: (val) => setState(() => _isTemporary = val),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Add Members Checklist
                  const Text(
                    'Select Squad Members 👾',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: friends.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      final isSelected = _selectedFriendIds.contains(friend.id);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedFriendIds.remove(friend.id);
                            } else {
                              _selectedFriendIds.add(friend.id);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryNeon.withOpacity(0.12)
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryNeon
                                  : AppColors.surfaceHover,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              GamifiedAvatar(config: friend.avatarConfig, size: 40, showGlow: false),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(friend.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('@${friend.username}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                color: isSelected ? AppColors.primaryNeon : AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Optional Initial Meetup Pin
                  const Text(
                    'Shared Meetup Destination (Optional) 🚩',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _meetupTitleController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Cyber Cafe / Beach Resort',
                      labelText: 'Meetup Place Title',
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Action
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
                  final name = _nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a Squad name')),
                    );
                    return;
                  }

                  if (currentUser != null) {
                    final selectedFriends = friends
                        .where((f) => _selectedFriendIds.contains(f.id))
                        .toList();

                    LocationPoint? meetup;
                    if (_meetupTitleController.text.trim().isNotEmpty) {
                      meetup = LocationPoint(
                        title: _meetupTitleController.text.trim(),
                        address: 'Squad Meetup Rendezvous Point',
                        latitude: 28.6180,
                        longitude: 77.2120,
                        type: LocationType.hangout,
                        updatedAt: DateTime.now(),
                      );
                    }

                    await squadService.createSquad(
                      name: name,
                      emoji: _selectedEmoji,
                      currentUser: currentUser,
                      selectedFriends: selectedFriends,
                      initialMeetupPin: meetup,
                      isTemporary: _isTemporary,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Squad "$name" created! Map is now filtered to this squad 🚀')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.group_add_rounded, color: Colors.black),
                label: const Text('Create Squad & Filter Map 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _showEmojiPicker() {
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
            const Text('Choose Squad Icon Emoji', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _emojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedEmoji = emoji);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceHover),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
