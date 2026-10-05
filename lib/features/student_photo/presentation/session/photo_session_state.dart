import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/photo_session.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/camera_opener.dart';

sealed class PhotoSessionState extends Equatable {
  const PhotoSessionState();

  @override
  List<Object?> get props => const [];
}

class SessionLoading extends PhotoSessionState {
  const SessionLoading();
}

class SessionLoadFailed extends PhotoSessionState {
  final Failure failure;

  const SessionLoadFailed(this.failure);

  @override
  List<Object?> get props => [failure];
}

/// Le choix de la classe.
class SessionSetup extends PhotoSessionState {
  final List<SessionClassSummary> classes;
  final String? selectedId;
  final bool onlyMissing;

  const SessionSetup({
    required this.classes,
    this.selectedId,
    this.onlyMissing = true,
  });

  SessionClassSummary? get selected {
    for (final summary in classes) {
      if (summary.klass.id == selectedId) return summary;
    }
    return null;
  }

  /// Les élèves que la séance va parcourir.
  int get startCount {
    final summary = selected;
    if (summary == null) return 0;
    return onlyMissing ? summary.missing : summary.total;
  }

  SessionSetup copyWith({String? selectedId, bool? onlyMissing}) =>
      SessionSetup(
        classes: classes,
        selectedId: selectedId ?? this.selectedId,
        onlyMissing: onlyMissing ?? this.onlyMissing,
      );

  @override
  List<Object?> get props => [classes, selectedId, onlyMissing];
}

/// La photo qui vient d'être prise, montrée un instant avant l'élève suivant.
class SessionFlash extends Equatable {
  final Uint8List photo;
  final String studentId;

  const SessionFlash({required this.photo, required this.studentId});

  @override
  List<Object?> get props => [photo, studentId];
}

/// La prise de vue en rafale.
class SessionShooting extends PhotoSessionState {
  final SessionClass klass;
  final List<SessionItem> queue;
  final int index;
  final CameraOpening? camera;
  final SessionFlash? flash;

  /// Une photo est en préparation : on ne déclenche pas deux fois.
  final bool busy;

  const SessionShooting({
    required this.klass,
    required this.queue,
    required this.index,
    this.camera,
    this.flash,
    this.busy = false,
  });

  SessionItem get current => queue[index];

  /// Les élèves déjà traités (photographiés, absents ou passés).
  int get handled =>
      queue.where((item) => item.status != SessionItemStatus.todo).length;

  SessionShooting copyWith({
    List<SessionItem>? queue,
    int? index,
    CameraOpening? camera,
    bool clearCamera = false,
    SessionFlash? flash,
    bool clearFlash = false,
    bool? busy,
  }) => SessionShooting(
    klass: klass,
    queue: queue ?? this.queue,
    index: index ?? this.index,
    camera: clearCamera ? null : (camera ?? this.camera),
    flash: clearFlash ? null : (flash ?? this.flash),
    busy: busy ?? this.busy,
  );

  @override
  List<Object?> get props => [klass, queue, index, camera, flash, busy];
}

/// Le bilan de la séance.
class SessionSummary extends PhotoSessionState {
  final SessionClass klass;
  final List<SessionItem> queue;

  const SessionSummary({required this.klass, required this.queue});

  List<SessionItem> _with(SessionItemStatus status) =>
      queue.where((item) => item.status == status).toList(growable: false);

  List<SessionItem> get photographed => _with(SessionItemStatus.photographed);
  int get absent => _with(SessionItemStatus.absent).length;

  /// Passés, et ceux que la séance n'a pas atteints.
  int get skipped =>
      _with(SessionItemStatus.skipped).length +
      _with(SessionItemStatus.todo).length;

  int get resumable => queue
      .where((item) => item.status != SessionItemStatus.photographed)
      .length;

  @override
  List<Object?> get props => [klass, queue];
}
