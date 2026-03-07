import 'dart:convert';
import 'package:ekdant/models/bid_model.dart';
import 'package:ekdant/services/token_helper.dart';
import 'package:http/http.dart' as http;

class BidService {
  final String _baseUrl = "https://api.ekadantaa.in";
  final String apiPath = '/api/bids';

  Future<Bid> createBid(BidRequest request) async {
    final url = '$_baseUrl$apiPath';
    final headers = await TokenHelper.getAuthHeaders();
    final body = json.encode(request.toJson());

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Bid.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create bid: ${response.body}');
    }
  }

  Future<List<Bid>> getAllBids() async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl$apiPath'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> bidsJson = json.decode(response.body);
      return bidsJson.map((json) => Bid.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load bids');
    }
  }

  Future<Bid?> getBidById(String id) async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl$apiPath/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Bid.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load bid');
    }
  }

  Future<Bid?> updateBid(String id, BidRequest request) async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await http.put(
      Uri.parse('$_baseUrl$apiPath/$id'),
      headers: headers,
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return Bid.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to update bid');
    }
  }

  Future<bool> deleteBid(String id) async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$_baseUrl$apiPath/$id'),
      headers: headers,
    );

    if (response.statusCode == 204) return true;
    if (response.statusCode == 404) return false;
    throw Exception('Failed to delete bid');
  }

  Future<Bid?> markBidAsWinner(String bidId) async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await http.patch(
      Uri.parse('$_baseUrl$apiPath/$bidId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Bid.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to mark bid as winner: ${response.body}');
    }
  }

  void dispose() {}
}
