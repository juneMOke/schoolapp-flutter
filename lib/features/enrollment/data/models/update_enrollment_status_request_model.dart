class UpdateEnrollmentStatusRequestModel {
  final String status;

  const UpdateEnrollmentStatusRequestModel({required this.status});

  Map<String, dynamic> toJson() => <String, dynamic>{
    'status': status,
  };
}
