import 'package:intl/intl.dart';

class Result {
  final String id;
  final String marketId;
  final String? marketName;
  final String session;
  final String openPana;
  final String openResult;
  final String closePana;
  final String closeResult;
  final DateTime? date;
  final String winner;
  factory Result.empty() => Result(
    id: '',
    marketId: '',
    session: '',
    openPana: '',
    openResult: '',
    closePana: '',
    closeResult: '',
    winner: '',
  );

  Result({
    required this.id,
    required this.marketId,
    this.marketName,
    required this.session,
    required this.openPana,
    required this.openResult,
    required this.closePana,
    required this.closeResult,
    this.date,
    required this.winner,
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      id: json['id'] ?? '',
      marketId: json['marketId'] ?? '',
      marketName: json['marketName'],
      session: json['session'] ?? '',
      openPana: json['openPana'] ?? '',
      openResult: json['openResult'] ?? '',
      closePana: json['closePana'] ?? '',
      closeResult: json['closeResult'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      winner: json['winner'] ?? '',
    );
  }
}

class ResultRequest {
  final String marketId;
  final String session;
  final String openPana;
  final String openResult;
  final String closePana;
  final String closeResult;
  final DateTime? date;
  final String winner;

  ResultRequest({
    required this.marketId,
    required this.session,
    required this.openPana,
    required this.openResult,
    required this.closePana,
    required this.closeResult,
    this.date,
    required this.winner,
  });

  Map<String, dynamic> toJson() {
    return {
      'marketId': marketId,
      'session': session,
      'openPana': openPana,
      'openResult': openResult,
      'closePana': closePana,
      'closeResult': closeResult,
      'date': date != null ? DateFormat('yyyy-MM-dd').format(date!) : null,
      'winner': winner,
    };
  }
}

class ResultResponse {
  final String id;
  final String marketId;
  final String? marketName;
  final String session;
  final String openPana;
  final String openResult;
  final String closePana;
  final String closeResult;
  final DateTime? date;
  final String winner;

  ResultResponse({
    required this.id,
    required this.marketId,
    this.marketName,
    required this.session,
    required this.openPana,
    required this.openResult,
    required this.closePana,
    required this.closeResult,
    this.date,
    required this.winner,
  });

  factory ResultResponse.fromJson(Map<String, dynamic> json) {
    return ResultResponse(
      id: json['id'] ?? '',
      marketId: json['marketId'] ?? '',
      marketName: json['marketName'],
      session: json['session'] ?? '',
      openPana: json['openPana'] ?? 0,
      openResult: json['openResult'] ?? 0,
      closePana: json['closePana'] ?? 0,
      closeResult: json['closeResult'] ?? 0,
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      winner: json['winner'] ?? '',
    );
  }
}
