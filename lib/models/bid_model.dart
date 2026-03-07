import 'package:intl/intl.dart';

class Bid {
  final String? id;
  final String marketId;
  final String userId;
  final String gameId;
  final String name;
  final String mobile;
  final String market;
  final String session;
  final String digit;
  final String pana;
  final String points;
  final String? win;
  final DateTime date;

  Bid({
    this.id,
    required this.marketId,
    required this.userId,
    required this.gameId,
    required this.name,
    required this.mobile,
    required this.market,
    required this.session,
    required this.digit,
    required this.pana,
    required this.points,
    this.win,
    required this.date,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['id'],
      marketId: json['marketId'],
      userId: json['userId'],
      gameId: json['gameId'],
      name: json['name'],
      mobile: json['mobile'],
      market: json['market'],
      session: json['session'],
      digit: json['digit'],
      pana: json['pana'],
      points: json['points'],
      win: json['win'],
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    return {
      'id': id,
      'marketId': marketId,
      'userId': userId,
      'gameId': gameId,
      'name': name,
      'mobile': mobile,
      'market': market,
      'session': session,
      'digit': digit,
      'pana': pana,
      'points': points,
      'win': win,
      'date': formattedDate,
    };
  }
}

class BidRequest {
  final String? id;
  final String marketId;
  final String userId;
  final String gameId;
  final String name;
  final String mobile;
  final String market;
  final String session;
  final String digit;
  final String pana;
  final String? win;
  final String points;
  final DateTime date;

  BidRequest({
    required this.id,
    required this.marketId,
    required this.userId,
    required this.gameId,
    required this.name,
    required this.mobile,
    required this.market,
    required this.session,
    required this.digit,
    required this.pana,
    required this.win,
    required this.points,
    required this.date,
  });
  Map<String, dynamic> toJson() {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    return {
      'id': id,
      'marketId': marketId,
      'userId': userId,
      'gameId': gameId,
      'name': name,
      'mobile': mobile,
      'market': market,
      'session': session,
      'digit': digit,
      'pana': pana,
      'points': points,
      'win': win,
      'date': formattedDate,
    };
  }
}
