import 'package:intl/intl.dart';

class Deposit {
  final String id;
  final String userId;
  final String name;
  final String balance;
  final String utrNumber;
  final String amount;
  final String upiName;
  final String status;
  final DateTime? reqDateTime;
  final DateTime? approvalDateTime;

  Deposit({
    required this.id,
    required this.userId,
    required this.name,
    required this.balance,
    required this.utrNumber,
    required this.amount,
    required this.upiName,
    required this.status,
    this.reqDateTime,
    this.approvalDateTime,
  });

  Map<String, dynamic> toJson() {
    final formatter = DateFormat("yyyy-MM-dd HH:mm:ss");

    return {
      "id": id,
      "userId": userId,
      "name": name,
      "balance": balance,
      "utrNumber": utrNumber,
      "amount": amount,
      "upiName": upiName,
      "status": status,
      "reqDateTime": reqDateTime != null
          ? formatter.format(reqDateTime!)
          : null,
      "approvalDateTime": approvalDateTime != null
          ? formatter.format(approvalDateTime!)
          : null,
    };
  }

  factory Deposit.fromJson(Map<String, dynamic> json) {
    return Deposit(
      id: json["id"] ?? '',
      userId: json["userId"] ?? '',
      name: json["name"] ?? '',
      balance: json["balance"] ?? '0',
      utrNumber: json["utrNumber"] ?? '',
      amount: json["amount"] ?? '0',
      upiName: json["upiName"] ?? '',
      status: json["status"] ?? '',
      reqDateTime: json["reqDateTime"] != null
          ? DateTime.tryParse(json["reqDateTime"])
          : null,
      approvalDateTime: json["approvalDateTime"] != null
          ? DateTime.tryParse(json["approvalDateTime"])
          : null,
    );
  }
}
