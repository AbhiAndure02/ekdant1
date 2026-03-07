import 'dart:convert';
import 'package:ekdant/services/token_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/deposit.dart';

class DepositService {
  final String baseUrl = "https://api.ekadantaa.in/api/deposits";

  Future<List<Deposit>> getAllDeposits() async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await http.get(Uri.parse(baseUrl), headers: headers);
    debugPrint("📡 Get All Deposits: ${response.statusCode}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Deposit.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load deposits");
    }
  }

  Future<Deposit> getDepositById(String id) async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await http.get(
      Uri.parse("$baseUrl/$id"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Deposit.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Deposit not found");
    }
  }

  Future<Deposit> createDeposit(Deposit deposit) async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode(deposit.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Deposit.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to create deposit: ${response.body}");
    }
  }

  Future<Deposit> updateDeposit(String id, Deposit deposit) async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: headers,
      body: jsonEncode(deposit.toJson()),
    );

    if (response.statusCode == 200) {
      return Deposit.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to update deposit");
    }
  }

  Future<void> deleteDeposit(String id) async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await http.delete(
      Uri.parse("$baseUrl/$id"),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete deposit");
    }
  }
}
