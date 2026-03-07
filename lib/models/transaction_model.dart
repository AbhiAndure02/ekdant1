class TransactionModel {
  final String id;
  final String userId;
  final String type;
  final String date;
  final String amount;
  final String? marketName;
  final String? gameName;
  final String? digit;
  final String? pana;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.date,
    required this.amount,
    this.marketName,
    this.gameName,
    this.digit,
    this.pana,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      date: json['date'] ?? '',
      amount: json['amount'] ?? '',
      marketName: json['marketName'] ?? '',
      gameName: json['gameName'] ?? '',
      digit: json['digit'] ?? '',
      pana: json['pana'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'date': date,
      'amount': amount,
      'marketName': marketName,
      'gameName': gameName,
      'digit': digit,
      'pana': pana,
    };
  }
}
