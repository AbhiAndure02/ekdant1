import 'dart:convert';
import 'package:ekdant/services/token_helper.dart'; // ✅ Use shared helper
import 'package:http/http.dart' as http;

class WalletService {
  static const String _baseUrl = 'https://api.ekadantaa.in/api/auth/wallet';

  // ✅ Get wallet balance for a specific user
  Future<WalletResponse> getWallet(String userId) async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return WalletResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('User not found with ID: $userId');
      } else {
        throw Exception('Failed to get wallet: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Wallet service error: $e');
    }
  }

  // ✅ Update wallet amount for a specific user
  Future<String> updateWallet(String userId, double newAmount) async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/$userId'),
        headers: headers,
        body: jsonEncode({'walletAmount': newAmount.toString()}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Wallet updated successfully';
      } else if (response.statusCode == 404) {
        throw Exception('User not found with ID: $userId');
      } else {
        throw Exception('Failed to update wallet: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Wallet update error: $e');
    }
  }
}

// ✅ WalletResponse Model
class WalletResponse {
  final String userId;
  final double walletAmount;

  WalletResponse({required this.userId, required this.walletAmount});

  factory WalletResponse.fromJson(Map<String, dynamic> json) {
    return WalletResponse(
      userId: json['userId'] ?? '',
      walletAmount:
          double.tryParse(json['walletAmount']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'walletAmount': walletAmount};
  }
}
