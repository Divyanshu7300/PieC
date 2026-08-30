import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:piec/core/constants/app_colors.dart';
import 'package:piec/core/models/friend_request_model.dart';
import 'package:piec/core/models/user_model.dart';
import 'package:piec/core/services/auth_service.dart';
import 'package:piec/core/services/firestore_chat_service.dart';
import 'package:piec/core/services/chat_service.dart';
import 'package:piec/core/services/friend_service.dart';
import 'package:piec/widgets/avatar/gamified_avatar.dart';
import 'package:provider/provider.dart';


class AddFriendsHubModal extends StatefulWidget {
  final int initialTab;

  const AddFriendsHubModal({super.key, this.initialTab = 0});

  static void show(BuildContext context, {int initialTab = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFriendsHubModal(initialTab: initialTab),
    );
  }

  @override
  State<AddFriendsHubModal> createState() => _AddFriendsHubModalState();
}

class _AddFriendsHubModalState extends State<AddFriendsHubModal> {
  late int _selectedTab; // 0: Requests, 1: Search @user, 2: Nearby Radar, 3: My Snapcode
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendService = Provider.of<FriendService>(context);
    final auth = Provider.of<AuthService>(context);
    final currentUser = auth.currentUser;

    final pendingCount = friendService.pendingCount;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: AppColors.primaryNeon, width: 2),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: const Text(
                    'Spatial Friends Hub 🤝',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // 4 Category Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildTabItem(0, 'Requests', '📬', badgeCount: pendingCount),
                _buildTabItem(1, 'Search @', '🔍'),
                _buildTabItem(2, 'Radar', '📡'),
                _buildTabItem(3, 'My Snapcode', '📷'),
              ],
            ),
          ),

          const Divider(color: AppColors.surfaceLight, height: 16),

          // Tab Content Area
          Expanded(
            child: _buildTabContent(friendService, currentUser),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, String emoji, {int badgeCount = 0}) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceHover : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: AppColors.primaryNeon.withOpacity(0.5))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.accentPink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(FriendService friendService, UserModel? currentUser) {
    switch (_selectedTab) {
      case 0: // Pending Requests Tab
        return _buildPendingRequestsTab(friendService);
      case 1: // Username Search Tab
        return _buildSearchTab(friendService, currentUser);
      case 2: // Nearby Radar Tab
        return _buildRadarTab(friendService, currentUser);
      case 3: // My Snapcode QR Tab
      default:
        return _buildSnapcodeTab(currentUser);
    }
  }

  // 1. Pending Requests Tab with Knock-Knock cards
  Widget _buildPendingRequestsTab(FriendService friendService) {
    final requests = friendService.pendingRequests;

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('✨', style: TextStyle(fontSize: 40)),
            SizedBox(height: 10),
            Text(
              'No Pending Friend Requests',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Share your Snapcode or search friends by @username',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        final sender = req.sender;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: req.type == FriendRequestType.knockKnockMap
                  ? AppColors.homeTag.withOpacity(0.5)
                  : AppColors.surfaceHover,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sender info row
              Row(
                children: [
                  GamifiedAvatar(
                    config: sender.avatarConfig,
                    size: 56,
                    showGlow: true,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              sender.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                req.typeLabel,
                                style: const TextStyle(fontSize: 10, color: AppColors.primaryNeon),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${sender.username}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sender.statusText,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(color: AppColors.surfaceHover, height: 1),
              const SizedBox(height: 12),

              // Action Buttons with Privacy selection
              Row(
                children: [
                  // Decline Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        friendService.declineFriendRequest(req.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Request declined')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        side: const BorderSide(color: AppColors.surfaceHover),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Accept with Privacy Picker Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAcceptPrivacySheet(context, req, friendService),
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.black, size: 18),
                      label: const Text('Accept Friend 🤝'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNeon,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAcceptPrivacySheet(
    BuildContext context,
    FriendRequestModel req,
    FriendService friendService,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.primaryNeon, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Privacy Level for ${req.sender.name.split(' ').first} 🛡️',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You control what locations they can see on the World Map:',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),

            _buildPrivacyOption(
              ctx,
              '📍 Full Map Access (Recommended)',
              'They can see your Home, Office & Live Pin on map',
              FriendPrivacyAccess.fullMapAccess,
              () => _confirmAccept(context, req, friendService, FriendPrivacyAccess.fullMapAccess),
            ),
            const SizedBox(height: 10),

            _buildPrivacyOption(
              ctx,
              '🔒 Chat-Only (Ghost on Map)',
              'You can chat with E2EE, but your map pins remain 100% hidden',
              FriendPrivacyAccess.chatOnlyNoMap,
              () => _confirmAccept(context, req, friendService, FriendPrivacyAccess.chatOnlyNoMap),
            ),
            const SizedBox(height: 10),

            _buildPrivacyOption(
              ctx,
              '🏙️ Blurred City Level',
              'Shows only your general city area, no exact street or house',
              FriendPrivacyAccess.blurredCityLevel,
              () => _confirmAccept(context, req, friendService, FriendPrivacyAccess.blurredCityLevel),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOption(
    BuildContext ctx,
    String title,
    String subtitle,
    FriendPrivacyAccess access,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceHover),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryNeon),
          ],
        ),
      ),
    );
  }

  void _confirmAccept(
    BuildContext context,
    FriendRequestModel req,
    FriendService friendService,
    FriendPrivacyAccess access,
  ) async {
    final chatService = Provider.of<ChatService>(context, listen: false);

    final acceptedUser = await friendService.acceptFriendRequest(req.id, access: access);
    if (acceptedUser != null && mounted) {
      if (!chatService.friends.any((f) => f.id == acceptedUser.id)) {
        chatService.friends.add(acceptedUser);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected with ${acceptedUser.name}! 🚀')),
        );
      }
    }
  }

  // 2. Search & Add by @username or Phone Number Tab
  Widget _buildSearchTab(FriendService friendService, UserModel? currentUser) {
    final searchResults = friendService.searchUsers(_searchQuery);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: 'Search by @username or Phone (e.g. 98765...)',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryNeon),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),

          // Quick Filter Shortcuts
          Row(
            children: [
              _buildQuickSearchPill('📱 +91 98765...', () {
                _searchController.text = '9876543210';
                setState(() => _searchQuery = '9876543210');
              }),
              const SizedBox(width: 8),
              _buildQuickSearchPill('@rohit_matrix', () {
                _searchController.text = 'rohit_matrix';
                setState(() => _searchQuery = 'rohit_matrix');
              }),
              const SizedBox(width: 8),
              _buildQuickSearchPill('📖 Sync Contacts', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Synced 3 phone contacts found on PieC Spatial! 📱✨')),
                );
              }),
            ],
          ),

          const SizedBox(height: 14),

          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: Provider.of<FirestoreChatService>(context, listen: false)
                  .searchRegisteredUsers(_searchQuery, currentUser?.id ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: AppColors.primaryNeon, strokeWidth: 2),
                    ),
                  );
                }

                final firestoreResults = snapshot.data ?? [];
                final combined = [
                  ...searchResults,
                  ...firestoreResults.where((fu) => !searchResults.any((su) => su.id == fu.id)),
                ];

                if (combined.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('🔍', style: TextStyle(fontSize: 36)),
                        SizedBox(height: 8),
                        Text(
                          'No Other Users Found Yet',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Open PieC on another phone to discover it here instantly!',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: combined.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final user = combined[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceHover),
                      ),
                      child: Row(
                        children: [
                          GamifiedAvatar(config: user.avatarConfig, size: 48, showGlow: false),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Row(
                                  children: [
                                    Text('@${user.username}', style: const TextStyle(fontSize: 12, color: AppColors.primaryNeon)),
                                    if (user.phone != null && user.phone!.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Text('• 📱 ${user.phone}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    ],
                                  ],
                                ),
                                Text(user.statusText, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (currentUser != null) {
                                await friendService.sendFriendRequest(
                                  sender: currentUser,
                                  receiver: user,
                                  type: FriendRequestType.usernameSearch,
                                );
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Friend request sent to ${user.name}!')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              foregroundColor: AppColors.primaryNeon,
                              side: const BorderSide(color: AppColors.primaryNeon),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            child: const Text('Add ➕', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildQuickSearchPill(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceHover),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // 3. Nearby Radar Bump Tab (Zenly style 50m radius)
  Widget _buildRadarTab(FriendService friendService, UserModel? currentUser) {
    final nearbyUsers = friendService.nearbyRadarUsers;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Radar Pulsing Graphic
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryNeon.withOpacity(0.4)),
            ),
            child: Row(
              children: const [
                Text('📡', style: TextStyle(fontSize: 28)),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nearby Radar Active (50m Radius)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryNeon),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Discovering people hanging out in the same cafe, campus, or room.',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView.separated(
              itemCount: nearbyUsers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = nearbyUsers[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accentYellow.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      GamifiedAvatar(config: user.avatarConfig, size: 48, showGlow: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(user.statusText, style: const TextStyle(fontSize: 12, color: AppColors.accentYellow)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (currentUser != null) {
                            friendService.sendFriendRequest(
                              sender: currentUser,
                              receiver: user,
                              type: FriendRequestType.nearbyRadar,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Bumped & Request Sent to ${user.name}! ⚡')),
                            );
                          }
                        },
                        icon: const Icon(Icons.bolt_rounded, size: 16, color: Colors.black),
                        label: const Text('Bump ⚡', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentYellow,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
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

  // 4. My 3D Snapcode / QR Tab
  Widget _buildSnapcodeTab(UserModel? user) {
    if (user == null) return const SizedBox();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Holographic Cyber Snapcode Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF2A1B4E),
                    AppColors.surfaceLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.primaryNeon, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryNeon.withOpacity(0.35),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 3D Avatar Head in Center of Snapcode
                  GamifiedAvatar(
                    config: user.avatarConfig,
                    size: 90,
                    showGlow: true,
                    enable3DInteraction: true,
                  ),
                  const SizedBox(height: 14),

                  Text(
                    user.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryNeon,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Stylized QR Matrix Pattern Box
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryNeon, width: 3),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.qr_code_2_rounded, size: 100, color: Colors.black),
                        Text(
                          'PIEC SPATIAL ID',
                          style: TextStyle(fontSize: 8, color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Scan to visit my 3D Avatar & E2EE Chat',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Share Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: 'https://piec-spatial.app/@${user.username}'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Spatial Invite Link copied to clipboard! 📋')),
                  );
                },
                icon: const Icon(Icons.share_rounded, color: Colors.black),
                label: const Text('Share Spatial Invite Link 🚀'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNeon,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
