import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/message_model.dart';

class MessageDetailsModal extends StatelessWidget {
  final MessageModel message;
  final ValueChanged<String> onSelectReaction;

  const MessageDetailsModal({
    super.key,
    required this.message,
    required this.onSelectReaction,
  });

  static void show(
    BuildContext context, {
    required MessageModel message,
    required ValueChanged<String> onSelectReaction,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MessageDetailsModal(
        message: message,
        onSelectReaction: onSelectReaction,
      ),
    );
  }

  final List<String> _emojis = const ['🔥', '❤️', '😂', '⚡', '🚀', '🏠', '✨', '👋'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.primaryNeon, width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji Quick Reaction Bar
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.surfaceHover),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _emojis.map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      onSelectReaction(emoji);
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // E2EE Inspector Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryPurple.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.shield_outlined, color: AppColors.primaryNeon, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'E2EE Cryptographic Inspection',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primaryNeon,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Raw Ciphertext (Server Payload):',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    message.encryptedPayload.isNotEmpty
                        ? message.encryptedPayload
                        : '[Pre-Encrypted Binary]',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppColors.accentGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'IV: ${message.iv.isNotEmpty ? message.iv.substring(0, 8) : "random"}...',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: message.encryptedPayload));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Encrypted payload copied!')),
                        );
                      },
                      child: const Text(
                        'Copy Ciphertext',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryNeon,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
