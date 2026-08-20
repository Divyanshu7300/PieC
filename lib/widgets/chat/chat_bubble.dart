import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/message_model.dart';
import 'package:piec/core/services/theme_service.dart';
import 'package:provider/provider.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final VoidCallback onLongPress;
  final ValueChanged<String> onAddReaction;

  const ChatBubble({
    super.key,
    required this.message,
    required this.onLongPress,
    required this.onAddReaction,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isMine = message.isMine;
    final timeStr = DateFormat('hh:mm a').format(message.timestamp);
    final radius = themeService.bubbleCornerRadius.toDouble();

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: EdgeInsets.only(
            top: 4,
            bottom: 4,
            left: isMine ? 50 : 12,
            right: isMine ? 12 : 50,
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Bubble Container
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMine
                          ? themeService.myMessageBubbleColor
                          : themeService.activeSurfaceLightColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(radius),
                        topRight: Radius.circular(radius),
                        bottomLeft: Radius.circular(isMine ? radius : 4),
                        bottomRight: Radius.circular(isMine ? 4 : radius),
                      ),
                      border: Border.all(
                        color: isMine
                            ? Colors.white.withOpacity(0.15)
                            : (themeService.isLightMode
                                ? const Color(0xFFE2E8F0)
                                : AppColors.surfaceHover),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        // Dynamic Content Based on MessageType
                        _buildMessageBody(context, themeService, isMine),

                        const SizedBox(height: 4),

                        // Timestamp & Encrypted Lock Indicator
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              size: 10,
                              color: isMine
                                  ? Colors.white70
                                  : themeService.activePrimaryColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 10,
                                color: isMine
                                    ? Colors.white.withOpacity(0.7)
                                    : (themeService.isLightMode
                                        ? const Color(0xFF64748B)
                                        : AppColors.textMuted),
                              ),
                            ),
                            if (isMine) ...[
                              const SizedBox(width: 4),
                              Icon(
                                message.isRead
                                    ? Icons.done_all_rounded
                                    : Icons.done_rounded,
                                size: 13,
                                color: message.isRead
                                    ? const Color(0xFF38BDF8) // Glowing Cyan Blue for Seen
                                    : Colors.white54, // Muted for Sent
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Message reaction badge if any
                  if (message.reactionEmoji != null)
                    Positioned(
                      bottom: -10,
                      right: isMine ? null : -6,
                      left: isMine ? -6 : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: themeService.activeSurfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: themeService.activePrimaryColor.withOpacity(0.6),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: Text(
                          message.reactionEmoji!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBody(BuildContext context, ThemeService themeService, bool isMine) {
    switch (message.type) {
      // 1. Image Message
      case MessageType.image:
        final hasMedia = message.mediaUrl != null && message.mediaUrl!.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 220,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1035), Color(0xFF0F172A)],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: hasMedia
                    ? Image.network(
                        message.mediaUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF1E1035),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.photo_rounded, size: 40, color: AppColors.primaryNeon),
                              SizedBox(height: 6),
                              Text('Encrypted Photo 📸', style: TextStyle(fontSize: 11, color: Colors.white70)),
                            ],
                          ),
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryNeon,
                              strokeWidth: 2,
                            ),
                          );
                        },
                      )
                    : Container(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.image_rounded, size: 48, color: AppColors.primaryNeon),
                            SizedBox(height: 6),
                            Text(
                              '🔒 Encrypted Photo',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            if (message.decryptedContent.isNotEmpty &&
                message.decryptedContent != '[Attachment: image]' &&
                !message.decryptedContent.startsWith('📸 Sent an encrypted photo')) ...[
              const SizedBox(height: 6),
              Text(
                message.decryptedContent,
                style: TextStyle(
                  fontSize: 14,
                  color: isMine ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ],
        );

      // 2. Video Message
      case MessageType.video:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 220,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A0B38), Color(0xFF0B0D17)],
                ),
                border: Border.all(color: AppColors.accentPink.withOpacity(0.4)),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.accentPink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Encrypted Video (0:24) 🎥',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
            if (message.decryptedContent.isNotEmpty && message.decryptedContent != '[Attachment: video]') ...[
              const SizedBox(height: 6),
              Text(
                message.decryptedContent,
                style: TextStyle(
                  fontSize: 14,
                  color: isMine ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ],
        );

      // 3. Document / File Message
      case MessageType.document:
        return Container(
          width: 210,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insert_drive_file_rounded, color: AppColors.accentYellow, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.fileName ?? 'Document_File.pdf',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message.fileSize ?? '2.4 MB • Encrypted PDF',
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.download_rounded, color: Colors.white, size: 20),
            ],
          ),
        );

      // 4. Map Location Pin
      case MessageType.location:
        final loc = message.locationData;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.homeTag, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('📍', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          loc?.title ?? 'Spatial Map Location',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc?.address ?? '28.6180° N, 77.2140° E',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.homeTag.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'View on World Map 🗺️',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      // 5. Voice Audio Note
      case MessageType.audio:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primaryNeon,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            Row(
              children: List.generate(12, (i) {
                final height = 8.0 + ((i % 4) * 4);
                return Container(
                  width: 3,
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: isMine ? Colors.white : AppColors.primaryNeon,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
            const SizedBox(width: 8),
            Text(
              message.audioDuration ?? '0:18',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isMine ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        );

      // Standard Text
      case MessageType.text:
      default:
        return Text(
          message.decryptedContent,
          style: TextStyle(
            fontSize: 15,
            color: isMine
                ? Colors.white
                : (themeService.isLightMode
                    ? const Color(0xFF0F172A)
                    : AppColors.textPrimary),
            height: 1.35,
          ),
        );
    }
  }
}
