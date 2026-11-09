import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/friendship_bloc.dart';
import '../bloc/friendship_event.dart';
import '../bloc/friendship_state.dart';
import '../data/friendship_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../features/auth/bloc/auth_bloc.dart';
import '../../../../features/auth/bloc/auth_state.dart';

class InviteFriendScreen extends StatefulWidget {
  final String? cardId;

  const InviteFriendScreen({super.key, this.cardId});

  @override
  State<InviteFriendScreen> createState() => _InviteFriendScreenState();
}

class _InviteFriendScreenState extends State<InviteFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  String _lastQuery = '';
  String _currentCardId = '';

  String get currentUserId {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated ? authState.user.userId : '';
  }

  @override
  void initState() {
    super.initState();
    _currentCardId = widget.cardId ?? '';
    // FriendshipBloc now auto-loads friends when userId is set via auth listener
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _lastQuery = query;
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    // Debounce search
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_lastQuery == query && query.trim().isNotEmpty && mounted) {
        context.read<FriendshipBloc>().add(SearchUsers(email: query));
      }
    });
  }

  void _inviteFriend(UserModel user) {
    if (_currentCardId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card ID tidak ditemukan')),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Undang Teman'),
        content: Text('Undang ${user.fullName} ke kolaborasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _sendInvitation(user.userId);
            },
            child: const Text('Undang'),
          ),
        ],
      ),
    );
  }

  void _sendInvitation(String friendId) {
    // Use CardCollabBloc to add collaborator
    // This will be implemented when CardCollabBloc has the method
    context.read<FriendshipBloc>().add(
          InviteFriendToCollaboration(
            cardId: _currentCardId,
            friendId: friendId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Undang Teman'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Card ID info
          if (_currentCardId.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                'Kartu: $_currentCardId',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari teman (email/nama)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchResults = []);
                            },
                          )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
              autofocus: true,
            ),
          ),

          // Search results or friend list
          Expanded(
            child: BlocConsumer<FriendshipBloc, FriendshipState>(
              listener: (context, state) {
                if (state is FriendshipError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                } else if (state is UsersSearchResult) {
                  setState(() {
                    _searchResults = state.users;
                    _isSearching = false;
                  });
                } else if (state is FriendsLoaded) {
                  // Use loaded friends if no search query
                  if (_searchController.text.trim().isEmpty) {
                    setState(() {
                      _searchResults = state.friends
                          .map((FriendshipModel f) => f.getOtherUser(currentUserId))
                          .where((u) => u != null)
                          .cast<UserModel>()
                          .toList();
                    });
                  }
                }
              },
              builder: (context, state) {
                if (state is FriendshipLoading && _searchResults.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_searchResults.isEmpty && _searchController.text.trim().isNotEmpty) {
                  return _buildNoResults();
                }

                if (_searchResults.isEmpty && _searchController.text.trim().isEmpty) {
                  return _buildInitialState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    return _buildUserTile(_searchResults[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Cari Teman untuk Diundang',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Masukkan email atau nama teman untuk mengundang mereka ke kolaborasi',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Tidak ditemukan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba cari dengan email atau nama lain',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(UserModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
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
        subtitle: Text(user.email),
        trailing: BlocBuilder<FriendshipBloc, FriendshipState>(
          builder: (context, state) {
            // Check if request already sent (outgoing pending)
            bool isPending = false;
            // Check if already friends (accepted)
            bool isFriend = false;

            if (state is PendingRequestsLoaded) {
              isPending = state.outgoingRequests.any((FriendshipModel f) => f.friendId == user.userId);
            }
            if (state is FriendsLoaded) {
              isFriend = state.friends.any((FriendshipModel f) =>
                (f.userId == user.userId || f.friendId == user.userId) && f.isAccepted
              );
            }

            if (isFriend) {
              return FilledButton(
                onPressed: () => _inviteFriend(user),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(80, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Undang'),
              );
            }

            if (isPending) {
              return const Chip(
                label: Text('Pending'),
                backgroundColor: Colors.orange,
                labelStyle: TextStyle(color: Colors.white, fontSize: 12),
              );
            }

            // Not friends yet - can't invite to collaboration
            return const Chip(
              label: Text('Not Friends'),
              backgroundColor: Colors.grey,
              labelStyle: TextStyle(color: Colors.white, fontSize: 12),
            );
          },
        ),
      ),
    );
  }
}