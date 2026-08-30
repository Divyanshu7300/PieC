import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/services/auth_service.dart';
import 'package:piec/core/services/firebase_auth_service.dart';
import 'package:piec/screens/main_navigation_screen.dart';
import 'package:piec/widgets/avatar/avatar_customizer_modal.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';
import 'package:provider/provider.dart';

class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.currentUser != null) {
      _nameController.text = auth.currentUser!.name;
      _usernameController.text = auth.currentUser!.username;
    } else {
      _nameController.text = 'Cyber Voyager';
      _usernameController.text = 'voyager_99';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final firebaseAuth = Provider.of<FirebaseAuthService>(context);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Profile & Avatar'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Create Your Spatial Identity 👾',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'This avatar will represent you on the map and during chats',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Interactive Avatar Card
              if (user != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.surfaceHover),
                  ),
                  child: Column(
                    children: [
                      GamifiedAvatar(
                        config: user.avatarConfig,
                        size: 110,
                        showGlow: true,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          AvatarCustomizerModal.show(
                            context,
                            initialConfig: user.avatarConfig,
                            onSave: (newConfig) {
                              auth.updateAvatarConfig(newConfig);
                            },
                          );
                        },
                        icon: const Icon(Icons.palette_outlined, size: 18),
                        label: const Text('Customize 3D Avatar 🎨'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceLight,
                          foregroundColor: AppColors.primaryNeon,
                          side: const BorderSide(color: AppColors.primaryNeon),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Full Name Field
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'e.g. Rahul Sharma / Cyber Knight',
                  prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primaryNeon),
                ),
              ),
              const SizedBox(height: 16),

              // Unique Username Field
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Unique Username',
                  hintText: 'e.g. rahul_99',
                  prefixIcon: Icon(Icons.alternate_email_rounded, color: AppColors.accentPink),
                ),
              ),

              const SizedBox(height: 30),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = _nameController.text.trim();
                    final username = _usernameController.text.trim();
                    if (name.isEmpty || username.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter name and username')),
                      );
                      return;
                    }

                    try {
                      await firebaseAuth.completeProfile(
                        name: name,
                        username: username,
                        avatarConfig: user?.avatarConfig.toMap(),
                      );
                    } on ArgumentError catch (error) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message?.toString() ?? 'Invalid profile')));
                      }
                      return;
                    }
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MainNavigationScreen(),
                        ),
                      );
                    }
                  },
                  child: const Text('Enter Spatial World 🚀'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
