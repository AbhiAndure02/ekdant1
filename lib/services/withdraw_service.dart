import 'dart:convert';
import 'dart:io';
import 'package:ekdant/models/withdraw.dart';
import 'package:ekdant/services/token_helper.dart';
import 'package:http/http.dart' as http;

class WithdrawService {
  static const String _baseUrl = 'https://api.ekadantaa.in/api/withdraws';
  static const bool _debugMode = true;

  void _logDebug(String message) {
    if (_debugMode) print('[WithdrawService DEBUG] $message');
  }

  Future<WithdrawResponse> createWithdraw(WithdrawRequest request) async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      _logDebug('Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return WithdrawResponse(
          id: responseData['id']?.toString() ?? '',
          userId: responseData['userId']?.toString() ?? request.userId,
          name: responseData['name']?.toString() ?? request.name,
          balance: responseData['balance']?.toDouble() ?? 0.0,
          amount: responseData['amount']?.toDouble() ?? request.amount,
          toAccount: responseData['toAccount']?.toString() ?? request.toAccount,
          reason: responseData['reason']?.toString() ?? 'Withdrawal request',
          status: responseData['status']?.toString() ?? 'PENDING',
          reqDateTime: responseData['reqDateTime'] != null
              ? DateTime.parse(responseData['reqDateTime'])
              : DateTime.now(),
          approvalDateTime: responseData['approvalDateTime'] != null
              ? DateTime.parse(responseData['approvalDateTime'])
              : null,
        );
      } else {
        throw HttpException(
          'Failed to create withdraw (${response.statusCode})',
        );
      }
    } catch (e) {
      _logDebug('Unexpected error: $e');
      rethrow;
    }
  }

  Future<List<WithdrawResponse>> getAllWithdraws() async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await http.get(Uri.parse(_baseUrl), headers: headers);

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((item) => WithdrawResponse.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load withdraws: ${response.statusCode}');
      }
    } catch (e) {
      _logDebug('Exception in getAllWithdraws: $e');
      rethrow;
    }
  }

  Future<WithdrawResponse?> getWithdrawById(String id) async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200)
        return WithdrawResponse.fromJson(json.decode(response.body));
      if (response.statusCode == 404) return null;
      throw Exception('Failed to load withdraw: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  Future<WithdrawResponse?> updateWithdraw(
    String id,
    WithdrawRequest request,
  ) async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/$id'),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200)
        return WithdrawResponse.fromJson(json.decode(response.body));
      if (response.statusCode == 404) return null;
      throw Exception('Failed to update withdraw: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteWithdraw(String id) async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete withdraw: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
