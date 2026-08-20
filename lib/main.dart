import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:piec/firebase_options.dart';
import 'package:piec/core/services/auth_service.dart';
import 'package:piec/core/services/firebase_auth_service.dart';
import 'package:piec/core/services/firestore_chat_service.dart';
import 'package:piec/core/services/call_service.dart';
import 'package:piec/core/services/chat_service.dart';
import 'package:piec/core/services/convoy_service.dart';
import 'package:piec/core/services/friend_service.dart';
import 'package:piec/core/services/location_service.dart';
import 'package:piec/core/services/navigation_service.dart';
import 'package:piec/core/services/notification_service.dart';
import 'package:piec/core/services/p2p_fastdrop_service.dart';
import 'package:piec/core/services/sentinel_safety_service.dart';
import 'package:piec/core/services/squad_service.dart';
import 'package:piec/core/services/story_service.dart';
import 'package:piec/core/services/theme_service.dart';
import 'package:piec/screens/auth/login_screen.dart';
import 'package:piec/screens/main_navigation_screen.dart';
import 'package:piec/widgets/notifications/dynamic_island_notification_banner.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase safely
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  final authService = AuthService();
  final firebaseAuthService = FirebaseAuthService();
  final firestoreChatService = FirestoreChatService();
  final locationService = LocationService();
  final themeService = ThemeService();
  final chatService = ChatService();
  final friendService = FriendService();
  final squadService = SquadService();
  final storyService = StoryService();
  final callService = CallService();
  final convoyService = ConvoyService();
  final navigationService = NavigationService();
  final safetyService = SentinelSafetyService();
  final p2pService = P2pFastDropService();
  final notificationService = NotificationService();

  // Persistent login session initialization
  await authService.init();
  await themeService.init();
  notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: firebaseAuthService),
        ChangeNotifierProvider.value(value: firestoreChatService),
        ChangeNotifierProvider.value(value: locationService),
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: notificationService),
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
    final firebaseAuth = Provider.of<FirebaseAuthService>(context);
    final auth = Provider.of<AuthService>(context);
    final themeService = Provider.of<ThemeService>(context);

    final isAuthenticated = firebaseAuth.isLoggedIn || auth.isAuthenticated;

    return MaterialApp(
      title: 'PieC Spatial - Gamified Map & E2EE Chat',
      debugShowCheckedModeBanner: false,
      theme: themeService.currentThemeData,
      home: DynamicIslandNotificationWrapper(
        child: isAuthenticated
            ? const MainNavigationScreen()
            : const LoginScreen(),
      ),
    );
  }
}

