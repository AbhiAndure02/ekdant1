import 'dart:convert';
import 'package:ekdant/models/game_model.dart';
import 'package:ekdant/services/token_helper.dart';
import 'package:http/http.dart' as http;

class GameService {
  static const String _baseUrl = 'https://api.ekadantaa.in/api/games';
  final http.Client _client;

  GameService({http.Client? client}) : _client = client ?? http.Client();

  Future<String> createGame(GameRequest request) async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await _client.post(
      Uri.parse('$_baseUrl/addgames'),
      headers: headers,
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) return response.body;
    throw Exception(
      'Failed to create game: ${response.statusCode} - ${response.body}',
    );
  }

  Future<GameResponse> updateGame(String id, GameRequest request) async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await _client.put(
      Uri.parse('$_baseUrl/$id'),
      headers: headers,
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200)
      return GameResponse.fromJson(json.decode(response.body));
    if (response.statusCode == 404) throw Exception('Game not found');
    throw Exception('Failed to update game: ${response.statusCode}');
  }

  Future<GameListResponse> getDetailedGameList() async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await _client.get(
      Uri.parse('$_baseUrl/allgame'),
      headers: headers,
    );

    if (response.statusCode == 200)
      return GameListResponse.fromJson(json.decode(response.body));
    throw Exception('Failed to load games: ${response.statusCode}');
  }

  Future<String> deleteGame(String id) async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await _client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) return 'Game deleted successfully';
    if (response.statusCode == 404) throw Exception('Game not found');
    throw Exception('Failed to delete game: ${response.statusCode}');
  }

  Future<GameResponse> getGameById(String id) async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await _client.get(
      Uri.parse('$_baseUrl/getGameById/$id'),
      headers: headers,
    );

    if (response.statusCode == 200)
      return GameResponse.fromJson(json.decode(response.body));
    if (response.statusCode == 404) throw Exception('Game not found');
    throw Exception('Failed to load game: ${response.statusCode}');
  }

  void dispose() => _client.close();
}
