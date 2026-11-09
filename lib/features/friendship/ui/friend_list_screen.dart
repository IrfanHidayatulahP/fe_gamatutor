import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/friendship_bloc.dart';
import '../bloc/friendship_event.dart';
import '../bloc/friendship_state.dart';
import '../data/friendship_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../features/auth/bloc/auth_bloc.dart';
import '../../../../features/auth/bloc/auth_state.dart';
import '../../../../features/calls/ui/livekit/outgoing_call_screen.dart' as livekit_outgoing;

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  final ScrollController _allFriendsScrollController = ScrollController();
  final ScrollController _teamFriendsScrollController = ScrollController();
  final ScrollController _requestsScrollController = ScrollController();
  
  int _allFriendsOffset = 0;
  int _teamFriendsOffset = 0;
  int _requestsOffset = 0;
  static const int _limit = 50;
  bool _isLoadingAllMore = false;
  bool _isLoadingTeamMore = false;
  bool _isLoadingRequestsMore = false;
  bool _hasMoreAll = true;
  bool _hasMoreTeam = true;
  final bool _hasMoreRequests = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _allFriendsScrollController.addListener(_onAllFriendsScroll);
    _teamFriendsScrollController.addListener(_onTeamFriendsScroll);
    _requestsScrollController.addListener(_onRequestsScroll);
    _tabController.addListener(_onTabChanged);
    
    // Load initial friends
    context.read<FriendshipBloc>().add(const LoadFriends());
    context.read<FriendshipBloc>().add(const LoadPendingRequests());
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      if (_tabController.index == 1) {
        _teamFriendsOffset = 0;
        context.read<FriendshipBloc>().add(const LoadTeamFriends());
      } else if (_tabController.index == 2) {
        _requestsOffset = 0;
        context.read<FriendshipBloc>().add(const LoadPendingRequests());
      } else if (_tabController.index == 0) {
        _allFriendsOffset = 0;
        context.read<FriendshipBloc>().add(const LoadFriends());
      }
      setState(() {});
    }
  }

  void _onAllFriendsScroll() {
    if (_allFriendsScrollController.position.pixels >=
            _allFriendsScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingAllMore &&
        _hasMoreAll) {
      _loadMoreAllFriends();
    }
  }

  void _onTeamFriendsScroll() {
    if (_teamFriendsScrollController.position.pixels >=
            _teamFriendsScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingTeamMore &&
        _hasMoreTeam) {
      _loadMoreTeamFriends();
    }
  }

  void _onRequestsScroll() {
    if (_requestsScrollController.position.pixels >=
            _requestsScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingRequestsMore &&
        _hasMoreRequests) {
      _loadMoreRequests();
    }
  }

  Future<void> _loadMoreAllFriends() async {
    setState(() => _isLoadingAllMore = true);
    _allFriendsOffset += _limit;
    context.read<FriendshipBloc>().add(LoadFriends(limit: _limit, offset: _allFriendsOffset));
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoadingAllMore = false);
  }

  Future<void> _loadMoreTeamFriends() async {
    setState(() => _isLoadingTeamMore = true);
    _teamFriendsOffset += _limit;
    context.read<FriendshipBloc>().add(LoadTeamFriends(limit: _limit, offset: _teamFriendsOffset));
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoadingTeamMore = false);
  }

  Future<void> _loadMoreRequests() async {
    setState(() => _isLoadingRequestsMore = true);
    _requestsOffset += _limit;
    context.read<FriendshipBloc>().add(LoadPendingRequests(limit: _limit, offset: _requestsOffset));
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoadingRequestsMore = false);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _allFriendsScrollController.dispose();
    _teamFriendsScrollController.dispose();
    _requestsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Teman',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () => _navigateToAddFriend(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar sesuai desain
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari teman.....',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) {
                  // Tambahkan logic pencarian jika diperlukan
                },
              ),
            ),
          ),

          // Custom Pill Filter Tabs (Semua, Dalam Tim, Request)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BlocBuilder<FriendshipBloc, FriendshipState>(
              builder: (context, state) {
                int incomingCount = 0;
                if (state is PendingRequestsLoaded) {
                  incomingCount = state.incomingRequests.length;
                }

                return Row(
                  children: [
                    _buildFilterTabButton(0, 'Semua'),
                    const SizedBox(width: 8),
                    _buildFilterTabButton(1, 'Dalam Tim'),
                    const SizedBox(width: 8),
                    _buildFilterTabButton(2, 'Request', badgeCount: incomingCount),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 4),

          // TabBarView Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllFriendsTab(),
                _buildTeamFriendsTab(),
                _buildRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabButton(int index, String label, {int badgeCount = 0}) {
    final bool isSelected = _tabController.index == index;
    return InkWell(
      onTap: () {
        _tabController.animateTo(index);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF6366F1) : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildAllFriendsTab() {
    return BlocConsumer<FriendshipBloc, FriendshipState>(
      listener: (context, state) {
        if (state is FriendsLoaded) {
          _hasMoreAll = state.hasMore;
          if (state.friends.isEmpty && _allFriendsOffset > 0) {
            _allFriendsOffset -= _limit;
          }
        } else if (state is FriendshipError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is FriendshipLoading && _allFriendsOffset == 0) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FriendsLoaded) {
          if (state.friends.isEmpty) {
            return _buildEmptyState(
              icon: Icons.people_outline,
              title: 'Belum ada teman',
              subtitle: 'Tambah teman untuk memulai chat',
              onAction: () => _navigateToAddFriend(context),
              actionLabel: 'Tambah Teman',
            );
          }
          return _buildFriendsList(state.friends, _allFriendsScrollController, _isLoadingAllMore, _hasMoreAll);
        }

        return const Center(child: Text('Memuat teman...'));
      },
    );
  }

  Widget _buildTeamFriendsTab() {
    return BlocConsumer<FriendshipBloc, FriendshipState>(
      listener: (context, state) {
        if (state is TeamFriendsLoaded) {
          _hasMoreTeam = state.hasMore;
          if (state.friends.isEmpty && _teamFriendsOffset > 0) {
            _teamFriendsOffset -= _limit;
          }
        }
      },
      builder: (context, state) {
        if (state is FriendshipLoading && _teamFriendsOffset == 0) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TeamFriendsLoaded) {
          if (state.friends.isEmpty) {
            return _buildEmptyState(
              icon: Icons.groups_outlined,
              title: 'Belum ada teman dalam tim',
              subtitle: 'Kolaborasi dengan teman untuk menambahkannya ke tim',
              onAction: () => _navigateToAddFriend(context),
              actionLabel: 'Tambah Teman',
            );
          }
          return _buildFriendsList(state.friends, _teamFriendsScrollController, _isLoadingTeamMore, _hasMoreTeam);
        }

        return const Center(child: Text('Memuat teman tim...'));
      },
    );
  }

  Widget _buildRequestsTab() {
    return BlocConsumer<FriendshipBloc, FriendshipState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is FriendshipLoading && _requestsOffset == 0) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PendingRequestsLoaded) {
          final incoming = state.incomingRequests;
          final outgoing = state.outgoingRequests;
          final allRequests = [...incoming, ...outgoing];

          if (allRequests.isEmpty) {
            return _buildEmptyState(
              icon: Icons.person_add_alt_1_outlined,
              title: 'Belum ada permintaan teman',
              subtitle: 'Permintaan teman masuk dan keluar akan muncul di sini',
            );
          }
          return _buildRequestsList(allRequests);
        }

        return const Center(child: Text('Memuat permintaan...'));
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList(List<FriendshipModel> friends, ScrollController controller, bool isLoadingMore, bool hasMore) {
    return ListView.separated(
      controller: controller,
      itemCount: friends.length + (hasMore ? 1 : 0),
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
      itemBuilder: (context, index) {
        if (index >= friends.length) {
          return isLoadingMore ? const Center(child: CircularProgressIndicator()) : const SizedBox.shrink();
        }
        return _buildFriendTile(friends[index]);
      },
    );
  }

  Widget _buildRequestsList(List<FriendshipModel> requests) {
    return ListView.separated(
      controller: _requestsScrollController,
      itemCount: requests.length + (_hasMoreRequests ? 1 : 0),
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
      itemBuilder: (context, index) {
        if (index >= requests.length) {
          return const SizedBox.shrink();
        }
        return _buildRequestTile(requests[index]);
      },
    );
  }

  Widget _buildFriendTile(FriendshipModel friendship) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated ? authState.user.userId : '';
    final otherUser = friendship.getOtherUser(currentUserId);
    final isOnline = friendship.status == 'accepted';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundImage: otherUser?.avatarUrl != null ? NetworkImage(otherUser!.avatarUrl!) : null,
        child: otherUser?.avatarUrl == null ? Text(otherUser?.initials ?? '?', style: const TextStyle(fontSize: 14)) : null,
      ),
      title: Text(
        otherUser?.fullName ?? 'Unknown User',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
      ),
      subtitle: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(fontSize: 12, color: isOnline ? Colors.green : Colors.grey[500]),
          ),
        ],
      ),
      onTap: () {
        if (otherUser != null) {
          context.push('/chat/${otherUser.userId}');
        }
      },
    );
  }

  Widget _buildRequestTile(FriendshipModel friendship) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated ? authState.user.userId : '';
    final otherUser = friendship.getOtherUser(currentUserId);
    final isIncoming = friendship.requester != null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundImage: otherUser?.avatarUrl != null ? NetworkImage(otherUser!.avatarUrl!) : null,
        child: otherUser?.avatarUrl == null ? Text(otherUser?.initials ?? '?', style: const TextStyle(fontSize: 14)) : null,
      ),
      title: Text(
        otherUser?.fullName ?? 'Unknown User',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
      ),
      subtitle: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text('Online', style: TextStyle(fontSize: 12, color: Colors.green)),
        ],
      ),
      trailing: isIncoming
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<FriendshipBloc>().add(AcceptFriendRequest(fsId: friendship.fsId));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Accept', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<FriendshipBloc>().add(RejectFriendRequest(fsId: friendship.fsId));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Decline', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Pending', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w500)),
            ),
    );
  }

  void _navigateToAddFriend(BuildContext context) {
    context.push('/add-friend');
  }
}