import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/services/firebase_auth_service.dart';
import 'package:piec/screens/auth/setup_profile_screen.dart';
import 'package:piec/screens/main_navigation_screen.dart';
import 'package:provider/provider.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseAuth = Provider.of<FirebaseAuthService>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Phone')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text('Enter 6-Digit Code 🔐',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text('We sent a verification code to ${widget.phoneNumber}',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 30),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 12, color: AppColors.primaryNeon),
                decoration: InputDecoration(
                  counterText: '',
                  fillColor: AppColors.surface,
                  hintText: '------',
                  hintStyle: TextStyle(color: AppColors.textMuted, letterSpacing: 12, fontSize: 28),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              if (firebaseAuth.errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(firebaseAuth.errorMessage!,
                        style: const TextStyle(fontSize: 13, color: Colors.red))),
                  ]),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: firebaseAuth.isLoading
                      ? null
                      : () async {
                          final otp = _otpController.text.trim();
                          if (otp.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter the 6-digit OTP')));
                            return;
                          }
                          final success = await firebaseAuth.verifyOtp(otp);
                          if (!mounted) return;
                          if (success) {
                            final isComplete = await firebaseAuth.isProfileComplete();
                            if (!mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => isComplete
                                      ? const MainNavigationScreen()
                                      : const SetupProfileScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(firebaseAuth.errorMessage ?? 'Invalid OTP. Try again.')));
                          }
                        },
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: firebaseAuth.isLoading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verify & Login 🚀',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
