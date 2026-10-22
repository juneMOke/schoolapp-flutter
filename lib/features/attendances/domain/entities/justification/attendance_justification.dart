import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/attachments/attachment_ref.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/justification_enums.dart';

/// Une justification d'absence déposée par un parent, telle que l'école la
/// voit : la demande, ce que le serveur en a décidé, et la décision de cette
/// tablette tant qu'elle n'est pas accusée.
class AttendanceJustification extends Equatable {
  final String id;
  final String studentId;
  final String classroomId;
  final String academicYearId;

  /// `YYYY-MM-DD`, le jour de l'absence.
  final String attendanceDate;
  final AbsenceReason reason;

  /// Le mot du parent (200 caractères au plus).
  final String? note;
  final DateTime? submittedAt;
  final AttachmentRef? attachment;

  final JustificationStatus status;
  final DateTime? decidedAt;

  /// Le mot de l'école au parent : le motif d'un refus.
  final String? decisionNote;

  /// La décision prise ici, en attente d'accusé ; `null` sinon.
  final JustificationDecision? localDecision;
  final SyncState sync;

  /// Pourquoi la dernière décision de cette tablette n'est pas passée (droit
  /// retiré, demande disparue) ; `null` sinon. La demande se tranche à
  /// nouveau.
  final String? refusal;

  /// Le serveur a refusé l'acceptation : seul le refus reste possible.
  final JustificationAcceptBlock? acceptBlock;

  /// Une autre tablette a tranché autrement que celle-ci.
  final bool decidedElsewhere;

  /// Identité affichée, lue du roster de la classe ; vide si l'élève n'y est
  /// plus.
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;
  final String? classroomName;

  const AttendanceJustification({
    required this.id,
    required this.studentId,
    required this.classroomId,
    required this.academicYearId,
    required this.attendanceDate,
    required this.reason,
    required this.status,
    this.note,
    this.submittedAt,
    this.attachment,
    this.decidedAt,
    this.decisionNote,
    this.localDecision,
    this.sync = SyncState.synced,
    this.refusal,
    this.acceptBlock,
    this.decidedElsewhere = false,
    this.studentFirstName = '',
    this.studentLastName = '',
    this.studentMiddleName,
    this.classroomName,
  });

  /// Une décision part : la demande n'attend plus l'école, elle attend le
  /// serveur.
  bool get isSending => localDecision != null;

  /// La demande attend une décision de l'école.
  bool get awaitsDecision =>
      status == JustificationStatus.pending && localDecision == null;

  bool get canReject => awaitsDecision;

  bool get canAccept => awaitsDecision && acceptBlock == null;

  /// « En attente » au sens de l'écran : pas encore tranchée par le serveur,
  /// décision locale en route comprise.
  bool get isOpen => status == JustificationStatus.pending;

  /// « Nom Post-nom Prénom », l'ordre des listes d'élèves.
  String get studentName => [
    studentLastName,
    studentMiddleName,
    studentFirstName,
  ].where((part) => part != null && part.trim().isNotEmpty).join(' ');

  @override
  List<Object?> get props => [
    id,
    studentId,
    classroomId,
    academicYearId,
    attendanceDate,
    reason,
    note,
    submittedAt,
    attachment,
    status,
    decidedAt,
    decisionNote,
    localDecision,
    sync,
    refusal,
    acceptBlock,
    decidedElsewhere,
    studentFirstName,
    studentLastName,
    studentMiddleName,
    classroomName,
  ];
}
