import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppUiTheme {
  cyberNeon, // Flagship Futuristic Cyan & Purple
  minimalPureWhite, // Apple / iOS Clean White
  minimalPitchBlack, // Pure OLED Stealth Black
  sakuraSunset, // Tokyo Anime Pastel & Magenta
  nordicSage, // Earthy Forest & Calm Green
  retroSynthwave, // 80s Arcade Neon Pink & Gold
}

enum MapTileStyle {
  satellite, // Real Space Satellite Photography
  darkMatter, // Cyber Dark CartoDB
  openStreetMap, // Standard Real Street & Road Map
  voyager, // Modern Voyager Vector Clean
}

class ThemeService extends ChangeNotifier {
  static const String _keyUiTheme = 'piec_ui_theme_v2';
  static const String _keyMapStyle = 'piec_map_style_v2';
  static const String _keyBubbleStyle = 'piec_bubble_style';

  AppUiTheme _currentTheme = AppUiTheme.cyberNeon;
  MapTileStyle _currentMapStyle = MapTileStyle.darkMatter;
  int _bubbleCornerRadius = 18; // 18: Modern Curved, 8: Angular Cyber, 24: Pill

  AppUiTheme get currentTheme => _currentTheme;
  MapTileStyle get currentMapStyle => _currentMapStyle;
  int get bubbleCornerRadius => _bubbleCornerRadius;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_keyUiTheme);
    if (themeIndex != null && themeIndex < AppUiTheme.values.length) {
      _currentTheme = AppUiTheme.values[themeIndex];
    }
    final mapIndex = prefs.getInt(_keyMapStyle);
    if (mapIndex != null && mapIndex < MapTileStyle.values.length) {
      _currentMapStyle = MapTileStyle.values[mapIndex];
    }
    _bubbleCornerRadius = prefs.getInt(_keyBubbleStyle) ?? 18;
    notifyListeners();
  }

  Future<void> setUiTheme(AppUiTheme theme) async {
    _currentTheme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUiTheme, theme.index);
  }

  Future<void> setMapStyle(MapTileStyle mapStyle) async {
    _currentMapStyle = mapStyle;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMapStyle, mapStyle.index);
  }

  Future<void> setBubbleRadius(int radius) async {
    _bubbleCornerRadius = radius;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBubbleStyle, radius);
  }

  String getMapTileUrl() {
    switch (_currentMapStyle) {
      case MapTileStyle.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapTileStyle.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapTileStyle.voyager:
        return 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
      case MapTileStyle.darkMatter:
      default:
        return 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
    }
  }

  // Active theme helper colors
  bool get isLightMode => _currentTheme == AppUiTheme.minimalPureWhite;

  Color get activePrimaryColor {
    switch (_currentTheme) {
      case AppUiTheme.minimalPureWhite:
        return const Color(0xFF007AFF); // Apple iOS Blue
      case AppUiTheme.minimalPitchBlack:
        return Colors.white; // Monochrome Minimal
      case AppUiTheme.sakuraSunset:
        return const Color(0xFFFF2A85); // Neon Pink
      case AppUiTheme.nordicSage:
        return const Color(0xFF10B981); // Emerald Sage
      case AppUiTheme.retroSynthwave:
        return const Color(0xFFFF007F); // Synthwave Pink
      case AppUiTheme.cyberNeon:
      default:
        return AppColors.primaryNeon;
    }
  }

  Color get activeSurfaceColor {
    switch (_currentTheme) {
      case AppUiTheme.minimalPureWhite:
        return Colors.white;
      case AppUiTheme.minimalPitchBlack:
        return const Color(0xFF0D0D0D);
      case AppUiTheme.sakuraSunset:
        return const Color(0xFF220D38);
      case AppUiTheme.nordicSage:
        return const Color(0xFF131D24);
      case AppUiTheme.retroSynthwave:
        return const Color(0xFF1A0B2E);
      case AppUiTheme.cyberNeon:
      default:
        return AppColors.surface;
    }
  }

  Color get activeSurfaceLightColor {
    switch (_currentTheme) {
      case AppUiTheme.minimalPureWhite:
        return const Color(0xFFF1F5F9);
      case AppUiTheme.minimalPitchBlack:
        return const Color(0xFF1A1A1A);
      case AppUiTheme.cyberNeon:
      default:
        return AppColors.surfaceLight;
    }
  }

  Color get activeBackgroundColor {
    switch (_currentTheme) {
      case AppUiTheme.minimalPureWhite:
        return const Color(0xFFF8FAFC);
      case AppUiTheme.minimalPitchBlack:
        return Colors.black;
      case AppUiTheme.sakuraSunset:
        return const Color(0xFF160924);
      case AppUiTheme.nordicSage:
        return const Color(0xFF0C1419);
      case AppUiTheme.retroSynthwave:
        return const Color(0xFF10061E);
      case AppUiTheme.cyberNeon:
      default:
        return AppColors.background;
    }
  }

  Color get activeTextPrimaryColor {
    return isLightMode ? const Color(0xFF0F172A) : AppColors.textPrimary;
  }

  Color get myMessageBubbleColor {
    switch (_currentTheme) {
      case AppUiTheme.minimalPureWhite:
        return const Color(0xFF007AFF); // iOS Blue
      case AppUiTheme.minimalPitchBlack:
        return const Color(0xFF262626); // Matte Charcoal
      case AppUiTheme.sakuraSunset:
        return const Color(0xFFFF2A85); // Pink
      case AppUiTheme.nordicSage:
        return const Color(0xFF059669); // Forest
      case AppUiTheme.retroSynthwave:
        return const Color(0xFF8B5CF6); // Synth Purple
      case AppUiTheme.cyberNeon:
      default:
        return const Color(0xFF6366F1);
    }
  }

  ThemeData get currentThemeData {
    switch (_currentTheme) {
      // 1. Minimal Pure White (iOS Clean)
      case AppUiTheme.minimalPureWhite:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          primaryColor: const Color(0xFF007AFF),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF007AFF),
            secondary: Color(0xFF64748B),
            surface: Colors.white,
            background: Color(0xFFF8FAFC),
          ),
          textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xFF0F172A)),
            titleTextStyle: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF007AFF), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        );

      // 2. Minimal Pitch Black (OLED Stealth)
      case AppUiTheme.minimalPitchBlack:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          primaryColor: Colors.white,
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            secondary: Color(0xFF737373),
            surface: Color(0xFF0D0D0D),
            background: Colors.black,
          ),
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF0D0D0D),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF262626)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF141414),
            hintStyle: const TextStyle(color: Color(0xFF737373), fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF262626))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        );

      // 3. Sakura Sunset (Pastel Tokyo)
      case AppUiTheme.sakuraSunset:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF160924),
          primaryColor: const Color(0xFFFF2A85),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFF2A85),
            secondary: Color(0xFFFFD600),
            surface: Color(0xFF230F38),
            background: Color(0xFF160924),
          ),
          textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF230F38),
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF2B1445),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF45206E)),
            ),
          ),
        );

      // 4. Nordic Sage (Earthy Forest Calm)
      case AppUiTheme.nordicSage:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0C1318),
          primaryColor: const Color(0xFF10B981),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF10B981),
            secondary: Color(0xFF06B6D4),
            surface: Color(0xFF131D24),
            background: Color(0xFF0C1318),
          ),
          textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF131D24),
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF19252E),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF253745)),
            ),
          ),
        );

      // 5. Retro Synthwave (80s Arcade)
      case AppUiTheme.retroSynthwave:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF120524),
          primaryColor: const Color(0xFFFF007F),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFF007F),
            secondary: Color(0xFF00FFFF),
            surface: Color(0xFF1D0938),
            background: Color(0xFF120524),
          ),
          textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1D0938),
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF260D4A),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFFF007F), width: 1),
            ),
          ),
        );

      // 6. Cyber Neon (Default Flagship)
      case AppUiTheme.cyberNeon:
      default:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          primaryColor: AppColors.primaryNeon,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primaryNeon,
            secondary: AppColors.primaryPurple,
            surface: AppColors.surface,
            background: AppColors.background,
          ),
          textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.surface,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          cardTheme: CardThemeData(
            color: AppColors.surface,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.surfaceLight),
            ),
          ),
        );
    }
  }
}
