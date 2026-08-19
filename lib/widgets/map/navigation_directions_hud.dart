import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/navigation_route_model.dart';
import 'package:piec/core/services/navigation_service.dart';
import 'package:provider/provider.dart';

class NavigationDirectionsHud extends StatelessWidget {
  final NavigationRouteModel route;

  const NavigationDirectionsHud({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    final navService = Provider.of<NavigationService>(context);
    final firstStep = route.steps.isNotEmpty ? route.steps.first : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryNeon, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Next Turn Instruction Card (Top Banner)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryNeon,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    firstStep?.iconEmoji ?? '⬆️',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstStep?.distanceText ?? '400 m',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryNeon,
                        ),
                      ),
                      Text(
                        firstStep?.instruction ?? 'Continue on route towards destination',
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Exit Navigation Button
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => navService.endNavigation(),
                ),
              ],
            ),
          ),

          // Bottom Stats & Mode Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Travel Mode Chips
                _buildModeIcon(
                  '🚗',
                  route.travelMode == TravelMode.driving,
                  () => navService.calculateRoute(
                    start: route.startLatLng,
                    destination: route.destinationLatLng,
                    destTitle: route.destinationTitle,
                    destAddress: route.destinationAddress,
                    mode: TravelMode.driving,
                  ),
                ),
                const SizedBox(width: 8),
                _buildModeIcon(
                  '🏍️',
                  route.travelMode == TravelMode.twoWheeler,
                  () => navService.calculateRoute(
                    start: route.startLatLng,
                    destination: route.destinationLatLng,
                    destTitle: route.destinationTitle,
                    destAddress: route.destinationAddress,
                    mode: TravelMode.twoWheeler,
                  ),
                ),
                const SizedBox(width: 8),
                _buildModeIcon(
                  '🚶',
                  route.travelMode == TravelMode.walking,
                  () => navService.calculateRoute(
                    start: route.startLatLng,
                    destination: route.destinationLatLng,
                    destTitle: route.destinationTitle,
                    destAddress: route.destinationAddress,
                    mode: TravelMode.walking,
                  ),
                ),

                const Spacer(),

                // Distance & ETA Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${route.durationMinutes} min',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGreen,
                      ),
                    ),
                    Text(
                      '${route.distanceKm.toStringAsFixed(1)} km • ${route.destinationTitle}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeIcon(String emoji, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNeon.withOpacity(0.2) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryNeon : AppColors.surfaceHover,
          ),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
