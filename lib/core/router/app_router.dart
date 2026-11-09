import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/board/ui/board_screen.dart';
import '../../features/card_collab/ui/collaboration_invite_screen.dart';
import '../../features/chat/ui/chat_list_screen.dart';
import '../../features/chat/ui/chat_screen.dart';
import '../../features/chat/ui/new_chat_screen.dart';
import '../../features/card_collab/ui/collaboration_screen.dart';
import '../../features/friendship/ui/add_friend_screen.dart';
import '../../features/friendship/ui/friend_list_screen.dart';
import '../../features/friendship/ui/invite_friend_screen.dart';
import '../../features/friendship/ui/pending_requests_screen.dart';
import '../../features/notification/ui/notification_center_screen.dart';
import '../../core/models/user_model.dart';

// ─── Import halaman dari versi lama (legacy) ───
import '../../pages/login/login.dart';
import '../../pages/dashboard/dashboard.dart';
import '../../pages/rekomendasi/quiz_intro_screen.dart';
import '../../pages/rekomendasi/quiz_questions_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  initialLocation: '/login',
  navigatorKey: navigatorKey,

  // ═══════════════════════════════════════════════════════════════
  // REDIRECT: hanya blokir user yang belum login
  // Navigasi setelah login (ke /quiz atau /dashboard) diurus oleh
  // BlocListener di dalam LoginPage.
  // ═══════════════════════════════════════════════════════════════
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final isLoggedIn = authState is AuthAuthenticated;
    final isLoading = authState is AuthLoading;
    final isInitial = authState is AuthInitial;
    final isLoggingIn = state.matchedLocation == '/login';

    // Belum login (atau masih loading/initial) & bukan di /login
    //   → paksa ke /login
    if ((isLoading || isInitial || !isLoggedIn) && !isLoggingIn) {
      return '/login';
    }

    // Sudah login & sedang di /login → BIARKAN LoginPage yang mengurus
    // (listener akan cek quiz & navigasi). Redirect = null (tidak redirect).
    return null;
  },

  routes: [
    // ─── AUTH ───
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),

    // ─── DASHBOARD (legacy, dengan bottom nav) ───
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const Dashboard(),
    ),

    // ─── QUIZ (legacy) ───
    GoRoute(
      path: '/quiz',
      builder: (context, state) {
        final authState = context.read<AuthBloc>().state;
        final userId =
            authState is AuthAuthenticated ? authState.user.userId : '';
        return QuizIntroScreen(userId: userId);
      },
    ),
    GoRoute(
      path: '/quiz-questions',
      builder: (context, state) => const QuizQuestionsScreen(),
    ),

    // ─── BOARD (BLoC) ───
    GoRoute(
      path: '/board',
      builder: (context, state) => const BoardScreen(),
    ),

    // ─── COLLABORATION ───
    GoRoute(
      path: '/collaboration',
      builder: (context, state) => const CollaborationScreen(),
    ),

    // ─── FRIENDSHIP ───
    GoRoute(
      path: '/friends',
      builder: (context, state) => const FriendListScreen(),
    ),
    GoRoute(
      path: '/friend-list',
      builder: (context, state) => const FriendListScreen(),
    ),
    GoRoute(
      path: '/pending-requests',
      builder: (context, state) => const PendingRequestsScreen(),
    ),
    GoRoute(
      path: '/add-friend',
      builder: (context, state) => const AddFriendScreen(),
    ),
    GoRoute(
      path: '/invite-friend',
      builder: (context, state) {
        final cardId = state.uri.queryParameters['cardId'];
        return InviteFriendScreen(cardId: cardId);
      },
    ),

    // ─── CHAT ───
    GoRoute(
      path: '/chat',
      builder: (context, state) => const ChatListScreen(),
    ),
    GoRoute(
      path: '/chat/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return ChatScreen(
          friend: UserModel(
            userId: userId,
            email: '',
            firstName: 'User',
            lastName: '',
            username: 'user',
            role: 'user',
            status: 'offline',
            createdAt: DateTime.now(),
          ),
        );
      },
    ),
    GoRoute(
      path: '/new-chat',
      builder: (context, state) => const NewChatScreen(),
    ),

    // ─── CARD COLLAB ───
    GoRoute(
      path: '/collaboration-invites',
      builder: (context, state) => const CollaborationInviteScreen(),
    ),

    // ─── NOTIFICATION ───
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationCenterScreen(),
    ),
  ],
);