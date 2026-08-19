import 'package:flutter/material.dart';
import 'package:piec/core/services/auth_service.dart';
import 'package:piec/core/services/call_service.dart';
import 'package:piec/core/services/chat_service.dart';
import 'package:piec/core/services/convoy_service.dart';
import 'package:piec/core/services/friend_service.dart';
import 'package:piec/core/services/navigation_service.dart';
import 'package:piec/core/services/p2p_fastdrop_service.dart';
import 'package:piec/core/services/sentinel_safety_service.dart';
import 'package:piec/core/services/squad_service.dart';
import 'package:piec/core/services/story_service.dart';
import 'package:piec/core/services/theme_service.dart';
import 'package:piec/screens/auth/login_screen.dart';
import 'package:piec/screens/main_navigation_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  await authService.init();

  final themeService = ThemeService();
  await themeService.init();

  final chatService = ChatService();
  final friendService = FriendService();
  final squadService = SquadService();
  final storyService = StoryService();
  final callService = CallService();
  final convoyService = ConvoyService();
  final navigationService = NavigationService();
  final safetyService = SentinelSafetyService();
  final p2pService = P2pFastDropService();

  if (authService.currentUser != null) {
    await chatService.init(authService.currentUser!.id);
    await friendService.init(authService.currentUser!.id);
    await squadService.init(authService.currentUser, chatService);
    await storyService.init(authService.currentUser, chatService);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: chatService),
        ChangeNotifierProvider.value(value: friendService),
        ChangeNotifierProvider.value(value: squadService),
        ChangeNotifierProvider.value(value: storyService),
        ChangeNotifierProvider.value(value: callService),
        ChangeNotifierProvider.value(value: convoyService),
        ChangeNotifierProvider.value(value: navigationService),
        ChangeNotifierProvider.value(value: safetyService),
        ChangeNotifierProvider.value(value: p2pService),
      ],
      child: const PieCApp(),
    ),
  );
}

class PieCApp extends StatelessWidget {
  const PieCApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final themeService = Provider.of<ThemeService>(context);

    // If user logs in later, initialize chats
    if (auth.currentUser != null) {
      final chatService = Provider.of<ChatService>(context, listen: false);
      if (chatService.friends.isEmpty) {
        chatService.init(auth.currentUser!.id);
      }
    }

    return MaterialApp(
      title: 'PieC Spatial - Gamified Map & E2EE Chat',
      debugShowCheckedModeBanner: false,
      theme: themeService.currentThemeData,
      home: auth.isAuthenticated
          ? const MainNavigationScreen()
          : const LoginScreen(),
    );
  }
}
