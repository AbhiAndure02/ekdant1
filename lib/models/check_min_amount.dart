class CheckMinAmount {
  final String? id;
  final int minWithAmount;
  final int minDepoAmount;
  final String homeText;
  final String withText;
  final int minWithDailyLim;
  final int minBidAmount;
  final String startTime;
  final String endTime;

  CheckMinAmount({
    this.id,
    required this.minWithAmount,
    required this.minDepoAmount,
    required this.homeText,
    required this.withText,
    required this.minWithDailyLim,
    required this.minBidAmount,
    required this.startTime,
    required this.endTime,
  });

  factory CheckMinAmount.fromJson(Map<String, dynamic> json) {
    return CheckMinAmount(
      id: json['_id'],
      minWithAmount: json['minWithAmount'],
      minDepoAmount: json['minDepoAmount'],
      homeText: json['homeText'],
      withText: json['withText'],
      minWithDailyLim: json['minWithDailyLim'],
      minBidAmount: json['minBidAmount'],
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'minWithAmount': minWithAmount,
      'minDepoAmount': minDepoAmount,
      'homeText': homeText,
      'withText': withText,
      'minWithDailyLim': minWithDailyLim,
      'minBidAmount': minBidAmount,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}
