class ApiErrorDetailModel {
  final String? field;
  final String? message;

  const ApiErrorDetailModel({
    this.field,
    this.message,
  });

  factory ApiErrorDetailModel.fromJson(Map<String, dynamic> json) =>
      ApiErrorDetailModel(
        field: json['field'] as String?,
        message: json['message'] as String?,
      );
}
