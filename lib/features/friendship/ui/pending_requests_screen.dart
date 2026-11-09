import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/friendship_bloc.dart';
import '../bloc/friendship_event.dart';
import '../bloc/friendship_state.dart';
import '../data/friendship_model.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<FriendshipBloc>().add(const LoadPendingRequests());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Incoming'),
            Tab(text: 'Outgoing'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<FriendshipBloc>().add(const LoadPendingRequests()),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIncomingTab(),
          _buildOutgoingTab(),
        ],
      ),
    );
  }

  Widget _buildIncomingTab() {
    return BlocBuilder<FriendshipBloc, FriendshipState>(
      builder: (context, state) {
        if (state is FriendshipLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PendingRequestsLoaded) {
          if (state.incomingRequests.isEmpty) {
            return _buildEmptyState('No incoming requests', 'When someone sends you a friend request, it will appear here');
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<FriendshipBloc>().add(const LoadPendingRequests());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: state.incomingRequests.length,
              itemBuilder: (context, index) {
                return _buildIncomingRequestTile(state.incomingRequests[index]);
              },
            ),
          );
        }

        return const Center(child: Text('No data'));
      },
    );
  }

  Widget _buildOutgoingTab() {
    return BlocBuilder<FriendshipBloc, FriendshipState>(
      builder: (context, state) {
        if (state is FriendshipLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PendingRequestsLoaded) {
          if (state.outgoingRequests.isEmpty) {
            return _buildEmptyState('No outgoing requests', 'Your sent friend requests will appear here');
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<FriendshipBloc>().add(const LoadPendingRequests());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: state.outgoingRequests.length,
              itemBuilder: (context, index) {
                return _buildOutgoingRequestTile(state.outgoingRequests[index]);
              },
            ),
          );
        }

        return const Center(child: Text('No data'));
      },
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingRequestTile(FriendshipModel friendship) {
    final requester = friendship.requester;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: requester?.avatarUrl != null
                      ? NetworkImage(requester!.avatarUrl!)
                      : null,
                  child: requester?.avatarUrl == null
                      ? Text(
                          requester!.fullName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 18),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requester?.fullName ?? 'Unknown User',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        requester?.email ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sent ${_formatTime(friendship.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Clear indicator that this is an INCOMING request
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_add_alt_1,
                    size: 16,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${requester?.firstName ?? 'Someone'} wants to be your friend',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => _showConfirmDialog(
                    context,
                    'Reject Request',
                    'Reject friend request from ${requester?.fullName}?',
                    () => context.read<FriendshipBloc>().add(RejectFriendRequest(fsId: friendship.fsId)),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => context.read<FriendshipBloc>().add(AcceptFriendRequest(fsId: friendship.fsId)),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutgoingRequestTile(FriendshipModel friendship) {
    final friend = friendship.friend;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: friend?.avatarUrl != null
                      ? NetworkImage(friend!.avatarUrl!)
                      : null,
                  child: friend?.avatarUrl == null
                      ? Text(
                          friend!.fullName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 18),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend?.fullName ?? 'Unknown User',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        friend?.email ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sent ${_formatTime(friendship.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Clear indicator that this is an OUTGOING request sent by current user
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'You sent this request — waiting for ${friend?.firstName ?? 'them'} to accept',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showConfirmDialog(
                  context,
                  'Cancel Request',
                  'Cancel friend request to ${friend?.fullName}?',
                  () => context.read<FriendshipBloc>().add(RejectFriendRequest(fsId: friendship.fsId)),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Cancel Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}