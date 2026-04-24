import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/constants/enrollment_constants.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';

class EnrollmentDetailIntent extends Equatable {
  static const String originQueryParameter = 'origin';
  static const String studentIdQueryParameter = 'studentId';
  static const String statusQueryParameter = 'status';

  final EnrollmentDetailOrigin origin;
  final String enrollmentId;
  final String? studentId;
  final String? status;

  const EnrollmentDetailIntent({
    required this.origin,
    required this.enrollmentId,
    this.studentId,
    this.status,
  });

  const EnrollmentDetailIntent.preRegistration({required String enrollmentId})
    : this(
        origin: EnrollmentDetailOrigin.preRegistration,
        enrollmentId: enrollmentId,
      );

  const EnrollmentDetailIntent.newFirstRegistration()
    : this(
        origin: EnrollmentDetailOrigin.newFirstRegistration,
        enrollmentId: 'new',
      );

  const EnrollmentDetailIntent.reRegistration({
    required String enrollmentId,
    required String studentId,
  }) : this(
         origin: EnrollmentDetailOrigin.reRegistration,
         enrollmentId: enrollmentId,
         studentId: studentId,
       );

  EnrollmentDetailIntent withEnrollmentId(String enrollmentId) {
    return EnrollmentDetailIntent(
      origin: origin,
      enrollmentId: enrollmentId,
      studentId: studentId,
      status: status,
    );
  }

  Map<String, String> toQueryParameters() {
    return {
      originQueryParameter: origin.name,
      if (studentId != null && studentId!.isNotEmpty)
        studentIdQueryParameter: studentId!,
      if (status != null && status!.isNotEmpty) statusQueryParameter: status!,
    };
  }

  String toLocation() {
    return Uri(
      path: '${EnrollmentConstants.enrollmentDetailRoute}/$enrollmentId',
      queryParameters: toQueryParameters(),
    ).toString();
  }

  static EnrollmentDetailIntent fromRouteContext({
    required String enrollmentId,
    required Map<String, String> queryParameters,
    Object? extra,
  }) {
    final extraIntent = extra is EnrollmentDetailIntent
        ? extra.withEnrollmentId(enrollmentId)
        : null;

    final origin = _parseOrigin(queryParameters[originQueryParameter]);
    if (origin == null) {
      return extraIntent ??
          EnrollmentDetailIntent.preRegistration(enrollmentId: enrollmentId);
    }

    final studentId = queryParameters[studentIdQueryParameter]?.trim();
    final status = queryParameters[statusQueryParameter]?.trim();

    return switch (origin) {
      EnrollmentDetailOrigin.preRegistration =>
        EnrollmentDetailIntent.preRegistration(enrollmentId: enrollmentId),
      EnrollmentDetailOrigin.reRegistration =>
        (studentId != null && studentId.isNotEmpty)
            ? EnrollmentDetailIntent.reRegistration(
                enrollmentId: enrollmentId,
                studentId: studentId,
              )
            : extraIntent ??
                  EnrollmentDetailIntent.preRegistration(
                    enrollmentId: enrollmentId,
                  ),
      EnrollmentDetailOrigin.firstRegistration => EnrollmentDetailIntent(
        origin: EnrollmentDetailOrigin.firstRegistration,
        enrollmentId: enrollmentId,
        studentId: studentId,
        status: status,
      ),
      EnrollmentDetailOrigin.newFirstRegistration => EnrollmentDetailIntent(
        origin: EnrollmentDetailOrigin.newFirstRegistration,
        enrollmentId: enrollmentId,
        studentId: studentId,
        status: status,
      ),
    };
  }

  static EnrollmentDetailOrigin? _parseOrigin(String? value) {
    return EnrollmentDetailOrigin.values
        .where((origin) => origin.name == value)
        .firstOrNull;
  }

  @override
  List<Object?> get props => [origin, enrollmentId, studentId, status];
}
