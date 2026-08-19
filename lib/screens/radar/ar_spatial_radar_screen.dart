import 'dart:async';
import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';

class ArSpatialRadarScreen extends StatefulWidget {
  final UserModel targetFriend;

  const ArSpatialRadarScreen({super.key, required this.targetFriend});

  static void show(BuildContext context, UserModel targetFriend) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ArSpatialRadarScreen(targetFriend: targetFriend),
      ),
    );
  }

  @override
  State<ArSpatialRadarScreen> createState() => _ArSpatialRadarScreenState();
}

class _ArSpatialRadarScreenState extends State<ArSpatialRadarScreen> {
  int _distanceMeters = 28;
  Timer? _radarTimer;
  bool _isFound = false;

  @override
  void initState() {
    super.initState();
    // Simulate walking towards friend in crowded mall/station
    _radarTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (_distanceMeters > 3) {
        setState(() => _distanceMeters -= 5);
      } else {
        setState(() {
          _distanceMeters = 0;
          _isFound = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _radarTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friend = widget.targetFriend;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Cyber Camera Viewfinder Background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Color(0xFF0F172A), Color(0xFF020617), Colors.black],
                radius: 1.2,
              ),
            ),
          ),

          // AR Reticle Grid Lines
          CustomPaint(
            size: Size.infinite,
            painter: _ArGridPainter(),
          ),

          // Top Header (Title, Floor & Close)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryNeon),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.radar_rounded, size: 16, color: AppColors.primaryNeon),
                      SizedBox(width: 6),
                      Text(
                        'AR SPATIAL RADAR BEAM',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNeon, letterSpacing: 1.2),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Center AR Holographic Avatar Target & Floor Locator
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Floating Floor Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accentYellow),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('🏢', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 6),
                      Text(
                        'Floor 2 • Near Main Entrance / Cafe',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentYellow),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Holographic 3D Avatar Target
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.9, end: 1.1),
                  duration: const Duration(seconds: 1),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: _isFound ? 1.2 : scale,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isFound ? AppColors.accentGreen : AppColors.primaryNeon,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isFound ? AppColors.accentGreen : AppColors.primaryNeon).withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: GamifiedAvatar(
                          config: friend.avatarConfig,
                          size: 130,
                          showGlow: true,
                          isAnimated: true,
                          enable3DInteraction: true,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                Text(
                  friend.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  _isFound ? '🎉 Spotted! Friend is directly in front of you!' : '⬆️ Point camera straight ahead',
                  style: TextStyle(
                    fontSize: 13,
                    color: _isFound ? AppColors.accentGreen : AppColors.primaryNeon,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Radar Distance Meter HUD
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.surfaceHover),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_isFound ? AppColors.accentGreen : AppColors.primaryNeon).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _isFound ? '🎯' : '⬆️',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isFound ? 'MATCH FOUND' : 'DISTANCE RADAR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: _isFound ? AppColors.accentGreen : AppColors.textMuted,
                          ),
                        ),
                        Text(
                          _isFound ? '0 meters • In Sight!' : '$_distanceMeters meters away',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _isFound ? AppColors.accentGreen : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ping Audio Beacon Button
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('🔊 Audio Beacon pinged to ${friend.name.split(' ').first}\'s phone!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNeon,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: const Text('Ping 🔊', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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

class _ArGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F0FF).withOpacity(0.12)
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);

    // Concentric Radar Rings
    canvas.drawCircle(center, 90, paint);
    canvas.drawCircle(center, 160, paint);
    canvas.drawCircle(center, 230, paint);

    // Crosshairs
    canvas.drawLine(Offset(center.dx - 180, center.dy), Offset(center.dx + 180, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - 180), Offset(center.dx, center.dy + 180), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
