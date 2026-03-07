import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Shared helper used by ALL services to inject the JWT auth header.
/// Make sure the user is logged in before calling any protected API.
class TokenHelper {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Returns headers with Bearer token. Throws if not logged in.
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await _storage.read(key: 'auth_token');

    if (token == null || token.isEmpty) {
      print(
        "❌ TokenHelper → No token in secure storage! User is not logged in.",
      );
      throw Exception('Not authenticated. Please log in first.');
    }

    print("✅ TokenHelper → Token found: ${token.substring(0, 20)}...");
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Returns just the raw token string, or null if not logged in.
  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  /// Returns true if a token exists in storage.
  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }
}
