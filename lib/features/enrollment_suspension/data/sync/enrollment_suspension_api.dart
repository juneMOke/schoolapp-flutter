import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/suspension_gesture.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/suspension_period_dto.dart';

/// Les trois échanges de la désactivation : désactiver, réactiver, tirer.
///
/// Un élève par requête : un lot de N élèves part en N gestes, et un refus ne
/// touche que le sien.
class EnrollmentSuspensionApi {
  final Dio _dio;

  const EnrollmentSuspensionApi(this._dio);

  /// Envoie [gesture] ; rend l'état canonique de l'inscription.
  Future<SuspensionGestureAckDto> push(
    Map<String, dynamic> extras,
    SuspensionGesture gesture,
  ) async {
    final response = await _dio.post<Object?>(
      switch (gesture.op) {
        SuspensionGestureOp.suspend =>
          AppConstants.syncEnrollmentSuspensionsEndpoint,
        SuspensionGestureOp.reactivate =>
          AppConstants.syncEnrollmentReactivationsEndpoint,
      },
      data: bodyOf(gesture),
      options: Options(extra: extras),
    );
    return SuspensionGestureAckDto.parse(response.data);
  }

  /// Le corps d'un geste : le fait sous sa clé, et l'auteur à côté
  /// (`SuspendGestureRequest` / `ReactivateGestureRequest`).
  static Map<String, Object?> bodyOf(SuspensionGesture g) => switch (g.op) {
    SuspensionGestureOp.suspend => {
      'suspension': {
        'id': g.id,
        'enrollmentId': g.enrollmentId,
        'suspendedAt': g.at,
        'suspendedBy': g.authorId,
        'reason': ?g.reason?.wire,
        'precision': ?g.precision,
      },
      kOutboxAuthorIdKey: g.authorId,
    },
    SuspensionGestureOp.reactivate => {
      'reactivation': {
        'id': g.id,
        'enrollmentId': g.enrollmentId,
        'reactivatedAt': g.at,
        'reactivatedBy': g.authorId,
      },
      kOutboxAuthorIdKey: g.authorId,
    },
  };

  /// Une page du flux `enrollment.suspensions`. Un 304 remonte en
  /// `DioException`, comme le lit `KeysetPullRunner`.
  Future<SuspensionPageDto> pull(
    Map<String, dynamic> extras,
    String? cursor,
    int limit,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      AppConstants.syncEnrollmentSuspensionsEndpoint,
      queryParameters: {'cursor': ?cursor, 'limit': limit},
      options: Options(extra: extras),
    );
    return SuspensionPageDto.fromJson(response.data ?? const {});
  }
}
