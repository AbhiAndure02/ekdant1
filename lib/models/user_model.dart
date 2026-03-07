class User {
  final String id;
  final String? apiToken;
  final String? deviceToken;
  final String name;
  final String number;
  final String password;
  final String? walletAmount;
  final String? status;
  final String role;
  final String registrationDate;
  final String? autoDepoositeStatus;
  final String? referalCode;
  final String? referalTo;
  final bool isActive;
  final String? accountNumber;
  final String? bankHolderName;
  final String? bankName;
  final String? upi;
  final String? waNumber;
  final String? ifsc;

  User({
    required this.id,
    this.apiToken,
    this.deviceToken,
    required this.name,
    required this.number,
    required this.password,
    this.walletAmount,
    this.status,
    required this.role,
    required this.registrationDate,
    this.autoDepoositeStatus,
    this.referalCode,
    this.referalTo,
    required this.isActive,
    this.accountNumber,
    this.bankHolderName,
    this.bankName,
    this.upi,
    this.waNumber,
    this.ifsc,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      apiToken: json['apiToken'],
      deviceToken: json['deviceToken'],
      name: json['name'] ?? '',
      number: json['number'] ?? '',
      password: json['password'] ?? '',
      walletAmount: json['walletAmount']?.toString(),
      status: json['status'],
      role: json['role'] ?? 'USER',
      registrationDate: json['registrationDate']?.toString() ?? '',
      autoDepoositeStatus: json['autoDepoositeStatus'],
      referalCode: json['referalCode'],
      referalTo: json['referalTo'],
      isActive: json['is_active'] ?? false,
      accountNumber: json['accountNumber'],
      bankHolderName: json['bankHolderName'],
      bankName: json['bankName'],
      upi: json['upi'],
      waNumber: json['waNumber'],
      ifsc: json['IFSC'] ?? json['ifsc'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "apiToken": apiToken,
      "deviceToken": deviceToken,
      "name": name,
      "number": number,
      "password": password,
      "walletAmount": walletAmount,
      "status": status,
      "role": role,
      "registrationDate": registrationDate,
      "autoDepoositeStatus": autoDepoositeStatus,
      "referalCode": referalCode,
      "referalTo": referalTo,
      "is_active": isActive,
      "accountNumber": accountNumber,
      "bankHolderName": bankHolderName,
      "bankName": bankName,
      "upi": upi,
      "waNumber": waNumber,
      "IFSC": ifsc,
    };
  }

  void copyWith({required String walletAmount}) {}
}
