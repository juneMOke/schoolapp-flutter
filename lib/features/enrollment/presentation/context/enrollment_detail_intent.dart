import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/constants/enrollment_constants.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';

class EnrollmentDetailIntent extends Equatable {
  static const String originQueryParameter = 'origin';
  static const String studentIdQueryParameter = 'studentId';
  static const String statusQueryParameter = 'status';
  static const String enrollmentTypeQueryParameter = 'enrollmentType';

  final EnrollmentDetailOrigin origin;
  final String enrollmentId;
  final String? studentId;
  final String? status;
  final String? enrollmentType;

  const EnrollmentDetailIntent({
    required this.origin,
    required this.enrollmentId,
    this.studentId,
    this.status,
    this.enrollmentType,
  });

  /// [studentId] réutilise le slot générique pour porter le `preEnrollmentId`
  /// d'un candidat BRUT (`enrollmentId` encore vide, segment de route littéral
  /// `new`) à travers le round-trip GoRouter — même procédé que
  /// `.reRegistration` avec son `studentId` réel. Une fois le dossier seedé
  /// (id réel), `studentId` redevient superflu (le dossier se rouvre par
  /// `enrollmentId`).
  const EnrollmentDetailIntent.preRegistration({
    required String enrollmentId,
    String? studentId,
  }) : this(
         origin: EnrollmentDetailOrigin.preRegistration,
         enrollmentId: enrollmentId,
         studentId: studentId,
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

  /// Reprise d'un brouillon LOCAL déjà en base : l'`enrollmentId` est l'id
  /// client du dossier DRAFT ; `studentId` est indicatif (l'agrégat local le
  /// porte déjà). `enrollmentType` = valeur RÉELLE du dossier repris (portée
  /// par `EnrollmentSummary` au tap) : sans elle, un re-save d'identité
  /// écraserait un brouillon RE/PRE avec le défaut NEW (cf.
  /// `LocalDraftResumeDetailPolicy`). Pas de `status` : `draftStatus` est
  /// DÉRIVÉ du type par la policy, pas lu depuis un status persisté (qui
  /// peut être une valeur legacy périmée sur un brouillon ancien).
  const EnrollmentDetailIntent.localDraftResume({
    required String enrollmentId,
    String? studentId,
    String? enrollmentType,
  }) : this(
         origin: EnrollmentDetailOrigin.localDraftResume,
         enrollmentId: enrollmentId,
         studentId: studentId,
         enrollmentType: enrollmentType,
       );

  EnrollmentDetailIntent withEnrollmentId(String enrollmentId) {
    return EnrollmentDetailIntent(
      origin: origin,
      enrollmentId: enrollmentId,
      studentId: studentId,
      status: status,
      enrollmentType: enrollmentType,
    );
  }

  Map<String, String> toQueryParameters() {
    return {
      originQueryParameter: origin.name,
      if (studentId != null && studentId!.isNotEmpty)
        studentIdQueryParameter: studentId!,
      if (status != null && status!.isNotEmpty) statusQueryParameter: status!,
      if (enrollmentType != null && enrollmentType!.isNotEmpty)
        enrollmentTypeQueryParameter: enrollmentType!,
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
    final enrollmentType = queryParameters[enrollmentTypeQueryParameter]
        ?.trim();

    return switch (origin) {
      EnrollmentDetailOrigin.preRegistration =>
        EnrollmentDetailIntent.preRegistration(
          enrollmentId: enrollmentId,
          studentId: (studentId != null && studentId.isNotEmpty)
              ? studentId
              : null,
        ),
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
      EnrollmentDetailOrigin.localDraftResume =>
        EnrollmentDetailIntent.localDraftResume(
          enrollmentId: enrollmentId,
          studentId: (studentId != null && studentId.isNotEmpty)
              ? studentId
              : null,
          enrollmentType: (enrollmentType != null && enrollmentType.isNotEmpty)
              ? enrollmentType
              : null,
        ),
    };
  }

  static EnrollmentDetailOrigin? _parseOrigin(String? value) {
    return EnrollmentDetailOrigin.values
        .where((origin) => origin.name == value)
        .firstOrNull;
  }

  @override
  List<Object?> get props => [
    origin,
    enrollmentId,
    studentId,
    status,
    enrollmentType,
  ];
}
