import 'package:flutter/material.dart';
import 'package:gamatutor_kanban/pages/friend/searchfriend.dart';
import 'package:gamatutor_kanban/pages/friendlist/friend_list_screen.dart';

class CollaborationScreen extends StatefulWidget {
  const CollaborationScreen({super.key});

  @override
  State<CollaborationScreen> createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFabExpanded = false;

  // Data Dummy untuk Chat Tim
  final List _chats = [
    {
      'name': 'Nina Ninul',
      'message': 'Bisa bantu jelaskan bagian validasi data? Aku ma...',
      'time': '10:42',
      'unread': 2,
      'avatar': 'https://i.pravatar.cc/150?img=1'
    },
    {
      'name': 'Bim bim',
      'message': 'Aku upload file referensi ya, cek di folder monitor...',
      'time': '09:15',
      'unread': 1,
      'avatar': 'https://i.pravatar.cc/150?img=3'
    },
    {
      'name': 'Fira',
      'message': 'Terima kasih!',
      'time': 'Kemarin',
      'unread': 0,
      'avatar': 'https://i.pravatar.cc/150?img=5'
    },
    {
      'name': 'Pryta',
      'message': 'Cek task baru di planning ya',
      'time': '2 hari lalu',
      'unread': 0,
      'avatar': 'https://i.pravatar.cc/150?img=8'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter chat untuk tab "Belum Dibaca"
    final unreadChats = _chats.where((c) => (c['unread'] as int) > 0).toList();

    return Scaffold(
      backgroundColor: Colors.white, // Background utama putih sesuai desain
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Collaboration',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Search & TabBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chat dengan teman tim',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 12),
                    // Search Bar
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari percakapan atau teman...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 22),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9), // Warna abu-abu muda
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Custom TabBar
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: false,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF5B4DBC), width: 1.5), // Border ungu
                          color: Colors.white,
                        ),
                        labelColor: const Color(0xFF5B4DBC), // Warna teks aktif
                        unselectedLabelColor: const Color(0xFF64748B), // Warna teks tidak aktif
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: [
  const Tab(text: 'Semua'),
  Tab(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Belum Dibaca',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF5B4DBC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '2',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  ),
  const Tab(text: 'Group Call'),
],
                      ),
                    ),
                  ],
                ),
              ),
              
              // List Chat
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChatList(_chats),
                    _buildChatList(unreadChats),
                    const Center(child: Text('Belum ada Group Call aktif', style: TextStyle(color: Colors.grey))),
                  ],
                ),
              ),
            ],
          ),

          // Overlay gelap saat FAB terbuka
          if (_isFabExpanded)
            GestureDetector(
              onTap: () => setState(() => _isFabExpanded = false),
              child: Container(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.2)),
            ),

          // Floating Action Button & Menu
          Positioned(
            bottom: 30,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_isFabExpanded) ...[
                  _buildFabMenuItem(
                    icon: Icons.mail_outline_rounded,
                    label: 'Chat',
                    onTap: () {
                      setState(() => _isFabExpanded = false);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildFabMenuItem(
                    icon: Icons.people_outline_rounded,
                    label: 'Friend List',
                    onTap: () {
                      setState(() => _isFabExpanded = false);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FriendListScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildFabMenuItem(
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Add Friends',
                    onTap: () {
                      setState(() => _isFabExpanded = false);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SearchFriendScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
                // Tombol Utama (+)
                FloatingActionButton(
                  backgroundColor: const Color(0xFF5B4DBC), // Warna ungu sesuai desain
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: Icon(_isFabExpanded ? Icons.close : Icons.add, color: Colors.white, size: 28),
                  onPressed: () {
                    setState(() {
                      _isFabExpanded = !_isFabExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(List items) {
    if (items.isEmpty) {
      return const Center(child: Text('Tidak ada percakapan', style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        thickness: 0.5,
        color: Color(0xFFE2E8F0),
        indent: 70, // Garis mulai setelah avatar
        endIndent: 20,
      ),
      itemBuilder: (context, index) {
        final chat = items[index];
        final int unreadCount = chat['unread'] as int;

        return InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(chat['avatar']),
                ),
                const SizedBox(width: 14),
                
                // Konten Chat
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris Nama & Waktu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            chat['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            chat['time'],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Baris Pesan & Badge Unread
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chat['message'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: unreadCount > 0 ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 10),
                              padding: const EdgeInsets.all(6), // Padding untuk lingkaran badge
                              decoration: const BoxDecoration(
                                color: Color(0xFF5B4DBC), // Warna badge ungu
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget untuk Item Menu FAB (Label kiri, Icon kanan)
  Widget _buildFabMenuItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Icon Bulat
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF5B4DBC), size: 22),
          ),
        ],
      ),
    );
  }
}