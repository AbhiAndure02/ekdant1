class GameRate {
  final String? id;
  final String gameName;
  final String rate;

  GameRate({this.id, required this.gameName, required this.rate});

  factory GameRate.fromJson(Map<String, dynamic> json) {
    return GameRate(
      id: json['id'],
      gameName: json['gameName'],
      rate: json['rate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {if (id != null) 'id': id, 'gameName': gameName, 'rate': rate};
  }

  GameRate copyWith({String? id, String? gameName, String? rate}) {
    return GameRate(
      id: id ?? this.id,
      gameName: gameName ?? this.gameName,
      rate: rate ?? this.rate,
    );
  }
}
