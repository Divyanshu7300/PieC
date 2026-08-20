import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/call_session_model.dart';
import 'package:piec/core/models/message_model.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/core/services/auth_service.dart';
import 'package:piec/core/services/firebase_auth_service.dart';
import 'package:piec/core/services/firestore_chat_service.dart';
import 'package:piec/core/services/call_service.dart';
import 'package:piec/core/services/chat_service.dart';
import 'package:piec/screens/call/active_call_screen.dart';
import 'package:piec/screens/p2p/fastdrop_hub_modal.dart';
import 'package:piec/screens/profile/security_screen.dart';
import 'package:piec/widgets/chat/avatar_chat_header.dart';
import 'package:piec/widgets/chat/chat_bubble.dart';
import 'package:piec/widgets/chat/reaction_bar.dart';
import 'package:provider/provider.dart';

class ChatRoomScreen extends StatefulWidget {
  final UserModel friend;

  const ChatRoomScreen({super.key, required this.friend});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (auth.currentUser != null) {
        Provider.of<FirestoreChatService>(context, listen: false).markAsRead(
          auth.currentUser!.id,
          widget.friend.id,
          auth.currentUser!.id,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final chatService = Provider.of<ChatService>(context);
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final messages = chatService.getMessagesForFriend(widget.friend.id);
    final isTyping = chatService.typingUsers[widget.friend.id] ?? false;
    final activeReaction = chatService.activeAvatarReactions[widget.friend.id];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.friend.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.friend.isOnline ? 'Online • In Spatial Hangout' : 'Offline',
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.friend.isOnline ? AppColors.online : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Audio Call Button
          IconButton(
            icon: const Icon(Icons.call_rounded, color: AppColors.primaryNeon),
            tooltip: 'Spatial Audio Call',
            onPressed: () {
              if (currentUser != null) {
                final callService = Provider.of<CallService>(context, listen: false);
                callService.startCall(
                  caller: currentUser,
                  receiver: widget.friend,
                  type: CallType.audio,
                );
                ActiveCallScreen.show(context);
              }
            },
          ),
          // 3D Avatar Video Call Button
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: AppColors.primaryNeon),
            tooltip: '3D Avatar Video Call',
            onPressed: () {
              if (currentUser != null) {
                final callService = Provider.of<CallService>(context, listen: false);
                callService.startCall(
                  caller: currentUser,
                  receiver: widget.friend,
                  type: CallType.avatarVideo,
                );
                ActiveCallScreen.show(context);
              }
            },
          ),
          // Security Lock Icon
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: AppColors.primaryNeon),
            tooltip: 'E2EE Safety Numbers',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SecurityScreen(
                    currentUser: currentUser,
                    friendUser: widget.friend,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Interactive Dual Avatar Dynamic Header
          AvatarChatHeader(
            currentUser: currentUser,
            friendUser: widget.friend,
            isFriendTyping: isTyping,
            activeReaction: activeReaction,
            onSecurityTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SecurityScreen(
                    currentUser: currentUser,
                    friendUser: widget.friend,
                  ),
                ),
              );
            },
          ),

          // Message List Stream (Live Multi-Device Firestore Stream + Local Cache)
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: Provider.of<FirestoreChatService>(context, listen: false)
                  .messagesStream(currentUser.id, widget.friend.id, currentUser.id),
              builder: (context, snapshot) {
                final displayMessages = (snapshot.hasData && snapshot.data!.isNotEmpty)
                    ? snapshot.data!
                    : messages;

                if (displayMessages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline_rounded, color: AppColors.primaryNeon, size: 36),
                        const SizedBox(height: 10),
                        const Text(
                          'End-to-End Encrypted Chat',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Say hi to ${widget.friend.name}! 👋',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: displayMessages.length,
                  itemBuilder: (context, index) {
                    final msg = displayMessages[index];
                    return ChatBubble(
                      message: msg,
                      onLongPress: () {
                        MessageDetailsModal.show(
                          context,
                          message: msg,
                          onSelectReaction: (emoji) {
                            chatService.addReaction(widget.friend.id, msg.id, emoji);
                          },
                        );
                      },
                      onAddReaction: (emoji) {
                        chatService.addReaction(widget.friend.id, msg.id, emoji);
                      },
                    );
                  },
                );
              },
            ),
          ),


          // Quick Reaction Row Bar
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickActionPill('👋 Wave', () {
                  chatService.sendMessage(
                    currentUserId: currentUser.id,
                    friendId: widget.friend.id,
                    text: '👋 *Avatar waved at you!*',
                    avatarReaction: '👋',
                  );
                  _scrollToBottom();
                }),
                _buildQuickActionPill('🏠 Visiting you', () {
                  chatService.sendMessage(
                    currentUserId: currentUser.id,
                    friendId: widget.friend.id,
                    text: '🏠 *I just visited your place on the map!*',
                    avatarReaction: '🏠',
                  );
                  _scrollToBottom();
                }),
                _buildQuickActionPill('🔥 Fire', () {
                  chatService.sendMessage(
                    currentUserId: currentUser.id,
                    friendId: widget.friend.id,
                    text: '🔥 *Avatar is super hyped!*',
                    avatarReaction: '🔥',
                  );
                  _scrollToBottom();
                }),
                _buildQuickActionPill('❤️ Love', () {
                  chatService.sendMessage(
                    currentUserId: currentUser.id,
                    friendId: widget.friend.id,
                    text: '❤️ *Sending heart energy!*',
                    avatarReaction: '❤️',
                  );
                  _scrollToBottom();
                }),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Chat Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.surfaceLight, width: 1)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Rich Media Attachment Hub Button
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded,
                        color: AppColors.primaryNeon, size: 24),
                    tooltip: 'Send Photo, Video, Document or Location',
                    onPressed: () => _showAttachmentSheet(context, currentUser, chatService),
                  ),

                  // Text Field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(currentUser.id, chatService),
                      decoration: InputDecoration(
                        hintText: 'End-to-End Encrypted message...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.mic_none_rounded, color: AppColors.primaryNeon),
                          tooltip: 'Send Voice Note',
                          onPressed: () {
                            chatService.sendMessage(
                              currentUserId: currentUser.id,
                              friendId: widget.friend.id,
                              text: '🎙️ [Voice Audio Note]',
                              type: MessageType.audio,
                              audioDuration: '0:14',
                            );
                            _scrollToBottom();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Encrypted Voice Note sent! 🎙️🔒')),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send Button
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                      onPressed: () => _sendMessage(currentUser.id, chatService),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionPill(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceHover),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _sendMessage(String currentUserId, ChatService chatService) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final firestoreChat = Provider.of<FirestoreChatService>(context, listen: false);
    firestoreChat.sendMessage(
      senderId: currentUserId,
      receiverId: widget.friend.id,
      text: text,
    );

    chatService.sendMessage(
      currentUserId: currentUserId,
      friendId: widget.friend.id,
      text: text,
    );

    _textController.clear();
    _scrollToBottom();
  }

  void _showAttachmentSheet(BuildContext context, UserModel? currentUser, ChatService chatService) {
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.primaryNeon, width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share Encrypted Media & Location 📎',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'All attachments are encrypted on-device before transmission',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Photo
                _buildAttachmentOption(
                  emoji: '📸',
                  label: 'Photo',
                  color: AppColors.accentPink,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPhotoPickerSheet(context, currentUser, chatService);
                  },
                ),

                // 2. Video
                _buildAttachmentOption(
                  emoji: '🎥',
                  label: 'Video Clip',
                  color: AppColors.primaryPurple,
                  onTap: () {
                    Navigator.pop(ctx);
                    chatService.sendMessage(
                      currentUserId: currentUser.id,
                      friendId: widget.friend.id,
                      text: '🎥 Sent an encrypted video clip (0:24)',
                      type: MessageType.video,
                    );
                    _scrollToBottom();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Encrypted Video sent! 🎥🔒')),
                    );
                  },
                ),

                // 3. Document / File
                _buildAttachmentOption(
                  emoji: '📄',
                  label: 'Document',
                  color: AppColors.accentYellow,
                  onTap: () {
                    Navigator.pop(ctx);
                    chatService.sendMessage(
                      currentUserId: currentUser.id,
                      friendId: widget.friend.id,
                      text: '📄 Project_Draft_v2.pdf',
                      type: MessageType.document,
                      fileName: 'Project_Draft_v2.pdf',
                      fileSize: '3.8 MB • PDF',
                    );
                    _scrollToBottom();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Encrypted Document sent! 📄🔒')),
                    );
                  },
                ),

                // 4. Location Pin
                _buildAttachmentOption(
                  emoji: '📍',
                  label: 'Map Pin',
                  color: AppColors.homeTag,
                  onTap: () {
                    Navigator.pop(ctx);
                    final loc = currentUser.liveLocation ?? currentUser.homeLocation;
                    chatService.sendMessage(
                      currentUserId: currentUser.id,
                      friendId: widget.friend.id,
                      text: '📍 Spatial Location Pin',
                      type: MessageType.location,
                      locationData: loc,
                    );
                    _scrollToBottom();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Spatial Map Location Pin shared! 📍🗺️')),
                    );
                  },
                ),

                // 5. FastDrop P2P (No Net / Multi-GB)
                _buildAttachmentOption(
                  emoji: '⚡',
                  label: 'FastDrop',
                  color: const Color(0xFF38BDF8),
                  onTap: () {
                    Navigator.pop(ctx);
                    FastDropHubModal.show(context, preselectedFriend: widget.friend);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required String emoji,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showPhotoPickerSheet(BuildContext context, UserModel currentUser, ChatService chatService) {
    final photoPresets = [
      {'title': 'Cyberpunk Selfie 📸', 'url': 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600&q=80', 'tag': 'Avatar'},
      {'title': 'World Map View 🗺️', 'url': 'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=600&q=80', 'tag': 'Spatial'},
      {'title': 'Cyber City Lights 🏙️', 'url': 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600&q=80', 'tag': 'City'},
      {'title': 'Tokyo Sunset 🌸', 'url': 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=600&q=80', 'tag': 'Travel'},
      {'title': 'Convoy Highway 🏎️', 'url': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=600&q=80', 'tag': 'Drive'},
      {'title': 'Café Spot ☕', 'url': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600&q=80', 'tag': 'Base'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.primaryNeon, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Encrypted Photo 📸',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photoPresets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = photoPresets[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      final firestoreChat = Provider.of<FirestoreChatService>(context, listen: false);
                      firestoreChat.sendMessage(
                        senderId: currentUser.id,
                        receiverId: widget.friend.id,
                        text: item['title']!,
                        type: MessageType.image,
                        mediaUrl: item['url'],
                      );
                      chatService.sendMessage(
                        currentUserId: currentUser.id,
                        friendId: widget.friend.id,
                        text: item['title']!,
                        type: MessageType.image,
                        mediaUrl: item['url'],
                      );
                      _scrollToBottom();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Encrypted ${item['title']} sent! 📸🔒')),
                      );
                    },
                    child: Container(
                      width: 130,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryNeon.withOpacity(0.4)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              item['url']!,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              right: 8,
                              child: Text(
                                item['title']!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
