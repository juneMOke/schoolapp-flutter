class ValidateOtpResponseModel {
  final String token;

  const ValidateOtpResponseModel({required this.token});

  factory ValidateOtpResponseModel.fromJson(Map<String, dynamic> json) {
    return ValidateOtpResponseModel(token: json['token'] as String);
  }
}
