class ResetPasswordRequest {
  final String userEmail;
  final String newPassword;

  const ResetPasswordRequest({
    required this.userEmail,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {'userEmail': userEmail, 'newPassword': newPassword};
  }
}
