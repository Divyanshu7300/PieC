import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/location_point.dart';
import 'package:piec/core/services/auth_service.dart';
import 'package:piec/core/services/sentinel_safety_service.dart';
import 'package:provider/provider.dart';

class SafeRideHomeModal extends StatelessWidget {
  const SafeRideHomeModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SafeRideHomeModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safetyService = Provider.of<SentinelSafetyService>(context);
    final auth = Provider.of<AuthService>(context);
    final currentUser = auth.currentUser;
    final homePoint = currentUser?.homeLocation ?? LocationPoint(
      title: 'Home Base',
      address: 'Central Skyline Sector 4',
      latitude: 28.6150,
      longitude: 77.2100,
      type: LocationType.home,
      updatedAt: DateTime.now(),
    );

    final isActive = safetyService.isRideSentinelActive;
    final isSos = safetyService.isSosPanicActive;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.accentGreen, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text('🛡️', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Safe-Ride Home Sentinel',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'Automatic 50m Geofence Arrival Alert',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Destination Home Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceHover),
            ),
            child: Row(
              children: [
                const Text('🏠', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        homePoint.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      Text(
                        homePoint.address,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${safetyService.distanceToHomeMeters}m away',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGreen),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Explanation / Value Prop
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.verified_rounded, size: 18, color: AppColors.accentGreen),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No need to call! When you enter within 50 meters of your Home, PieC automatically sends a verified safe arrival push notification to your trusted squad & parents.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Main Trigger Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (isActive) {
                  safetyService.cancelRideSentinel();
                } else {
                  safetyService.startSafeRideHome(homePoint, currentUser);
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      !isActive
                          ? '🚗 Safe-Ride Sentinel Active! Monitoring arrival to ${homePoint.title}...'
                          : 'Safe-Ride Sentinel stopped.',
                    ),
                    backgroundColor: !isActive ? AppColors.accentGreen : AppColors.surface,
                  ),
                );
              },
              icon: Icon(isActive ? Icons.stop_circle_outlined : Icons.shield_rounded, color: Colors.black),
              label: Text(
                isActive ? 'Stop Safe-Ride Sentinel' : 'Start Safe-Ride Home Sentinel 🚗',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? AppColors.accentYellow : AppColors.accentGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // SOS Panic Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                if (isSos) {
                  safetyService.cancelSos();
                } else {
                  safetyService.triggerSosEmergency(currentUser);
                }
                Navigator.pop(context);
              },
              icon: Icon(isSos ? Icons.check_circle : Icons.warning_amber_rounded, color: const Color(0xFFEF4444)),
              label: Text(
                isSos ? 'Cancel Emergency SOS' : '🚨 3-Sec SOS Emergency Beacon',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFEF4444)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
