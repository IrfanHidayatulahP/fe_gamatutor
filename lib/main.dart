// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
// import 'package:flutter_callkit_incoming/entities/entities.dart' as fci_entities;
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:go_router/go_router.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:provider/provider.dart';
// import 'package:timezone/data/latest.dart' as tz_data;
// import 'package:timezone/timezone.dart' as tz;
// import 'package:flutter_timezone/flutter_timezone.dart';

// // ─── Project imports (file 1) ───
// import 'core/di/injection_container.dart';
// import 'core/messaging/fcm_service.dart';
// import 'core/navigation/navigation_service.dart';
// import 'core/router/app_router.dart';
// import 'core/navigation/call_navigation_service.dart';
// import 'features/auth/bloc/auth_bloc.dart';
// import 'features/auth/bloc/auth_event.dart';
// import 'features/board/bloc/board_bloc.dart';
// import 'features/chat/bloc/chat/chat_bloc.dart';
// import 'features/calls/bloc/call/call_bloc.dart';
// import 'features/calls/bloc/group_call/group_call_bloc.dart';
// import 'features/friendship/bloc/friendship_bloc.dart';
// import 'features/card_collab/bloc/card_collab_bloc.dart';
// import 'features/chat/bloc/collab_chat/collab_chat_bloc.dart';
// import 'features/notification/bloc/notification_bloc.dart';
// import 'features/notification/ui/notification_toast.dart';
// import 'features/calls/bloc/livekit/call_bloc.dart' as livekit_bloc;
// import 'features/calls/ui/livekit/incoming_call_handler.dart';

// // ─── Project imports (file 2) ───
// import 'package:gamatutor_kanban/service/notifService.dart';
// import 'package:gamatutor_kanban/utils/theme_provider.dart';

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// // ═══════════════════════════════════════════════════════════════
// // CALLKIT GLOBAL HANDLERS (dari file 1)
// // ═══════════════════════════════════════════════════════════════

// @pragma('vm:entry-point')
// void _setupCallKitListenerEarly() {
//   FlutterCallkitIncoming.onEvent.listen((event) {
//     if (event != null) {
//       _handleGlobalCallKitEvent(event);
//     }
//   });
// }

// @pragma('vm:entry-point')
// void _handleGlobalCallKitEvent(fci_entities.CallEvent event) {
//   if (event is fci_entities.CallEventActionCallAccept) {
//     final extra = event.callKitParams.extra as Map<String, dynamic>?;
//     if (extra != null) {
//       CallNavigationService.setPendingIncomingCall(extra);
//     }
//   } else if (event is fci_entities.CallEventActionCallDecline) {
//     final callId = event.callKitParams.id;
//     CallNavigationService.clearPendingCall();
//     debugPrint('📞 CallKit Decline for callId: $callId - backend notification needed');
//     FlutterCallkitIncoming.endCall(callId);
//   } else if (event is fci_entities.CallEventActionCallEnded) {
//     final callId = event.callKitParams.id;
//     CallNavigationService.clearPendingCall();
//     FlutterCallkitIncoming.endCall(callId);
//   } else if (event is fci_entities.CallEventActionCallTimeout) {
//     final callId = event.id;
//     CallNavigationService.clearPendingCall();
//     debugPrint('📞 CallKit Timeout for callId: $callId');
//     FlutterCallkitIncoming.endCall(callId);
//   }
// }

// // ═══════════════════════════════════════════════════════════════
// // LOCAL NOTIFICATIONS + TIMEZONE + PERMISSIONS (dari file 2)
// // ═══════════════════════════════════════════════════════════════

// Future<void> _initLocalNotifications() async {
//   tz_data.initializeTimeZones();
//   String timeZoneName = 'Asia/Jakarta';
//   try {
//     final TimezoneInfo currentTimeZone =
//         await FlutterTimezone.getLocalTimezone();
//     timeZoneName = currentTimeZone.identifier;
//   } catch (e) {
//     debugPrint('⚠️ Gagal mendapatkan timezone, menggunakan default: $e');
//   }
//   tz.setLocalLocation(tz.getLocation(timeZoneName));
//   debugPrint('🌍 TIMEZONE SEKARANG: ${tz.local.name}');

//   await NotificationService.init();

//   final notifStatus = await Permission.notification.request();
//   debugPrint('📱 POST_NOTIFICATIONS granted: ${notifStatus.isGranted}');
//   if (!notifStatus.isGranted) {
//     debugPrint('❌ Notifikasi DIBLOKIR user — scheduled tidak akan terlihat');
//     if (notifStatus.isPermanentlyDenied) {
//       await openAppSettings();
//     }
//   }

//   final exactStatus = await Permission.scheduleExactAlarm.request();
//   debugPrint('📱 SCHEDULE_EXACT_ALARM granted: ${exactStatus.isGranted}');
//   if (!exactStatus.isGranted) {
//     debugPrint('⚠️ Exact alarm DENIED — fallback ke inexact akan dipakai');
//   }

//   final batteryStatus = await Permission.ignoreBatteryOptimizations.request();
//   debugPrint('📱 Battery optimization exempt: ${batteryStatus.isGranted}');
//   if (!batteryStatus.isGranted) {
//     debugPrint('⚠️ Battery optimization aktif — beberapa HP bisa membunuh alarm');
//   }

//   await NotificationService.scheduleDailyReminder(
//     id: 1,
//     title: 'Waktunya Belajar! 📚',
//     body: 'Avatarmu sudah siap menemanimu. Yuk selesaikan 1 misi hari ini!',
//     hour: 19,
//     minute: 00,
//   );

//   await NotificationService.scheduleGhostingReminder();

//   await Future.delayed(const Duration(milliseconds: 500));
//   final pending = await NotificationService.getPendingNotifications();
//   debugPrint('⏰ PENDING NOTIFS: ${pending.length}');
//   for (final p in pending) {
//     debugPrint('   → id=${p.id} "${p.title}"');
//   }
// }

// // ═══════════════════════════════════════════════════════════════
// // MAIN
// // ═══════════════════════════════════════════════════════════════

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // 1) Firebase dulu (wajib sebelum service yang depends on Firebase)
//   await Firebase.initializeApp();

//   // 2) Local notifications + timezone + permission (dari file 2)
//   await _initLocalNotifications();

//   // 3) Dependency injection (BLoC, service, dll)
//   await initDependencies();

//   // 4) Setup CallKit listener SEBELUM runApp (dari file 1)
//   _setupCallKitListenerEarly();

//   // 5) Init IncomingCallHandler secara sinkron (dari file 1)
//   IncomingCallHandler.instance.initializeEarly();

//   // 6) Trigger cek auth
//   sl<AuthBloc>().add(AuthCheckStatusRequested());

//   runApp(
//     ChangeNotifierProvider(
//       create: (_) => ThemeProvider(),
//       child: const MyApp(),
//     ),
//   );

//   // 7) FCM setelah first frame (non-blocking, dari file 1)
//   WidgetsBinding.instance.addPostFrameCallback((_) {
//     final fcmService = sl<FCMService>();
//     fcmService.initialize().catchError((e) {
//       debugPrint('❌ FCM init failed (non-fatal): $e');
//     });
//     final navigatorKey = router.routerDelegate.navigatorKey;
//     FCMNavigationHandler.setNavigatorKey(navigatorKey);
//     NavigationService().setNavigatorKey(navigatorKey);
//     FCMNavigationHandler.executePendingNavigation(navigatorKey);
//   });
// }

// // ═══════════════════════════════════════════════════════════════
// // APP
// // ═══════════════════════════════════════════════════════════════

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final themeProvider = Provider.of<ThemeProvider>(context);

//     return MultiBlocProvider(
//       providers: [
//         BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()),
//         BlocProvider<BoardBloc>.value(value: sl<BoardBloc>()),
//         BlocProvider<FriendshipBloc>.value(value: sl<FriendshipBloc>()),
//         BlocProvider<ChatBloc>.value(value: sl<ChatBloc>()),
//         BlocProvider<CallBloc>.value(value: sl<CallBloc>()),
//         BlocProvider<GroupCallBloc>.value(value: sl<GroupCallBloc>()),
//         BlocProvider<CardCollabBloc>.value(value: sl<CardCollabBloc>()),
//         BlocProvider<CollabChatBloc>.value(value: sl<CollabChatBloc>()),
//         BlocProvider<NotificationBloc>.value(value: sl<NotificationBloc>()),
//         BlocProvider<livekit_bloc.CallBloc>.value(value: sl<livekit_bloc.CallBloc>()),
//       ],
//       child: MaterialApp.router(
//         routerConfig: router,
//         title: 'Gamatutor',
//         debugShowCheckedModeBanner: false,

//         // ─── TEMA TERANG (dari file 2) ───
//         theme: ThemeData(
//           scaffoldBackgroundColor: const Color(0xFFF8FAFC),
//           fontFamily: 'Roboto',
//           colorScheme: ColorScheme.fromSeed(
//             seedColor: const Color(0xFF2563EB),
//             primary: const Color(0xFF2563EB),
//           ),
//           useMaterial3: true,
//         ),

//         // ─── TEMA GELAP (dari file 2) ───
//         darkTheme: ThemeData(
//           scaffoldBackgroundColor: const Color(0xFF0F172A),
//           fontFamily: 'Roboto',
//           colorScheme: ColorScheme.fromSeed(
//             seedColor: const Color(0xFF2563EB),
//             primary: const Color(0xFF2563EB),
//             brightness: Brightness.dark,
//           ),
//           useMaterial3: true,
//         ),

//         themeMode: themeProvider.themeMode,

//         builder: (context, child) {
//           return IncomingCallProvider(
//             child: NotificationToastWrapper(
//               child: child ?? const SizedBox.shrink(),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart' as fci_entities;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

// ─── Project imports ───
import 'core/di/injection_container.dart';
import 'core/messaging/fcm_service.dart';
import 'core/navigation/navigation_service.dart';
import 'core/router/app_router.dart';
import 'core/navigation/call_navigation_service.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/board/bloc/board_bloc.dart';
import 'features/chat/bloc/chat/chat_bloc.dart';
import 'features/calls/bloc/call/call_bloc.dart';
import 'features/calls/bloc/group_call/group_call_bloc.dart';
import 'features/friendship/bloc/friendship_bloc.dart';
import 'features/card_collab/bloc/card_collab_bloc.dart';
import 'features/chat/bloc/collab_chat/collab_chat_bloc.dart';
import 'features/notification/bloc/notification_bloc.dart';
import 'features/notification/ui/notification_toast.dart';
import 'features/calls/bloc/livekit/call_bloc.dart' as livekit_bloc;
import 'features/calls/ui/livekit/incoming_call_handler.dart';

import 'package:gamatutor_kanban/service/notifService.dart';
import 'package:gamatutor_kanban/utils/theme_provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void _setupCallKitListenerEarly() {
  FlutterCallkitIncoming.onEvent.listen((event) {
    if (event != null) {
      _handleGlobalCallKitEvent(event);
    }
  });
}

@pragma('vm:entry-point')
void _handleGlobalCallKitEvent(fci_entities.CallEvent event) {
  if (event is fci_entities.CallEventActionCallAccept) {
    final extra = event.callKitParams.extra as Map<String, dynamic>?;
    if (extra != null) {
      CallNavigationService.setPendingIncomingCall(extra);
    }
  } else if (event is fci_entities.CallEventActionCallDecline) {
    final callId = event.callKitParams.id;
    CallNavigationService.clearPendingCall();
    debugPrint('📞 CallKit Decline for callId: $callId - backend notification needed');
    FlutterCallkitIncoming.endCall(callId);
  } else if (event is fci_entities.CallEventActionCallEnded) {
    final callId = event.callKitParams.id;
    CallNavigationService.clearPendingCall();
    FlutterCallkitIncoming.endCall(callId);
  } else if (event is fci_entities.CallEventActionCallTimeout) {
    final callId = event.id;
    CallNavigationService.clearPendingCall();
    debugPrint('📞 CallKit Timeout for callId: $callId');
    FlutterCallkitIncoming.endCall(callId);
  }
}

Future<void> _initLocalNotifications() async {
  tz_data.initializeTimeZones();
  String timeZoneName = 'Asia/Jakarta';
  try {
    final TimezoneInfo currentTimeZone = await FlutterTimezone.getLocalTimezone();
    timeZoneName = currentTimeZone.identifier;
  } catch (e) {
    debugPrint('⚠️ Gagal mendapatkan timezone, menggunakan default: $e');
  }
  tz.setLocalLocation(tz.getLocation(timeZoneName));
  debugPrint('🌍 TIMEZONE SEKARANG: ${tz.local.name}');

  await NotificationService.init();

  final notifStatus = await Permission.notification.request();
  debugPrint('📱 POST_NOTIFICATIONS granted: ${notifStatus.isGranted}');

  final exactStatus = await Permission.scheduleExactAlarm.request();
  debugPrint('📱 SCHEDULE_EXACT_ALARM granted: ${exactStatus.isGranted}');

  final batteryStatus = await Permission.ignoreBatteryOptimizations.request();
  debugPrint('📱 Battery optimization exempt: ${batteryStatus.isGranted}');

  await NotificationService.scheduleDailyReminder(
    id: 1,
    title: 'Waktunya Belajar! 📚',
    body: 'Avatarmu sudah siap menemanimu. Yuk selesaikan 1 misi hari ini!',
    hour: 19,
    minute: 00,
  );

  await NotificationService.scheduleGhostingReminder();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await _initLocalNotifications();
  await initDependencies();

  _setupCallKitListenerEarly();
  IncomingCallHandler.instance.initializeEarly();
  sl<AuthBloc>().add(AuthCheckStatusRequested());

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final fcmService = sl<FCMService>();
    fcmService.initialize().catchError((e) {
      debugPrint('❌ FCM init failed (non-fatal): $e');
    });
    final navigatorKey = router.routerDelegate.navigatorKey;
    FCMNavigationHandler.setNavigatorKey(navigatorKey);
    NavigationService().setNavigatorKey(navigatorKey);
    FCMNavigationHandler.executePendingNavigation(navigatorKey);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()),
        BlocProvider<BoardBloc>.value(value: sl<BoardBloc>()),
        BlocProvider<FriendshipBloc>.value(value: sl<FriendshipBloc>()),
        BlocProvider<ChatBloc>.value(value: sl<ChatBloc>()),
        BlocProvider<CallBloc>.value(value: sl<CallBloc>()),
        BlocProvider<GroupCallBloc>.value(value: sl<GroupCallBloc>()),
        BlocProvider<CardCollabBloc>.value(value: sl<CardCollabBloc>()),
        BlocProvider<CollabChatBloc>.value(value: sl<CollabChatBloc>()),
        BlocProvider<NotificationBloc>.value(value: sl<NotificationBloc>()),
        BlocProvider<livekit_bloc.CallBloc>.value(value: sl<livekit_bloc.CallBloc>()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        title: 'Gamatutor',
        debugShowCheckedModeBanner: false,

        // ═══════════════════════════════════════════════════════════════
        // TEMA TERANG
        // ═══════════════════════════════════════════════════════════════
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Warna background utama
          fontFamily: 'Roboto',
          primaryColor: const Color(0xFF2563EB),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            primary: const Color(0xFF2563EB),
            brightness: Brightness.light,
            surface: Colors.white,
            background: const Color(0xFFF8FAFC),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFF2563EB),
            unselectedItemColor: Colors.grey,
          ),
          // Menggunakan CardThemeData untuk Flutter versi baru
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Colors.white,
            modalBackgroundColor: Colors.white,
          ),
          useMaterial3: true,
        ),

        // ═══════════════════════════════════════════════════════════════
        // TEMA GELAP (DARK MODE)
        // ═══════════════════════════════════════════════════════════════
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F172A), // Latar belakang utama gelap
          fontFamily: 'Roboto',
          primaryColor: const Color(0xFF6C5CE7),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C5CE7),
            primary: const Color(0xFF6C5CE7),
            brightness: Brightness.dark,
            surface: const Color(0xFF1E293B), // Warna untuk Card / Dialog / BottomSheet
            background: const Color(0xFF0F172A),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0F172A),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF1E293B),
            selectedItemColor: Color(0xFF6C5CE7),
            unselectedItemColor: Colors.grey,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF1E293B),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: const Color(0xFF1E293B),
            titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            contentTextStyle: const TextStyle(color: Colors.white70, fontSize: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Color(0xFF1E293B),
            modalBackgroundColor: Color(0xFF1E293B),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white70),
            titleMedium: TextStyle(color: Colors.white),
          ),
          useMaterial3: true,
        ),

        themeMode: themeProvider.themeMode,

        builder: (context, child) {
          return IncomingCallProvider(
            child: NotificationToastWrapper(
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}