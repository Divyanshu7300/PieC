import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/avatar_config.dart';
import 'package:piec/core/services/auth_service.dart';
import 'package:piec/core/services/story_service.dart';
import 'package:piec/screens/stories/create_story_modal.dart';
import 'package:piec/screens/stories/story_viewer_screen.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';
import 'package:provider/provider.dart';

class StoriesTray extends StatelessWidget {
  const StoriesTray({super.key});

  @override
  Widget build(BuildContext context) {
    final storyService = Provider.of<StoryService>(context);
    final auth = Provider.of<AuthService>(context);
    final currentUser = auth.currentUser;

    final myStories = storyService.userStories;
    final friendStories = storyService.friendStories;

    return Container(
      height: 98,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // 1. My Story / Add Story Item
          GestureDetector(
            onTap: () {
              if (myStories.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoryViewerScreen(stories: myStories),
                  ),
                );
              } else {
                CreateStoryModal.show(context);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: myStories.isNotEmpty
                                ? AppColors.primaryNeon
                                : AppColors.surfaceHover,
                            width: 2,
                          ),
                        ),
                        child: GamifiedAvatar(
                          config: currentUser?.avatarConfig ?? AvatarConfig(),
                          size: 56,
                          showGlow: myStories.isNotEmpty,
                          isAnimated: false,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => CreateStoryModal.show(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, size: 14, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your Story',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Friends' Stories
          ...friendStories.map((story) {
            final isUnviewed = !story.isViewed;

            return GestureDetector(
              onTap: () {
                final friendStoryIndex = friendStories.indexOf(story);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoryViewerScreen(
                      stories: friendStories,
                      initialIndex: friendStoryIndex,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isUnviewed
                            ? const LinearGradient(
                                colors: [AppColors.accentPink, AppColors.primaryNeon],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        border: isUnviewed
                            ? null
                            : Border.all(color: AppColors.surfaceHover, width: 2),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: GamifiedAvatar(
                          config: story.user.avatarConfig,
                          size: 52,
                          showGlow: isUnviewed,
                          isAnimated: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      story.user.name.split(' ').first,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isUnviewed ? FontWeight.bold : FontWeight.normal,
                        color: isUnviewed ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
