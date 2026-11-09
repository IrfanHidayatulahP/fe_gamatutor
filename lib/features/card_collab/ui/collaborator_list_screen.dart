import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/constants.dart';
import '../bloc/card_collab_bloc.dart';
import '../bloc/card_collab_event.dart';
import '../bloc/card_collab_state.dart';
import '../data/card_collab_model.dart';
import '../../../../core/models/user_model.dart';
import 'add_collaborator_bottom_sheet.dart';
import '../../calls/ui/livekit/outgoing_call_screen.dart' as livekit;

class CollaboratorListScreen extends StatefulWidget {
  final String cardId;
  final String cardTitle;
  final String currentUserId;

  const CollaboratorListScreen({
    super.key,
    required this.cardId,
    required this.cardTitle,
    required this.currentUserId,
  });

  @override
  State<CollaboratorListScreen> createState() => _CollaboratorListScreenState();
}

class _CollaboratorListScreenState extends State<CollaboratorListScreen> {
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    context.read<CardCollabBloc>().add(
      LoadCardCollaborators(cardId: widget.cardId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => AddCollaboratorBottomSheet.show(
              context,
              cardId: widget.cardId,
              cardTitle: widget.cardTitle,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CardCollabBloc>().add(
              LoadCardCollaborators(cardId: widget.cardId),
            ),
          ),
        ],
      ),
      body: BlocConsumer<CardCollabBloc, CardCollabState>(
        listener: (context, state) {
          if (state is CollaborationActionSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
            context.read<CardCollabBloc>().add(
              LoadCardCollaborators(cardId: widget.cardId),
            );
          } else if (state is CardCollabError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CardCollabLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CollaboratorsLoaded) {
            _isOwner = state.collaborators.any(
              (c) => c.userId == widget.currentUserId && c.isOwner,
            );
            return _buildCollaboratorList(state.collaborators);
          }

          return const Center(child: Text('No collaborators'));
        },
      ),
    );
  }

  Widget _buildCollaboratorList(List<CardCollaborationModel> collaborators) {
    if (collaborators.isEmpty) {
      return _buildEmptyState();
    }

    // Sort: owner first, then members
    final sortedCollaborators = List<CardCollaborationModel>.from(collaborators)
      ..sort((a, b) {
        if (a.isOwner && !b.isOwner) return -1;
        if (!a.isOwner && b.isOwner) return 1;
        return 0;
      });

    return RefreshIndicator(
      onRefresh: () async {
        context.read<CardCollabBloc>().add(
          LoadCardCollaborators(cardId: widget.cardId),
        );
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedCollaborators.length,
        itemBuilder: (context, index) {
          final collaborator = sortedCollaborators[index];
          return _buildCollaboratorTile(collaborator);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No collaborators yet',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add collaborators to work together on this card',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => AddCollaboratorBottomSheet.show(
              context,
              cardId: widget.cardId,
              cardTitle: widget.cardTitle,
            ),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Collaborator'),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaboratorTile(CardCollaborationModel collaborator) {
    final user = collaborator.user;
    final isCurrentUser = collaborator.userId == widget.currentUserId;
    final isOwner = collaborator.isOwner;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: user?.avatarUrl != null
                  ? NetworkImage(user!.avatarUrl!)
                  : null,
              child: user?.avatarUrl == null
                  ? Text(
                      user?.initials ?? '?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            if (isOwner)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user?.fullName ?? 'Unknown User',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'You',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _buildRoleChip(collaborator.role),
                const SizedBox(width: 8),
                Text(
                  user?.email ?? '',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Added ${_formatDate(collaborator.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: _isOwner && !isCurrentUser
            ? PopupMenuButton<String>(
                onSelected: (value) => _handleAction(value, collaborator),
                itemBuilder: (context) => [
                  if (!isOwner)
                    const PopupMenuItem(
                      value: 'make_owner',
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 20),
                          SizedBox(width: 8),
                          Text('Make Owner'),
                        ],
                      ),
                    )
                  else
                    const PopupMenuItem(
                      value: 'demote',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 20),
                          SizedBox(width: 8),
                          Text('Change to Member'),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Remove', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              )
            : isCurrentUser && isOwner
            ? null
            : const SizedBox.shrink(),
        onTap: isCurrentUser ? null : () => _showUserProfile(context, user!),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    Color color;
    String label;

    switch (role) {
      case CollaborationRole.owner:
        color = Colors.amber;
        label = 'Owner';
        break;
      case CollaborationRole.member:
      default:
        color = Colors.blue;
        label = 'Member';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _handleAction(String action, CardCollaborationModel collaborator) {
    switch (action) {
      case 'make_owner':
        _confirmAction(
          context,
          'Make Owner',
          'Transfer ownership to ${collaborator.user?.fullName}? You will become a member.',
          () => context.read<CardCollabBloc>().add(
            UpdateCollaboratorRole(
              collabId: collaborator.collabId,
              role: CollaborationRole.owner,
            ),
          ),
        );
        break;
      case 'demote':
        _confirmAction(
          context,
          'Change to Member',
          'Change ${collaborator.user?.fullName}\'s role to Member?',
          () => context.read<CardCollabBloc>().add(
            UpdateCollaboratorRole(
              collabId: collaborator.collabId,
              role: CollaborationRole.member,
            ),
          ),
        );
        break;
      case 'remove':
        _confirmAction(
          context,
          'Remove Collaborator',
          'Remove ${collaborator.user?.fullName} from this collaboration?',
          () => context.read<CardCollabBloc>().add(
            RemoveCollaborator(collabId: collaborator.collabId),
          ),
          isDestructive: true,
        );
        break;
    }
  }

  void _confirmAction(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm, {
    bool isDestructive = false,
  }) {
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
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            child: Text(isDestructive ? 'Remove' : 'Confirm'),
          ),
        ],
      ),
    );
  }

  void _showUserProfile(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.initials,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to chat
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              livekit.LiveKitOutgoingCallScreen(
                                calleeId: user.userId,
                                calleeName: user.fullName,
                              ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final collabDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (collabDate == today) {
      return 'Today';
    } else if (collabDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (collabDate.year == now.year) {
      return '${dateTime.day}/${dateTime.month}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
