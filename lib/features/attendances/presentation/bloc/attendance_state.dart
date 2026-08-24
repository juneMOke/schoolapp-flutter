import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';
import 'package:school_app_flutter/features/attendances/presentation/models/attendance_editable_row.dart';

enum AttendanceStatus { initial, loading, success, failure }

enum AttendanceErrorType {
  none,
  network,
  notFound,
  validation,
  unauthorized,
  // 403 (acces refuse) : produit par `UnauthorizedFailure` (HTTP 403) via
  // `_mapFailureToErrorType`, affiche par l'anatomie d'erreur partagee.
  forbidden,
  invalidCredentials,
  server,
  storage,
  auth,
  unknown,
}

class AttendanceState extends Equatable {
  final AttendanceStatus fetchStatus;
  final List<AttendanceRecord> records;
  final List<AttendanceEditableRow> draftRows;
  final AttendanceErrorType fetchErrorType;

  /// L'appel du jour a-t-il été fait (une session existe) ? `false` = **appel
  /// non fait** : le roster est présenté « présent par défaut » pour la saisie,
  /// mais l'UI ne doit PAS le donner pour validé (invariant #1, piège B4).
  final bool callTaken;

  final AttendanceStatus saveStatus;
  final AttendanceErrorType saveErrorType;
  final String? activeClassroomId;
  final String? activeAcademicYearId;
  final DateTime? activeDate;
  final bool hasUnsavedChanges;
  final bool hasValidationErrors;
  final Set<String> modifiedStudentIds;

  const AttendanceState({
    this.fetchStatus = AttendanceStatus.initial,
    this.records = const [],
    this.draftRows = const [],
    this.fetchErrorType = AttendanceErrorType.none,
    this.callTaken = false,
    this.saveStatus = AttendanceStatus.initial,
    this.saveErrorType = AttendanceErrorType.none,
    this.activeClassroomId,
    this.activeAcademicYearId,
    this.activeDate,
    this.hasUnsavedChanges = false,
    this.hasValidationErrors = false,
    this.modifiedStudentIds = const <String>{},
  });

  AttendanceState copyWith({
    AttendanceStatus? fetchStatus,
    List<AttendanceRecord>? records,
    List<AttendanceEditableRow>? draftRows,
    AttendanceErrorType? fetchErrorType,
    bool? callTaken,
    AttendanceStatus? saveStatus,
    AttendanceErrorType? saveErrorType,
    Object? activeClassroomId = _undefined,
    Object? activeAcademicYearId = _undefined,
    Object? activeDate = _undefined,
    bool? hasUnsavedChanges,
    bool? hasValidationErrors,
    Set<String>? modifiedStudentIds,
  }) => AttendanceState(
    fetchStatus: fetchStatus ?? this.fetchStatus,
    records: records ?? this.records,
    draftRows: draftRows ?? this.draftRows,
    fetchErrorType: fetchErrorType ?? this.fetchErrorType,
    callTaken: callTaken ?? this.callTaken,
    saveStatus: saveStatus ?? this.saveStatus,
    saveErrorType: saveErrorType ?? this.saveErrorType,
    activeClassroomId: identical(activeClassroomId, _undefined)
        ? this.activeClassroomId
        : activeClassroomId as String?,
    activeAcademicYearId: identical(activeAcademicYearId, _undefined)
        ? this.activeAcademicYearId
        : activeAcademicYearId as String?,
    activeDate: identical(activeDate, _undefined)
        ? this.activeDate
        : activeDate as DateTime?,
    hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    hasValidationErrors: hasValidationErrors ?? this.hasValidationErrors,
    modifiedStudentIds: modifiedStudentIds ?? this.modifiedStudentIds,
  );

  /// L'appel est-il enregistrable en l'état ?
  ///
  /// ⚠️ Ce n'est PAS « le brouillon a changé ». Un appel **jamais fait**
  /// ([callTaken] faux) présente le roster « présent par défaut » : « tout le
  /// monde est là » est donc exactement **zéro différence** avec ce qui est
  /// affiché — et c'est pourtant l'appel le plus courant. Exiger
  /// [hasUnsavedChanges] rendait ce cas-là inenregistrable : le bouton restait
  /// gris, la confirmation « tous présents » de l'écran était inatteignable, et
  /// le bandeau « appel non fait » ne pouvait jamais tomber. Il fallait rendre
  /// un élève absent puis le repasser présent pour... revenir à un brouillon
  /// identique, donc à un bouton gris.
  ///
  /// Une fois l'appel FAIT, la règle redevient « il faut quelque chose à
  /// enregistrer » : réenregistrer à l'identique ne ferait que rebumper le
  /// jeton LWW et repousser au serveur un agrégat qu'il détient déjà.
  bool get canSave =>
      draftRows.isNotEmpty &&
      (!callTaken || hasUnsavedChanges) &&
      !hasValidationErrors &&
      saveStatus != AttendanceStatus.loading;

  int get modifiedCount => modifiedStudentIds.length;

  @override
  List<Object?> get props => [
    fetchStatus,
    records,
    draftRows,
    fetchErrorType,
    callTaken,
    saveStatus,
    saveErrorType,
    activeClassroomId,
    activeAcademicYearId,
    activeDate,
    hasUnsavedChanges,
    hasValidationErrors,
    modifiedStudentIds,
  ];
}

const _undefined = Object();
