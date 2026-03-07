import 'dart:convert';
import 'package:ekdant/models/transaction_model.dart';
import 'package:ekdant/services/token_helper.dart';
import 'package:http/http.dart' as http;

class TransactionService {
  static const String baseUrl = 'https://api.ekadantaa.in/api/transactions';

  Future<List<TransactionModel>> getTransactionsByUser(String userId) async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/$userId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      if (jsonBody['transactions'] is List) {
        return (jsonBody['transactions'] as List)
            .map((e) => TransactionModel.fromJson(e))
            .toList();
      }
      throw FormatException('Invalid transactions data format');
    } else {
      throw Exception('Failed to load transactions: ${response.statusCode}');
    }
  }

  Future<TransactionModel> createTransaction(
    TransactionModel transaction,
  ) async {
    final headers = await TokenHelper.getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/create'),
      headers: headers,
      body: jsonEncode(transaction.toJson()),
    );

    if (response.statusCode == 200) {
      return TransactionModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create transaction: ${response.statusCode}');
    }
  }
}
