class GenerateOtpRequestModel {
  final String userEmail;

  const GenerateOtpRequestModel({
    required this.userEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      'userEmail': userEmail,
    };
  }
}