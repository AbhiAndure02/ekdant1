import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String _baseUrl = 'https://api.ekadantaa.in/api/auth';
  static const String _userUrlBase = 'https://api.ekadantaa.in/api/user';

  static const String signUpUrl = '$_baseUrl/signup';
  static const String signInUrl = '$_baseUrl/signin';
  static const String logoutUrl = '$_baseUrl/logout';
  static const String userInfoUrl = '$_baseUrl/me';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final StreamController<double> _walletController =
      StreamController<double>.broadcast();

  // Stream to listen to wallet changes
  Stream<double> get walletUpdates => _walletController.stream;

  void updateWallet(double newAmount) {
    _walletController.add(newAmount);
  }

  // 🔁 Fetch latest user data from /auth/me
  Future<void> refreshUserData() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse(userInfoUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        await _storage.write(key: 'user_data', value: jsonEncode(userData));

        final walletAmount =
            double.tryParse(userData['walletAmount']?.toString() ?? '0.0') ??
            0.0;
        _walletController.add(walletAmount);
      }
    } catch (e) {
      print("❌ REFRESH Error: $e");
    }
  }

  // 🔁 Fetch latest user data using user ID from /user/{id}
  Future<void> refreshWalletById(String userId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return;

      final url = '$_userUrlBase/$userId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        await _storage.write(key: 'user_data', value: jsonEncode(userData));

        final walletAmount =
            double.tryParse(userData['walletAmount']?.toString() ?? '0.0') ??
            0.0;
        _walletController.add(walletAmount);
      } else {
        print("⚠️ Failed to fetch wallet by ID: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error in refreshWalletById: $e");
    }
  }

  // 🔐 Sign Up
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String number,
    required String password,
  }) async {
    try {
      final body = jsonEncode({
        'name': name,
        'number': number,
        'password': password,
        'role': 'ROLE_ADMIN',
      });

      final response = await http.post(
        Uri.parse(signUpUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print("SIGNUP RAW RESPONSE: ${response.body}");

      final responseData = jsonDecode(response.body);

      Map<String, dynamic> data;

      if (responseData.containsKey('body')) {
        data = responseData['body'];
      } else {
        data = responseData;
      }

      if (response.statusCode == 201 || data['user'] != null) {
        final userJson = data['user'];

        await _storage.write(key: 'user_data', value: jsonEncode(userJson));
        await _storage.write(key: 'auth_token', value: data['token']);

        final walletAmount =
            double.tryParse(userJson['walletAmount']?.toString() ?? '0.0') ??
            0.0;

        _walletController.add(walletAmount);

        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful',
          'user': User.fromJson(userJson),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<bool> isLoggedIn() async {
    final userData = await _storage.read(key: 'user_data');
    return userData != null;
  }

  // 🔑 Sign In
  Future<Map<String, dynamic>> signIn({
    required String number,
    required String password,
  }) async {
    try {
      final body = jsonEncode({'number': number, 'password': password});

      final response = await http.post(
        Uri.parse(signInUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final user = User.fromJson(responseData);

        await _storage.write(key: 'auth_token', value: responseData['token']);
        await _storage.write(
          key: 'user_data',
          value: jsonEncode(user.toJson()),
        );

        final walletAmount = double.tryParse(user.walletAmount ?? '0.0') ?? 0.0;
        _walletController.add(walletAmount);

        return {'success': true, 'message': 'Login successful', 'user': user};
      } else {
        final errorResponse = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorResponse['message'] ?? 'Invalid credentials',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Login failed: $e'};
    }
  }

  // 🚪 Logout
  Future<Map<String, dynamic>> logout() async {
    try {
      final token = await _storage.read(key: 'auth_token');

      await http.post(
        Uri.parse(logoutUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      await _storage.delete(key: 'user_data');
      await _storage.delete(key: 'auth_token');
      _walletController.add(0.0);

      return {'success': true, 'message': 'Logged out successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Logout error: $e'};
    }
  }

  // 🧠 Get user data from secure storage
  Future<User?> getUserData() async {
    try {
      final userData = await _storage.read(key: 'user_data');
      if (userData != null) {
        return User.fromJson(jsonDecode(userData));
      }
    } catch (_) {}
    return null;
  }

  // 🔒 Check if user is logged in

  // 💰 Get wallet balance from stored user
  Future<double> getCurrentWallet() async {
    final user = await getUserData();
    return double.tryParse(user?.walletAmount ?? '0.0') ?? 0.0;
  }

  void dispose() {
    _walletController.close();
  }

  // 🔄 Refresh user data including wallet from /api/user/{id}
  Future<void> refreshUserWallet() async {
    try {
      final user = await getUserData();
      if (user == null || user.id.isEmpty) return;

      final token = await _storage.read(key: 'auth_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$_userUrlBase/${user.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        await _storage.write(key: 'user_data', value: jsonEncode(userData));

        final walletAmount =
            double.tryParse(userData['walletAmount']?.toString() ?? '0.0') ??
            0.0;
        _walletController.add(walletAmount);
      }
    } catch (e) {
      debugPrint('Wallet refresh error: $e');
    }
  }

  // ✅ Get stored JWT token
  Future<String?> getToken() async {
    final token = await _storage.read(key: 'auth_token');
    print(
      "🔑 getToken() called → ${token != null ? 'token found (${token.substring(0, 20)}...)' : 'NO TOKEN FOUND'}",
    );
    return token;
  }

  // ✅ Get auth headers with token — use this in all services
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      print("❌ getAuthHeaders() → No token in storage! User must log in.");
      throw Exception('Not authenticated. Please log in.');
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}

class User {
  final String id;
  final String? apiToken;
  final String? deviceToken;
  final String name;
  final String number;
  final String password;
  final String? walletAmount;
  final String? status;
  final String role;
  final String registrationDate;
  final String? autoDepoositeStatus;
  final String? referalCode;
  final String? referalTo;
  final bool isActive;
  final String? accountNumber;
  final String? bankHolderName;
  final String? bankName;
  final String? upi;
  final String? waNumber;
  final String? ifsc;

  User({
    required this.id,
    this.apiToken,
    this.deviceToken,
    required this.name,
    required this.number,
    required this.password,
    this.walletAmount,
    this.status,
    required this.role,
    required this.registrationDate,
    this.autoDepoositeStatus,
    this.referalCode,
    this.referalTo,
    required this.isActive,
    this.accountNumber,
    this.bankHolderName,
    this.bankName,
    this.upi,
    this.waNumber,
    this.ifsc,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      apiToken: json['apiToken'],
      deviceToken: json['deviceToken'],
      name: json['name'] ?? '',
      number: json['number'] ?? '',
      password: json['password'] ?? '',
      walletAmount: json['walletAmount']?.toString(),
      status: json['status'],
      role: json['role'] ?? 'USER',
      registrationDate: json['registrationDate']?.toString() ?? '',
      autoDepoositeStatus: json['autoDepoositeStatus'],
      referalCode: json['referalCode'],
      referalTo: json['referalTo'],
      isActive: json['is_active'] ?? true,
      accountNumber: json['accountNumber'],
      bankHolderName: json['bankHolderName'],
      bankName: json['bankName'],
      upi: json['upi'],
      waNumber: json['waNumber'],
      ifsc: json['IFSC'] ?? json['ifsc'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "apiToken": apiToken,
      "deviceToken": deviceToken,
      "name": name,
      "number": number,
      "password": password,
      "walletAmount": walletAmount,
      "status": status,
      "role": role,
      "registrationDate": registrationDate,
      "autoDepoositeStatus": autoDepoositeStatus,
      "referalCode": referalCode,
      "referalTo": referalTo,
      "is_active": isActive,
      "accountNumber": accountNumber,
      "bankHolderName": bankHolderName,
      "bankName": bankName,
      "upi": upi,
      "waNumber": waNumber,
      "IFSC": ifsc,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? number,
    String? password,
    String? walletAmount,
    String? status,
    String? role,
    String? registrationDate,
    bool? isActive,
    String? apiToken,
    String? deviceToken,
    String? autoDepoositeStatus,
    String? referalCode,
    String? referalTo,
    String? accountNumber,
    String? bankHolderName,
    String? bankName,
    String? upi,
    String? waNumber,
    String? ifsc,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      password: password ?? this.password,
      walletAmount: walletAmount ?? this.walletAmount,
      status: status ?? this.status,
      role: role ?? this.role,
      registrationDate: registrationDate ?? this.registrationDate,
      isActive: isActive ?? this.isActive,
      apiToken: apiToken ?? this.apiToken,
      deviceToken: deviceToken ?? this.deviceToken,
      autoDepoositeStatus: autoDepoositeStatus ?? this.autoDepoositeStatus,
      referalCode: referalCode ?? this.referalCode,
      referalTo: referalTo ?? this.referalTo,
      accountNumber: accountNumber ?? this.accountNumber,
      bankHolderName: bankHolderName ?? this.bankHolderName,
      bankName: bankName ?? this.bankName,
      upi: upi ?? this.upi,
      waNumber: waNumber ?? this.waNumber,
      ifsc: ifsc ?? this.ifsc,
    );
  }
}
