import 'package:flutter/material.dart';
import 'package:gamatutor_kanban/model/user.dart';
import 'package:gamatutor_kanban/model/Rekomendasi.dart';
import 'package:gamatutor_kanban/pages/dashboard/wardrobescreen.dart';
import 'package:gamatutor_kanban/pages/dashboard/widgets/user_avatar_profile.dart';
import 'package:gamatutor_kanban/service/loginService.dart';
import 'package:gamatutor_kanban/service/secureTokenStorage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:gamatutor_kanban/utils/theme_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avatar_builder/avatar_builder.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_event.dart';

class AccountScreen extends StatelessWidget {
  final User? currentUser;
  final Rekomendasi? quizProfile;
  final int userXp;
  final Avataaar? currentAvatar;
  final Future<void> Function()? onAvatarUpdated;
  final Future<void> Function()? onProfileUpdated;

  const AccountScreen({
    Key? key,
    this.currentUser,
    this.quizProfile,
    this.userXp = 0,
    this.currentAvatar,
    this.onAvatarUpdated,
    this.onProfileUpdated,
  }) : super(key: key);

  // 🎨 PALETTE
  static const _primary = Color(0xFF6C5CE7);
  static const _primarySoft = Color(0xFFEDE9FE);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFEEF0F5);

  void _showEditProfileBottomSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController(text: currentUser?.username ?? '');
    final emailController = TextEditingController(text: currentUser?.email ?? '');
    final passwordController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Edit Profil ✨', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _ink)),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _border)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Username tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _border)),
                      ),
                      validator: (val) => val == null || !val.contains('@') ? 'Format email tidak valid' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password Baru (Opsional)',
                        hintText: 'Kosongkan jika tidak ingin mengubah',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _border)),
                      ),
                      validator: (val) {
                        if (val != null && val.isNotEmpty && val.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: isLoading ? null : () async {
                          if (!formKey.currentState!.validate()) return;
                          setStateModal(() => isLoading = true);
                          try {
                            final token = currentUser?.token ?? '';
                            final userId = currentUser?.userId ?? '';
                            final updatedUser = await LoginService().updateProfile(
                              token: token, userId: userId,
                              username: usernameController.text.trim(),
                              email: emailController.text.trim(),
                              password: passwordController.text.trim(),
                            );
                            if (!context.mounted) return;
                            if (updatedUser != null) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profil berhasil diperbarui! 🎉'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
                              );
                              if (onProfileUpdated != null) await onProfileUpdated!();
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                            );
                          } finally {
                            if (context.mounted) setStateModal(() => isLoading = false);
                          }
                        },
                        child: isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = "${currentUser?.firstName ?? 'Super'} ${currentUser?.lastName ?? 'Admin'}";
    final username = currentUser?.username ?? '@superadmin';
    final profileBadge = quizProfile?.userProfile ?? 'The Explorer';
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Warna dinamis berdasarkan mode
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F5FF);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : _ink;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : _border;
    final mutedColor = isDark ? Colors.grey.shade400 : _muted;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── HEADER ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Akun Saya',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kelola preferensi & profil belajarmu',
                        style: TextStyle(fontSize: 12, color: mutedColor),
                      ),
                    ],
                  ),
                  // XP Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFF97316)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$userXp XP',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ─── HERO PROFILE CARD ───
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.04), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: _primary.withOpacity(0.25), blurRadius: 16, spreadRadius: 2),
                            ],
                          ),
                          child: currentAvatar != null
                              ? UserAvatarProfile(avatar: currentAvatar!, size: 76, isCircle: true)
                              : Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : _primarySoft,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _primary, width: 2),
                                  ),
                                  child: const Icon(Icons.person_rounded, size: 38, color: _primary),
                                ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                username,
                                style: TextStyle(fontSize: 13, color: mutedColor),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : _primarySoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '✨ $profileBadge',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.purple.shade200 : const Color(0xFF9333EA),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Level Progress',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.7)),
                            ),
                            Text(
                              '$userXp / 1000 XP',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (userXp / 1000).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: isDark ? Colors.white.withOpacity(0.1) : _border,
                            valueColor: const AlwaysStoppedAnimation(_primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ─── KUSTOMISASI KARAKTER ───
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [const Color(0xFF4C1D95), const Color(0xFF3730A3)]
                      : [const Color(0xFF8B5CF6), const Color(0xFF6C5CE7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(color: _primary.withOpacity(isDark ? 0.15 : 0.35), blurRadius: 16, offset: const Offset(0, 8)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AvatarCustomizerScreen(userXp: userXp)),
                      );
                      if (onAvatarUpdated != null) await onAvatarUpdated!();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text('🎨', style: TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sesuaikan Karakter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                                SizedBox(height: 2),
                                Text('Personalisasi avatar & gaya belajarmu', style: TextStyle(fontSize: 11, color: Colors.white70)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── PENGATURAN APLIKASI ───
              _buildSectionTitle('PENGATURAN APLIKASI', textColor),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(isDark ? 0.15 : 0.03), blurRadius: 12, offset: const Offset(0, 3)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.dark_mode_rounded,
                      iconColor: Colors.purple,
                      title: 'Mode Gelap',
                      textColor: textColor,
                      trailing: Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return Switch.adaptive(
                            value: themeProvider.isDarkMode,
                            onChanged: (val) => themeProvider.toggleTheme(val),
                            activeColor: _primary,
                          );
                        },
                      ),
                    ),
                    Divider(height: 1, indent: 64, color: borderColor),
                    _buildMenuItem(
                      context,
                      icon: Icons.notifications_active_rounded,
                      iconColor: Colors.blue,
                      title: 'Notifikasi Belajar',
                      textColor: textColor,
                      trailing: Switch.adaptive(value: true, onChanged: (v) {}, activeColor: _primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── TENTANG AKU ───
              _buildSectionTitle('TENTANG AKU', textColor),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(isDark ? 0.15 : 0.03), blurRadius: 12, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.person_outline_rounded,
                      iconColor: Colors.indigo,
                      title: 'Edit Profil',
                      textColor: textColor,
                      onTap: () => _showEditProfileBottomSheet(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ─── LOGOUT BUTTON ───
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await SecureTokenStorage.clearSession();
                    if (context.mounted) {
                      context.read<AuthBloc>().add(AuthLogoutRequested());
                      context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                  label: const Text('Keluar Akun', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: const Color(0xFFEF4444).withOpacity(isDark ? 0.15 : 0.06),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.5), letterSpacing: 1.2),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color textColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
        ),
        trailing: trailing ?? Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Theme.of(context).dividerColor.withOpacity(0.05), shape: BoxShape.circle),
          child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: textColor.withOpacity(0.4)),
        ),
        onTap: onTap,
      ),
    );
  }
}