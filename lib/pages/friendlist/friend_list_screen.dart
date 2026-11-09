// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:gamatutor_kanban/service/SecureTokenStorage.dart';

// class FriendListScreen extends StatefulWidget {
//   const FriendListScreen({super.key});

//   @override
//   State<FriendListScreen> createState() => _FriendListScreenState();
// }

// class _FriendListScreenState extends State<FriendListScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   bool _isLoading = true;
//   List<dynamic> _allFriends = [];
//   List<dynamic> _pendingRequests = [];
//   String _searchQuery = '';

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     _fetchFriendData();
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   String? _parseJwtUserId(String token) {
//   try {
//     final parts = token.split('.');
//     if (parts.length != 3) return null;
    
//     final payload = jsonDecode(
//       utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
//     );
    
//     // Sesuaikan key dengan isi payload JWT backend Anda (biasanya 'userId' atau 'id')
//     return payload['userId'] ?? payload['id'] ?? payload['sub'];
//   } catch (e) {
//     debugPrint('Gagal decode token: $e');
//     return null;
//   }
// }

//   // Future<void> _fetchFriendData() async {
//   //   setState(() => _isLoading = true);
//   //   try {
//   //     final token = await SecureTokenStorage.getToken();
//   //     if (token == null) return;

//   //     // 1. Ambil data teman yang sudah berteman (Accepted)
//   //     final friendsRes = await http.get(
//   //       Uri.parse('http://10.0.2.2:3000/api/friendships?status=accepted'),
//   //       headers: {'Authorization': 'Bearer $token'},
//   //     );

//   //     // 2. Ambil data request pertemanan yang masuk (Pending)
//   //     // Catatan: Sesuaikan endpoint jika menggunakan ID spesifik atau endpoint universal pending
//   //     final pendingRes = await http.get(
//   //       Uri.parse('http://10.0.2.2:3000/api/friendships?status=pending'),
//   //       headers: {'Authorization': 'Bearer $token'},
//   //     );

//   //     if (friendsRes.statusCode == 200 && pendingRes.statusCode == 200) {
//   //       final friendsData = jsonDecode(friendsRes.body);
//   //       final pendingData = jsonDecode(pendingRes.body);

//   //       setState(() {
//   //         _allFriends = friendsData['friendships'] ?? [];
//   //         _pendingRequests = pendingData['friendships'] ?? [];
//   //         _isLoading = false;
//   //       });
//   //     }
//   //   } catch (e) {
//   //     debugPrint('Gagal memuat data teman: $e');
//   //     setState(() => _isLoading = false);
//   //   }
//   // }

//   String? _currentUserId;

// Future<void> _fetchFriendData() async {
//     setState(() => _isLoading = true);
//     try {
//       final token = await SecureTokenStorage.getToken();
//       if (token == null) return;

//       // 💡 Ambil userId dengan mendecode token JWT yang sedang aktif
//       final userId = _parseJwtUserId(token);

//       // 1. Ambil data teman (Accepted)
//       final friendsRes = await http.get(
//         Uri.parse('http://10.0.2.2:3000/api/friendships?status=accepted'),
//         headers: {'Authorization': 'Bearer $token'},
//       );

//       // 2. Ambil data request pertemanan (Pending)
//       final pendingRes = await http.get(
//         Uri.parse('http://10.0.2.2:3000/api/friendships?status=pending'),
//         headers: {'Authorization': 'Bearer $token'},
//       );

//       if (friendsRes.statusCode == 200 && pendingRes.statusCode == 200) {
//         final friendsData = jsonDecode(friendsRes.body);
//         final pendingData = jsonDecode(pendingRes.body);

//         setState(() {
//           _currentUserId = userId;
//           _allFriends = friendsData['friendships'] ?? [];
//           _pendingRequests = pendingData['friendships'] ?? [];
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Gagal memuat data teman: $e');
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _handleFriendAction(String fsId, String action) async {
//     try {
//       final token = await SecureTokenStorage.getToken();
//       if (token == null) return;

//       final endpoint = action == 'accept'
//           ? 'http://10.0.2.2:3000/api/friendships/$fsId/accept'
//           : 'http://10.0.2.2:3000/api/friendships/$fsId/reject';

//       final response = await http.put(
//         Uri.parse(endpoint),
//         headers: {'Authorization': 'Bearer $token'},
//       );

//       if (response.statusCode == 200) {
//         _fetchFriendData(); // Refresh data setelah aksi berhasil
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Permintaan pertemanan berhasil di-$action')),
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint('Gagal memproses aksi teman: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Filter pencarian berdasarkan nama atau username
//     final filteredFriends = _allFriends.where((item) {
//       final requester = item['requester'] ?? {};
//       final friend = item['friend'] ?? {};
//       final name = '${requester['firstName'] ?? ''} ${requester['lastName'] ?? ''} ${friend['username'] ?? ''}'.toLowerCase();
//       return name.contains(_searchQuery.toLowerCase());
//     }).toList();

//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Teman',
//           style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
//         ),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.more_vert_rounded, color: Colors.black),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Container(
//             color: Colors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             child: Column(
//               children: [
//                 TextField(
//                   onChanged: (value) => setState(() => _searchQuery = value),
//                   decoration: InputDecoration(
//                     hintText: 'Cari teman.....',
//                     hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
//                     prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
//                     filled: true,
//                     fillColor: const Color(0xFFF1F5F9),
//                     contentPadding: const EdgeInsets.symmetric(vertical: 0),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(20),
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Container(
//                   height: 38,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFF1F5F9),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: TabBar(
//                     controller: _tabController,
//                     indicator: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(20),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.05),
//                           blurRadius: 4,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     labelColor: const Color(0xFF6366F1),
//                     unselectedLabelColor: const Color(0xFF64748B),
//                     labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
//                     tabs: [
//                       const Tab(text: 'Semua'),
//                       const Tab(text: 'Dalam Tim'),
//                       Tab(
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Text('Request'),
//                             if (_pendingRequests.isNotEmpty) ...[
//                               const SizedBox(width: 4),
//                               Container(
//                                 padding: const EdgeInsets.all(5),
//                                 decoration: const BoxDecoration(
//                                   color: Color(0xFF6366F1),
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: Text('${_pendingRequests.length}', style: const TextStyle(color: Colors.white, fontSize: 9)),
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const Divider(height: 1, color: Color(0xFFE2E8F0)),
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : TabBarView(
//                     controller: _tabController,
//                     children: [
//                       _buildFriendList(filteredFriends, isRequestTab: false),
//                       _buildFriendList(filteredFriends, isRequestTab: false), // Tab Dalam Tim (bisa disesuaikan filternya jika ada field team)
//                       _buildRequestList(_pendingRequests),
//                     ],
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Widget _buildFriendList(List items, {required bool isRequestTab}) {
//   //   if (items.isEmpty) {
//   //     return const Center(child: Text('Belum ada teman', style: TextStyle(color: Colors.grey)));
//   //   }

//   //   return ListView.builder(
//   //     itemCount: items.length,
//   //     itemBuilder: (context, index) {
//   //       final friendship = items[index];
//   //       // Mengambil data user partner (bisa requester atau friend tergantung siapa yang login)
//   //       final user = friendship['friend'] ?? friendship['requester'] ?? {};
//   //       final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
//   //       final displayName = name.isNotEmpty ? name : (user['username'] ?? 'User');

//   //       return Container(
//   //         color: Colors.white,
//   //         child: ListTile(
//   //           leading: const CircleAvatar(
//   //             radius: 22,
//   //             backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
//   //           ),
//   //           title: Text(
//   //             displayName,
//   //             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
//   //           ),
//   //           subtitle: const Padding(
//   //             padding: EdgeInsets.only(top: 4.0),
//   //             child: Row(
//   //               children: [
//   //                 Icon(Icons.circle, color: Colors.green, size: 8),
//   //                 SizedBox(width: 6),
//   //                 Text('Online', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
//   //               ],
//   //             ),
//   //           ),
//   //         ),
//   //       );
//   //     },
//   //   );
//   // }

//   Widget _buildFriendList(List items, {required bool isRequestTab}) {
//     if (items.isEmpty) {
//       return const Center(child: Text('Belum ada teman', style: TextStyle(color: Colors.grey)));
//     }

//     return ListView.builder(
//       itemCount: items.length,
//       itemBuilder: (context, index) {
//         final friendship = items[index];
        
//         final requester = friendship['requester'] ?? {};
//         final friend = friendship['friend'] ?? {};

//         // 💡 PERBAIKAN LOGIKA:
//         // Jika ID requester sama dengan ID kita, maka yang ditampilkan adalah data 'friend' (Ipan).
//         // Sebaliknya, jika ID friend sama dengan ID kita, maka yang ditampilkan adalah 'requester'.
//         final user = (requester['userId'] == _currentUserId || requester['user_id'] == _currentUserId)
//             ? friend
//             : requester;

//         final firstName = user['firstName'] ?? user['first_name'] ?? '';
//         final lastName = user['lastName'] ?? user['last_name'] ?? '';
//         final name = '$firstName $lastName'.trim();
//         final displayName = name.isNotEmpty ? name : (user['username'] ?? 'User');

//         return Container(
//           color: Colors.white,
//           child: ListTile(
//             leading: const CircleAvatar(
//               radius: 22,
//               backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
//             ),
//             title: Text(
//               displayName,
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
//             ),
//             subtitle: const Padding(
//               padding: EdgeInsets.only(top: 4.0),
//               child: Row(
//                 children: [
//                   Icon(Icons.circle, color: Colors.green, size: 8),
//                   SizedBox(width: 6),
//                   Text('Online', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildRequestList(List items) {
//     if (items.isEmpty) {
//       return const Center(child: Text('Tidak ada permintaan pertemanan', style: TextStyle(color: Colors.grey)));
//     }

//     return ListView.builder(
//       itemCount: items.length,
//       itemBuilder: (context, index) {
//         final friendship = items[index];
//         final fsId = friendship['fsId'] ?? friendship['fs_id'];
//         final requester = friendship['requester'] ?? {};
//         final name = '${requester['firstName'] ?? ''} ${requester['lastName'] ?? ''}'.trim();
//         final displayName = name.isNotEmpty ? name : (requester['username'] ?? 'User');

//         return Container(
//           color: Colors.white,
//           padding: const EdgeInsets.symmetric(vertical: 4),
//           child: ListTile(
//             leading: const CircleAvatar(
//               radius: 22,
//               backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=15'),
//             ),
//             title: Text(
//               displayName,
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
//             ),
//             subtitle: const Padding(
//               padding: EdgeInsets.only(top: 4.0),
//               child: Row(
//                 children: [
//                   Icon(Icons.circle, color: Colors.grey, size: 8),
//                   SizedBox(width: 6),
//                   Text('Offline', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
//                 ],
//               ),
//             ),
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 ElevatedButton(
//                   onPressed: () => _handleFriendAction(fsId, 'accept'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF10B981),
//                     foregroundColor: Colors.white,
//                     minimumSize: const Size(60, 32),
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                   ),
//                   child: const Text('Accept', style: TextStyle(fontSize: 11)),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton(
//                   onPressed: () => _handleFriendAction(fsId, 'reject'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFFEF4444),
//                     foregroundColor: Colors.white,
//                     minimumSize: const Size(60, 32),
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                   ),
//                   child: const Text('Decline', style: TextStyle(fontSize: 11)),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gamatutor_kanban/service/SecureTokenStorage.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _allFriends = [];
  List<dynamic> _pendingRequests = [];
  String _searchQuery = '';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchFriendData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? _parseJwtUserId(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
      );
      return payload['userId'] ?? payload['id'] ?? payload['sub'];
    } catch (e) {
      debugPrint('Gagal decode token: $e');
      return null;
    }
  }

  Future<void> _fetchFriendData() async {
    setState(() => _isLoading = true);
    try {
      final token = await SecureTokenStorage.getToken();
      if (token == null) return;

      final userId = _parseJwtUserId(token);

      // Ambil data friendships (bisa jadi API mengembalikan semua, kita filter manual)
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/friendships'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List rawFriendships = data['friendships'] ?? [];

        List<dynamic> acceptedFriends = [];
        List<dynamic> incomingRequests = [];

        for (var f in rawFriendships) {
          final status = f['status'];
          final requesterId = f['requester']?['userId'] ?? f['userId'];
          final friendId = f['friend']?['userId'] ?? f['friendId'];

          if (status == 'accepted') {
            // Masukkan ke list teman jika statusnya accepted
            acceptedFriends.add(f);
          } else if (status == 'pending') {
            // Masukkan ke list request HANYA JIKA kita adalah penerima (bukan pengirim)
            if (friendId == userId) {
              incomingRequests.add(f);
            }
          }
        }

        setState(() {
          _currentUserId = userId;
          _allFriends = acceptedFriends;
          _pendingRequests = incomingRequests;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Gagal memuat data teman: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFriendAction(String fsId, String action) async {
    try {
      final token = await SecureTokenStorage.getToken();
      if (token == null) return;

      final endpoint = action == 'accept'
          ? 'http://10.0.2.2:3000/api/friendships/$fsId/accept'
          : 'http://10.0.2.2:3000/api/friendships/$fsId/reject';

      final response = await http.put(
        Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _fetchFriendData(); 
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Permintaan pertemanan berhasil di-$action')),
          );
        }
      }
    } catch (e) {
      debugPrint('Gagal memproses aksi teman: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFriends = _allFriends.where((item) {
      final requester = item['requester'] ?? {};
      final friend = item['friend'] ?? {};
      
      // Ambil data user lawan bicara untuk pencarian
      final user = (requester['userId'] == _currentUserId) ? friend : requester;
      
      final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''} ${user['username'] ?? ''}'.toString();
      return name.contains(_searchQuery.toString());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Teman',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Cari teman.....',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 22),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
                      color: Colors.white,
                    ),
                    labelColor: const Color(0xFF6366F1),
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: [
                      const Tab(text: 'Semua'),
                      const Tab(text: 'Dalam Tim'),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Request'),
                            if (_pendingRequests.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_pendingRequests.length}', 
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFriendList(filteredFriends),
                      _buildFriendList(filteredFriends),
                      _buildRequestList(_pendingRequests),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendList(List items) {
    if (items.isEmpty) {
      return const Center(child: Text('Belum ada teman', style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        thickness: 0.5,
        color: Color(0xFFE2E8F0),
        indent: 70,
        endIndent: 20,
      ),
      itemBuilder: (context, index) {
        final friendship = items[index];
        final requester = friendship['requester'] ?? {};
        final friend = friendship['friend'] ?? {};

        final user = (requester['userId'] == _currentUserId || requester['user_id'] == _currentUserId)
            ? friend
            : requester;

        final firstName = user['firstName'] ?? user['first_name'] ?? '';
        final lastName = user['lastName'] ?? user['last_name'] ?? '';
        final name = '$firstName $lastName'.trim();
        final displayName = name.isNotEmpty ? name : (user['username'] ?? 'User');
        
        final String userStatus = (user['status'] ?? 'offline').toString().toString();
        final bool isOnline = userStatus == 'online';

        return Container(
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFEEF2FF),
              backgroundImage: (user['avatar'] != null && user['avatar'].toString().isNotEmpty) 
                  ? NetworkImage(user['avatar']) 
                  : null,
              child: (user['avatar'] == null || user['avatar'].toString().isEmpty) 
                  ? Text(displayName[0].toUpperCase(), style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)) 
                  : null,
            ),
            title: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOnline ? 'Online' : 'Offline', 
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestList(List items) {
    if (items.isEmpty) {
      return const Center(child: Text('Tidak ada permintaan pertemanan', style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        thickness: 0.5,
        color: Color(0xFFE2E8F0),
        indent: 70,
        endIndent: 20,
      ),
      itemBuilder: (context, index) {
        final friendship = items[index];
        final fsId = friendship['fsId'] ?? friendship['fs_id'];
        final requester = friendship['requester'] ?? {};
        final name = '${requester['firstName'] ?? ''} ${requester['lastName'] ?? ''}'.trim();
        final displayName = name.isNotEmpty ? name : (requester['username'] ?? 'User');

        final String userStatus = (requester['status'] ?? 'offline').toString().toString();
        final bool isOnline = userStatus == 'online';

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFEEF2FF),
              backgroundImage: (requester['avatar'] != null && requester['avatar'].toString().isNotEmpty) 
                  ? NetworkImage(requester['avatar']) 
                  : null,
              child: (requester['avatar'] == null || requester['avatar'].toString().isEmpty) 
                  ? Text(displayName[0].toUpperCase(), style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)) 
                  : null,
            ),
            title: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOnline ? 'Online' : 'Offline', 
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => _handleFriendAction(fsId, 'accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(60, 32),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Accept', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _handleFriendAction(fsId, 'reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFEF4444),
                    minimumSize: const Size(60, 32),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFEF4444), width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Decline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}