class ValidateOtpRequestModel {
  final String userEmail;
  final String code;

  const ValidateOtpRequestModel({required this.userEmail, required this.code});

  Map<String, dynamic> toJson() {
    return {'userEmail': userEmail, 'code': code};
  }
}
