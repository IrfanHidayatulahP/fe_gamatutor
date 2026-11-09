import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/chat/chat_bloc.dart';
import '../bloc/chat/chat_event.dart';
import '../bloc/chat/chat_state.dart';
import '../data/chat_message_model.dart';
import '../../calls/ui/livekit/outgoing_call_screen.dart' as livekit;
import '../../../../core/models/user_model.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';

class ChatScreen extends StatefulWidget {
  final UserModel friend;

  const ChatScreen({super.key, required this.friend});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatBloc _chatBloc;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  int _currentOffset = 0;
  static const int _limit = 50;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _scrollController.addListener(_onScroll);
    _chatBloc.setCurrentChatUserId(widget.friend.userId);
    _chatBloc.add(LoadMessages(userId: widget.friend.userId));
    context.read<ChatBloc>().setCurrentChatUserId(widget.friend.userId);
    context.read<ChatBloc>().add(LoadMessages(userId: widget.friend.userId));
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 100 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreMessages();
    }

    // Auto-scroll to bottom when new messages arrive
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      // User is at bottom, keep them there
    }
  }

  Future<void> _loadMoreMessages() async {
    setState(() => _isLoadingMore = true);
    _currentOffset += _limit;
    context.read<ChatBloc>().add(
      LoadMoreMessages(userId: widget.friend.userId, offset: _currentOffset),
    );
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoadingMore = false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _chatBloc.setCurrentChatUserId(null);
    context.read<ChatBloc>().setCurrentChatUserId(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.friend.avatarUrl != null
                  ? NetworkImage(widget.friend.avatarUrl!)
                  : null,
              child: widget.friend.avatarUrl == null
                  ? Text(
                      widget.friend.initials,
                      style: const TextStyle(fontSize: 14),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.friend.fullName,
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Online', // This would come from presence
                  style: TextStyle(fontSize: 11, color: Colors.green[400]),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => _initiateCall(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is ChatError) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              builder: (context, state) {
                if (state is ChatLoading && _currentOffset == 0) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is MessagesLoaded) {
                  _hasMore = state.hasMore;
                  if (state.messages.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildMessageList(state.messages);
                }

                return const Center(child: Text('No messages'));
              },
            ),
          ),
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator()),
            ),
          MessageInputWidget(onSendMessage: _sendMessage),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Say hello to ${widget.friend.fullName}!',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessageModel> messages) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated
        ? authState.user.userId
        : '';

    // Build items with date separators (messages reversed, so iterate from end)
    final items = <_ChatItem>[];
    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final prev = i + 1 < messages.length ? messages[i + 1] : null;
      items.add(_ChatItem.message(msg));
      if (prev == null || !_sameDay(msg.createdAt, prev.createdAt)) {
        items.add(_ChatItem.dateSeparator(msg.createdAt));
      }
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isDateSeparator) {
          return _buildDateSeparator(item.date!);
        }
        final message = item.message!;
        final isSentByMe = message.senderId == currentUserId;
        return MessageBubbleWidget(
          message: message,
          isSentByMe: isSentByMe,
          onLongPress: () => _showMessageOptions(context, message),
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    String label;
    if (d == today) {
      label = 'Today';
    } else if (d == today.subtract(const Duration(days: 1))) {
      label = 'Yesterday';
    } else if (d.year == now.year) {
      label = DateFormat('d MMMM').format(date);
    } else {
      label = DateFormat('d MMMM yyyy').format(date);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    context.read<ChatBloc>().add(
      SendMessage(friendId: widget.friend.userId, message: text.trim()),
    );
    _messageController.clear();

    // Scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _initiateCall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => livekit.LiveKitOutgoingCallScreen(
          calleeId: widget.friend.userId,
          calleeName: widget.friend.fullName,
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, ChatMessageModel message) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated
        ? authState.user.userId
        : '';
    final isSentByMe = message.senderId == currentUserId;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                // Copy to clipboard
              },
            ),
            if (isSentByMe) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditMessageDialog(context, message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirm(context, message);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                // Implement reply
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMessageDialog(BuildContext context, ChatMessageModel message) {
    final controller = TextEditingController(text: message.messageChat);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Message'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ChatBloc>().add(
                EditMessage(chatId: message.chatId, message: controller.text),
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, ChatMessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatBloc>().add(
                DeleteMessage(chatId: message.chatId),
              );
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ChatItem {
  final ChatMessageModel? message;
  final DateTime? date;

  const _ChatItem._({this.message, this.date});
  factory _ChatItem.message(ChatMessageModel m) => _ChatItem._(message: m);
  factory _ChatItem.dateSeparator(DateTime d) => _ChatItem._(date: d);

  bool get isDateSeparator => date != null;
}

class MessageInputWidget extends StatelessWidget {
  final Function(String) onSendMessage;

  const MessageInputWidget({super.key, required this.onSendMessage});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // Attach file
            },
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (value) {
                onSendMessage(value);
                controller.clear();
              },
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              onSendMessage(controller.text);
              controller.clear();
            },
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

class MessageBubbleWidget extends StatelessWidget {
  final ChatMessageModel message;
  final bool isSentByMe;
  final VoidCallback? onLongPress;

  const MessageBubbleWidget({
    super.key,
    required this.message,
    required this.isSentByMe,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: isSentByMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isSentByMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage: message.sender?.avatarUrl != null
                    ? NetworkImage(message.sender!.avatarUrl!)
                    : null,
                child: message.sender?.avatarUrl == null
                    ? Text(
                        message.sender?.initials ?? '?',
                        style: const TextStyle(fontSize: 12),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSentByMe
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isSentByMe ? 16 : 4),
                    bottomRight: Radius.circular(isSentByMe ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isSentByMe && message.sender != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          message.sender!.fullName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSentByMe
                                ? colorScheme.onPrimary.withValues(alpha: 0.8)
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    Text(
                      message.messageChat,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSentByMe
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSentByMe
                                ? colorScheme.onPrimary.withValues(alpha: 0.6)
                                : colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.6,
                                  ),
                          ),
                        ),
                        if (isSentByMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 14,
                            color: message.isRead
                                ? Colors.blue
                                : colorScheme.onPrimary.withValues(alpha: 0.6),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isSentByMe) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundImage: message.receiver?.avatarUrl != null
                    ? NetworkImage(message.receiver!.avatarUrl!)
                    : null,
                child: message.receiver?.avatarUrl == null
                    ? Text(
                        message.receiver?.initials ?? '?',
                        style: const TextStyle(fontSize: 12),
                      )
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
