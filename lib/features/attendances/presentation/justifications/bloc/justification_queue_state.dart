import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/attachments/attachment_availability.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/attendance_justification.dart';

enum JustificationQueueLoad { initial, loading, ready, failure }

/// Les deux vues de la file : ce qui attend l'école, ce qu'elle a tranché.
enum JustificationQueueFilter { open, decided }

class JustificationQueueState extends Equatable {
  final JustificationQueueLoad load;
  final String? academicYearId;
  final List<AttendanceJustification> all;
  final JustificationQueueFilter filter;
  final Failure? failure;

  /// Les demandes qu'une autre tablette a tranchées autrement que celle-ci,
  /// à annoncer une fois. Vidé dès l'annonce.
  final List<AttendanceJustification> decidedElsewhere;

  /// Les pièces jointes peuvent-elles s'ouvrir maintenant ?
  final AttachmentAvailability attachments;

  const JustificationQueueState({
    this.load = JustificationQueueLoad.initial,
    this.academicYearId,
    this.all = const [],
    this.filter = JustificationQueueFilter.open,
    this.failure,
    this.decidedElsewhere = const [],
    this.attachments = const AttachmentAvailability(),
  });

  List<AttendanceJustification> get open => all.where((j) => j.isOpen).toList();

  List<AttendanceJustification> get decided =>
      all.where((j) => !j.isOpen).toList();

  List<AttendanceJustification> get visible =>
      filter == JustificationQueueFilter.open ? open : decided;

  /// Ce qui attend vraiment l'école : sans les décisions déjà en route.
  int get awaitingCount => all.where((j) => j.awaitsDecision).length;

  bool get isLoading =>
      load == JustificationQueueLoad.initial ||
      load == JustificationQueueLoad.loading;

  JustificationQueueState copyWith({
    JustificationQueueLoad? load,
    String? academicYearId,
    List<AttendanceJustification>? all,
    JustificationQueueFilter? filter,
    Failure? failure,
    List<AttendanceJustification>? decidedElsewhere,
    AttachmentAvailability? attachments,
  }) => JustificationQueueState(
    load: load ?? this.load,
    academicYearId: academicYearId ?? this.academicYearId,
    all: all ?? this.all,
    filter: filter ?? this.filter,
    failure: failure,
    decidedElsewhere: decidedElsewhere ?? this.decidedElsewhere,
    attachments: attachments ?? this.attachments,
  );

  @override
  List<Object?> get props => [
    load,
    academicYearId,
    all,
    filter,
    failure,
    decidedElsewhere,
    attachments,
  ];
}
