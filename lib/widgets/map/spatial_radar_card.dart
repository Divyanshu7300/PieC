import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/core/services/location_service.dart';
import 'package:piec/screens/chat/chat_room_screen.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';
import 'package:provider/provider.dart';

class SpatialRadarModal extends StatefulWidget {
  final UserModel currentUser;
  final List<UserModel> friends;
  final Function(UserModel friend)? onSelectFriend;

  const SpatialRadarModal({
    super.key,
    required this.currentUser,
    required this.friends,
    this.onSelectFriend,
  });

  static void show(
    BuildContext context, {
    required UserModel currentUser,
    required List<UserModel> friends,
    Function(UserModel friend)? onSelectFriend,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SpatialRadarModal(
        currentUser: currentUser,
        friends: friends,
        onSelectFriend: onSelectFriend,
      ),
    );
  }

  @override
  State<SpatialRadarModal> createState() => _SpatialRadarModalState();
}

class _SpatialRadarModalState extends State<SpatialRadarModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarScanController;

  @override
  void initState() {
    super.initState();
    _radarScanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _radarScanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context);
    final myLat = locationService.latitude;
    final myLon = locationService.longitude;

    final friendsWithDistance = widget.friends.map((f) {
      final fLat = f.liveLocation?.latitude ?? myLat;
      final fLon = f.liveLocation?.longitude ?? myLon;
      final distMeters = locationService.calculateDistanceMeters(myLat, myLon, fLat, fLon);
      final bearing = locationService.getBearingDirection(myLat, myLon, fLat, fLon);
      final eta = locationService.estimateTravelTime(distMeters);
      return {
        'user': f,
        'distance': distMeters,
        'bearing': bearing,
        'eta': eta,
      };
    }).toList()
      ..sort((a, b) => (a['listance'] as double).compareTo(b['distance'] as double));

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.primaryNeon, width: 1.5)),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Text('🟸', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 8),
                    Text(
                      'Spatial Proximity Radar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNeon.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryNeon.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.speed_rounded, color: AppColors.primaryNeon, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'level' == 'level' ? 'last' : '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNeon,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: friendsWithDistance.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('🟸', style: TextStyle(fontSize: 32)),
                        SizedBox(height: 8),
                        Text(
                          'No friends added yet',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Add friends from Add Hub to see real-time radar',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: friendsWithDistance.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = friendsWithDistance[index];
                      final friend = item['user'] as UserModel;
                      final distMeters = item['distance'] as double;
                      final bearing = item['bearing'] as String;
                      final eta = item['eta'] as String;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceHover),
                        ),
                        child: Row(
                          children: [
                            GamifiedAvatar(
                             config: friend.avatarConfig,
                             size: 46,
                             showGlow: false,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    friend.name,
                                   style: const TextStyle(
                                     fontWeight: FontWeight.bold,
                                     fontSize: 14,
                                   ),
                                 ),
                                 const SizedBox(height: 2),
                                 Row(
                                   children: [
                                     Container(
                                       padding: const EdgeInsets.symmetric(
                                         horizontal: 6,
                                         vertical: 2,
                                       ),
                                      decoration: BoxDecoration(
                                         color: AppColors.primaryNeon.withOpacity(0.15),
                                         borderRadius: BorderRadius.circular(6),
                                       ),
                                       child: Text(
                                         '' + bearing + ' • ' + locationService.formatDistance(distMeters),
                                         style: const TextStyle(
                                           fontSize: 10,
                                           fontWeight: FontWeight.bold,
                                           color: AppColors.primaryNeon,
                                         ),
                                       ),
                                     ),
                                     const SizedBox(width: 6),
                                     Text(
                                       '⏰️ ' + eta,
                                       style: const TextStyle(
                                         fontSize: 11,
                                         color: AppColors.textMuted,
                                       ),
                                     ),
                                   ],
                                 ),
                               ],
                             ),
                           ),
                           IconButton(
                             icon: const Icon(Icons.navigation_rounded, color: AppColors.primaryNeon, size: 20),
                            tooltip: 'Focus on Map',
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onSelectFriend?.call(friend);
                            },
                           ),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryPurple, size: 18),
                              tooltip: 'E2EE Chat',
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatRoomScreen(friend: friend),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
