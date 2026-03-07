import 'dart:convert';
import 'package:ekdant/models/result_model.dart';
import 'package:ekdant/services/token_helper.dart';
import 'package:http/http.dart' as http;

class ResultService {
  static const String _baseUrl = 'https://api.ekadantaa.in/api/results';
  final http.Client _client;

  ResultService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Result>> getAllResults() async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await _client.get(Uri.parse(_baseUrl), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'] is List) {
          return (data['results'] as List)
              .map((json) => Result.fromJson(json))
              .toList();
        } else {
          throw Exception('Invalid response format - missing results array');
        }
      } else {
        throw Exception(
          'Failed to load results. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch results: ${e.toString()}');
    }
  }

  Future<String> createResult(ResultRequest request) async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await _client.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201)
        return response.body;
      throw Exception(
        'Failed to create result. Status code: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Failed to create result: ${e.toString()}');
    }
  }

  Future<String> updateResult(String id, ResultRequest request) async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await _client.put(
        Uri.parse('$_baseUrl/$id'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 204)
        return response.body;
      throw Exception(
        'Failed to update result. Status code: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Failed to update result: ${e.toString()}');
    }
  }

  Future<String> deleteResult(String id) async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await _client.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) return response.body;
      throw Exception(
        'Failed to delete result. Status code: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Failed to delete result: ${e.toString()}');
    }
  }

  void dispose() => _client.close();
}
