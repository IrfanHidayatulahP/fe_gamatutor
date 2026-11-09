import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/constants.dart';
import '../bloc/card_collab_bloc.dart';
import '../bloc/card_collab_event.dart';
import '../bloc/card_collab_state.dart';
import '../data/card_collab_model.dart';

class CollaborationInviteScreen extends StatefulWidget {
  const CollaborationInviteScreen({super.key});

  @override
  State<CollaborationInviteScreen> createState() => _CollaborationInviteScreenState();
}

class _CollaborationInviteScreenState extends State<CollaborationInviteScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CardCollaborationModel> _pendingInvites = [];
  List<CardCollaborationModel> _sentInvites = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInvites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadInvites() {
    context.read<CardCollabBloc>().add(const LoadUserCollaborations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collaboration Invites'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvites,
          ),
        ],
      ),
      body: BlocConsumer<CardCollabBloc, CardCollabState>(
        listener: (context, state) {
          if (state is CollaborationActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            _loadInvites();
          } else if (state is CardCollabError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is UserCollaborationsLoaded) {
            _processCollaborations(state.collaborations);
          }
        },
        builder: (context, state) {
          if (state is CardCollabLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildInviteList(_pendingInvites, isReceived: true),
              _buildInviteList(_sentInvites, isReceived: false),
            ],
          );
        },
      ),
    );
  }

  void _processCollaborations(List<CardCollaborationModel> collaborations) {
    setState(() {
      _pendingInvites = collaborations
          .where((c) => !c.isOwner && c.role == 'pending')
          .toList();
      _sentInvites = collaborations
          .where((c) => c.isOwner && c.role == 'pending')
          .toList();
    });
  }

  Widget _buildInviteList(List<CardCollaborationModel> invites, {required bool isReceived}) {
    if (invites.isEmpty) {
      return _buildEmptyState(isReceived);
    }

    return RefreshIndicator(
      onRefresh: () async => _loadInvites(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: invites.length,
        itemBuilder: (context, index) {
          final invite = invites[index];
          return _buildInviteTile(invite, isReceived: isReceived);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isReceived) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isReceived ? Icons.inbox_outlined : Icons.send_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isReceived ? 'No pending invites' : 'No sent invites',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isReceived
                ? 'Invites to collaborate on cards will appear here'
                : 'Your sent collaboration invites will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInviteTile(CardCollaborationModel invite, {required bool isReceived}) {
    final user = invite.user;
    final card = invite.card;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.credit_card,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card?.title ?? 'Card',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (card?.courseName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          card!.courseName!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusChip(invite.role),
              ],
            ),
            const SizedBox(height: 12),
            // Other user info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null
                      ? Text(
                          user?.initials ?? '?',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReceived ? 'Invited by' : 'Invited',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        user?.fullName ?? 'Unknown User',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                if (isReceived) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectInvite(invite),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _acceptInvite(invite),
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelInvite(invite),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel Invite'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String role) {
    Color color;
    String label;

    switch (role) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case CollaborationRole.owner:
        color = Colors.amber;
        label = 'Owner';
        break;
      case CollaborationRole.member:
        color = Colors.blue;
        label = 'Member';
        break;
      default:
        color = Colors.grey;
        label = role;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _acceptInvite(CardCollaborationModel invite) {
    context.read<CardCollabBloc>().add(UpdateCollaboratorRole(
      collabId: invite.collabId,
      role: CollaborationRole.member,
    ));
  }

  void _rejectInvite(CardCollaborationModel invite) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Invite'),
        content: Text('Are you sure you want to reject the collaboration invite for "${invite.card?.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CardCollabBloc>().add(RemoveCollaborator(collabId: invite.collabId));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _cancelInvite(CardCollaborationModel invite) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Invite'),
        content: Text('Cancel the collaboration invite sent to ${invite.user?.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CardCollabBloc>().add(RemoveCollaborator(collabId: invite.collabId));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Cancel Invite'),
          ),
        ],
      ),
    );
  }
}