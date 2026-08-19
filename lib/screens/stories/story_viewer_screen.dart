import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/story_model.dart';
import 'package:piec/core/services/auth_service.dart';
import 'package:piec/core/services/chat_service.dart';
import 'package:piec/core/services/story_service.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';
import 'package:provider/provider.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressController;
  final TextEditingController _replyController = TextEditingController();

  String? _burstEmoji;
  Timer? _burstTimer;

  final List<String> _quickReactions = ['🔥', '❤️', '⚡', '😂', '👋', '☕', '🚀'];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextStory();
        }
      });

    _startCurrentStory();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _replyController.dispose();
    _burstTimer?.cancel();
    super.dispose();
  }

  void _startCurrentStory() {
    _progressController.reset();
    _progressController.forward();

    final storyService = Provider.of<StoryService>(context, listen: false);
    storyService.markStoryAsViewed(widget.stories[_currentIndex].id);
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() => _currentIndex++);
      _startCurrentStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startCurrentStory();
    } else {
      _progressController.reset();
      _progressController.forward();
    }
  }

  void _triggerEmojiBurst(String emoji) {
    setState(() => _burstEmoji = emoji);
    _burstTimer?.cancel();
    _burstTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _burstEmoji = null);
    });

    final auth = Provider.of<AuthService>(context, listen: false);
    final storyService = Provider.of<StoryService>(context, listen: false);
    if (auth.currentUser != null) {
      storyService.reactToStory(widget.stories[_currentIndex].id, emoji, auth.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    final auth = Provider.of<AuthService>(context);
    final chatService = Provider.of<ChatService>(context);
    final currentUser = auth.currentUser;

    final timeAgo = DateFormat('hh:mm a').format(story.createdAt);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth * 0.35) {
            _prevStory();
          } else if (details.globalPosition.dx > screenWidth * 0.65) {
            _nextStory();
          }
        },
        child: Stack(
          children: [
            // Dynamic Scene Background Gradient
            _buildSceneBackdrop(story.sceneType),

            // Center 3D Avatar Scene Stage
            Positioned.fill(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 80),

                      // Scene Badge Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primaryNeon.withOpacity(0.5)),
                        ),
                        child: Text(
                          story.sceneTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNeon,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3D Avatar Hero
                      GamifiedAvatar(
                        config: story.user.avatarConfig,
                        size: 150,
                        showGlow: true,
                        enable3DInteraction: true,
                      ),
                      const SizedBox(height: 24),

                      // Story Caption Card
                      if (story.caption.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: Text(
                            story.caption,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Geo-Drop Location Pill (if tagged)
                      if (story.locationPoint != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.homeTag, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('📍', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                story.locationPoint!.title,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Music Track Pill (if tagged)
                      if (story.musicTrack != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primaryNeon.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.music_note_rounded, size: 14, color: AppColors.primaryNeon),
                              const SizedBox(width: 4),
                              Text(
                                story.musicTrack!,
                                style: const TextStyle(fontSize: 11, color: AppColors.primaryNeon, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),

            // Top Segmented Progress Bars
            Positioned(
              top: 40,
              left: 12,
              right: 12,
              child: Row(
                children: List.generate(widget.stories.length, (index) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, _) {
                          double value = 0.0;
                          if (index < _currentIndex) {
                            value = 1.0;
                          } else if (index == _currentIndex) {
                            value = _progressController.value;
                          }
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryNeon,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Top User Info Header
            Positioned(
              top: 54,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  GamifiedAvatar(
                    config: story.user.avatarConfig,
                    size: 38,
                    showGlow: false,
                    isAnimated: false,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.user.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '@${story.user.username} • $timeAgo',
                          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Floating Emoji Burst Animation
            if (_burstEmoji != null)
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.5, end: 2.2),
                  duration: const Duration(milliseconds: 900),
                  builder: (context, scale, _) {
                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: (2.2 - scale).clamp(0.0, 1.0),
                        child: Text(
                          _burstEmoji!,
                          style: const TextStyle(fontSize: 70),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Bottom Quick Reactions & Encrypted DM Reply Bar
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Column(
                children: [
                  // Quick Reactions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _quickReactions.map((emoji) {
                      return GestureDetector(
                        onTap: () => _triggerEmojiBurst(emoji),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 20)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Encrypted DM Input
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.primaryNeon.withOpacity(0.4)),
                          ),
                          child: TextField(
                            controller: _replyController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Send encrypted reply 🔒...',
                              hintStyle: TextStyle(color: Colors.white54, fontSize: 12),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 44,
                        width: 44,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
                          onPressed: () {
                            final text = _replyController.text.trim();
                            if (text.isNotEmpty && currentUser != null) {
                              chatService.sendMessage(
                                currentUserId: currentUser.id,
                                friendId: story.userId,
                                text: '💬 *Replied to your Story (${story.sceneTitle}):*\n$text',
                              );
                              _replyController.clear();
                              _triggerEmojiBurst('💬');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Encrypted reply sent to chat! 🔒')),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSceneBackdrop(AvatarSceneType scene) {
    List<Color> colors;
    switch (scene) {
      case AvatarSceneType.cafeCoffee:
        colors = [const Color(0xFF3B1E08), const Color(0xFF140A04), Colors.black];
        break;
      case AvatarSceneType.gamingRig:
        colors = [const Color(0xFF0F172A), const Color(0xFF1E1035), const Color(0xFF0B0D17)];
        break;
      case AvatarSceneType.carDrive:
        colors = [const Color(0xFF1A0B2E), const Color(0xFF0F041D), Colors.black];
        break;
      case AvatarSceneType.pizzaLateNight:
        colors = [const Color(0xFF3B0B14), const Color(0xFF1F060A), Colors.black];
        break;
      case AvatarSceneType.gymWorkout:
        colors = [const Color(0xFF062A1E), const Color(0xFF03140F), Colors.black];
        break;
      case AvatarSceneType.beachSunset:
        colors = [const Color(0xFF3B122D), const Color(0xFF1F0A1A), Colors.black];
        break;
      case AvatarSceneType.chillLoFi:
      default:
        colors = [const Color(0xFF1A1A3A), const Color(0xFF0C0C1F), Colors.black];
        break;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: colors,
          center: Alignment.center,
          radius: 1.0,
        ),
      ),
    );
  }
}
