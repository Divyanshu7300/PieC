import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/crypto/e2ee_engine.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';

class SecurityScreen extends StatefulWidget {
  final UserModel currentUser;
  final UserModel friendUser;

  const SecurityScreen({
    super.key,
    required this.currentUser,
    required this.friendUser,
  });

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _isCodeRevealed = false;

  @override
  Widget build(BuildContext context) {
    final crypto = E2EEEngine();
    final safetyFingerprint = crypto.generateSafetyFingerprint(
      widget.currentUser.id,
      widget.friendUser.id,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Encryption & Security'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Shield & Lock Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentGreen.withOpacity(0.12),
                border: Border.all(color: AppColors.accentGreen, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGreen.withOpacity(0.2),
                    blurRadius: 20,
                  )
                ],
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                size: 48,
                color: AppColors.accentGreen,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'End-to-End Encrypted Chat',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Messages & calls with ${widget.friendUser.name} are secured with Zero-Knowledge encryption. No third party can read them.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Visual Avatars Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GamifiedAvatar(config: widget.currentUser.avatarConfig, size: 54, showGlow: false),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: const [
                      Icon(Icons.lock_rounded, color: AppColors.accentGreen, size: 20),
                      SizedBox(width: 4),
                      Text('🔒 ────── 🔒', style: TextStyle(color: AppColors.accentGreen)),
                    ],
                  ),
                ),
                GamifiedAvatar(config: widget.friendUser.avatarConfig, size: 54, showGlow: false),
              ],
            ),

            const SizedBox(height: 32),

            // Safety Verification Card (Masked by default)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.shield_outlined, size: 16, color: AppColors.primaryNeon),
                      SizedBox(width: 6),
                      Text(
                        'E2EE SAFETY VERIFICATION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AppColors.primaryNeon,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceHover),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isCodeRevealed
                              ? safetyFingerprint
                              : '••••  ••••  ••••  ${safetyFingerprint.substring(safetyFingerprint.length - 4)}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: _isCodeRevealed ? 3 : 2,
                            color: _isCodeRevealed ? AppColors.accentGreen : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextButton.icon(
                    onPressed: () => setState(() => _isCodeRevealed = !_isCodeRevealed),
                    icon: Icon(
                      _isCodeRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 16,
                      color: AppColors.primaryNeon,
                    ),
                    label: Text(
                      _isCodeRevealed ? 'Hide Safety Number' : 'Reveal Safety Number 👁️',
                      style: const TextStyle(fontSize: 12, color: AppColors.primaryNeon, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Text(
                    'Your cryptographic identity keys are private and stored locally on your device.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Copy Verification Code Button (Only when revealed)
            if (_isCodeRevealed)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: safetyFingerprint));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Safety verification code copied! 📋')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy Safety Number'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.primaryNeon),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
