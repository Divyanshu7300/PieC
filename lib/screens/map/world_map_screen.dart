import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/location_point.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/core/services/auth_service.dart';
import 'package:piec/core/services/chat_service.dart';
import 'package:piec/core/services/convoy_service.dart';
import 'package:piec/core/services/firestore_chat_service.dart';
import 'package:piec/core/services/location_service.dart';
import 'package:piec/core/services/navigation_service.dart';
import 'package:piec/core/services/sentinel_safety_service.dart';
import 'package:piec/core/services/squad_service.dart';
import 'package:piec/core/services/theme_service.dart';
import 'package:piec/screens/chat/chat_room_screen.dart';
import 'package:piec/screens/map/set_location_screen.dart';
import 'package:piec/screens/safety/safe_ride_home_modal.dart';
import 'package:piec/screens/squad/create_squad_modal.dart';
import 'package:piec/screens/squad/squad_chat_room_screen.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';
import 'package:piec/widgets/map/convoy_hud_sheet.dart';
import 'package:piec/widgets/map/friend_map_marker.dart';
import 'package:piec/widgets/map/navigation_directions_hud.dart';
import 'package:piec/widgets/map/poi_category_chips.dart';
import 'package:piec/widgets/map/visit_place_sheet.dart';
import 'package:piec/core/services/firebase_auth_service.dart';
import 'package:piec/widgets/map/spatial_radar_card.dart';
import 'package:provider/provider.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedFriendId;
  List<SearchResultLocation> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  Timer? _debounceTimer;

  final LatLng _initialCenter = const LatLng(28.6150, 77.2100);

  @override
  void initState() {
    super.initState();
    _initLiveGps();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLiveGps() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final firebaseAuth = Provider.of<FirebaseAuthService>(context, listen: false);
    final locationService = Provider.of<LocationService>(context, listen: false);
    final uid = firebaseAuth.currentUser?.id ?? auth.currentUser?.id;

    await locationService.startLocationTracking(currentUserId: uid);
    if (mounted && locationService.currentPosition != null) {
      final pos = locationService.currentPosition!;
      final livePoint = LocationPoint(
        title: 'Current Spot',
        address: locationService.currentAddress,
        latitude: pos.latitude,
        longitude: pos.longitude,
        type: LocationType.live,
        updatedAt: DateTime.now(),
      );
      auth.setLocationTag(live: livePoint);
      _animatedPanTo(livePoint.latLng, zoom: 15.5);
    }
  }

  void _animatedPanTo(LatLng target, {double zoom = 15.5}) {
    _mapController.move(target, zoom);
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final results = await _locationService.searchWorldwideAddresses(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _showSearchResults = results.isNotEmpty;
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final chatService = Provider.of<ChatService>(context);
    final squadService = Provider.of<SquadService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final currentUser = auth.currentUser;
    final isGhostMode = currentUser?.isGhostMode ?? false;

    final activeSquad = squadService.activeSquad;

    // Filter visible friends based on active squad
    final allFriends = <UserModel>[];
    for (final f in chatService.friends) {
      if (!allFriends.any((e) => e.id == f.id)) allFriends.add(f);
    }

    final List<UserModel> visibleFriends = allFriends.where((f) {
      if (activeSquad == null) return true; // Show all
      return activeSquad.members.any((m) => m.id == f.id);
    }).toList();

    final convoyService = Provider.of<ConvoyService>(context);
    final safetyService = Provider.of<SentinelSafetyService>(context);

    // If active squad has a meetup pin, auto-init convoy if needed
    if (activeSquad != null && activeSquad.meetupLocation != null && !convoyService.isConvoyActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        convoyService.initForSquad(activeSquad, currentUser);
      });
    }

    // Collect all active markers
    final List<Marker> markers = [];
    final List<Polyline> polylines = [];

    // 0. If Convoy is active, build moving convoy markers and polyline trails
    if (convoyService.isConvoyActive && convoyService.members.isNotEmpty) {
      for (final m in convoyService.members) {
        // Smooth Google Maps Style Polyline Route
        if (!m.hasArrived) {
          polylines.add(
            Polyline(
              points: [m.currentLatLng, m.destinationLatLng],
              color: const Color(0xFF38BDF8).withOpacity(0.85),
              strokeWidth: 4.0,
              borderColor: const Color(0xFF0F172A).withOpacity(0.6),
              borderStrokeWidth: 1.5,
            ),
          );
        }

        // Google Maps Style Live Avatar Pin
        markers.add(
          Marker(
            point: m.currentLatLng,
            width: 90,
            height: 90,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Clean floating ETA pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: m.hasArrived ? AppColors.accentGreen : const Color(0xFF38BDF8),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    m.hasArrived
                        ? '${m.name.split(' ').first} • Arrived 🎉'
                        : '${m.name.split(' ').first} • ${m.etaMinutes}m',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: m.hasArrived ? AppColors.accentGreen : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 3),

                // Avatar Head with live pointer ring
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (m.hasArrived ? AppColors.accentGreen : const Color(0xFF38BDF8)).withOpacity(0.6),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: GamifiedAvatar(
                    config: m.avatarConfig,
                    size: 38,
                    showGlow: false,
                    isAnimated: false,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      // 1. Current User Live Marker
      if (currentUser != null && currentUser.liveLocation != null && !isGhostMode) {
        markers.add(
          Marker(
            point: currentUser.liveLocation!.latLng,
            width: 70,
            height: 70,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryNeon, width: 1),
                  ),
                  child: Text(
                    currentUser.name.split(' ').first,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNeon,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                GamifiedAvatar(
                  config: currentUser.avatarConfig,
                  size: 44,
                  showGlow: true,
                ),
              ],
            ),
          ),
        );

        // Current User Home Pin
        if (currentUser.homeLocation != null) {
          markers.add(
            Marker(
              point: currentUser.homeLocation!.latLng,
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () => _showMyPlaceDialog(currentUser.homeLocation!),
                child: _buildSimplePlacePin('🏠', 'My Home', AppColors.homeTag),
              ),
            ),
          );
        }

        // Current User Office Pin
        if (currentUser.officeLocation != null) {
          markers.add(
            Marker(
              point: currentUser.officeLocation!.latLng,
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () => _showMyPlaceDialog(currentUser.officeLocation!),
                child: _buildSimplePlacePin('💼', 'My Office', AppColors.officeTag),
              ),
            ),
          );
        }
      }

      // 2. Filtered Friends' Locations
      for (final friend in visibleFriends) {
        if (friend.liveLocation != null) {
          markers.add(
            Marker(
              point: friend.liveLocation!.latLng,
              width: 80,
              height: 85,
              child: FriendMapMarker(
                user: friend,
                locationPoint: friend.liveLocation!,
                isSelected: _selectedFriendId == friend.id,
                onTap: () => _onFriendMarkerTapped(friend, friend.liveLocation!),
              ),
            ),
          );
        }
      }
    }

    // 3. Shared Squad Meetup Destination Pin (if any)
    if (activeSquad?.meetupLocation != null) {
      markers.add(
        Marker(
          point: activeSquad!.meetupLocation!.latLng,
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🚩 ${activeSquad.name} Meetup: ${activeSquad.meetupLocation!.title}'),
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.homeTag, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.homeTag.withOpacity(0.6),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Text(
                    '${activeSquad.emoji} Meetup',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.homeTag),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.homeTag,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🚩', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final navService = Provider.of<NavigationService>(context);

    // 4. Navigation Route Polyline
    if (navService.isNavigating && navService.activeRoute != null) {
      polylines.add(
        Polyline(
          points: navService.activeRoute!.routePoints,
          color: const Color(0xFF00E5FF),
          strokeWidth: 5.0,
          borderColor: Colors.black.withOpacity(0.5),
          borderStrokeWidth: 1.5,
        ),
      );

      // Destination Marker for active navigation
      markers.add(
        Marker(
          point: navService.activeRoute!.destinationLatLng,
          width: 70,
          height: 70,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                ),
                child: Text(
                  navService.activeRoute!.destinationTitle,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF00E5FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_rounded, size: 16, color: Colors.black),
              ),
            ],
          ),
        ),
      );
    }

    // 5. Nearby POIs (Cafes, Food, Fuel, Hospitals, ATMs)
    for (final poi in navService.nearbyPois) {
      markers.add(
        Marker(
          point: poi.latLng,
          width: 75,
          height: 75,
          child: GestureDetector(
            onTap: () {
              final start = currentUser?.liveLocation?.latLng ?? _initialCenter;
              navService.calculateRoute(
                start: start,
                destination: poi.latLng,
                destTitle: poi.title,
                destAddress: poi.address,
              );
              _animatedPanTo(poi.latLng, zoom: 16.0);
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accentYellow),
                  ),
                  child: Text(
                    poi.title.split(' ').first,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: AppColors.accentYellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.place_rounded, size: 14, color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // FlutterMap with dynamic Tile Provider (Satellite / Dark / Streets)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 14.8,
              minZoom: 2,
              maxZoom: 19.0,
              onLongPress: (tapPosition, point) {
                final start = currentUser?.liveLocation?.latLng ?? _initialCenter;
                navService.calculateRoute(
                  start: start,
                  destination: point,
                  destTitle: 'Custom Dropped Pin',
                  destAddress: '${point.latitude.toStringAsFixed(4)}°, ${point.longitude.toStringAsFixed(4)}°',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('📍 Custom Pin Dropped — Turn-by-Turn Route Calculated! 🧭')),
                );
              },
            ),
            children: [
              TileLayer(
                urlTemplate: themeService.getMapTileUrl(),
                userAgentPackageName: 'com.piec.app',
                maxZoom: 19,
              ),
              if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
              MarkerLayer(markers: markers),
            ],
          ),

          // Top Header, Squad Filter Bar & Real Address Search Bar
          Positioned(
            top: 46,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Top Action Bar with Search
                Row(
                  children: [
                    // Search Bar Box
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.surfaceHover),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search city or address...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                            prefixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : const Icon(Icons.search_rounded, color: AppColors.primaryNeon, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchResults = [];
                                        _showSearchResults = false;
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Map Layer Style Switcher Button (Satellite / Dark / Streets)
                    GestureDetector(
                      onTap: () => _showMapStyleSheet(context, themeService),
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.primaryNeon.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _getMapStyleEmoji(themeService.currentMapStyle),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.layers_outlined, size: 16, color: AppColors.primaryNeon),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Ghost Mode Pill
                    GestureDetector(
                      onTap: () {
                        auth.toggleGhostMode(!isGhostMode);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              !isGhostMode
                                  ? '👻 Ghost Mode ON: You are invisible on the map!'
                                  : '📍 Ghost Mode OFF: Friends can see your live avatar!',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isGhostMode
                              ? AppColors.primaryPurple.withOpacity(0.9)
                              : AppColors.surface.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isGhostMode
                                ? AppColors.primaryNeon
                                : AppColors.surfaceHover,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            isGhostMode ? '👻 Ghost' : '📍 Live',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isGhostMode ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 🛰️ Spatial Radar Button
                    GestureDetector(
                      onTap: () {
                        if (currentUser != null) {
                          SpatialRadarModal.show(
                            context,
                            currentUser: currentUser,
                            friends: visibleFriends,
                            onSelectFriend: (friend) {
                              if (friend.liveLocation != null) {
                                _animatedPanTo(friend.liveLocation!.latLng, zoom: 16.0);
                              }
                            },
                          );
                        }
                      },
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.primaryNeon),
                        ),
                        child: Row(
                          children: const [
                            Text('🛰️', style: TextStyle(fontSize: 16)),
                            SizedBox(width: 4),
                            Text(
                              'Radar',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryNeon,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),


                const SizedBox(height: 8),

                // 🌟 Spatial Squads / Circles Switcher Filter Bar
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // All Friends Chip
                      _buildSquadFilterChip(
                        label: '🌐 All Friends (${chatService.friends.length})',
                        isSelected: activeSquad == null,
                        onTap: () => squadService.selectSquadFilter(null),
                      ),

                      // Squad Specific Filter Chips
                      ...squadService.squads.map((squad) {
                        final isSelected = activeSquad?.id == squad.id;
                        return _buildSquadFilterChip(
                          label: '${squad.emoji} ${squad.name} (${squad.members.length})',
                          isSelected: isSelected,
                          onTap: () => squadService.selectSquadFilter(squad.id),
                          onLongPress: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SquadChatRoomScreen(squad: squad),
                              ),
                            );
                          },
                        );
                      }),

                      // Create New Squad Button
                      GestureDetector(
                        onTap: () => CreateSquadModal.show(context),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.primaryNeon),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.add_rounded, size: 16, color: AppColors.primaryNeon),
                              SizedBox(width: 4),
                              Text(
                                'New Squad',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryNeon,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Nearby Quick Category Discovery Chips (☕ Cafes, 🍕 Food, ⛽ Fuel, 🏥 Medical, 🏧 ATMs)
                PoiCategoryChips(mapCenter: currentUser?.liveLocation?.latLng ?? _initialCenter),

                // Active Squad Destination Banner (if set)
                if (activeSquad?.meetupLocation != null)
                  GestureDetector(
                    onTap: () {
                      _animatedPanTo(activeSquad!.meetupLocation!.latLng, zoom: 16.5);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2A1435), Color(0xFF160924)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.homeTag, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.homeTag.withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Text('🚩', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${activeSquad!.name} Meetup: ${activeSquad.meetupLocation!.title}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Text(
                            'Fly to 📍',
                            style: TextStyle(fontSize: 11, color: AppColors.primaryNeon, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Live Address Search Results Dropdown Card
                if (_showSearchResults && _searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryNeon.withOpacity(0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 16,
                        )
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(color: AppColors.surfaceLight, height: 1),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          tileColor: Colors.transparent,
                          dense: true,
                          leading: const Icon(Icons.location_pin, color: AppColors.primaryNeon, size: 20),
                          title: Text(
                            result.displayName,
                            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            setState(() => _showSearchResults = false);
                            _searchController.text = result.displayName.split(',').first;
                            _animatedPanTo(result.latLng, zoom: 16.0);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Floating Action Buttons (Right Side)
          Positioned(
            right: 16,
            bottom: 140,
            child: Column(
              children: [
                // Squad Group Chat Shortcut
                if (activeSquad != null)
                  FloatingActionButton.small(
                    heroTag: 'btn_squad_chat',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SquadChatRoomScreen(squad: activeSquad),
                        ),
                      );
                    },
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primaryNeon,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.primaryNeon),
                    ),
                    child: Text(activeSquad.emoji, style: const TextStyle(fontSize: 18)),
                  ),
                if (activeSquad != null) const SizedBox(height: 10),

                // Tag Home/Office Button
                FloatingActionButton.small(
                  heroTag: 'btn_tag_location',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SetLocationScreen(),
                      ),
                    );
                  },
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.accentYellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.surfaceHover),
                  ),
                  child: const Text('🏠', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 10),

                // Zoom In Button
                FloatingActionButton.small(
                  heroTag: 'btn_zoom_in',
                  onPressed: () {
                    final currZoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, currZoom + 1.0);
                  },
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primaryNeon,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.surfaceHover),
                  ),
                  child: const Icon(Icons.add_rounded, size: 20),
                ),
                const SizedBox(height: 8),

                // Zoom Out Button
                FloatingActionButton.small(
                  heroTag: 'btn_zoom_out',
                  onPressed: () {
                    final currZoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, currZoom - 1.0);
                  },
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primaryNeon,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.surfaceHover),
                  ),
                  child: const Icon(Icons.remove_rounded, size: 20),
                ),
                const SizedBox(height: 10),

                // Safe-Ride Sentinel / SOS Button
                FloatingActionButton.small(
                  heroTag: 'btn_safety_sentinel',
                  onPressed: () => SafeRideHomeModal.show(context),
                  backgroundColor: safetyService.isRideSentinelActive
                      ? AppColors.accentGreen
                      : (safetyService.isSosPanicActive ? const Color(0xFFEF4444) : AppColors.surface),
                  foregroundColor: safetyService.isRideSentinelActive || safetyService.isSosPanicActive
                      ? Colors.black
                      : AppColors.accentGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: safetyService.isRideSentinelActive ? AppColors.accentGreen : AppColors.surfaceHover,
                    ),
                  ),
                  child: Text(
                    safetyService.isSosPanicActive ? '🚨' : '🛡️',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 10),

                // Recenter GPS Button
                FloatingActionButton.small(
                  heroTag: 'btn_recenter',
                  onPressed: () async {
                    final pos = await _locationService.getCurrentPosition();
                    if (pos != null) {
                      _animatedPanTo(LatLng(pos.latitude, pos.longitude), zoom: 16.0);
                    } else if (currentUser?.liveLocation != null) {
                      _animatedPanTo(currentUser!.liveLocation!.latLng);
                    } else {
                      _animatedPanTo(_initialCenter);
                    }
                  },
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primaryNeon,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.surfaceHover),
                  ),
                  child: const Icon(Icons.my_location_rounded, size: 20),
                ),
              ],
            ),
          ),

          // Safe Arrival Geofence Notification Toast Banner
          if (safetyService.safeArrivalAlert != null)
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGreen.withOpacity(0.5),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🏠', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        safetyService.safeArrivalAlert!,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.black, size: 18),
                      onPressed: () => safetyService.dismissSafeArrivalAlert(),
                    ),
                  ],
                ),
              ),
            ),

          // Emergency SOS Active Banner
          if (safetyService.sosBroadcastMessage != null)
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x99EF4444),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🚨', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        safetyService.sosBroadcastMessage!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () => safetyService.cancelSos(),
                      child: const Text('DISMISS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),

          // Turn-by-Turn Navigation HUD (if Navigating)
          if (navService.isNavigating && navService.activeRoute != null)
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: NavigationDirectionsHud(route: navService.activeRoute!),
            ),

          // Convoy Live Trip HUD Sheet (if Convoy is Active)
          if (convoyService.isConvoyActive && activeSquad != null && !navService.isNavigating)
            Positioned(
              left: 0,
              right: 0,
              bottom: 125,
              child: ConvoyHudSheet(squad: activeSquad),
            ),

          // Bottom Friends Quick Bar (Filters to active squad)
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: SizedBox(
              height: 105,
              child: visibleFriends.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text('No other members in this circle yet'),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: visibleFriends.length,
                      itemBuilder: (context, index) {
                        final friend = visibleFriends[index];
                        final isSelected = _selectedFriendId == friend.id;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedFriendId = friend.id);
                            if (friend.liveLocation != null) {
                              _animatedPanTo(friend.liveLocation!.latLng, zoom: 16.0);
                              _onFriendMarkerTapped(friend, friend.liveLocation!);
                            }
                          },
                          child: Container(
                            width: 145,
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withOpacity(0.94),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryNeon
                                    : AppColors.surfaceHover,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppColors.primaryNeon.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                GamifiedAvatar(
                                  config: friend.avatarConfig,
                                  size: 44,
                                  showGlow: isSelected,
                                  isAnimated: false,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        friend.name.split(' ').first,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        friend.statusText,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: friend.isOnline
                                                  ? AppColors.online
                                                  : AppColors.offline,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            friend.isOnline ? 'Online' : 'Offline',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: friend.isOnline
                                                  ? AppColors.online
                                                  : AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquadFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryNeon.withOpacity(0.2)
              : AppColors.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primaryNeon : AppColors.surfaceHover,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primaryNeon.withOpacity(0.3),
                blurRadius: 8,
              ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primaryNeon : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  void _showMapStyleSheet(BuildContext context, ThemeService themeService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.primaryNeon, width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Real Map Style 🗺️',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildMapOption(
                  '🛰️ Real Satellite',
                  'Space high-res photography',
                  MapTileStyle.satellite,
                  themeService,
                ),
                _buildMapOption(
                  '🌌 Dark Matter',
                  'Cyber dark streets',
                  MapTileStyle.darkMatter,
                  themeService,
                ),
                _buildMapOption(
                  '🗺️ Real OpenStreetMap',
                  'Roads, stations & streets',
                  MapTileStyle.openStreetMap,
                  themeService,
                ),
                _buildMapOption(
                  '🧭 Voyager Crisp',
                  'Modern clean vector navigation',
                  MapTileStyle.voyager,
                  themeService,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildMapOption(
    String title,
    String subtitle,
    MapTileStyle style,
    ThemeService themeService,
  ) {
    final isSelected = themeService.currentMapStyle == style;
    return GestureDetector(
      onTap: () {
        themeService.setMapStyle(style);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryNeon.withOpacity(0.15)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryNeon : AppColors.surfaceHover,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primaryNeon, size: 20),
          ],
        ),
      ),
    );
  }

  String _getMapStyleEmoji(MapTileStyle style) {
    switch (style) {
      case MapTileStyle.satellite:
        return '🛰️';
      case MapTileStyle.openStreetMap:
        return '🗺️';
      case MapTileStyle.voyager:
        return '🧭';
      case MapTileStyle.darkMatter:
      default:
        return '🌌';
    }
  }

  Widget _buildSimplePlacePin(String emoji, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 8,
              ),
            ],
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  void _onFriendMarkerTapped(UserModel friend, LocationPoint locationPoint) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);

    VisitPlaceSheet.show(
      context,
      user: friend,
      locationPoint: locationPoint,
      currentUserLocation: auth.currentUser?.liveLocation,
      onStartChat: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(friend: friend),
          ),
        );
      },
      onWave: () {
        if (auth.currentUser != null) {
          chatService.sendMessage(
            currentUserId: auth.currentUser!.id,
            friendId: friend.id,
            text: '👋 *Waved at your ${locationPoint.title} pin!*',
            avatarReaction: '👋',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Waved at ${friend.name}\'s ${locationPoint.title}! 👋'),
            ),
          );
        }
      },
    );
  }

  void _showMyPlaceDialog(LocationPoint point) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(point.iconEmoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(point.title, style: const TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Text(
          'Address: ${point.address}\nCoordinates: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SetLocationScreen(initialType: point.type),
                ),
              );
            },
            child: const Text('Edit Pin 📍'),
          ),
        ],
      ),
    );
  }
}
