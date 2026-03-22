import 'dart:convert';
import 'package:ekdant/models/win_model.dart';
import 'package:ekdant/services/token_helper.dart';
import 'package:http/http.dart' as http;

class WinService {
  static const String _baseUrl = 'https://api.ekadantaa.in/api/wins';
  final http.Client _client;

  WinService({http.Client? client}) : _client = client ?? http.Client();

  Future<WinListResponse> getAllWins() async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await _client.get(Uri.parse(_baseUrl), headers: headers);

      if (response.statusCode == 200) {
        return WinListResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to load wins. Status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch wins: $e');
    }
  }

  Future<UserWinListResponse> getWinsByUser(String userId) async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await _client.get(
        Uri.parse('$_baseUrl/user/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return UserWinListResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception(
        'Failed to load user wins. Status: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Failed to fetch user wins: $e');
    }
  }

  Future<Win> getWinById(String id) async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await _client.get(
        Uri.parse('$_baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Win.fromJson(jsonDecode(response.body));
      }
      if (response.statusCode == 404) throw Exception('Win record not found');
      throw Exception('Failed to load win. Status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch win: $e');
    }
  }

  Future<bool> deleteWin(String id) async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await _client.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) return true;
      if (response.statusCode == 404) return false;
      throw Exception('Failed to delete win. Status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to delete win: $e');
    }
  }

  void dispose() => _client.close();
}
