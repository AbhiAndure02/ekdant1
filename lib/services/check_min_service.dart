import 'dart:async';
import 'dart:convert';
import 'package:ekdant/models/check_min_amount.dart';
import 'package:ekdant/services/token_helper.dart';
import 'package:http/http.dart' as http;

class CheckMinService {
  static const String baseUrl = 'https://api.ekadantaa.in/api/check-min';
  static const Duration timeoutDuration = Duration(seconds: 30);

  Future<CheckMinAmount?> getCheckMin() async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await http
          .get(Uri.parse(baseUrl), headers: headers)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return null;
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded.isEmpty
              ? null
              : CheckMinAmount.fromJson(decoded.first);
        } else if (decoded is Map<String, dynamic>) {
          return CheckMinAmount.fromJson(decoded);
        } else {
          throw const FormatException('Unexpected response format from server');
        }
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw HttpException('Failed to fetch check min', response.statusCode);
      }
    } on TimeoutException {
      throw TimeoutException('Request timed out after $timeoutDuration');
    } on FormatException catch (e) {
      throw FormatException('Failed to parse response: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching check min: ${e.toString()}');
    }
  }

  Future<CheckMinAmount> updateCheckMin(
    String id,
    CheckMinAmount checkMin,
  ) async {
    if (id.isEmpty) throw ArgumentError('ID cannot be empty for update');

    final url = '$baseUrl/$id';
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await http
          .put(
            Uri.parse(url),
            headers: headers,
            body: json.encode(checkMin.toJson()),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return CheckMinAmount.fromJson(json.decode(response.body));
      } else {
        throw HttpException('Failed to update check min', response.statusCode);
      }
    } on TimeoutException {
      throw TimeoutException('Request timed out after $timeoutDuration');
    } catch (e) {
      throw Exception('Error updating check min: ${e.toString()}');
    }
  }

  Future<CheckMinAmount> createCheckMin(CheckMinAmount checkMin) async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: headers,
            body: json.encode(checkMin.toJson()),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 201) {
        return CheckMinAmount.fromJson(json.decode(response.body));
      } else {
        throw HttpException('Failed to create check min', response.statusCode);
      }
    } on TimeoutException {
      throw TimeoutException('Request timed out after $timeoutDuration');
    } catch (e) {
      throw Exception('Error creating check min: ${e.toString()}');
    }
  }
}

class HttpException implements Exception {
  final String message;
  final int statusCode;
  HttpException(this.message, this.statusCode);
  @override
  String toString() => '$message (Status: $statusCode)';
}
