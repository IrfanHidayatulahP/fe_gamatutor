import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gamatutor_kanban/service/SecureTokenStorage.dart';

class SearchFriendScreen extends StatefulWidget {
  const SearchFriendScreen({super.key});

  @override
  State<SearchFriendScreen> createState() => _SearchFriendScreenState();
}

class _SearchFriendScreenState extends State<SearchFriendScreen> {
  final String baseUrl = 'http://10.0.2.2:3000/api';

  List<dynamic> _usersList = [];
  final Set<String> _requestedUsers = {}; // Status Pending (Request dikirim/diterima)
  final Set<String> _friends = {}; // Status Accepted (Berteman)
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchInitialData('');
  }

  // Fungsi untuk mengekstrak userId dari token JWT
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

  Future<void> _fetchInitialData(String query) async {
    setState(() => _isLoading = true);
    try {
      final token = await SecureTokenStorage.getToken();
      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Ambil current user ID
      final userId = _parseJwtUserId(token);
      _currentUserId = userId;

      // 1. Ambil data pencarian user
      final userResponse = await http.get(
        Uri.parse('$baseUrl/users/search?query=$query'),
        headers: {'Authorization': 'Bearer $token'},
      );

      // 2. Ambil daftar friendship (semua relasi)
      final friendshipResponse = await http.get(
        Uri.parse('$baseUrl/friendships'),
        headers: {'Authorization': 'Bearer $token'},
      );

      Set<String> existingRequestedIds = {};
      Set<String> existingFriendIds = {};

      if (friendshipResponse.statusCode == 200) {
        final friendshipData = jsonDecode(friendshipResponse.body);
        final List friendships = friendshipData['friendships'] ?? [];
        
        for (var f in friendships) {
          final status = f['status'];
          final requesterId = f['requester']?['userId'] ?? f['userId'];
          final friendId = f['friend']?['userId'] ?? f['friendId'];

          // Cari ID lawan bicara
          String? otherUserId;
          if (requesterId == _currentUserId) {
            otherUserId = friendId;
          } else if (friendId == _currentUserId) {
            otherUserId = requesterId;
          }

          if (otherUserId != null) {
            if (status == 'pending') {
              existingRequestedIds.add(otherUserId);
            } else if (status == 'accepted') {
              existingFriendIds.add(otherUserId);
            }
          }
        }
      }

      if (userResponse.statusCode == 200) {
        final data = jsonDecode(userResponse.body);
        setState(() {
          _usersList = data['users'] ?? [];
          _requestedUsers.addAll(existingRequestedIds);
          _friends.addAll(existingFriendIds);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFriendRequest(String friendId, bool isRequested) async {
    if (_friends.contains(friendId)) return; 

    try {
      final token = await SecureTokenStorage.getToken();
      if (token == null) return;

      if (isRequested) {
        // Aksi Tombol "Batal"
        final response = await http.delete(
          Uri.parse('$baseUrl/friendships/cancel/$friendId'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          setState(() {
            _requestedUsers.remove(friendId);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permintaan pertemanan dibatalkan')),
            );
          }
        }
      } else {
        // Aksi Tombol "Tambah"
        final response = await http.post(
          Uri.parse('$baseUrl/friendships'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'friendId': friendId}),
        );

        if (response.statusCode == 201) {
          setState(() {
            _requestedUsers.add(friendId);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permintaan pertemanan terkirim')),
            );
          }
        } else {
          final errBody = jsonDecode(response.body);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errBody['message'] ?? 'Gagal mengirim permintaan')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error action friend request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cari Teman',
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (value) {
                _fetchInitialData(value);
              },
              decoration: InputDecoration(
                hintText: 'Cari teman.....',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // List User
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _usersList.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada user ditemukan',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _usersList.length,
                          itemBuilder: (context, index) {
                            final user = _usersList[index];
                            final String userId = user['userId'] ?? user['id'];
                            
                            // Jangan tampilkan diri sendiri di pencarian
                            if (userId == _currentUserId) return const SizedBox.shrink();

                            final String fullName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
                            final String displayName = fullName.isNotEmpty ? fullName : (user['username'] ?? 'Tanpa Nama');
                            
                            final String statusStr = (user['status'] ?? 'offline').toString();
                            final bool isOnline = statusStr.toString() == 'online';

                            final bool isFriend = _friends.contains(userId);
                            final bool isRequested = _requestedUsers.contains(userId);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFFEEF2FF),
                                  backgroundImage: user['avatar'] != null ? NetworkImage(user['avatar']) : null,
                                  child: user['avatar'] == null 
                                      ? Text(
                                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                          style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  displayName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                ),
                                subtitle: Row(
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
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: isFriend ? null : () => _toggleFriendRequest(userId, isRequested),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isFriend 
                                        ? Colors.grey.shade300 
                                        : (isRequested ? Colors.white : const Color(0xFF6366F1)),
                                    foregroundColor: isFriend 
                                        ? Colors.grey.shade600 
                                        : (isRequested ? const Color(0xFF6366F1) : Colors.white),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: isFriend 
                                            ? Colors.grey.shade300 
                                            : const Color(0xFF6366F1),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                                  ),
                                  child: Text(
                                    isFriend ? 'Berteman' : (isRequested ? 'Batal' : 'Tambah'),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}