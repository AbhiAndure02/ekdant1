class Game {
  final String? id;
  final String userId;
  final String gameName;
  final String shortCode;
  final String rate;

  Game({
    this.id,
    required this.userId,
    required this.gameName,
    required this.shortCode,
    required this.rate,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      userId: json['userId'],
      gameName: json['gameName'],
      shortCode: json['shortCode'],
      rate: json['rate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'gameName': gameName,
      'shortCode': shortCode,
      'rate': rate,
    };
  }
}

class GameRequest {
  final String userId;
  final String gameName;
  final String shortCode;
  final String rate;

  GameRequest({
    required this.userId,
    required this.gameName,
    required this.shortCode,
    required this.rate,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'gameName': gameName,
      'shortCode': shortCode,
      'rate': rate,
    };
  }
}

class GameResponse {
  final String id;
  final String userId;
  final String gameName;
  final String shortCode;
  final String rate;

  GameResponse({
    required this.id,
    required this.userId,
    required this.gameName,
    required this.shortCode,
    required this.rate,
  });

  factory GameResponse.fromJson(Map<String, dynamic> json) {
    return GameResponse(
      id: json['id'],
      userId: json['userId'],
      gameName: json['gameName'],
      shortCode: json['shortCode'],
      rate: json['rate'],
    );
  }

  factory GameResponse.empty() =>
      GameResponse(id: '', userId: '', gameName: '', shortCode: '', rate: '');
}

class GameListResponse {
  final List<GameResponse> games;

  GameListResponse({required this.games});

  factory GameListResponse.fromJson(Map<String, dynamic> json) {
    var games = json['games'] as List;
    return GameListResponse(
      games: games.map((game) => GameResponse.fromJson(game)).toList(),
    );
  }

  void map(GameResponse Function(dynamic e) param0) {}
}
