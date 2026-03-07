import 'dart:convert';
import 'package:ekdant/services/token_helper.dart';
import 'package:http/http.dart' as http;

class UserService {
  static const String _baseUrl = 'https://api.ekadantaa.in/api/user';

  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/all'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<User> users = (data['users'] as List)
            .map((json) => User.fromJson(json))
            .toList();
        final double totalWalletAmount = (data['totalWalletAmount'] ?? 0)
            .toDouble();
        return {'users': users, 'totalWalletAmount': totalWalletAmount};
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }

  Future<List<User>> getAllUser() async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/all'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return (data['users'] as List)
            .map((json) => User.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }

  Future<User> getUserById(String userId) async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  Future<void> updateUser(User user) async {
    try {
      final headers = await TokenHelper.getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/${user.id}'),
        headers: headers,
        body: json.encode(user.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }
}

class User {
  final String id;
  final String? apiToken;
  final String? deviceToken;
  final String name;
  final String number;
  final String password;
  final String? balance;
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
    this.balance,
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
      balance: json['walletAmount']?.toString(),
      status: json['status'],
      role: json['role'] ?? 'USER',
      registrationDate: json['registrationDate'] ?? '',
      autoDepoositeStatus: json['autoDepoositeStatus'],
      referalCode: json['referalCode'],
      referalTo: json['referalTo'],
      isActive: json['is_active'] ?? false,
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
      "walletAmount": balance,
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
    String? name,
    String? number,
    String? wa_number,
    String? upi,
    String? accountNumber,
    String? bankHolderName,
    String? bankName,
    String? ifsc,
    String? balance,
  }) {
    return User(
      id: id,
      apiToken: apiToken,
      deviceToken: deviceToken,
      name: name ?? this.name,
      number: number ?? this.number,
      password: password,
      balance: balance ?? this.balance,
      status: status,
      role: role,
      registrationDate: registrationDate,
      autoDepoositeStatus: autoDepoositeStatus,
      referalCode: referalCode,
      referalTo: referalTo,
      isActive: isActive,
      accountNumber: accountNumber ?? this.accountNumber,
      bankHolderName: bankHolderName ?? this.bankHolderName,
      bankName: bankName ?? this.bankName,
      upi: upi ?? this.upi,
      waNumber: wa_number ?? waNumber,
      ifsc: ifsc ?? this.ifsc,
    );
  }
}
