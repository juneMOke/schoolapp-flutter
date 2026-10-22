import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/attachments/attachment_availability.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/resource_sync_signals.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/attendance_justification.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/justification_enums.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/justification/attendance_justification_use_cases.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/bloc/justification_queue_state.dart';

/// Disciplines ▸ Justifications — la file des justifications d'absence
/// déposées par les parents.
///
/// Lecture locale, relue à chaque pull du flux et à chaque flush de l'outbox
/// (un accusé change la ligne).
class JustificationQueueCubit extends Cubit<JustificationQueueState> {
  final LoadAttendanceJustificationsUseCase _load;
  final DecideAttendanceJustificationUseCase _decide;
  final OpenJustificationAttachmentUseCase _attachment;
  final AcknowledgeJustificationNoticeUseCase _acknowledge;
  final ResourceSyncSignals _signals;
  final AttachmentAvailabilityTracker _availability;
  void Function()? _unwatch;
  void Function()? _unwatchRadio;

  /// Numéro de la dernière lecture lancée : une lecture plus ancienne qui
  /// répond après ne doit pas écraser la plus récente.
  int _read = 0;

  JustificationQueueCubit({
    required LoadAttendanceJustificationsUseCase load,
    required DecideAttendanceJustificationUseCase decide,
    required OpenJustificationAttachmentUseCase attachment,
    required AcknowledgeJustificationNoticeUseCase acknowledge,
    required ResourceSyncSignals signals,
    required AttachmentAvailabilityTracker availability,
  }) : _load = load,
       _decide = decide,
       _attachment = attachment,
       _acknowledge = acknowledge,
       _signals = signals,
       _availability = availability,
       super(const JustificationQueueState());

  /// Ouvre la file sur l'année ; la descente du flux part en même temps.
  Future<void> setAcademicYear(String academicYearId) async {
    _unwatch ??= _signals.watch(() => unawaited(refresh()));
    _unwatchRadio ??= _availability.watch((online) {
      if (!isClosed) {
        emit(state.copyWith(attachments: state.attachments.withOnline(online)));
      }
    });
    if (academicYearId == state.academicYearId && !state.isLoading) return;
    emit(
      state.copyWith(
        academicYearId: academicYearId,
        load: JustificationQueueLoad.loading,
      ),
    );
    unawaited(_signals.pull());
    await refresh();
  }

  Future<void> refresh() async {
    final year = state.academicYearId;
    if (year == null) return;
    final read = ++_read;
    final result = await _load(year);
    if (isClosed || read != _read) return;
    result.fold(
      (failure) {
        // Une relecture qui échoue ne remplace pas une file déjà montrée.
        if (state.load == JustificationQueueLoad.ready) return;
        emit(
          state.copyWith(
            load: JustificationQueueLoad.failure,
            failure: failure,
          ),
        );
      },
      (all) => emit(
        state.copyWith(
          load: JustificationQueueLoad.ready,
          all: all,
          decidedElsewhere: all.where((j) => j.decidedElsewhere).toList(),
        ),
      ),
    );
    final refs = [for (final j in state.all) ?j.attachment];
    final attachments = await _availability.snapshot(refs);
    if (isClosed || read != _read) return;
    emit(state.copyWith(attachments: attachments));
  }

  void setFilter(JustificationQueueFilter filter) =>
      emit(state.copyWith(filter: filter));

  /// L'annonce « tranchée par un autre poste » a été faite : elle ne revient
  /// pas, ni ici ni à la prochaine ouverture.
  Future<void> acknowledgeDecidedElsewhere() async {
    final shown = state.decidedElsewhere;
    if (shown.isEmpty) return;
    emit(state.copyWith(decidedElsewhere: const []));
    for (final justification in shown) {
      await _acknowledge(justification.id);
    }
  }

  Future<Either<Failure, Unit>> decide(
    AttendanceJustification justification,
    JustificationDecision decision, {
    String? note,
  }) async {
    final result = await _decide(justification, decision, note: note);
    await refresh();
    return result;
  }

  /// Les octets de la pièce ; une pièce obtenue reste ouvrable hors ligne
  /// jusqu'à la fin de la session.
  Future<Either<Failure, Uint8List>> attachment(
    AttendanceJustification justification,
  ) async {
    final result = await _attachment(justification);
    final ref = justification.attachment;
    if (result.isRight() && ref != null && !isClosed) {
      emit(
        state.copyWith(attachments: state.attachments.withCached(ref.sha256)),
      );
    }
    return result;
  }

  @override
  Future<void> close() {
    _unwatch?.call();
    _unwatchRadio?.call();
    return super.close();
  }
}
