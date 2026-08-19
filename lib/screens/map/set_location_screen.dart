import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/location_point.dart';
import 'package:piec/core/services/auth_service.dart';
import 'package:provider/provider.dart';

class SetLocationScreen extends StatefulWidget {
  final LocationType initialType;

  const SetLocationScreen({super.key, this.initialType = LocationType.home});

  @override
  State<SetLocationScreen> createState() => _SetLocationScreenState();
}

class _SetLocationScreenState extends State<SetLocationScreen> {
  late LocationType _selectedType;
  late LatLng _selectedCoords;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedCoords = const LatLng(28.6139, 77.2090);

    if (_selectedType == LocationType.home) {
      _titleController.text = 'My Home Base';
      _addressController.text = 'Green Park, Block B';
    } else {
      _titleController.text = 'My Workspace';
      _addressController.text = 'Tech Hub, Cyber Boulevard';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Tag ${_selectedType == LocationType.home ? "Home 🏠" : "Office 💼"} on Map'),
      ),
      body: Stack(
        children: [
          // Interactive Map Picker
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedCoords,
              initialZoom: 15.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedCoords = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedCoords,
                    width: 60,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedType == LocationType.home
                                ? AppColors.homeTag
                                : AppColors.officeTag,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: (_selectedType == LocationType.home
                                        ? AppColors.homeTag
                                        : AppColors.officeTag)
                                    .withOpacity(0.6),
                                blurRadius: 12,
                              )
                            ],
                          ),
                          child: Text(
                            _selectedType == LocationType.home ? '🏠' : '💼',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Top Instruction Pill
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryNeon.withOpacity(0.4)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.touch_app_rounded, color: AppColors.primaryNeon, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tap anywhere on the map to place your pin',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Configuration Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: AppColors.surfaceHover, width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Switcher
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('🏠 Home Base')),
                          selected: _selectedType == LocationType.home,
                          selectedColor: AppColors.homeTag,
                          backgroundColor: AppColors.surfaceLight,
                          labelStyle: TextStyle(
                            color: _selectedType == LocationType.home
                                ? Colors.white
                                : AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedType = LocationType.home;
                              _titleController.text = 'My Home Base';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('💼 Workspace')),
                          selected: _selectedType == LocationType.office,
                          selectedColor: AppColors.officeTag,
                          backgroundColor: AppColors.surfaceLight,
                          labelStyle: TextStyle(
                            color: _selectedType == LocationType.office
                                ? Colors.black
                                : AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedType = LocationType.office;
                              _titleController.text = 'My Workspace';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Pin Title',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address Description',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final newPoint = LocationPoint(
                          title: _titleController.text.trim(),
                          address: _addressController.text.trim(),
                          latitude: _selectedCoords.latitude,
                          longitude: _selectedCoords.longitude,
                          type: _selectedType,
                          updatedAt: DateTime.now(),
                        );

                        if (_selectedType == LocationType.home) {
                          await auth.setLocationTag(home: newPoint);
                        } else {
                          await auth.setLocationTag(office: newPoint);
                        }

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${_selectedType == LocationType.home ? "Home" : "Office"} pin updated successfully! 📍',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Save Pin on Map ✨'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
