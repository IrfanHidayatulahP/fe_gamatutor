import 'package:flutter/foundation.dart';
import 'package:gamatutor_kanban/service/MdnsHelper.dart';

// class ApiConstants {
//   static String? _cachedBaseUrl;
//   static String getApiBaseUrl(String path) {
//     if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS) {
//       return 'http://localhost:3000/api$path';
//     }
//     return 'http://10.0.2.2:3000/api$path'; // device fisik
//   }

//   static Future<String> getBaseUrl(String path) async {
//     if (_cachedBaseUrl != null) {
//       return '$_cachedBaseUrl$path';
//     }

//     final discovered = await MdnsHelper.discoverService();

//     if (discovered != null) {
//       _cachedBaseUrl = "http://$discovered:3000/api";
//     } else {
//       _cachedBaseUrl = getApiBaseUrl('');
//     }

//     return '$_cachedBaseUrl$path';
//   }
// }

class ApiConstants {
  static const String _baseUrl = 'http://192.168.1.25:3000/api';

  static String getApiBaseUrl(String path) {
    if (kIsWeb) {
      return 'http://localhost:3000/api$path';
    }

    return '$_baseUrl$path';
  }

  static Future<String> getBaseUrl(String path) async {
    return getApiBaseUrl(path);
  }
}

// class ApiConstants {
//   // ============================================================
//   // KONFIGURASI IP
//   // ============================================================
//   // IP komputer Anda (server backend): 192.168.110.137
//   // IP device Anda (HP): 192.168.110.175
//   // Keduanya harus di WiFi yang sama.
//   //
//   // Jika IP komputer berubah, update _baseUrl di bawah.
//   // ============================================================

//   static const String _host = '192.168.110.137';
//   static const int _port = 3000;
//   static const String _baseUrl = 'http://$_host:$_port/api';

//   // ============================================================
//   // MENGEMBALIKAN BASE URL
//   // ============================================================
//   static String getApiBaseUrl(String path) {
//     String url;

//     if (kIsWeb) {
//       // Untuk Flutter Web (Chrome), gunakan localhost
//       url = 'http://localhost:$_port/api$path';
//     } else if (defaultTargetPlatform == TargetPlatform.android) {
//       // Untuk Android (emulator atau device fisik)
//       // Jika emulator: gunakan 10.0.2.2
//       // Jika device fisik: gunakan IP komputer (192.168.110.137)
//       //
//       // Kode ini menggunakan IP komputer karena Anda pakai device fisik.
//       // Jika pakai emulator, ganti _host ke '10.0.2.2'.
//       url = '$_baseUrl$path';
//     } else if (defaultTargetPlatform == TargetPlatform.iOS) {
//       // Untuk iOS simulator, gunakan localhost
//       // Untuk iOS device fisik, gunakan IP komputer
//       url = '$_baseUrl$path';
//     } else {
//       // Fallback (Windows, Linux, macOS desktop)
//       url = '$_baseUrl$path';
//     }

//     // Debug: Print URL yang digunakan (bisa dihapus nanti)
//     debugPrint('=== API URL: $url ===');
//     return url;
//   }

//   // ============================================================
//   // WRAPPER ASYNC (untuk kompatibilitas dengan kode lama)
//   // ============================================================
//   static Future<String> getBaseUrl(String path) async {
//     return getApiBaseUrl(path);
//   }
// }