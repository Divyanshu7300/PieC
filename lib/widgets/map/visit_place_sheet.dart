import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/location_point.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/core/services/location_service.dart';
import 'package:piec/screens/radar/ar_spatial_radar_screen.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';

class VisitPlaceSheet extends StatelessWidget {
  final UserModel user;
  final LocationPoint locationPoint;
  final LocationPoint? currentUserLocation;
  final VoidCallback onStartChat;
  final VoidCallback onWave;

  const VisitPlaceSheet({
    super.key,
    required this.user,
    required this.locationPoint,
    this.currentUserLocation,
    required this.onStartChat,
    required this.onWave,
  });

  static void show(
    BuildContext context, {
    required UserModel user,
    required LocationPoint locationPoint,
    LocationPoint? currentUserLocation,
    required VoidCallback onStartChat,
    required VoidCallback onWave,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => VisitPlaceSheet(
        user: user,
        locationPoint: locationPoint,
        currentUserLocation: currentUserLocation,
        onStartChat: onStartChat,
        onWave: onWave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locService = LocationService();
    String distanceStr = 'Nearby';
    if (currentUserLocation != null) {
      distanceStr = locService.formatDistance(
        currentUserLocation!.latLng,
        locationPoint.latLng,
      );
    }

    Color badgeColor = AppColors.primaryNeon;
    if (locationPoint.type == LocationType.home) badgeColor = AppColors.homeTag;
    if (locationPoint.type == LocationType.office) badgeColor = AppColors.officeTag;
    if (locationPoint.type == LocationType.hangout) badgeColor = AppColors.hangoutTag;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: badgeColor, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // User Info Row with Avatar
          Row(
            children: [
              GamifiedAvatar(
                config: user.avatarConfig,
                size: 72,
                showGlow: true,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: user.isOnline ? AppColors.online : AppColors.offline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryNeon,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.surfaceHover),
                      ),
                      child: Text(
                        user.statusText,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: AppColors.surfaceLight, height: 1),
          const SizedBox(height: 16),

          // Location Details Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceHover),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: badgeColor.withOpacity(0.4)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    locationPoint.iconEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locationPoint.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locationPoint.address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryNeon.withOpacity(0.4)),
                  ),
                  child: Text(
                    distanceStr,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNeon,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Battery & Privacy Indicator Row
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: user.batteryPercentage <= 5
                  ? const Color(0xFFEF4444).withOpacity(0.15)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: user.batteryPercentage <= 5
                    ? const Color(0xFFEF4444).withOpacity(0.5)
                    : AppColors.surfaceHover,
              ),
            ),
            child: Row(
              children: [
                Text(
                  user.batteryPercentage <= 5
                      ? '🪫'
                      : (user.isCharging ? '⚡' : '🔋'),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Text(
                  user.batteryPercentage <= 5
                      ? 'Low Battery Mode (${user.batteryPercentage}%)'
                      : (user.isCharging
                          ? '${user.batteryPercentage}% • Fast Charging'
                          : '${user.batteryPercentage}% Battery Level'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: user.batteryPercentage <= 5
                        ? const Color(0xFFEF4444)
                        : AppColors.accentGreen,
                  ),
                ),
                const Spacer(),
                if (user.lastKnownBeaconAddress != null)
                  const Text(
                    'Last Safe Beacon Active 📍',
                    style: TextStyle(fontSize: 10, color: AppColors.accentYellow, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),

          // Actions
          Row(
            children: [
              // AR Spatial Radar Button (Find in Crowd)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ArSpatialRadarScreen.show(context, user);
                  },
                  icon: const Text('🔦', style: TextStyle(fontSize: 16)),
                  label: const Text('AR Radar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryNeon,
                    side: const BorderSide(color: AppColors.primaryNeon, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Knock-Knock Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onWave();
                  },
                  icon: const Text('🚪', style: TextStyle(fontSize: 16)),
                  label: const Text('Knock'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.homeTag, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Visit & Chat Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onStartChat();
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.black, size: 18),
                  label: Text('Visit & Chat ${locationPoint.iconEmoji}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNeon,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
