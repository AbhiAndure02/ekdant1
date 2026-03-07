import 'package:intl/intl.dart';

class WithdrawResponse {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final double balance;
  final String status;
  final DateTime reqDateTime;
  final DateTime? approvalDateTime;

  WithdrawResponse({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.balance,
    required this.status,
    required this.reqDateTime,
    this.approvalDateTime,
    required String toAccount,
    required String reason,
  });

  factory WithdrawResponse.fromJson(Map<String, dynamic> json) {
    return WithdrawResponse(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      amount: _parseDouble(json['amount']),
      balance: _parseDouble(json['balance']),
      status: json['status'] as String,
      reqDateTime: DateTime.parse(json['reqDateTime'] as String),
      approvalDateTime: json['approvalDateTime'] != null
          ? DateTime.parse(json['approvalDateTime'] as String)
          : null,
      toAccount: '',
      reason: '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    throw Exception('Cannot parse $value to double');
  }
}

class WithdrawRequest {
  final String userId;
  final String name;
  final String amount;
  final String toAccount;
  final String reason;
  final String status;
  final String reqDateTime; // Changed to String
  final String? approvalDateTime;
  final String balance;

  WithdrawRequest({
    required this.userId,
    required this.name,
    required this.amount,
    required this.toAccount,
    required this.reason,
    required this.status,
    required DateTime
    reqDateTime, // Accept DateTime but store as formatted String
    this.approvalDateTime,
    required this.balance,
  }) : reqDateTime = _formatDateTime(reqDateTime);

  static String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'balance': balance,
    'amount': amount,
    'toAccount': toAccount,
    'reason': reason,
    'status': status,
    'reqDateTime': reqDateTime, // Already formatted
    'approvalDateTime': approvalDateTime,
  };
}
