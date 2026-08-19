import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';

class AvatarChatHeader extends StatelessWidget {
  final UserModel? currentUser;
  final UserModel friendUser;
  final bool isFriendTyping;
  final String? activeReaction;
  final VoidCallback onSecurityTap;

  const AvatarChatHeader({
    super.key,
    this.currentUser,
    required this.friendUser,
    required this.isFriendTyping,
    this.activeReaction,
    required this.onSecurityTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.7),
        border: const Border(
          bottom: BorderSide(
            color: AppColors.surfaceLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Security verification badge
          GestureDetector(
            onTap: onSecurityTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryPurple.withOpacity(0.35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.lock_rounded, size: 11, color: AppColors.primaryNeon),
                  SizedBox(width: 4),
                  Text(
                    'End-to-End Encrypted (AES-256)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryNeon,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 13, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Focused Friend's 3D Avatar Hero Stage
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  GamifiedAvatar(
                    config: friendUser.avatarConfig,
                    size: 76,
                    showGlow: true,
                    isTalking: isFriendTyping,
                    enable3DInteraction: true,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    friendUser.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: friendUser.isOnline ? AppColors.online : AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isFriendTyping
                            ? 'typing...'
                            : (friendUser.isOnline ? friendUser.statusText : 'Offline'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isFriendTyping ? AppColors.primaryNeon : AppColors.textMuted,
                          fontWeight: isFriendTyping ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        friendUser.batteryPercentage <= 5
                            ? '🪫 ${friendUser.batteryPercentage}%'
                            : (friendUser.isCharging
                                ? '⚡ ${friendUser.batteryPercentage}%'
                                : '🔋 ${friendUser.batteryPercentage}%'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: friendUser.batteryPercentage <= 5
                              ? const Color(0xFFEF4444)
                              : AppColors.accentGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Active Floating Reaction Burst on Friend Avatar
              if (activeReaction != null)
                Positioned(
                  top: -6,
                  right: 40,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.5, end: 1.2),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryNeon),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryNeon.withOpacity(0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Text(activeReaction!, style: const TextStyle(fontSize: 20)),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
