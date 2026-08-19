import 'package:flutter/material.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/p2p_transfer_model.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/core/services/auth_service.dart';
import 'package:piec/core/services/chat_service.dart';
import 'package:piec/core/services/p2p_fastdrop_service.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';
import 'package:provider/provider.dart';

class FastDropHubModal extends StatefulWidget {
  final UserModel? preselectedFriend;

  const FastDropHubModal({super.key, this.preselectedFriend});

  static void show(BuildContext context, {UserModel? preselectedFriend}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FastDropHubModal(preselectedFriend: preselectedFriend),
    );
  }

  @override
  State<FastDropHubModal> createState() => _FastDropHubModalState();
}

class _FastDropHubModalState extends State<FastDropHubModal> {
  P2pTransferMode _selectedMode = P2pTransferMode.turboOnlineCloudStream;
  String _selectedFileName = '4K_Goa_Raw_Footage_Master.mov';
  double _selectedFileSizeGb = 4.8;
  UserModel? _selectedTargetUser;

  @override
  void initState() {
    super.initState();
    _selectedTargetUser = widget.preselectedFriend;
  }

  @override
  Widget build(BuildContext context) {
    final p2pService = Provider.of<P2pFastDropService>(context);
    final auth = Provider.of<AuthService>(context);
    final chatService = Provider.of<ChatService>(context);
    final currentUser = auth.currentUser;
    final friends = chatService.friends;

    final activeTransfer = p2pService.activeTransfer;
    final isCompleted = activeTransfer?.status == P2pTransferStatus.completed;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF38BDF8), width: 2)),
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
                  color: const Color(0xFF38BDF8).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text('⚡', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'FastDrop P2P Turbo Beam',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'Multi-GB Heavy Files • Offline Mesh & 16x Turbo Online',
                      style: TextStyle(fontSize: 12, color: Color(0xFF38BDF8)),
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

          // If transfer is currently running or completed
          if (activeTransfer != null) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCompleted ? AppColors.accentGreen : const Color(0xFF38BDF8),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isCompleted ? AppColors.accentGreen : const Color(0xFF38BDF8)).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(isCompleted ? '✅' : '🚀', style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeTransfer.fileName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${activeTransfer.fileSizeGb} GB • ${activeTransfer.parallelStreams}x Parallel Streams Active • To ${activeTransfer.receiverName}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: activeTransfer.progressPercent,
                      backgroundColor: AppColors.surfaceHover,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? AppColors.accentGreen : const Color(0xFF38BDF8),
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isCompleted
                            ? 'Transfer Completed! 🎉'
                            : '⚡ ${activeTransfer.currentSpeedMbPerSec.toStringAsFixed(1)} MB/s',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isCompleted ? AppColors.accentGreen : const Color(0xFF38BDF8),
                        ),
                      ),
                      Text(
                        isCompleted
                            ? 'SHA-256 Verified 🔒'
                            : 'ETA ${activeTransfer.remainingSeconds}s • Auto-Resume Safe 🛡️',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),

                  if (isCompleted) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          p2pService.cancelTransfer();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            // 3-Way Mode Switcher (Online Turbo vs Offline Wi-Fi vs WebRTC P2P)
            Row(
              children: [
                Expanded(
                  child: _buildModeTab(
                    title: '🚀 16x Online Turbo',
                    subtitle: '55 MB/s Multi-Thread',
                    isSelected: _selectedMode == P2pTransferMode.turboOnlineCloudStream,
                    onTap: () => setState(() => _selectedMode = P2pTransferMode.turboOnlineCloudStream),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildModeTab(
                    title: '⚡ 0 MB Offline',
                    subtitle: '80 MB/s AirDrop Mesh',
                    isSelected: _selectedMode == P2pTransferMode.offlineWifiDirect,
                    onTap: () => setState(() => _selectedMode = P2pTransferMode.offlineWifiDirect),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildModeTab(
                    title: '🌐 P2P Direct',
                    subtitle: 'Zero Cloud Server',
                    isSelected: _selectedMode == P2pTransferMode.p2pWebRtcStream,
                    onTap: () => setState(() => _selectedMode = P2pTransferMode.p2pWebRtcStream),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Select Target Device / Friend
            const Text(
              'Select Target Device / Friend 📡',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 75,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  final isSelected = _selectedTargetUser?.id == friend.id;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedTargetUser = friend),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF38BDF8).withOpacity(0.2) : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF38BDF8) : AppColors.surfaceHover,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          GamifiedAvatar(config: friend.avatarConfig, size: 40, showGlow: false, isAnimated: false),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                friend.name.split(' ').first,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? const Color(0xFF38BDF8) : Colors.white,
                                ),
                              ),
                              const Text('Nearby Ready ⚡', style: TextStyle(fontSize: 10, color: AppColors.accentGreen)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            // Heavy File Selector
            const Text(
              'Select Heavy Multi-GB File 📦',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),

            _buildFileOption(
              emoji: '🎬',
              name: '4K_Goa_Raw_Footage_Master.mov',
              size: '4.8 GB • 4K ProRes Video',
              isSelected: _selectedFileName.contains('4K_Goa'),
              onTap: () => setState(() {
                _selectedFileName = '4K_Goa_Raw_Footage_Master.mov';
                _selectedFileSizeGb = 4.8;
              }),
            ),
            const SizedBox(height: 6),
            _buildFileOption(
              emoji: '📦',
              name: 'Unreal_Engine_Game_Assets_3D.zip',
              size: '2.4 GB • Full 3D Models & Textures',
              isSelected: _selectedFileName.contains('Unreal'),
              onTap: () => setState(() {
                _selectedFileName = 'Unreal_Engine_Game_Assets_3D.zip';
                _selectedFileSizeGb = 2.4;
              }),
            ),
            const SizedBox(height: 20),

            // Start Turbo Beam Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final target = _selectedTargetUser ?? friends.first;
                  p2pService.startTransfer(
                    fileName: _selectedFileName,
                    fileSizeGb: _selectedFileSizeGb,
                    senderName: currentUser?.name ?? 'You',
                    receiverName: target.name,
                    mode: _selectedMode,
                  );
                },
                icon: const Icon(Icons.bolt_rounded, color: Colors.black),
                label: Text(
                  'Start Turbo Beam ($_selectedFileSizeGb GB) ⚡',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF38BDF8).withOpacity(0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : AppColors.surfaceHover,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF38BDF8) : Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileOption({
    required String emoji,
    required String name,
    required String size,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF38BDF8).withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : AppColors.surfaceHover,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(size, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? const Color(0xFF38BDF8) : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
