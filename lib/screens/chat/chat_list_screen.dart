import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/core/services/auth_service.dart';
import 'package:piec/core/services/chat_service.dart';
import 'package:piec/screens/chat/chat_room_screen.dart';
import 'package:piec/screens/friends/add_friends_hub_modal.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';
import 'package:piec/widgets/stories/stories_tray.dart';
import 'package:provider/provider.dart';

class ChatListScreen extends StatefulWidget {
  final Function(UserModel friend)? onVisitOnMap;

  const ChatListScreen({super.key, this.onVisitOnMap});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final chatService = Provider.of<ChatService>(context);

    final filteredFriends = chatService.friends.where((f) {
      final nameMatches = f.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final usernameMatches = f.username.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatches || usernameMatches;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: const Text(
                'Encrypted Chats',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryNeon.withOpacity(0.3)),
              ),
              child: const Text(
                'E2EE 🔒',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNeon,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primaryNeon),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.accentPink,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '2',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            tooltip: 'Add Friends & Pending Requests',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Scaffold(body: AddFriendsHubModal())),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 🌟 3D Spatial Stories Tray (Snapchat/Instagram style)
          const StoriesTray(),
          const Divider(color: AppColors.surfaceLight, height: 1),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search friends, @usernames, or rooms...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          const Divider(color: AppColors.surfaceLight, height: 1),

          // Chat Conversations List
          Expanded(
            child: filteredFriends.isEmpty
                ? const Center(
                    child: Text(
                      'No friends found',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredFriends.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppColors.surfaceLight, height: 1, indent: 76),
                    itemBuilder: (context, index) {
                      final friend = filteredFriends[index];
                      final lastMsg = chatService.getLastMessageForFriend(friend.id);
                      final timeStr = lastMsg != null
                          ? DateFormat('hh:mm a').format(lastMsg.timestamp)
                          : '';

                      return ListTile(
                        tileColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatRoomScreen(friend: friend),
                            ),
                          );
                        },
                        leading: Stack(
                          children: [
                            GamifiedAvatar(
                              config: friend.avatarConfig,
                              size: 52,
                              showGlow: false,
                              isAnimated: false,
                            ),
                            if (friend.isOnline)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppColors.online,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.surface, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                friend.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            const Icon(
                              Icons.lock_rounded,
                              size: 11,
                              color: AppColors.primaryNeon,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lastMsg?.decryptedContent ?? friend.statusText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (lastMsg?.reactionEmoji != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  lastMsg!.reactionEmoji!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                        trailing: widget.onVisitOnMap != null
                            ? IconButton(
                                icon: const Icon(
                                  Icons.location_searching_rounded,
                                  color: AppColors.primaryNeon,
                                  size: 20,
                                ),
                                tooltip: 'Visit on Map',
                                onPressed: () => widget.onVisitOnMap!(friend),
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
