import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../chat/bloc/chat/chat_bloc.dart';
import '../../chat/bloc/chat/chat_event.dart';
import '../../chat/bloc/chat/chat_state.dart';
import '../../calls/bloc/group_call/group_call_bloc.dart';
import '../../calls/bloc/group_call/group_call_event.dart';
import '../../calls/bloc/group_call/group_call_state.dart';
import '../../chat/data/chat_message_model.dart';
import '../../calls/data/group_call_model.dart';
import '../../chat/ui/chat_screen.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../board/ui/collaborative_tasks_screen.dart';

class CollaborationScreen extends StatefulWidget {
  const CollaborationScreen({super.key});

  @override
  State<CollaborationScreen> createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<ChatBloc>().add(const LoadConversations());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showFabMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Pilih Aksi',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_add,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: const Text('Add Friend'),
              subtitle: const Text('Cari dan tambah teman baru'),
              onTap: () {
                Navigator.pop(context);
                context.go('/add-friend');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.people,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: const Text('Friend List'),
              subtitle: const Text('Lihat daftar temanmu'),
              onTap: () {
                Navigator.pop(context);
                context.go('/friend-list');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.chat,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: const Text('New Chat'),
              subtitle: const Text('Mulai percakapan baru'),
              onTap: () {
                Navigator.pop(context);
                context.go('/new-chat');
              },
            ),
            // ─── Menu "Invite to Collaboration" SUDAH DIHAPUS ───
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kolaborasi'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Belum dibaca'),
            Tab(text: 'Group Call'),
          ],
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConversationsTab(),
          _buildUnreadConversationsTab(),
          _buildGroupCallTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFabMenu(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }

  Widget _buildConversationsTab() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state is ChatLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ConversationsLoaded) {
          if (state.conversations.isEmpty) {
            return _buildEmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'Belum ada percakapan',
              subtitle: 'Mulai chat dengan teman Anda',
            );
          }
          return _buildConversationList(state.conversations);
        }

        return const Center(child: Text('Tidak ada percakapan'));
      },
    );
  }

  Widget _buildUnreadConversationsTab() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state is ChatLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final authState = context.read<AuthBloc>().state;
        final currentUserId = authState is AuthAuthenticated
            ? authState.user.userId
            : '';

        if (state is ConversationsLoaded) {
          final unreadConversations = state.conversations
              .where((msg) => !msg.isRead && msg.senderId != currentUserId)
              .toList();

          if (unreadConversations.isEmpty) {
            return _buildEmptyState(
              icon: Icons.mark_email_read_outlined,
              title: 'Tidak ada pesan belum dibaca',
              subtitle: 'Semua pesan telah dibaca',
            );
          }
          return _buildConversationList(unreadConversations);
        }

        return const Center(child: Text('Tidak ada pesan belum dibaca'));
      },
    );
  }

  Widget _buildGroupCallTab() {
    return const CollaborativeTasksScreen(showAppBar: false);
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
          ],
        ),
      ),
    );
  }

  Widget _buildConversationList(List<ChatMessageModel> conversations) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated
        ? authState.user.userId
        : '';

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ChatBloc>().add(const LoadConversations());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final message = conversations[index];
          final otherUser = message.senderId == currentUserId
              ? message.receiver
              : message.sender;
          final isSentByMe = message.senderId == currentUserId;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundImage: otherUser?.avatarUrl != null
                    ? NetworkImage(otherUser!.avatarUrl!)
                    : null,
                child: otherUser?.avatarUrl == null
                    ? Text(
                        otherUser?.initials ?? '?',
                        style: const TextStyle(fontSize: 18),
                      )
                    : null,
              ),
              title: Text(otherUser?.fullName ?? 'Unknown User'),
              subtitle: Row(
                children: [
                  if (isSentByMe)
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: message.isRead ? Colors.blue : Colors.grey,
                    ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      message.messageChat,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(message.createdAt),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[500]),
                  ),
                  if (!message.isRead && !isSentByMe)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '1',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                ],
              ),
              onTap: () {
                if (otherUser != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(friend: otherUser),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  // ─── Riwayat group call (read-only, tanpa tombol join) ───
  Widget _buildGroupCallList(List<GroupCallModel> calls) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<GroupCallBloc>().add(const LoadGroupCallHistory());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: calls.length,
        itemBuilder: (context, index) {
          final call = calls[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getCallStatusColor(
                    call.status,
                    context,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.call,
                  color: _getCallStatusColor(call.status, context),
                  size: 24,
                ),
              ),
              title: Text(call.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: ${_getStatusText(call.status)}',
                    style: TextStyle(
                      color: _getCallStatusColor(call.status, context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (call.scheduledAt != null)
                    Text(
                      'Dijadwalkan: ${_formatDateTime(call.scheduledAt!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (call.startedAt != null)
                    Text(
                      'Dimulai: ${_formatDateTime(call.startedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              // Tombol join dihilangkan — aksi join dilakukan di CollaborativeTasksScreen
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Kemarin';
    } else if (messageDate.year == now.year) {
      return '${dateTime.day}/${dateTime.month}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getCallStatusColor(String status, BuildContext context) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'scheduled':
        return Theme.of(context).colorScheme.primary;
      case 'ended':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'scheduled':
        return 'Dijadwalkan';
      case 'ended':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }
}
