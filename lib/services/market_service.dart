import 'dart:convert';
import 'package:ekdant/models/market_model.dart';
import 'package:ekdant/services/token_helper.dart';
import 'package:http/http.dart' as http;

class MarketService {
  static const String _baseUrl = 'https://api.ekadantaa.in/api/market';
  final http.Client _client;

  MarketService({http.Client? client}) : _client = client ?? http.Client();

  Future<String> createMarket(MarketRequest request) async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await _client.post(
      Uri.parse('$_baseUrl/createmarket'),
      headers: headers,
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) return response.body;
    throw Exception(
      'Failed to create market: ${response.statusCode} - ${response.body}',
    );
  }

  Future<MarketListResponse> getAllMarkets() async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await _client.get(
      Uri.parse('$_baseUrl/allmarket'),
      headers: headers,
    );

    if (response.statusCode == 200)
      return MarketListResponse.fromJson(json.decode(response.body));
    throw Exception('Failed to load markets: ${response.statusCode}');
  }

  Future<MarketResponse> getMarketById(String id) async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await _client.get(
      Uri.parse('$_baseUrl/marketid/$id'),
      headers: headers,
    );

    if (response.statusCode == 200)
      return MarketResponse.fromJson(json.decode(response.body));
    if (response.statusCode == 404) throw Exception('Market not found');
    throw Exception('Failed to load market: ${response.statusCode}');
  }

  Future<MarketResponse> updateMarket(String id, MarketRequest request) async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await _client.put(
      Uri.parse('$_baseUrl/update/$id'),
      headers: headers,
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200)
      return MarketResponse.fromJson(json.decode(response.body));
    if (response.statusCode == 404) throw Exception('Market not found');
    throw Exception('Failed to update market: ${response.statusCode}');
  }

  void dispose() => _client.close();
}
