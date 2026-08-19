import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/squad_model.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/core/services/auth_service.dart';
import 'package:piec/core/services/squad_service.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';
import 'package:provider/provider.dart';

class SquadChatRoomScreen extends StatefulWidget {
  final SquadModel squad;

  const SquadChatRoomScreen({super.key, required this.squad});

  @override
  State<SquadChatRoomScreen> createState() => _SquadChatRoomScreenState();
}

class _SquadChatRoomScreenState extends State<SquadChatRoomScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
    final squadService = Provider.of<SquadService>(context);
    final auth = Provider.of<AuthService>(context);
    final currentUser = auth.currentUser;

    final messages = squadService.getSquadMessages(widget.squad.id);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Text(widget.squad.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.squad.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${widget.squad.members.length} Squad Members Synced on Map',
                    style: const TextStyle(fontSize: 11, color: AppColors.primaryNeon),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Filter Map Button
          IconButton(
            icon: const Icon(Icons.map_rounded, color: AppColors.primaryNeon),
            tooltip: 'Filter Map to this Squad',
            onPressed: () {
              squadService.selectSquadFilter(widget.squad.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('World Map filtered to "${widget.squad.name}" 🗺️')),
              );
            },
          ),
          // Squad SOS Beacon
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded, color: AppColors.accentPink),
            tooltip: 'Squad SOS Beacon',
            onPressed: () {
              squadService.sendSquadMessage(
                squadId: widget.squad.id,
                senderId: currentUser?.id ?? 'me',
                text: '🚨 [SOS SQUAD BEACON]: High-priority emergency location beacon triggered!',
                avatarReaction: '🚨',
              );
              _scrollToBottom();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Squad SOS Alert Broadcasted to all members! 🚨')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Multi-Avatar 3D Stage Header (All Squad Members Standing Together)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                bottom: BorderSide(color: AppColors.surfaceLight, width: 1.5),
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.squad.members.length,
                    itemBuilder: (context, index) {
                      final member = widget.squad.members[index];
                      final isMe = member.id == currentUser?.id;

                      return Container(
                        margin: const EdgeInsets.only(right: 14),
                        child: Column(
                          children: [
                            GamifiedAvatar(
                              config: member.avatarConfig,
                              size: 46,
                              showGlow: isMe,
                              isAnimated: false,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              member.name.split(' ').first,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isMe ? AppColors.primaryNeon : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Shared Meetup Destination Pin Banner
                if (widget.squad.meetupLocation != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.homeTag.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Text('🚩', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Meetup: ${widget.squad.meetupLocation!.title}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                widget.squad.meetupLocation!.address,
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.homeTag.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Active Pin',
                            style: TextStyle(fontSize: 10, color: AppColors.homeTag, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Message Stream
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMine = msg.senderId == currentUser?.id;

                final sender = widget.squad.members.firstWhere(
                  (m) => m.id == msg.senderId,
                  orElse: () => UserModel(
                    id: 'unknown',
                    name: 'Squad Member',
                    username: 'user',
                    lastActive: DateTime.now(),
                  ),
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMine) ...[
                        GamifiedAvatar(config: sender.avatarConfig, size: 36, showGlow: false, isAnimated: false),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMine ? AppColors.myMessageBg : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isMine ? AppColors.primaryNeon.withOpacity(0.3) : AppColors.surfaceHover,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMine)
                                Text(
                                  sender.name,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNeon),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                msg.decryptedContent,
                                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.surfaceLight)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Message ${widget.squad.name}...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                      onPressed: () {
                        final text = _textController.text.trim();
                        if (text.isNotEmpty && currentUser != null) {
                          squadService.sendSquadMessage(
                            squadId: widget.squad.id,
                            senderId: currentUser.id,
                            text: text,
                          );
                          _textController.clear();
                          _scrollToBottom();
                        }
                      },
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
}
