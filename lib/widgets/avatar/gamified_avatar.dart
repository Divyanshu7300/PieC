import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/avatar_config.dart';

class GamifiedAvatar extends StatefulWidget {
  final AvatarConfig config;
  final double size;
  final bool isTalking;
  final bool isAnimated;
  final bool showGlow;
  final bool enable3DInteraction;
  final String? activeReaction;
  final VoidCallback? onTap;

  const GamifiedAvatar({
    super.key,
    required this.config,
    this.size = 90,
    this.isTalking = false,
    this.isAnimated = true,
    this.showGlow = true,
    this.enable3DInteraction = false,
    this.activeReaction,
    this.onTap,
  });

  @override
  State<GamifiedAvatar> createState() => _GamifiedAvatarState();
}

class _GamifiedAvatarState extends State<GamifiedAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _breathAnimation;
  late Animation<double> _blinkAnimation;

  double _interactiveTiltX = 0.0;
  double _interactiveTiltY = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOutSine,
      ),
    );

    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.05).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.88, 0.96, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onPanUpdate: widget.enable3DInteraction
          ? (details) {
              setState(() {
                _interactiveTiltY =
                    (_interactiveTiltY + details.delta.dx * 0.015).clamp(-0.45, 0.45);
                _interactiveTiltX =
                    (_interactiveTiltX - details.delta.dy * 0.015).clamp(-0.35, 0.35);
              });
            }
          : null,
      onPanEnd: widget.enable3DInteraction
          ? (_) {
              setState(() {
                _interactiveTiltX = 0.0;
                _interactiveTiltY = 0.0;
              });
            }
          : null,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          final breathOffset = widget.isAnimated ? _breathAnimation.value : 0.0;
          final eyeScale = widget.isAnimated ? _blinkAnimation.value : 1.0;
          final phase = _animController.value * 2 * math.pi;

          final tiltX = widget.enable3DInteraction
              ? _interactiveTiltX
              : widget.config.faceTiltX;
          final tiltY = widget.enable3DInteraction
              ? _interactiveTiltY
              : widget.config.faceTiltY;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Outer Volumetric Neon Glow
              if (widget.showGlow)
                Container(
                  width: widget.size * 1.25,
                  height: widget.size * 1.25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.config.glowColor.withOpacity(0.4),
                        blurRadius: widget.size * 0.35,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),

              if (widget.showGlow && widget.config.auraEffect != AvatarAuraEffect.none)
                _buildAuraParticles(phase, widget.size, widget.config.auraEffect),

              // 3D Perspective Rotated Avatar Body
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002) // 3D perspective depth
                  ..rotateX(tiltX)
                  ..rotateY(tiltY)
                  ..translate(0.0, breathOffset, 0.0),
                child: Container(
                  width: widget.size,
                  height: widget.size * 1.15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.surfaceLight,
                        AppColors.surface,
                        Colors.black.withOpacity(0.8),
                      ],
                      center: const Alignment(-0.3, -0.3),
                      radius: 0.9,
                    ),
                    border: Border.all(
                      color: widget.config.glowColor.withOpacity(0.85),
                      width: widget.size > 80 ? 3 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CustomPaint(
                      size: Size(widget.size, widget.size * 1.15),
                      painter: _Snap3DAvatarPainter(
                        config: widget.config,
                        eyeScale: eyeScale,
                        isTalking: widget.isTalking,
                        talkingPhase: phase,
                        tiltX: tiltX,
                        tiltY: tiltY,
                      ),
                    ),
                  ),
                ),
              ),

              // Active Emoji Reaction Balloon
              if (widget.activeReaction != null)
                Positioned(
                  top: -widget.size * 0.15,
                  right: -widget.size * 0.1,
                  child: Container(
                    padding: EdgeInsets.all(widget.size * 0.08),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryNeon, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryNeon.withOpacity(0.6),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.activeReaction!,
                      style: TextStyle(fontSize: widget.size * 0.28),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAuraParticles(double phase, double size, AvatarAuraEffect effect) {
    String particleEmoji = '✨';
    if (effect == AvatarAuraEffect.neonHearts) particleEmoji = '💖';
    if (effect == AvatarAuraEffect.fireFlameEnergy) particleEmoji = '🔥';
    if (effect == AvatarAuraEffect.matrixCodeGlow) particleEmoji = '⚡';
    if (effect == AvatarAuraEffect.galaxyNebula) particleEmoji = '🪐';

    return Stack(
      alignment: Alignment.center,
      children: List.generate(4, (index) {
        final angle = phase + (index * (math.pi / 2));
        final orbitRadius = size * 0.58;
        final x = math.cos(angle) * orbitRadius;
        final y = math.sin(angle) * (orbitRadius * 0.65);

        return Transform.translate(
          offset: Offset(x, y),
          child: Text(
            particleEmoji,
            style: TextStyle(fontSize: size * 0.16),
          ),
        );
      }),
    );
  }
}

class _Snap3DAvatarPainter extends CustomPainter {
  final AvatarConfig config;
  final double eyeScale;
  final bool isTalking;
  final double talkingPhase;
  final double tiltX;
  final double tiltY;

  _Snap3DAvatarPainter({
    required this.config,
    required this.eyeScale,
    required this.isTalking,
    required this.talkingPhase,
    required this.tiltX,
    required this.tiltY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final offsetX = tiltY * w * 0.12;
    final offsetY = -tiltX * h * 0.12;

    // 1. Draw 3D Shaded Torso & Outfit
    _draw3DOutfit(canvas, size, offsetX, offsetY);

    // 2. Draw 3D Neck & Ambient Occlusion
    _draw3DNeck(canvas, size, offsetX, offsetY);

    // 3. Draw 3D Head & Soft Face Contours
    _draw3DFace(canvas, size, offsetX, offsetY);

    // 4. Draw Facial Hair if selected
    _drawFacialHair(canvas, size, offsetX, offsetY);

    // 5. Draw 3D Expressive Eyes & Glares
    _draw3DEyes(canvas, size, offsetX, offsetY);

    // 6. Draw 3D Nose Bridge & Highlights
    _draw3DNose(canvas, size, offsetX, offsetY);

    // 7. Draw 3D Expressive Mouth (Viseme / Talk / Grin)
    _draw3DMouth(canvas, size, offsetX, offsetY);

    // 8. Draw Layered 3D Hairstyle with Neon Streaks
    _draw3DHair(canvas, size, offsetX, offsetY);

    // 9. Draw 3D Accessories (Headphones, Visor, Gold Chain, Crown)
    _draw3DAccessory(canvas, size, offsetX, offsetY);

    // 10. Draw Pose Arms / Hands (Waving / Peace)
    _drawPoseArm(canvas, size, offsetX, offsetY);
  }

  void _draw3DOutfit(Canvas canvas, Size size, double ox, double oy) {
    final w = size.width;
    final h = size.height;

    final outfitShader = LinearGradient(
      colors: [
        config.outfitPrimaryColor,
        Color.lerp(config.outfitPrimaryColor, Colors.black, 0.4)!,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, h * 0.65, w, h * 0.4));

    final shoulderPath = Path()
      ..moveTo(w * 0.08, h)
      ..quadraticBezierTo(w * 0.12 + ox, h * 0.72 + oy, w * 0.35 + ox, h * 0.70 + oy)
      ..lineTo(w * 0.65 + ox, h * 0.70 + oy)
      ..quadraticBezierTo(w * 0.88 + ox, h * 0.72 + oy, w * 0.92, h)
      ..close();

    canvas.drawPath(shoulderPath, Paint()..shader = outfitShader);

    // 3D Collar / Zipper / Tech Armor Accents
    final neonAccent = Paint()
      ..color = config.outfitSecondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, w * 0.035)
      ..strokeCap = StrokeCap.round;

    // Glowing Neon Hoodie Trim / Zipper
    canvas.drawLine(
      Offset(w * 0.50 + ox, h * 0.72 + oy),
      Offset(w * 0.50 + ox, h + oy),
      neonAccent,
    );

    // Neon Collar Left & Right Folds
    canvas.drawLine(
      Offset(w * 0.38 + ox, h * 0.72 + oy),
      Offset(w * 0.48 + ox, h * 0.84 + oy),
      neonAccent,
    );
    canvas.drawLine(
      Offset(w * 0.62 + ox, h * 0.72 + oy),
      Offset(w * 0.52 + ox, h * 0.84 + oy),
      neonAccent,
    );
  }

  void _draw3DNeck(Canvas canvas, Size size, double ox, double oy) {
    final w = size.width;
    final h = size.height;

    final neckShader = LinearGradient(
      colors: [
        config.skinShadowColor,
        config.skinColor,
        config.skinShadowColor,
      ],
    ).createShader(Rect.fromLTWH(w * 0.38 + ox, h * 0.58 + oy, w * 0.24, h * 0.20));

    final neckRect = Rect.fromCenter(
      center: Offset(w * 0.50 + ox, h * 0.66 + oy),
      width: w * 0.24,
      height: h * 0.18,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(neckRect, Radius.circular(w * 0.08)),
      Paint()..shader = neckShader,
    );

    // Under-chin Ambient Occlusion Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.50 + ox, h * 0.62 + oy), width: w * 0.22, height: h * 0.06),
      shadowPaint,
    );
  }

  void _draw3DFace(Canvas canvas, Size size, double ox, double oy) {
    final w = size.width;
    final h = size.height;

    final faceCenter = Offset(w * 0.50 + ox, h * 0.44 + oy);

    // 3D Spherical Face Gradient
    final faceShader = RadialGradient(
      colors: [
        config.skinColor,
        config.skinColor,
        config.skinShadowColor,
      ],
      center: const Alignment(-0.25, -0.3),
      radius: 0.85,
    ).createShader(Rect.fromCenter(center: faceCenter, width: w * 0.58, height: h * 0.56));

    final faceRect = Rect.fromCenter(
      center: faceCenter,
      width: w * 0.56,
      height: h * 0.54,
    );

    // Face base
    canvas.drawRRect(
      RRect.fromRectAndRadius(faceRect, Radius.circular(w * 0.26)),
      Paint()..shader = faceShader,
    );

    // Cute 3D Cheek Blush
    final blushShader = RadialGradient(
      colors: [
        Colors.pinkAccent.withOpacity(0.35),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset(w * 0.32 + ox, h * 0.50 + oy), radius: w * 0.08));

    canvas.drawCircle(Offset(w * 0.32 + ox, h * 0.50 + oy), w * 0.08, Paint()..shader = blushShader);
    canvas.drawCircle(Offset(w * 0.68 + ox, h * 0.50 + oy), w * 0.08, Paint()..shader = blushShader);
  }

  void _drawFacialHair(Canvas canvas, Size size, double ox, double oy) {
    if (config.facialHair == FacialHair.none) return;

    final w = size.width;
    final h = size.height;
    final beardPaint = Paint()
      ..color = config.hairBaseColor.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    if (config.facialHair == FacialHair.stubbleShadow || config.facialHair == FacialHair.cyberGoatee) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.50 + ox, h * 0.60 + oy), width: w * 0.20, height: h * 0.08),
        beardPaint,
      );
    } else if (config.facialHair == FacialHair.fullBeard) {
      final beardPath = Path()
        ..moveTo(w * 0.26 + ox, h * 0.48 + oy)
        ..quadraticBezierTo(w * 0.50 + ox, h * 0.72 + oy, w * 0.74 + ox, h * 0.48 + oy)
        ..quadraticBezierTo(w * 0.50 + ox, h * 0.66 + oy, w * 0.26 + ox, h * 0.48 + oy)
        ..close();
      canvas.drawPath(beardPath, beardPaint);
    }
  }

  void _draw3DEyes(Canvas canvas, Size size, double ox, double oy) {
    final w = size.width;
    final h = size.height;

    final leftCenter = Offset(w * 0.37 + ox, h * 0.42 + oy);
    final rightCenter = Offset(w * 0.63 + ox, h * 0.42 + oy);
    final eyeRadius = w * 0.068;

    // Eyebrows with attitude
    final browPaint = Paint()
      ..color = config.hairBaseColor
      ..strokeWidth = math.max(2.5, w * 0.035)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(w * 0.28 + ox, h * 0.34 + oy),
      Offset(w * 0.44 + ox, h * 0.35 + oy),
      browPaint,
    );
    canvas.drawLine(
      Offset(w * 0.56 + ox, h * 0.35 + oy),
      Offset(w * 0.72 + ox, h * 0.34 + oy),
      browPaint,
    );

    // Eye base (White Sclera)
    canvas.save();
    canvas.scale(1.0, eyeScale);
    final scaledLY = leftCenter.dy / eyeScale;
    final scaledRY = rightCenter.dy / eyeScale;

    final scleraPaint = Paint()..color = Colors.white;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(leftCenter.dx, scaledLY), width: eyeRadius * 2.2, height: eyeRadius * 1.8),
      scleraPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rightCenter.dx, scaledRY), width: eyeRadius * 2.2, height: eyeRadius * 1.8),
      scleraPaint,
    );

    // Glowing Iris with 3D Depth
    final irisShader = RadialGradient(
      colors: [
        config.irisColorValue,
        Color.lerp(config.irisColorValue, Colors.black, 0.5)!,
      ],
    ).createShader(Rect.fromCircle(center: Offset(leftCenter.dx, scaledLY), radius: eyeRadius));

    final irisPaint = Paint()..shader = irisShader;
    canvas.drawCircle(Offset(leftCenter.dx, scaledLY), eyeRadius * 0.82, irisPaint);
    canvas.drawCircle(Offset(rightCenter.dx, scaledRY), eyeRadius * 0.82, irisPaint);

    // Pupil (Dark Core)
    final pupilPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawCircle(Offset(leftCenter.dx, scaledLY), eyeRadius * 0.42, pupilPaint);
    canvas.drawCircle(Offset(rightCenter.dx, scaledRY), eyeRadius * 0.42, pupilPaint);

    // Specular Catchlights (Anime Shine Reflections)
    final shinePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(leftCenter.dx - eyeRadius * 0.28, scaledLY - eyeRadius * 0.28),
      eyeRadius * 0.28,
      shinePaint,
    );
    canvas.drawCircle(
      Offset(rightCenter.dx - eyeRadius * 0.28, scaledRY - eyeRadius * 0.28),
      eyeRadius * 0.28,
      shinePaint,
    );
    canvas.restore();
  }

  void _draw3DNose(Canvas canvas, Size size, double ox, double oy) {
    final w = size.width;
    final h = size.height;

    final nosePaint = Paint()
      ..color = config.skinShadowColor
      ..strokeWidth = math.max(1.8, w * 0.028)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final nosePath = Path()
      ..moveTo(w * 0.50 + ox, h * 0.42 + oy)
      ..lineTo(w * 0.48 + ox, h * 0.49 + oy)
      ..quadraticBezierTo(w * 0.52 + ox, h * 0.51 + oy, w * 0.54 + ox, h * 0.49 + oy);

    canvas.drawPath(nosePath, nosePaint);
  }

  void _draw3DMouth(Canvas canvas, Size size, double ox, double oy) {
    final w = size.width;
    final h = size.height;

    final mouthCenter = Offset(w * 0.50 + ox, h * 0.56 + oy);

    if (isTalking) {
      final talkOpen = (math.sin(talkingPhase).abs() * 0.08 + 0.02) * h;
      final talkRect = Rect.fromCenter(center: mouthCenter, width: w * 0.18, height: talkOpen);

      // Mouth Cavity
      canvas.drawOval(talkRect, Paint()..color = const Color(0xFF1E112A));

      // White Upper Teeth
      final teethRect = Rect.fromCenter(
        center: Offset(mouthCenter.dx, mouthCenter.dy - talkOpen * 0.25),
        width: w * 0.12,
        height: talkOpen * 0.4,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(teethRect, const Radius.circular(2)), Paint()..color = Colors.white);
      return;
    }

    // Dynamic 3D Smile with depth
    final lipPaint = Paint()
      ..color = const Color(0xFF8B253E)
      ..strokeWidth = math.max(2.0, w * 0.035)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final smilePath = Path()
      ..moveTo(w * 0.42 + ox, h * 0.55 + oy)
      ..quadraticBezierTo(w * 0.50 + ox, h * 0.60 + oy, w * 0.58 + ox, h * 0.55 + oy);

    canvas.drawPath(smilePath, lipPaint);
  }

  void _draw3DHair(Canvas canvas, Size size, double ox, double oy) {
    final w = size.width;
    final h = size.height;

    final basePaint = Paint()..color = config.hairBaseColor;
    final highlightPaint = Paint()
      ..color = config.hairHighlightColor
      ..strokeWidth = math.max(2.5, w * 0.04)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (config.hairStyle) {
      case HairStyle.cyberPunkFade:
        final punkPath = Path()
          ..moveTo(w * 0.22 + ox, h * 0.38 + oy)
          ..quadraticBezierTo(w * 0.18 + ox, h * 0.12 + oy, w * 0.48 + ox, h * 0.06 + oy)
          ..lineTo(w * 0.62 + ox, h * 0.08 + oy)
          ..quadraticBezierTo(w * 0.82 + ox, h * 0.18 + oy, w * 0.78 + ox, h * 0.38 + oy)
          ..quadraticBezierTo(w * 0.50 + ox, h * 0.24 + oy, w * 0.22 + ox, h * 0.38 + oy)
          ..close();
        canvas.drawPath(punkPath, basePaint);

        // Neon Glow Streak through hair
        canvas.drawLine(
          Offset(w * 0.32 + ox, h * 0.20 + oy),
          Offset(w * 0.52 + ox, h * 0.10 + oy),
          highlightPaint,
        );
        canvas.drawLine(
          Offset(w * 0.44 + ox, h * 0.24 + oy),
          Offset(w * 0.64 + ox, h * 0.14 + oy),
          highlightPaint,
        );
        break;

      case HairStyle.animeSpiky:
        for (var i = 0; i < 6; i++) {
          final spikePath = Path()
            ..moveTo(w * (0.20 + i * 0.10) + ox, h * 0.28 + oy)
            ..lineTo(w * (0.24 + i * 0.10) + ox, h * (0.04 + (i % 2) * 0.06) + oy)
            ..lineTo(w * (0.30 + i * 0.10) + ox, h * 0.28 + oy)
            ..close();
          canvas.drawPath(spikePath, i % 2 == 0 ? basePaint : Paint()..color = config.hairHighlightColor);
        }
        break;

      case HairStyle.pompadourVolume:
        final pompPath = Path()
          ..moveTo(w * 0.22 + ox, h * 0.36 + oy)
          ..quadraticBezierTo(w * 0.14 + ox, h * 0.05 + oy, w * 0.50 + ox, h * 0.04 + oy)
          ..quadraticBezierTo(w * 0.86 + ox, h * 0.05 + oy, w * 0.78 + ox, h * 0.36 + oy)
          ..close();
        canvas.drawPath(pompPath, basePaint);
        canvas.drawLine(Offset(w * 0.30 + ox, h * 0.16 + oy), Offset(w * 0.70 + ox, h * 0.16 + oy), highlightPaint);
        break;

      case HairStyle.longFlowyWavy:
        final wavyPath = Path()
          ..moveTo(w * 0.18 + ox, h * 0.30 + oy)
          ..quadraticBezierTo(w * 0.10 + ox, h * 0.10 + oy, w * 0.50 + ox, h * 0.10 + oy)
          ..quadraticBezierTo(w * 0.90 + ox, h * 0.10 + oy, w * 0.82 + ox, h * 0.30 + oy)
          ..lineTo(w * 0.88 + ox, h * 0.85 + oy)
          ..quadraticBezierTo(w * 0.72 + ox, h * 0.75 + oy, w * 0.76 + ox, h * 0.44 + oy)
          ..quadraticBezierTo(w * 0.50 + ox, h * 0.22 + oy, w * 0.24 + ox, h * 0.44 + oy)
          ..quadraticBezierTo(w * 0.28 + ox, h * 0.75 + oy, w * 0.12 + ox, h * 0.85 + oy)
          ..close();
        canvas.drawPath(wavyPath, basePaint);
        break;

      default:
        // Dreadlocks / Buzzcut volume
        for (var i = 0; i < 6; i++) {
          final cx = w * (0.24 + i * 0.10) + ox;
          final cy = h * (0.22 - (i == 2 || i == 3 ? 0.06 : 0.02)) + oy;
          canvas.drawCircle(Offset(cx, cy), w * 0.10, basePaint);
          if (i % 2 == 1) {
            canvas.drawCircle(Offset(cx, cy), w * 0.05, Paint()..color = config.hairHighlightColor);
          }
        }
    }
  }

  void _draw3DAccessory(Canvas canvas, Size size, double ox, double oy) {
    final w = size.width;
    final h = size.height;

    switch (config.accessory) {
      case AvatarAccessory.studioHeadphonesLed:
        // Glowing Neon Headband
        final hpPaint = Paint()
          ..color = config.glowColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(3.0, w * 0.06);

        canvas.drawArc(
          Rect.fromCenter(center: Offset(w * 0.50 + ox, h * 0.30 + oy), width: w * 0.72, height: h * 0.55),
          math.pi,
          math.pi,
          false,
          hpPaint,
        );

        // Ear Cups with LED Ring
        final cupPaint = Paint()..color = const Color(0xFF1E1B4B);
        final ledRing = Paint()
          ..color = config.glowColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(w * 0.15 + ox, h * 0.44 + oy), width: w * 0.10, height: h * 0.20),
            Radius.circular(w * 0.04),
          ),
          cupPaint,
        );
        canvas.drawCircle(Offset(w * 0.15 + ox, h * 0.44 + oy), w * 0.04, ledRing);

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(w * 0.85 + ox, h * 0.44 + oy), width: w * 0.10, height: h * 0.20),
            Radius.circular(w * 0.04),
          ),
          cupPaint,
        );
        canvas.drawCircle(Offset(w * 0.85 + ox, h * 0.44 + oy), w * 0.04, ledRing);
        break;

      case AvatarAccessory.cyberVisorHolo:
        // Holographic Cyber Visor with Grid HUD
        final visorShader = LinearGradient(
          colors: [
            AppColors.primaryNeon.withOpacity(0.85),
            AppColors.primaryPurple.withOpacity(0.85),
          ],
        ).createShader(Rect.fromLTWH(w * 0.22 + ox, h * 0.36 + oy, w * 0.56, h * 0.14));

        final visorRect = Rect.fromCenter(
          center: Offset(w * 0.50 + ox, h * 0.42 + oy),
          width: w * 0.54,
          height: h * 0.14,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(visorRect, Radius.circular(w * 0.04)),
          Paint()..shader = visorShader,
        );

        // Futuristic Grid HUD shine
        final hudPaint = Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..strokeWidth = 1.5;
        canvas.drawLine(Offset(w * 0.28 + ox, h * 0.39 + oy), Offset(w * 0.38 + ox, h * 0.45 + oy), hudPaint);
        break;

      case AvatarAccessory.goldCyberChain:
        final goldPaint = Paint()
          ..color = const Color(0xFFFFD700)
          ..strokeWidth = math.max(3.0, w * 0.04)
          ..style = PaintingStyle.stroke;
        canvas.drawArc(
          Rect.fromCenter(center: Offset(w * 0.50 + ox, h * 0.68 + oy), width: w * 0.36, height: h * 0.22),
          0.1,
          math.pi - 0.2,
          false,
          goldPaint,
        );
        break;

      case AvatarAccessory.royalCyberCrown:
        final crownPaint = Paint()..color = const Color(0xFFFFD700);
        final crownPath = Path()
          ..moveTo(w * 0.28 + ox, h * 0.16 + oy)
          ..lineTo(w * 0.28 + ox, h * 0.06 + oy)
          ..lineTo(w * 0.38 + ox, h * 0.12 + oy)
          ..lineTo(w * 0.50 + ox, h * 0.02 + oy)
          ..lineTo(w * 0.62 + ox, h * 0.12 + oy)
          ..lineTo(w * 0.72 + ox, h * 0.06 + oy)
          ..lineTo(w * 0.72 + ox, h * 0.16 + oy)
          ..close();
        canvas.drawPath(crownPath, crownPaint);
        break;

      default:
        break;
    }
  }

  void _drawPoseArm(Canvas canvas, Size size, double ox, double oy) {
    if (config.pose == AvatarPose.chillStand) return;

    final w = size.width;
    final h = size.height;
    final handPaint = Paint()..color = config.skinColor;

    if (config.pose == AvatarPose.wavingHand) {
      // Waving Hand with glove/cuff
      canvas.drawCircle(Offset(w * 0.88 + ox, h * 0.55 + oy), w * 0.08, handPaint);
      canvas.drawCircle(Offset(w * 0.88 + ox, h * 0.48 + oy), w * 0.04, handPaint);
    } else if (config.pose == AvatarPose.peaceSign) {
      // Peace sign fingers
      canvas.drawCircle(Offset(w * 0.86 + ox, h * 0.54 + oy), w * 0.07, handPaint);
      canvas.drawLine(
        Offset(w * 0.84 + ox, h * 0.52 + oy),
        Offset(w * 0.82 + ox, h * 0.42 + oy),
        Paint()
          ..color = config.skinColor
          ..strokeWidth = w * 0.04
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(w * 0.88 + ox, h * 0.52 + oy),
        Offset(w * 0.92 + ox, h * 0.42 + oy),
        Paint()
          ..color = config.skinColor
          ..strokeWidth = w * 0.04
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Snap3DAvatarPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.eyeScale != eyeScale ||
        oldDelegate.isTalking != isTalking ||
        oldDelegate.talkingPhase != talkingPhase ||
        oldDelegate.tiltX != tiltX ||
        oldDelegate.tiltY != tiltY;
  }
}
