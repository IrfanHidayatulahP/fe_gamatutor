import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../friendship/bloc/friendship_bloc.dart';
import '../../friendship/bloc/friendship_event.dart';
import '../../friendship/bloc/friendship_state.dart';
import '../../friendship/data/friendship_model.dart';
import 'chat_screen.dart';
import '../../../../core/models/user_model.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _allFriendsScrollController = ScrollController();
  final ScrollController _teamFriendsScrollController = ScrollController();
  int _allFriendsOffset = 0;
  int _teamFriendsOffset = 0;
  static const int _limit = 50;
  bool _isLoadingAllMore = false;
  bool _isLoadingTeamMore = false;
  bool _hasMoreAll = true;
  bool _hasMoreTeam = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _allFriendsScrollController.addListener(_onAllFriendsScroll);
    _teamFriendsScrollController.addListener(_onTeamFriendsScroll);
    context.read<FriendshipBloc>().add(const LoadFriends());
    context.read<FriendshipBloc>().add(const LoadTeamFriends());
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

  Future<void> _loadMoreAllFriends() async {
    setState(() => _isLoadingAllMore = true);
    _allFriendsOffset += _limit;
    context
        .read<FriendshipBloc>()
        .add(LoadFriends(limit: _limit, offset: _allFriendsOffset));
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoadingAllMore = false);
  }

  Future<void> _loadMoreTeamFriends() async {
    setState(() => _isLoadingTeamMore = true);
    _teamFriendsOffset += _limit;
    context
        .read<FriendshipBloc>()
        .add(LoadTeamFriends(limit: _limit, offset: _teamFriendsOffset));
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoadingTeamMore = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _allFriendsScrollController.dispose();
    _teamFriendsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Baru'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Dalam Tim'),
          ],
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Semua - All friends
          _buildAllFriendsTab(),
          // Tab 2: Dalam Tim - Team friends
          _buildTeamFriendsTab(),
        ],
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
            );
          }
          return _buildFriendsList(
            state.friends,
            _allFriendsScrollController,
            _isLoadingAllMore,
            _hasMoreAll,
          );
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
        } else if (state is FriendshipError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
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
            );
          }
          return _buildFriendsList(
            state.friends,
            _teamFriendsScrollController,
            _isLoadingTeamMore,
            _hasMoreTeam,
          );
        }

        // Show loading or empty while waiting for TeamFriendsLoaded
        if (state is FriendsLoaded) {
          // Could show friends while team friends loading
        }

        return const Center(child: Text('Memuat teman tim...'));
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 50,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/invite-friend'),
              icon: const Icon(Icons.person_add),
              label: const Text('Tambah Teman'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList(
    List<FriendshipModel> friends,
    ScrollController controller,
    bool isLoadingMore,
    bool hasMore,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        if (_tabController.index == 0) {
          _allFriendsOffset = 0;
          context.read<FriendshipBloc>().add(const LoadFriends());
        } else {
          _teamFriendsOffset = 0;
          context.read<FriendshipBloc>().add(const LoadTeamFriends());
        }
      },
      child: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.all(8),
        itemCount: friends.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= friends.length) {
            return isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink();
          }

          final friendship = friends[index];
          final authState = context.read<AuthBloc>().state;
          final currentUserId = authState is AuthAuthenticated ? authState.user.userId : '';
          final otherUser = friendship.getOtherUser(currentUserId);
          if (otherUser == null) return const SizedBox.shrink();

          return _buildFriendTile(otherUser);
        },
      ),
    );
  }

  Widget _buildFriendTile(UserModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
          child: user.avatarUrl == null
              ? Text(
                  user.initials,
                  style: const TextStyle(fontSize: 18),
                )
              : null,
        ),
        title: Text(user.fullName),
        subtitle: Text(
          user.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chat_bubble_outline),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(friend: user),
            ),
          );
        },
      ),
    );
  }
}