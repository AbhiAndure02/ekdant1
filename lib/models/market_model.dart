class Market {
  final String? id;
  final String name;
  final String openTime;
  final String closeTimeOpen;
  final String closeTimeClose;
  final bool type;
  final bool status;
  final bool monday;
  final bool tuesday;
  final bool wednesday;
  final bool thursday;
  final bool friday;
  final bool saturday;
  final bool sunday;

  Market({
    this.id,
    required this.name,
    required this.openTime,
    required this.closeTimeOpen,
    required this.closeTimeClose,
    required this.type,
    required this.status,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
  });

  factory Market.fromJson(Map<String, dynamic> json) {
    return Market(
      id: json['id'],
      name: json['name'],
      openTime: json['openTime'],
      closeTimeOpen: json['closeTimeOpen'],
      closeTimeClose: json['closeTimeClose'],
      type: json['type'] ?? false,
      status: json['status'] ?? false,
      monday: json['monday'] ?? false,
      tuesday: json['tuesday'] ?? false,
      wednesday: json['wednesday'] ?? false,
      thursday: json['thursday'] ?? false,
      friday: json['friday'] ?? false,
      saturday: json['saturday'] ?? false,
      sunday: json['sunday'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'openTime': openTime,
      'closeTimeOpen': closeTimeOpen,
      'closeTimeClose': closeTimeClose,
      'type': type,
      'status': status,
      'monday': monday,
      'tuesday': tuesday,
      'wednesday': wednesday,
      'thursday': thursday,
      'friday': friday,
      'saturday': saturday,
      'sunday': sunday,
    };
  }
}

class MarketRequest {
  final String name;
  final String openTime;
  final String closeTimeOpen;
  final String closeTimeClose;
  final bool type;
  final bool status;
  final bool monday;
  final bool tuesday;
  final bool wednesday;
  final bool thursday;
  final bool friday;
  final bool saturday;
  final bool sunday;

  MarketRequest({
    required this.name,
    required this.openTime,
    required this.closeTimeOpen,
    required this.closeTimeClose,
    required this.type,
    required this.status,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'openTime': openTime,
      'closeTimeOpen': closeTimeOpen,
      'closeTimeClose': closeTimeClose,
      'type': type,
      'status': status,
      'monday': monday,
      'tuesday': tuesday,
      'wednesday': wednesday,
      'thursday': thursday,
      'friday': friday,
      'saturday': saturday,
      'sunday': sunday,
    };
  }
}

class MarketResponse {
  final String id;
  final String name;
  final String openTime;
  final String closeTimeOpen;
  final String closeTimeClose;
  final bool type;
  final bool status;
  final bool monday;
  final bool tuesday;
  final bool wednesday;
  final bool thursday;
  final bool friday;
  final bool saturday;
  final bool sunday;

  MarketResponse({
    required this.id,
    required this.name,
    required this.openTime,
    required this.closeTimeOpen,
    required this.closeTimeClose,
    required this.type,
    required this.status,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
  });

  factory MarketResponse.fromJson(Map<String, dynamic> json) {
    return MarketResponse(
      id: json['id'],
      name: json['name'],
      openTime: json['openTime'],
      closeTimeOpen: json['closeTimeOpen'],
      closeTimeClose: json['closeTimeClose'],
      type: json['type'] ?? false,
      status: json['status'] ?? false,
      monday: json['monday'] ?? false,
      tuesday: json['tuesday'] ?? false,
      wednesday: json['wednesday'] ?? false,
      thursday: json['thursday'] ?? false,
      friday: json['friday'] ?? false,
      saturday: json['saturday'] ?? false,
      sunday: json['sunday'] ?? false,
    );
  }
}

class MarketListResponse {
  final List<MarketResponse> markets;

  MarketListResponse({required this.markets});

  factory MarketListResponse.fromJson(Map<String, dynamic> json) {
    var markets = json['markets'] as List;
    return MarketListResponse(
      markets:
          markets.map((market) => MarketResponse.fromJson(market)).toList(),
    );
  }
}
