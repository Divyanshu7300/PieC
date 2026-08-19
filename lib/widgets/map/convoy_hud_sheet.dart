import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/squad_model.dart';
import 'package:piec/core/services/auth_service.dart';
import 'package:piec/core/services/convoy_service.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';
import 'package:provider/provider.dart';

class ConvoyHudSheet extends StatefulWidget {
  final SquadModel squad;

  const ConvoyHudSheet({super.key, required this.squad});

  @override
  State<ConvoyHudSheet> createState() => _ConvoyHudSheetState();
}

class _ConvoyHudSheetState extends State<ConvoyHudSheet> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final convoyService = Provider.of<ConvoyService>(context);
    final auth = Provider.of<AuthService>(context);
    final currentUser = auth.currentUser;

    final members = convoyService.members;
    final honkMsg = convoyService.lastHonkMessage;
    final destTitle = widget.squad.meetupLocation?.title ?? 'Meetup Point';

    // Find nearest or next arriving member
    final arrivingMember = members.where((m) => !m.hasArrived).toList()
      ..sort((a, b) => a.etaMinutes.compareTo(b.etaMinutes));
    final nextETA = arrivingMember.isNotEmpty ? '${arrivingMember.first.name.split(' ').first} (${arrivingMember.first.etaMinutes}m)' : 'All Arrived!';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Honk Alert Notification Toast (if triggered)
          if (honkMsg != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.accentYellow,
                borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
              ),
              child: Row(
                children: [
                  const Text('📢', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      honkMsg,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),

          // Sleek Google Maps Style 1-Line Compact Trip Bar
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.homeTag.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🚩', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Next: $nextETA',
                              style: const TextStyle(fontSize: 11, color: AppColors.primaryNeon, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '• ${members.length} friends en route',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Quick Honk Button
                  IconButton(
                    icon: const Text('📢', style: TextStyle(fontSize: 16)),
                    tooltip: 'Honk Horn',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      convoyService.honkHorn(currentUser?.name.split(' ').first ?? 'You');
                    },
                  ),

                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expandable Clean Members List (Only shown when tapped)
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                children: [
                  const Divider(color: Colors.white12, height: 12),
                  ...members.map((m) {
                    final isMe = currentUser != null && m.userId == currentUser.id;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          GamifiedAvatar(config: m.avatarConfig, size: 28, showGlow: false, isAnimated: false),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              m.name.split(' ').first + (isMe ? ' (You)' : ''),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isMe ? AppColors.primaryNeon : Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            m.hasArrived ? 'Arrived! 🎉' : '${m.distanceKm.toStringAsFixed(1)} km • ${m.etaMinutes} min',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: m.hasArrived ? AppColors.accentGreen : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
