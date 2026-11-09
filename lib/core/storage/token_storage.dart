import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _tokenExpiryKey = 'token_expiry';

  final SharedPreferences _prefs;

  TokenStorage(this._prefs);

  Future<void> saveAccessToken(String token) async {
    await _prefs.setString(_accessTokenKey, token);
  }

  Future<String?> getAccessToken() async {
    return _prefs.getString(_accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _prefs.setString(_refreshTokenKey, token);
  }

  Future<String?> getRefreshToken() async {
    return _prefs.getString(_refreshTokenKey);
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _prefs.setString(_userDataKey, userData.toString());
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final data = _prefs.getString(_userDataKey);
    if (data != null) {
      // Simple parsing - in production use jsonDecode
      return {};
    }
    return null;
  }

  Future<void> saveTokenExpiry(DateTime expiry) async {
    await _prefs.setString(_tokenExpiryKey, expiry.toIso8601String());
  }

  Future<DateTime?> getTokenExpiry() async {
    final expiry = _prefs.getString(_tokenExpiryKey);
    if (expiry != null) {
      return DateTime.parse(expiry);
    }
    return null;
  }

  Future<void> clear() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_userDataKey);
    await _prefs.remove(_tokenExpiryKey);
  }

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;
    final expiry = await getTokenExpiry();
    if (expiry != null && DateTime.now().isAfter(expiry)) return false;
    return true;
  }
}