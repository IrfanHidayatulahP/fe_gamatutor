import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/friendship_bloc.dart';
import '../bloc/friendship_event.dart';
import '../data/friendship_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../features/chat/ui/chat_screen.dart';
import '../../../../features/calls/ui/livekit/outgoing_call_screen.dart'
    as livekit_outgoing;

class FriendProfileBottomSheet extends StatelessWidget {
  final FriendshipModel friendship;
  final UserModel currentUser;

  const FriendProfileBottomSheet({
    super.key,
    required this.friendship,
    required this.currentUser,
  });

  static void show(
    BuildContext context,
    FriendshipModel friendship,
    UserModel currentUser,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FriendProfileBottomSheet(
        friendship: friendship,
        currentUser: currentUser,
      ),
    );
  }

  UserModel get otherUser => friendship.getOtherUser(currentUser.userId)!;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Avatar and name
                CircleAvatar(
                  radius: 50,
                  backgroundImage: otherUser.avatarUrl != null
                      ? NetworkImage(otherUser.avatarUrl!)
                      : null,
                  child: otherUser.avatarUrl == null
                      ? Text(
                          otherUser.initials,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  otherUser.fullName,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  otherUser.email,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                _buildStatusChip(),
                const SizedBox(height: 24),

                // Action buttons
                _buildActionButtons(context),
                const SizedBox(height: 16),

                // Friendship info
                _buildFriendshipInfo(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String label;

    switch (friendship.status) {
      case 'accepted':
        color = Colors.green;
        label = 'Friends';
        break;
      case 'pending':
        if (friendship.requester?.userId == currentUser.userId) {
          color = Colors.orange;
          label = 'Request Sent';
        } else {
          color = Colors.blue;
          label = 'Pending';
        }
        break;
      case 'blocked':
        color = Colors.red;
        label = 'Blocked';
        break;
      case 'declined':
        color = Colors.grey;
        label = 'Declined';
        break;
      default:
        color = Colors.grey;
        label = friendship.status;
    }

    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      labelStyle: const TextStyle(fontSize: 12),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isFriend = friendship.isAccepted;
    final isBlocked = friendship.isBlocked;
    final isPending = friendship.isPending;
    final isRequester = friendship.requester?.userId == currentUser.userId;

    final List<Widget> children = [];

    // Chat button
    if (isFriend && !isBlocked) {
      children.add(
        _buildActionButton(
          context,
          icon: Icons.chat,
          label: 'Chat',
          color: Theme.of(context).colorScheme.primary,
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(friend: otherUser),
              ),
            );
          },
        ),
      );
    }

    // Voice call button (voice-only app)
    if (isFriend && !isBlocked) {
      children.add(
        _buildActionButton(
          context,
          icon: Icons.call,
          label: 'Call',
          color: Colors.green,
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => livekit_outgoing.LiveKitOutgoingCallScreen(
                  calleeId: otherUser.userId,
                  calleeName: otherUser.fullName,
                ),
              ),
            );
          },
        ),
      );
    }

    // Accept/Reject buttons for incoming requests
    if (isPending && !isRequester) {
      children.add(
        _buildActionButton(
          context,
          icon: Icons.check,
          label: 'Accept',
          color: Colors.green,
          onPressed: () {
            context.read<FriendshipBloc>().add(
              AcceptFriendRequest(fsId: friendship.fsId),
            );
            Navigator.pop(context);
          },
        ),
      );
      children.add(
        _buildActionButton(
          context,
          icon: Icons.close,
          label: 'Reject',
          color: Colors.red,
          onPressed: () {
            context.read<FriendshipBloc>().add(
              RejectFriendRequest(fsId: friendship.fsId),
            );
            Navigator.pop(context);
          },
        ),
      );
    }

    // Cancel button for outgoing requests
    if (isPending && isRequester) {
      children.add(
        _buildActionButton(
          context,
          icon: Icons.cancel,
          label: 'Cancel Request',
          color: Colors.orange,
          onPressed: () {
            context.read<FriendshipBloc>().add(
              RejectFriendRequest(fsId: friendship.fsId),
            );
            Navigator.pop(context);
          },
        ),
      );
    }

    // Block/Unblock/Remove buttons
    if (isFriend) {
      if (!isBlocked) {
        children.add(
          _buildActionButton(
            context,
            icon: Icons.block,
            label: 'Block',
            color: Colors.red,
            onPressed: () => _showConfirmDialog(
              context,
              'Block User',
              'Are you sure you want to block ${otherUser.fullName}?',
              () {
                context.read<FriendshipBloc>().add(
                  BlockFriend(fsId: friendship.fsId),
                );
                Navigator.pop(context);
              },
            ),
          ),
        );
      } else {
        children.add(
          _buildActionButton(
            context,
            icon: Icons.block,
            label: 'Unblock',
            color: Colors.green,
            onPressed: () {
              context.read<FriendshipBloc>().add(
                UnblockFriend(fsId: friendship.fsId),
              );
              Navigator.pop(context);
            },
          ),
        );
      }

      // Remove friend button
      children.add(
        _buildActionButton(
          context,
          icon: Icons.person_remove,
          label: 'Remove Friend',
          color: Colors.red,
          isOutline: true,
          onPressed: () => _showConfirmDialog(
            context,
            'Remove Friend',
            'Are you sure you want to remove ${otherUser.fullName} from your friends?',
            () {
              context.read<FriendshipBloc>().add(
                RemoveFriend(fsId: friendship.fsId),
              );
              Navigator.pop(context);
            },
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: children,
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isOutline = false,
  }) {
    return isOutline
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        : FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
  }

  Widget _buildFriendshipInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Friendship Info',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Status', _getStatusLabel()),
          _buildInfoRow('Since', _formatDate(friendship.createdAt)),
          if (friendship.updatedAt != friendship.createdAt)
            _buildInfoRow('Last Updated', _formatDate(friendship.updatedAt)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _getStatusLabel() {
    switch (friendship.status) {
      case 'accepted':
        return 'Friends';
      case 'pending':
        return 'Pending';
      case 'blocked':
        return 'Blocked';
      case 'declined':
        return 'Declined';
      default:
        return friendship.status;
    }
  }

  String _formatDate(DateTime dateTime) {
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
