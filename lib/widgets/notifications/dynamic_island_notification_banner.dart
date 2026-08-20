import 'dart:async';
import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/call_session_model.dart';
import 'package:piec/core/services/call_service.dart';
import 'package:piec/core/services/notification_service.dart';
import 'package:piec/screens/call/active_call_screen.dart';
import 'package:provider/provider.dart';

class DynamicIslandNotificationWrapper extends StatefulWidget {
  final Widget child;

  const DynamicIslandNotificationWrapper({super.key, required this.child});

  @override
  State<DynamicIslandNotificationWrapper> createState() =>
      _DynamicIslandNotificationWrapperState();
}

class _DynamicIslandNotificationWrapperState
    extends State<DynamicIslandNotificationWrapper>
    with SingleTickerProviderStateMixin {
  StreamSubscription<InAppNotificationItem>? _subscription;
  InAppNotificationItem? _currentNotification;
  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifService =
          Provider.of<NotificationService>(context, listen: false);
      _subscription = notifService.bannerStream.listen((item) {
        _showNotification(item);
      });
    });
  }

  void _showNotification(InAppNotificationItem item) {
    _dismissTimer?.cancel();
    setState(() {
      _currentNotification = item;
    });
    _animController.forward();

    _dismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _animController.reverse().then((_) {
          if (mounted) {
            setState(() => _currentNotification = null);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _subscription?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callService = Provider.of<CallService>(context);
    final incomingCall = callService.incomingCall;

    return Stack(
      children: [
        widget.child,

        // 1. INCOMING CALL OVERLAY MODAL (Real-time Cross-Device Call Alert)
        if (incomingCall != null)
          Positioned.fill(
            child: Material(
              color: Colors.black.withOpacity(0.85),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Caller Info Header
                      Column(
                        children: [
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryNeon.withOpacity(0.15),
                              border: Border.all(color: AppColors.primaryNeon, width: 2),
                            ),
                            child: const Text('📞', style: TextStyle(fontSize: 48)),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            incomingCall.caller.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Incoming ${incomingCall.type == CallType.avatarVideo ? "Video" : "Spatial Voice"} Call 🛰️',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.primaryNeon,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // Accept / Decline Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Decline Button
                          GestureDetector(
                            onTap: () {
                              callService.declineIncomingCall();
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentPink,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: AppColors.accentPink, blurRadius: 16),
                                    ],
                                  ),
                                  child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
                                ),
                                const SizedBox(height: 8),
                                const Text('Decline', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),

                          // Accept Button
                          GestureDetector(
                            onTap: () {
                              callService.acceptIncomingCall();
                              ActiveCallScreen.show(context);
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentGreen,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: AppColors.accentGreen, blurRadius: 16),
                                    ],
                                  ),
                                  child: const Icon(Icons.call_rounded, color: Colors.white, size: 30),
                                ),
                                const SizedBox(height: 8),
                                const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // 2. DYNAMIC ISLAND FLOATING ALERT
        if (_currentNotification != null && incomingCall == null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -60 * (1 - _slideAnimation.value)),
                  child: Opacity(
                    opacity: _slideAnimation.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onTap: () {
                  _animController.reverse().then((_) {
                    if (mounted) setState(() => _currentNotification = null);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primaryNeon.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: AppColors.primaryNeon.withOpacity(0.2),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNeon.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _currentNotification!.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentNotification!.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentNotification!.body,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
