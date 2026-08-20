import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/avatar_config.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/core/services/auth_service.dart';
import 'package:piec/core/services/firebase_auth_service.dart';
import 'package:piec/screens/auth/otp_screen.dart';
import 'package:piec/screens/auth/setup_profile_screen.dart';
import 'package:piec/screens/main_navigation_screen.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _selectedTab = 0; // 0: Mobile OTP, 1: Email & Password
  bool _isSignUp = false;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseAuth = Provider.of<FirebaseAuthService>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Glowing App Avatar Badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [AppColors.primaryNeon, Colors.transparent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryNeon.withOpacity(0.25),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const GamifiedAvatar(
                  config: AvatarConfig(
                    hairStyle: HairStyle.cyberPunkFade,
                    hairBaseColorHex: 0xFF1C1427,
                    hairHighlightColorHex: 0xFF00F0FF,
                    irisColor: IrisColor.cyberCyan,
                    facialHair: FacialHair.stubbleShadow,
                    outfitStyle: OutfitStyle.cyberHoodieWithGlow,
                    outfitPrimaryColorHex: 0xFF8B5CF6,
                    outfitSecondaryColorHex: 0xFF00F0FF,
                    accessory: AvatarAccessory.studioHeadphonesLed,
                    auraEffect: AvatarAuraEffect.none,
                    glowColorHex: 0xFF00F0FF,
                  ),
                  size: 76,
                  showGlow: false,
                ),
              ),
              const SizedBox(height: 12),

              // App Name
              ShaderMask(
                shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                child: const Text(
                  'PieC Spatial',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Live 3D Map, E2EE Encrypted Chat & Safety Sentinel',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Method Switcher (Phone vs Email)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? AppColors.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedTab == 0
                                ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.phone_android_rounded, size: 16, color: AppColors.primaryNeon),
                              SizedBox(width: 6),
                              Text('Mobile OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? AppColors.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedTab == 1
                                ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.email_rounded, size: 16, color: AppColors.primaryNeon),
                              SizedBox(width: 6),
                              Text('Email / Pass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Tab 0: Phone OTP
              if (_selectedTab == 0) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Enter Phone Number 📱',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.surfaceHover),
                      ),
                      child: const Text('🇮🇳 +91', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '98765 43210',
                          prefixIcon: Icon(Icons.phone_rounded, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: firebaseAuth.isLoading
                        ? null
                        : () async {
                            final rawPhone = _phoneController.text.trim();
                            if (rawPhone.isEmpty || rawPhone.length < 10) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
                              );
                              return;
                            }
                            final phone = '+91$rawPhone';
                            await firebaseAuth.sendOtp(phone);
                            if (mounted) {
                              if (firebaseAuth.errorMessage != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Firebase Error: ${firebaseAuth.errorMessage}')),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OtpScreen(phoneNumber: phone),
                                  ),
                                );
                              }
                            }
                          },
                    child: firebaseAuth.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Send SMS OTP 🚀', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],

              // Tab 1: Email & Password
              if (_selectedTab == 1) ...[
                if (_isSignUp) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text('Your Full Name 👤', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Divyanshu Nagar',
                      prefixIcon: Icon(Icons.person_rounded, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text('Email Address ✉️', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'name@example.com',
                    prefixIcon: Icon(Icons.email_rounded, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text('Password 🔐', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: Icon(Icons.lock_rounded, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: firebaseAuth.isLoading
                        ? null
                        : () async {
                            final email = _emailController.text.trim();
                            final password = _passwordController.text.trim();
                            if (email.isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter both email and password')),
                              );
                              return;
                            }
                            if (_isSignUp) {
                              final name = _nameController.text.trim();
                              final success = await firebaseAuth.signUpWithEmail(
                                email: email,
                                password: password,
                                name: name,
                              );
                              if (success && mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SetupProfileScreen()),
                                );
                              } else if (mounted && firebaseAuth.errorMessage != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(firebaseAuth.errorMessage!)),
                                );
                              }
                            } else {
                              final success = await firebaseAuth.signInWithEmail(email, password);
                              if (success && mounted) {
                                final isComplete = await firebaseAuth.isProfileComplete();
                                if (!mounted) return;
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => isComplete
                                        ? const MainNavigationScreen()
                                        : const SetupProfileScreen(),
                                  ),
                                );
                              } else if (mounted && firebaseAuth.errorMessage != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(firebaseAuth.errorMessage!)),
                                );
                              }
                            }
                          },
                    child: firebaseAuth.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isSignUp ? 'Create New Account 🚀' : 'Sign In 🔑', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign In'
                        : "Don't have an account? Sign Up",
                    style: const TextStyle(color: AppColors.primaryNeon, fontWeight: FontWeight.bold),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(color: AppColors.surfaceHover, height: 1),
              const SizedBox(height: 16),

              // Quick Explorer 1-Tap Access Button
              OutlinedButton.icon(
                onPressed: () async {
                  final auth = Provider.of<AuthService>(context, listen: false);
                  final deviceId = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
                  final user = UserModel(
                    id: 'user_$deviceId',
                    name: 'PieC Explorer $deviceId',
                    username: 'explorer_$deviceId',
                    publicKey: 'pk_$deviceId',
                    lastActive: DateTime.now(),
                  );
                  await auth.saveCurrentUser(user);
                  try {
                    await FirebaseFirestore.instance.collection('users').doc(user.id).set(
                      user.toFirestore(),
                      SetOptions(merge: true),
                    );
                  } catch (e) {
                    debugPrint('Firestore Quick Access save error: $e');
                  }
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                    );
                  }
                },
                icon: const Icon(Icons.flash_on_rounded, color: AppColors.primaryNeon, size: 18),
                label: const Text('Instant Quick Access ⚡ (1-Tap)', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryNeon,
                  side: const BorderSide(color: AppColors.primaryNeon),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                '100% Client-Side AES-256 E2EE Protected & Zero Knowledge Architecture.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
