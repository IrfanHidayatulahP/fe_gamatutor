import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/friendship_bloc.dart';
import '../bloc/friendship_event.dart';
import '../bloc/friendship_state.dart';
import '../data/friendship_model.dart';
import '../../../../core/models/user_model.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friend'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by email',
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

          // Search results
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
                } else if (state is FriendActionSuccess) {
                  // Show success message for friend request actions
                  if (state.action == 'send_request') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
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
            'Search for friends',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter an email address to find users',
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
            'No users found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different email address',
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
              return const Chip(
                label: Text('Already Friends'),
                backgroundColor: Colors.green,
                labelStyle: TextStyle(color: Colors.white, fontSize: 12),
              );
            }

            if (isPending) {
              return const Chip(
                label: Text('Pending'),
                backgroundColor: Colors.orange,
                labelStyle: TextStyle(color: Colors.white, fontSize: 12),
              );
            }

            return FilledButton(
              onPressed: () {
                context.read<FriendshipBloc>().add(SendFriendRequest(friendId: user.userId));
                _searchController.clear();
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(80, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Add'),
            );
          },
        ),
      ),
    );
  }
}