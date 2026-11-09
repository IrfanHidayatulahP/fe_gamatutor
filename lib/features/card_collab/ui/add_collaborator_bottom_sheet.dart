import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/constants.dart';
import '../bloc/card_collab_bloc.dart';
import '../bloc/card_collab_event.dart';
import '../../friendship/bloc/friendship_bloc.dart';
import '../../friendship/bloc/friendship_event.dart';
import '../../friendship/bloc/friendship_state.dart';
import '../../friendship/data/friendship_model.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';

class AddCollaboratorBottomSheet extends StatefulWidget {
  final String cardId;
  final String cardTitle;

  const AddCollaboratorBottomSheet({
    super.key,
    required this.cardId,
    required this.cardTitle,
  });

  static void show(BuildContext context, {required String cardId, required String cardTitle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddCollaboratorBottomSheet(
        cardId: cardId,
        cardTitle: cardTitle,
      ),
    );
  }

  @override
  State<AddCollaboratorBottomSheet> createState() => _AddCollaboratorBottomSheetState();
}

class _AddCollaboratorBottomSheetState extends State<AddCollaboratorBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = CollaborationRole.member;
  List<FriendshipModel> _friends = [];
  List<FriendshipModel> _filteredFriends = [];
  bool _isLoadingFriends = true;
  String? _error;

  String get currentUserId {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated ? authState.user.userId : '';
  }

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _searchController.addListener(_filterFriends);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadFriends() {
    context.read<FriendshipBloc>().add(const LoadFriends());
  }

  void _filterFriends() {
    final query = _searchController.text.toString();
    setState(() {
      _filteredFriends = _friends.where((friend) {
        final otherUser = friend.getOtherUser(currentUserId);
        if (otherUser == null) return false;
        final name = otherUser.fullName.toString();
        final email = otherUser.email.toString();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return BlocConsumer<FriendshipBloc, FriendshipState>(
          listener: (context, state) {
            if (state is FriendsLoaded) {
              setState(() {
                _friends = state.friends.where((f) => f.isAccepted).toList();
                _filteredFriends = _friends;
                _isLoadingFriends = false;
              });
            } else if (state is FriendshipError) {
              setState(() {
                _error = state.message;
                _isLoadingFriends = false;
              });
            }
          },
          builder: (context, state) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Collaborator',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.cardTitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search friends...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Role selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Role',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: CollaborationRole.member,
                              label: Text('Member'),
                              icon: Icon(Icons.person_outline),
                            ),
                            ButtonSegment(
                              value: CollaborationRole.owner,
                              label: Text('Owner'),
                              icon: Icon(Icons.star_outline),
                            ),
                          ],
                          selected: {_selectedRole},
                          onSelectionChanged: (selection) {
                            setState(() => _selectedRole = selection.first);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Friends list
                  Expanded(
                    child: _buildFriendsList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFriendsList() {
    if (_isLoadingFriends) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text('Error loading friends', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadFriends,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredFriends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty ? 'No friends available' : 'No friends found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            if (_searchController.text.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Add friends first to collaborate',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      controller: ScrollController(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _filteredFriends.length,
      itemBuilder: (context, index) {
        final friendship = _filteredFriends[index];
        final otherUser = friendship.getOtherUser(currentUserId);
        if (otherUser == null) return const SizedBox.shrink();

        return _buildFriendTile(friendship);
      },
    );
  }

  Widget _buildFriendTile(FriendshipModel friendship) {
    final otherUser = friendship.getOtherUser(currentUserId)!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: otherUser.avatarUrl != null
              ? NetworkImage(otherUser.avatarUrl!)
              : null,
          child: otherUser.avatarUrl == null
              ? Text(
                  otherUser.initials,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(
          otherUser.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          otherUser.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: FilledButton.tonal(
          onPressed: () {
            context.read<CardCollabBloc>().add(AddCollaborator(
              cardId: widget.cardId,
              userId: otherUser.userId,
              role: _selectedRole,
            ));
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ),
    );
  }
}