import 'dart:convert';
import 'package:ekdant/models/game_model..dart';
import 'package:ekdant/services/token_helper.dart';
import 'package:http/http.dart' as http;

class GameRateService {
  final String baseUrl = "https://api.ekadantaa.in";

  Future<GameRate> createGameRate(GameRate gameRate) async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/game-rate'),
            headers: headers,
            body: jsonEncode(gameRate.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty)
          throw Exception('Empty response from server');
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == false) {
          throw Exception(responseData['message'] ?? 'Request failed');
        }
        return GameRate.fromJson(responseData);
      } else {
        throw Exception('Failed to create game rate: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create game rate: $e');
    }
  }

  Future<List<GameRate>> getAllGameRates() async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/game-rate'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => GameRate.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load game rates: ${response.statusCode}');
    }
  }
}
