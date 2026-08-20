import 'dart:async';
import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/call_session_model.dart';
import 'package:piec/core/services/call_service.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';
import 'package:provider/provider.dart';

class ActiveCallScreen extends StatefulWidget {
  const ActiveCallScreen({super.key});

  static void show(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ActiveCallScreen(),
      ),
    );
  }

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  String? _burstEmoji;
  Timer? _burstTimer;

  final List<String> _callReactions = ['🔥', '❤️', '⚡', '😂', '👋', '☕'];

  void _triggerReaction(String emoji) {
    setState(() => _burstEmoji = emoji);
    _burstTimer?.cancel();
    _burstTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _burstEmoji = null);
    });
  }

  @override
  void dispose() {
    _burstTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final callService = Provider.of<CallService>(context);
    final call = callService.activeCall;

    if (call == null || call.status == CallStatus.ended) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      return Scaffold(
        backgroundColor: const Color(0xFF0B0D17),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.call_end_rounded, color: Color(0xFFEF4444), size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Call Ended 📴',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    final isVideo = call.isVideoOn;
    final isConnected = call.status == CallStatus.connected;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D17),
      body: Stack(
        children: [
          // Background Gradient / Cyber HUD
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: isVideo
                    ? [const Color(0xFF1E1035), const Color(0xFF0B0D17), Colors.black]
                    : [const Color(0xFF162035), const Color(0xFF0B0D17), Colors.black],
                center: Alignment.center,
                radius: 1.1,
              ),
            ),
          ),

          // Main View Content
          Positioned.fill(
            child: isVideo
                ? _buildVideoCallView(call, isConnected)
                : _buildAudioCallView(call, isConnected),
          ),

          // Floating Reaction Burst
          if (_burstEmoji != null)
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 2.4),
                duration: const Duration(milliseconds: 800),
                builder: (context, scale, _) {
                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: (2.4 - scale).clamp(0.0, 1.0),
                      child: Text(_burstEmoji!, style: const TextStyle(fontSize: 60)),
                    ),
                  );
                },
              ),
            ),

          // Top Header (User Info, E2EE Lock & Call Timer)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryNeon.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_rounded, size: 12, color: AppColors.primaryNeon),
                      const SizedBox(width: 4),
                      Text(
                        isVideo ? 'E2EE 3D Video' : 'E2EE Spatial Audio',
                        style: const TextStyle(fontSize: 11, color: AppColors.primaryNeon, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isConnected ? _formatDuration(call.durationSeconds) : 'Ringing...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isConnected ? Colors.white : AppColors.accentYellow,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Video Call Picture-in-Picture (PiP) Window for Caller Avatar
          if (isVideo)
            Positioned(
              top: 100,
              right: 16,
              child: Container(
                width: 100,
                height: 130,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primaryNeon, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryNeon.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GamifiedAvatar(
                      config: call.caller.avatarConfig,
                      size: 60,
                      showGlow: false,
                      isTalking: isConnected,
                    ),
                    const SizedBox(height: 4),
                    const Text('You', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryNeon)),
                  ],
                ),
              ),
            ),

          // Bottom Control Dock & In-Call Reactions
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Column(
              children: [
                // Quick Call Reactions Row
                if (isConnected)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _callReactions.map((emoji) {
                        return GestureDetector(
                          onTap: () => _triggerReaction(emoji),
                          child: Text(emoji, style: const TextStyle(fontSize: 22)),
                        );
                      }).toList(),
                    ),
                  ),

                // Main Controls Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppColors.surfaceHover),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute Mic Toggle
                      _buildControlButton(
                        icon: call.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        isActive: call.isMuted,
                        activeColor: AppColors.accentPink,
                        onTap: () => callService.toggleMute(),
                      ),

                      // Video Camera Toggle
                      _buildControlButton(
                        icon: call.isVideoOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                        isActive: call.isVideoOn,
                        activeColor: AppColors.primaryNeon,
                        onTap: () => callService.toggleVideo(),
                      ),

                      // Speakerphone Toggle
                      _buildControlButton(
                        icon: call.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        isActive: call.isSpeakerOn,
                        activeColor: AppColors.primaryNeon,
                        onTap: () => callService.toggleSpeaker(),
                      ),

                      // End Call Button
                      GestureDetector(
                        onTap: () {
                          callService.endCall();
                          if (mounted && Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x66EF4444),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Audio Call View
  Widget _buildAudioCallView(CallSessionModel call, bool isConnected) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 3D Avatar Hero with Speaking Visemes
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isConnected ? AppColors.primaryNeon.withOpacity(0.3) : Colors.transparent,
                  blurRadius: 30,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: GamifiedAvatar(
              config: call.receiver.avatarConfig,
              size: 150,
              showGlow: true,
              isTalking: isConnected,
              enable3DInteraction: true,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            call.receiver.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '@${call.receiver.username}',
            style: const TextStyle(fontSize: 14, color: AppColors.primaryNeon, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            isConnected ? 'Spatial HD Voice Connected ⚡' : 'Calling...',
            style: TextStyle(
              fontSize: 13,
              color: isConnected ? AppColors.accentGreen : AppColors.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // 3D Avatar Video Call View
  Widget _buildVideoCallView(CallSessionModel call, bool isConnected) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Friend 3D Avatar on Holographic Stage
          GamifiedAvatar(
            config: call.receiver.avatarConfig,
            size: 200,
            showGlow: true,
            isTalking: isConnected,
            enable3DInteraction: true,
          ),
          const SizedBox(height: 20),

          Text(
            call.receiver.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            call.receiver.statusText,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.2) : AppColors.surfaceLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? activeColor : AppColors.surfaceHover,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? activeColor : AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}
