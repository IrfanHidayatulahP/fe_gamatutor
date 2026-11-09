import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:gamatutor_kanban/service/SecureTokenStorage.dart';
import 'package:gamatutor_kanban/service/app_config.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // FETCH NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════
  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final token = await SecureTokenStorage.getToken();
      if (token == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      // FIX: pakai baseUrl dinamis, bukan hardcoded 10.0.2.2
      final baseUrl = await ApiConstants.getBaseUrl('');
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _notifications = data['notifications'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Gagal memuat notifikasi: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HANDLE ACTION (Accept / Decline)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _handleAction(
    String notifId,
    String? referenceId,
    String? triggerUserId,
    String action, {
    String? triggerAction,
  }) async {
    try {
      final token = await SecureTokenStorage.getToken();
      if (token == null) return;

      final baseUrl = await ApiConstants.getBaseUrl('');

      if (referenceId != null && referenceId.isNotEmpty) {
        String endpoint;

        // Cek jenis aksi: kolaborasi task vs pertemanan
        if (triggerAction == 'collaboration_request') {
          endpoint = action == 'accept'
              ? '$baseUrl/cards/$referenceId/collaboration/accept'
              : '$baseUrl/cards/$referenceId/collaboration/reject';
        } else {
          // Permintaan pertemanan (friendship)
          endpoint = action == 'accept'
              ? '$baseUrl/friendships/$referenceId/accept'
              : '$baseUrl/friendships/$referenceId/reject';
        }

        final response = await http.put(
          Uri.parse(endpoint),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (!mounted) return;

        if (response.statusCode == 200) {
          _fetchNotifications();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Undangan berhasil di-${action == 'accept' ? 'terima' : 'tolak'}',
                ),
                backgroundColor: action == 'accept'
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            );
          }
          return;
        }
      }

      // Fallback: notifikasi umum
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notifId/action'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'action': action}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _fetchNotifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Berhasil memproses undangan $action')),
          );
        }
      }
    } catch (e) {
      debugPrint('Gagal memproses aksi notifikasi: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kanbanNotifications = _notifications
        .where(
          (n) =>
              n['type'] == 'kanban' ||
              n['type'] == 'task' ||
              n['type'] == 'collaboration' ||
              n['triggerAction'] == 'friend_request' ||
              n['triggerAction'] == 'collaboration_request',
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: const Color(0xFF6366F1),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Semua'),
                  Tab(text: 'Kanban'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList(_notifications, isKanbanTab: false),
                _buildNotificationList(kanbanNotifications, isKanbanTab: true),
              ],
            ),
    );
  }

  Widget _buildNotificationList(
    List<dynamic> items, {
    required bool isKanbanTab,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'Belum ada notifikasi baru',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final notifId = item['notifId'] ?? item['notif_id'];
        final referenceId = item['referenceId'] ?? item['reference_id'];
        final triggerUserId = item['triggerUserId'] ?? item['trigger_user_id'];
        final title = item['title'] ?? 'Pemberitahuan';
        final message = item['message'] ?? '';
        final triggerAction = item['triggerAction'] ?? item['trigger_action'];

        // Tampilkan card tombol aksi jika kanban atau friend_request
        if (isKanbanTab || triggerAction == 'friend_request' || triggerAction == 'collaboration_request') {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFEEF2FF),
                      child: Icon(
                        Icons.person_add_rounded,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // ─── TOMBOL DECLINE ───
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleAction(
                          notifId,
                          referenceId,
                          triggerUserId,
                          'decline', // ✅ FIX: pakai 'decline' (bukan 'accept')
                          triggerAction: triggerAction,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ─── TOMBOL ACCEPT ───
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleAction(
                          notifId,
                          referenceId,
                          triggerUserId,
                          'accept', // ✅ Accept sudah benar
                          triggerAction: triggerAction,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Notifikasi umum
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFEEF2FF),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                message,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ),
          ),
        );
      },
    );
  }
}
