import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/location_point.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';

class FriendMapMarker extends StatefulWidget {
  final UserModel user;
  final LocationPoint locationPoint;
  final bool isSelected;
  final VoidCallback onTap;

  const FriendMapMarker({
    super.key,
    required this.user,
    required this.locationPoint,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  State<FriendMapMarker> createState() => _FriendMapMarkerState();
}

class _FriendMapMarkerState extends State<FriendMapMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final locType = widget.locationPoint.type;
    final isLowBattery = user.batteryPercentage <= 5;
    final isBlurred = user.privacyMode == LocationPrivacyMode.blurred;

    Color tagColor = AppColors.primaryNeon;
    if (locType == LocationType.home) tagColor = AppColors.homeTag;
    if (locType == LocationType.office) tagColor = AppColors.officeTag;
    if (locType == LocationType.hangout) tagColor = AppColors.hangoutTag;
    if (isLowBattery) tagColor = const Color(0xFFEF4444);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isSelected ? 1.18 : _scaleAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Tag Pill (Name + Battery % / Beacon)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.94),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isSelected
                          ? AppColors.primaryNeon
                          : (isLowBattery ? const Color(0xFFEF4444) : tagColor),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isLowBattery ? const Color(0xFFEF4444) : tagColor).withOpacity(0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLowBattery)
                        const Text('🪫', style: TextStyle(fontSize: 10))
                      else if (user.isCharging)
                        const Text('⚡', style: TextStyle(fontSize: 10))
                      else
                        Text(widget.locationPoint.iconEmoji, style: const TextStyle(fontSize: 10)),

                      const SizedBox(width: 3),
                      Text(
                        user.name.split(' ').first,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLowBattery ? '4%' : '${user.batteryPercentage}%',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isLowBattery ? const Color(0xFFEF4444) : AppColors.accentGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),

                // Avatar Pin Body with Blurred Zone indicator if enabled
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Outer Blurred Privacy Aura or Pulsing Glow
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isBlurred ? Border.all(color: AppColors.primaryNeon.withOpacity(0.5), width: 2) : null,
                        boxShadow: [
                          BoxShadow(
                            color: tagColor.withOpacity(isBlurred ? 0.3 : 0.45),
                            blurRadius: isBlurred ? 18 : 8,
                            spreadRadius: isBlurred ? 4 : 1,
                          )
                        ],
                      ),
                    ),

                    // Avatar
                    GamifiedAvatar(
                      config: user.avatarConfig,
                      size: 40,
                      showGlow: false,
                      isAnimated: false,
                    ),

                    // Location Type / Battery Beacon Badge
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isLowBattery ? const Color(0xFFEF4444) : tagColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 1.5),
                        ),
                        child: Text(
                          isLowBattery ? '📍' : widget.locationPoint.iconEmoji,
                          style: const TextStyle(fontSize: 8),
                        ),
                      ),
                    ),
                  ],
                ),

                // Map Pin Pointer Triangle
                CustomPaint(
                  size: const Size(10, 5),
                  painter: _TrianglePainter(color: isLowBattery ? const Color(0xFFEF4444) : tagColor),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
