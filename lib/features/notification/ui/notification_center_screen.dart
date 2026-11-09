// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import 'package:intl/intl.dart';

// import '../bloc/notification_bloc.dart';
// import '../bloc/notification_event.dart';
// import '../bloc/notification_state.dart';
// import '../data/notification_model.dart';

// // Import DI untuk API Client
// import '../../../../core/di/injection_container.dart';
// import '../../../../core/network/api_client.dart';

// class NotificationCenterScreen extends StatefulWidget {
//   const NotificationCenterScreen({super.key});

//   @override
//   State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
// }

// class _NotificationCenterScreenState extends State<NotificationCenterScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final ScrollController _scrollController = ScrollController();
//   int _currentOffset = 0;
//   static const int _limit = 50;
//   bool _isLoadingMore = false;
//   bool _hasMore = true;
//   String? _currentType;
//   bool? _currentRead;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 4, vsync: this);
//     _scrollController.addListener(_onScroll);
//     context.read<NotificationBloc>().add(const LoadNotifications());
//   }

//   void _onScroll() {
//     if (_scrollController.position.pixels >=
//             _scrollController.position.maxScrollExtent - 200 &&
//         !_isLoadingMore &&
//         _hasMore) {
//       _loadMore();
//     }
//   }

//   Future<void> _loadMore() async {
//     setState(() => _isLoadingMore = true);
//     _currentOffset += _limit;
//     context.read<NotificationBloc>().add(LoadNotifications(
//           type: _currentType,
//           read: _currentRead,
//           limit: _limit,
//           offset: _currentOffset,
//         ));
//     await Future.delayed(const Duration(milliseconds: 500));
//     setState(() => _isLoadingMore = false);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 18),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Notification',
//           style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
//         ),
//         centerTitle: true,
//         bottom: TabBar(
//           controller: _tabController,
//           isScrollable: true,
//           labelColor: const Color(0xFF6C5CE7),
//           unselectedLabelColor: Colors.grey.shade600,
//           indicatorColor: const Color(0xFF6C5CE7),
//           indicatorWeight: 3,
//           tabs: const [
//             Tab(text: 'Semua'),
//             Tab(text: 'Unread'),
//             Tab(text: 'Kanban'),
//             Tab(text: 'System'),
//           ],
//           onTap: (index) {
//             String? type;
//             bool? read;
//             switch (index) {
//               case 1:
//                 read = false;
//                 break;
//               case 2:
//                 type = 'social';
//                 break;
//               case 3:
//                 type = 'system';
//                 break;
//               default:
//                 type = null;
//                 read = null;
//             }
//             _currentType = type;
//             _currentRead = read;
//             _currentOffset = 0;
//             context.read<NotificationBloc>().add(LoadNotifications(
//                   type: type,
//                   read: read,
//                 ));
//           },
//         ),
//         actions: [
//           BlocBuilder<NotificationBloc, NotificationState>(
//             builder: (context, state) {
//               if (state is NotificationsLoaded && state.unreadCount > 0) {
//                 return TextButton.icon(
//                   onPressed: () => context.read<NotificationBloc>().add(const MarkAllAsRead()),
//                   icon: const Icon(Icons.done_all, size: 18),
//                   label: Text('Mark all read (${state.unreadCount})'),
//                 );
//               }
//               return const SizedBox.shrink();
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () => context.read<NotificationBloc>().add(LoadNotifications(
//                   type: _currentType,
//                   read: _currentRead,
//                 )),
//           ),
//         ],
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           _buildNotificationList(),
//           _buildNotificationList(),
//           _buildNotificationList(),
//           _buildNotificationList(),
//         ],
//       ),
//     );
//   }

//   Widget _buildNotificationList() {
//     return BlocConsumer<NotificationBloc, NotificationState>(
//       listener: (context, state) {
//         if (state is NotificationError) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(state.message), backgroundColor: Colors.red),
//           );
//         } else if (state is NotificationActionSuccess) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(state.message)),
//           );
//         }
//       },
//       builder: (context, state) {
//         if (state is NotificationLoading && _currentOffset == 0) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (state is NotificationsLoaded) {
//           _hasMore = state.hasMore;
//           if (state.notifications.isEmpty) {
//             return _buildEmptyState();
//           }
//           return _buildList(state.notifications);
//         }

//         return const Center(child: Text('No notifications'));
//       },
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
//           const SizedBox(height: 16),
//           Text(
//             'No notifications',
//             style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                   color: Colors.grey[600],
//                 ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'You\'re all caught up!',
//             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                   color: Colors.grey[500],
//                 ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildList(List<NotificationModel> notifications) {
//     return RefreshIndicator(
//       onRefresh: () async {
//         _currentOffset = 0;
//         context.read<NotificationBloc>().add(LoadNotifications(
//               type: _currentType,
//               read: _currentRead,
//             ));
//       },
//       child: ListView.builder(
//         controller: _scrollController,
//         padding: const EdgeInsets.all(16),
//         itemCount: notifications.length + (_hasMore ? 1 : 0),
//         itemBuilder: (context, index) {
//           if (index >= notifications.length) {
//             return _isLoadingMore
//                 ? const Padding(
//                     padding: EdgeInsets.all(16),
//                     child: Center(child: CircularProgressIndicator()),
//                   )
//                 : const SizedBox.shrink();
//           }
//           return _buildNotificationTile(notifications[index]);
//         },
//       ),
//     );
//   }

//   Widget _buildNotificationTile(NotificationModel notification) {
//     final isUnread = !notification.read;

//     // 1. Ambil nilai triggerAction dan title dengan aman
//     final String triggerActionStr = (notification.triggerAction ?? '');
//     final String titleStr = (notification.title ?? '');
    
//     // 2. Cek apakah ini permintaan sesi fokus
//     final isFocusRequest = triggerActionStr.contains('focus_request') || titleStr.contains('sesi fokus');
    
//     // 3. Cek apakah ini undangan kolaborasi (opsional, jika ingin menampilkan tombol juga)
//     final isCollabInvite = triggerActionStr.contains('collaboration_request') || titleStr.contains('kolaborasi');

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey.shade200),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.02),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(16),
//           onTap: () => _handleNotificationTap(notification),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column( // 👈 Gunakan Column agar tombol bisa ditaruh di bawah
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Icon
//                     Container(
//                       width: 44,
//                       height: 44,
//                       decoration: BoxDecoration(
//                         color: isFocusRequest ? const Color(0xFFEEF2FF) : Colors.grey.shade100,
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         isFocusRequest ? Icons.notifications_active : Icons.notifications,
//                         color: isFocusRequest ? const Color(0xFF6C5CE7) : Colors.grey,
//                         size: 22,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
                    
//                     // Text Content
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             notification.title ?? 'Notifikasi',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 14,
//                               color: isUnread ? Colors.black87 : Colors.grey.shade600,
//                             ),
//                           ),
//                           const SizedBox(height: 6),
//                           Text(
//                             notification.message,
//                             style: TextStyle(
//                               color: Colors.grey.shade600,
//                               fontSize: 13,
//                               height: 1.4,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
                
//                 // 👇 TOMBOL ACCEPT & DECLINE MUNCUL DI SINI 👇
//                 if (isFocusRequest) ...[
//                   const SizedBox(height: 16),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton(
//                           onPressed: () {
//                             final cardId = notification.referenceId ?? '';
//                             if (cardId.isNotEmpty) _respondFocus(cardId, 'reject');
//                           },
//                           style: OutlinedButton.styleFrom(
//                             foregroundColor: Colors.red,
//                             side: const BorderSide(color: Colors.red),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                             padding: const EdgeInsets.symmetric(vertical: 12),
//                           ),
//                           child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: () {
//                             final cardId = notification.referenceId ?? '';
//                             if (cardId.isNotEmpty) _respondFocus(cardId, 'accept');
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF6C5CE7),
//                             elevation: 0,
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                             padding: const EdgeInsets.symmetric(vertical: 12),
//                           ),
//                           child: const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _handleNotificationTap(NotificationModel notification) {
//     // Mark as read when tapped
//     if (!notification.read) {
//       context.read<NotificationBloc>().add(MarkAsRead(notifId: notification.notifId));
//     } else {
//       context.read<NotificationBloc>().add(MarkAsClicked(notifId: notification.notifId));
//     }

//     // Jika ini adalah permintaan fokus, kita tidak perlu melakukan navigasi
//     // karena tombol aksinya sudah ada di dalam card.
//     final String triggerActionStr = '${notification.triggerAction ?? ''}';
//     if (triggerActionStr.contains('focus_request')) {
//       return;
//     }

//     _navigateFromNotification(notification);
//   }

//   Future<void> _respondFocus(String cardId, String action) async {
//     try {
//       await sl<ApiClient>().post('/cards/$cardId/respond-focus', data: {'action': action});
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(action == 'accept' ? 'Sesi fokus disetujui!' : 'Sesi fokus ditolak.'),
//             backgroundColor: action == 'accept' ? Colors.green : Colors.red,
//           ),
//         );
//         // Reload notifikasi agar item yang di-klik hilang atau terupdate
//         context.read<NotificationBloc>().add(const LoadNotifications());
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Gagal merespon: $e'), backgroundColor: Colors.red),
//         );
//       }
//     }
//   }

//   void _navigateFromNotification(NotificationModel notification) {
//     switch (notification.type) {
//       case 'friend_request_received':
//       case 'friend_request_accepted':
//       case 'friend_request_rejected':
//         context.push('/pending-requests');
//         break;
//       case 'call_incoming':
//       case 'call_missed':
//         context.push('/call-history');
//         break;
//       case 'group_call_invite':
//       case 'group_call_starting':
//         if (notification.triggerAction != null) {
//           context.push('/group-call/${notification.triggerAction}');
//         }
//         break;
//       case 'collaboration_invite':
//         context.push('/collaboration-invites');
//         break;
//       default:
//         break;
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../data/notification_model.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  int _currentOffset = 0;
  static const int _limit = 50;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _currentType;
  bool? _currentRead;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_onScroll);
    context.read<NotificationBloc>().add(const LoadNotifications());
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    _currentOffset += _limit;
    context.read<NotificationBloc>().add(LoadNotifications(
          type: _currentType,
          read: _currentRead,
          limit: _limit,
          offset: _currentOffset,
        ));
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoadingMore = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF6C5CE7),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFF6C5CE7),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Unread'),
            Tab(text: 'Kanban'),
            Tab(text: 'System'),
          ],
          onTap: (index) {
            String? type;
            bool? read;
            switch (index) {
              case 1:
                read = false;
                break;
              case 2:
                type = 'social';
                break;
              case 3:
                type = 'system';
                break;
              default:
                type = null;
                read = null;
            }
            _currentType = type;
            _currentRead = read;
            _currentOffset = 0;
            context.read<NotificationBloc>().add(LoadNotifications(
                  type: type,
                  read: read,
                ));
          },
        ),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && state.unreadCount > 0) {
                return TextButton.icon(
                  onPressed: () => context.read<NotificationBloc>().add(const MarkAllAsRead()),
                  icon: const Icon(Icons.done_all, size: 18),
                  label: Text('Mark all read (${state.unreadCount})'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(),
          _buildNotificationList(),
          _buildNotificationList(),
          _buildNotificationList(),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return BlocConsumer<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state is NotificationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is NotificationLoading && _currentOffset == 0) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is NotificationsLoaded) {
          _hasMore = state.hasMore;
          if (state.notifications.isEmpty) {
            return _buildEmptyState();
          }
          return _buildList(state.notifications);
        }

        return const Center(child: Text('Tidak ada notifikasi'));
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada notifikasi',
            style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<NotificationModel> notifications) {
    return RefreshIndicator(
      onRefresh: () async {
        _currentOffset = 0;
        context.read<NotificationBloc>().add(LoadNotifications(
              type: _currentType,
              read: _currentRead,
            ));
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= notifications.length) {
            return _isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink();
          }
          return _buildNotificationTile(notifications[index]);
        },
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    final isUnread = !notification.read;

    // =========================================================================
    // 👇 PERBAIKAN: Mengambil data dari 'type' dan 'cardId' sesuai log backend
    // =========================================================================
    
    // 1. Ambil Tipe (Bisa dari type, atau triggerAction)
    final String typeStr = '${notification.type}';
    final String triggerStr = notification.triggerAction ?? '';
    
    // Cek apakah ini request fokus
    final isFocusRequest = typeStr.contains('focus') || triggerStr.contains('focus');

    // 2. Ambil Card ID (Bisa dari referenceId, atau cardId di triggerAction)
    // Karena backend mengirim 'cardId' di FCM, kita coba ambil dari model
    final String cardId = (notification.referenceId ?? notification.triggerAction ?? '').toString();

    // Tampilkan tombol jika ini request fokus DAN cardId tidak kosong
    final showButtons = isFocusRequest && cardId.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          if (isUnread)
            BoxShadow(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isFocusRequest ? const Color(0xFFEEF2FF) : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFocusRequest ? Icons.notifications_active : Icons.notifications,
                        color: isFocusRequest ? const Color(0xFF6C5CE7) : Colors.grey,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title ?? 'Notifikasi',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notification.message,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // 👇 TOMBOL MUNCUL DI SINI 👇
                if (showButtons) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _respondFocus(cardId, 'reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _respondFocus(cardId, 'accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C5CE7),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (!notification.read) {
      context.read<NotificationBloc>().add(MarkAsRead(notifId: notification.notifId));
    } else {
      context.read<NotificationBloc>().add(MarkAsClicked(notifId: notification.notifId));
    }
  }

  Future<void> _respondFocus(String cardId, String action) async {
    if (cardId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Card ID tidak ditemukan.'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await sl<ApiClient>().post('/cards/$cardId/respond-focus', data: {'action': action});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'accept' ? 'Sesi fokus disetujui!' : 'Sesi fokus ditolak.'),
            backgroundColor: action == 'accept' ? Colors.green : Colors.red,
          ),
        );
        context.read<NotificationBloc>().add(const LoadNotifications());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal merespon: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}