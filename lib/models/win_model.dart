class Win {
  final String id;
  final String userId;
  final String? bidId;
  final String? resultId;
  final String? gameId;
  final String name;
  final String number;
  final String details;
  final String amount;
  final DateTime? date;

  Win({
    required this.id,
    required this.userId,
    this.bidId,
    this.resultId,
    this.gameId,
    required this.name,
    required this.number,
    required this.details,
    required this.amount,
    this.date,
  });

  factory Win.fromJson(Map<String, dynamic> json) {
    return Win(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      bidId: json['bidId'],
      resultId: json['resultId'],
      gameId: json['gameId'],
      name: json['name'] ?? '',
      number: json['number'] ?? '',
      details: json['details'] ?? '',
      amount: json['amount'] ?? '0.00',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : null,
    );
  }

  double get amountDouble {
    try {
      return double.parse(amount);
    } catch (_) {
      return 0.0;
    }
  }
}

class WinListResponse {
  final int totalRecords;
  final String totalAmountPaid;
  final List<Win> wins;

  WinListResponse({
    required this.totalRecords,
    required this.totalAmountPaid,
    required this.wins,
  });

  factory WinListResponse.fromJson(Map<String, dynamic> json) {
    return WinListResponse(
      totalRecords: json['totalRecords'] ?? 0,
      totalAmountPaid: json['totalAmountPaid'] ?? '0.00',
      wins: (json['wins'] as List<dynamic>? ?? [])
          .map((e) => Win.fromJson(e))
          .toList(),
    );
  }

  double get totalAmountDouble {
    try {
      return double.parse(totalAmountPaid);
    } catch (_) {
      return 0.0;
    }
  }
}

class UserWinListResponse {
  final String userId;
  final int totalRecords;
  final String totalWon;
  final List<Win> wins;

  UserWinListResponse({
    required this.userId,
    required this.totalRecords,
    required this.totalWon,
    required this.wins,
  });

  factory UserWinListResponse.fromJson(Map<String, dynamic> json) {
    return UserWinListResponse(
      userId: json['userId'] ?? '',
      totalRecords: json['totalRecords'] ?? 0,
      totalWon: json['totalWon'] ?? '0.00',
      wins: (json['wins'] as List<dynamic>? ?? [])
          .map((e) => Win.fromJson(e))
          .toList(),
    );
  }

  double get totalWonDouble {
    try {
      return double.parse(totalWon);
    } catch (_) {
      return 0.0;
    }
  }
}
