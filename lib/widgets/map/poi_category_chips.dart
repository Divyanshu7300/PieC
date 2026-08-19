import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/services/navigation_service.dart';
import 'package:provider/provider.dart';

class PoiCategoryChips extends StatelessWidget {
  final LatLng mapCenter;

  const PoiCategoryChips({super.key, required this.mapCenter});

  final List<String> _categories = const [
    '☕ Cafes',
    '🍕 Food',
    '⛽ Fuel & EV',
    '🏥 Medical',
    '🏧 ATMs',
  ];

  @override
  Widget build(BuildContext context) {
    final navService = Provider.of<NavigationService>(context);
    final activeCat = navService.activePoiCategory;

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (activeCat != null)
            GestureDetector(
              onTap: () => navService.clearPois(),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentPink,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.close_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Clear',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          ..._categories.map((cat) {
            final isSelected = activeCat == cat;
            return GestureDetector(
              onTap: () {
                if (isSelected) {
                  navService.clearPois();
                } else {
                  navService.filterNearbyPois(cat, mapCenter);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryNeon.withOpacity(0.25) : AppColors.surface.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryNeon : AppColors.surfaceHover,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primaryNeon : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
