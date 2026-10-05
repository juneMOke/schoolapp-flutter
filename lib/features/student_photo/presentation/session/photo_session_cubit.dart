import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/capture/camera/camera_viewfinder_gateway.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/capture/document_capture_gateway.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/crop_window.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/photo_session.dart';
import 'package:school_app_flutter/features/student_photo/domain/usecases/load_photo_session_classes_use_case.dart';
import 'package:school_app_flutter/features/student_photo/domain/services/square_photo_encoder.dart';
import 'package:school_app_flutter/features/student_photo/domain/usecases/student_photo_use_cases.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/camera_opener.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/session_camera_control.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/session_queue.dart';

/// La séance photo d'une classe : choisir la classe, photographier en rafale
/// (recadrage automatique sur le guide ovale), puis le bilan.
///
/// Chaque photo est gardée sur le poste dès la prise et part par l'outbox :
/// hors connexion, la séance continue.
class PhotoSessionCubit extends Cubit<PhotoSessionState>
    with SessionCameraControl {
  final LoadPhotoSessionClassesUseCase _classes;
  final SaveStudentPhotoUseCase _save;
  final SquarePhotoEncoder _encoder;
  final CameraViewfinderGateway _cameras;
  final DocumentCaptureGateway _files;
  final DateTime Function() _now;

  PhotoSessionCubit({
    required LoadPhotoSessionClassesUseCase classes,
    required SaveStudentPhotoUseCase save,
    required SquarePhotoEncoder encoder,
    required CameraViewfinderGateway cameras,
    required DocumentCaptureGateway files,
    DateTime Function()? now,
  }) : _classes = classes,
       _save = save,
       _encoder = encoder,
       _cameras = cameras,
       _files = files,
       _now = now ?? DateTime.now,
       super(const SessionLoading());

  @override
  CameraOpener? opener;

  /// Les classes de l'année, chacune avec ses élèves sans photo.
  Future<void> load(String academicYearId, {required bool isTouch}) async {
    opener ??= CameraOpener(_cameras, isTouch: isTouch);
    emit(const SessionLoading());
    final result = await _classes(academicYearId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(SessionLoadFailed(failure)),
      (summaries) => emit(SessionSetup(classes: summaries)),
    );
  }

  void selectClass(String classId) {
    final current = state;
    if (current is SessionSetup) emit(current.copyWith(selectedId: classId));
  }

  void setOnlyMissing(bool value) {
    final current = state;
    if (current is SessionSetup) emit(current.copyWith(onlyMissing: value));
  }

  /// « Commencer » : la file de la classe choisie, et la caméra.
  Future<void> start() async {
    final setup = state;
    if (setup is! SessionSetup) return;
    final summary = setup.selected;
    if (summary == null || setup.startCount == 0) return;
    final students = [
      for (final student in summary.students)
        if (!setup.onlyMissing || !summary.withPhoto.contains(student.id))
          student,
    ]..sort((a, b) => SessionQueue.order(a, b, summary.withPhoto));
    emit(
      SessionShooting(
        klass: summary.klass,
        queue: [for (final student in students) SessionItem(student)],
        index: 0,
      ),
    );
    await openCamera();
  }

  /// Déclenche : recadrage automatique sur l'ovale, photo gardée, flash.
  Future<void> shoot() async {
    final current = state;
    if (current is! SessionShooting || current.busy || current.flash != null) {
      return;
    }
    final camera = current.camera;
    if (camera is! CameraOpened) return;
    emit(current.copyWith(busy: true));
    final takenAt = _now();
    try {
      final bytes = await camera.session.capture();
      await _keep(
        bytes,
        takenAt,
        mirror: camera.session.lens.mirrors,
        guided: true,
      );
    } catch (_) {
      _release();
    }
  }

  /// Importer un fichier pour l'élève courant : même recadrage, même flash.
  Future<void> importForCurrent() async {
    final current = state;
    if (current is! SessionShooting || current.busy) return;
    final RawCapture? raw;
    try {
      raw = await _files.acquire(DocumentCaptureMode.importImage);
    } catch (_) {
      return;
    }
    if (raw == null) return;
    emit((state as SessionShooting).copyWith(busy: true));
    try {
      await _keep(raw.bytes, _now(), mirror: false, guided: false);
    } catch (_) {
      _release();
    }
  }

  void _release() {
    final current = state;
    if (!isClosed && current is SessionShooting) {
      emit(current.copyWith(busy: false));
    }
  }

  Future<void> _keep(
    Uint8List bytes,
    DateTime takenAt, {
    required bool mirror,
    required bool guided,
  }) async {
    final size = await _encoder.measure(bytes);
    final window = guided
        ? CropWindow.ovalGuide(size.width, size.height)
        : CropWindow.centered(size.width, size.height);
    final square = await _encoder.encode(bytes, window, mirror: mirror);
    final current = state;
    if (isClosed || current is! SessionShooting) return;
    final studentId = current.current.student.id;
    final saved = await _save(
      studentId: studentId,
      jpeg: square,
      takenAt: takenAt,
    );
    if (isClosed || state is! SessionShooting) return;
    final shooting = state as SessionShooting;
    if (saved.isLeft()) {
      emit(shooting.copyWith(busy: false));
      return;
    }
    emit(
      shooting.copyWith(
        busy: false,
        queue: SessionQueue.withStatus(
          shooting.queue,
          shooting.index,
          SessionItemStatus.photographed,
        ),
        flash: SessionFlash(photo: square, studentId: studentId),
      ),
    );
  }

  /// Le flash a duré : élève suivant (le prochain encore à photographier).
  Future<void> advance() async {
    final current = state;
    if (current is! SessionShooting) return;
    final next = SessionQueue.nextTodo(current.queue, current.index);
    if (next == null) {
      await finish();
      return;
    }
    emit(current.copyWith(index: next, clearFlash: true));
  }

  /// « Reprendre » sur le flash : on reste sur l'élève, la prochaine prise
  /// remplacera la photo.
  void retakeCurrent() {
    final current = state;
    if (current is! SessionShooting) return;
    emit(
      current.copyWith(
        clearFlash: true,
        queue: SessionQueue.withStatus(
          current.queue,
          current.index,
          SessionItemStatus.todo,
        ),
      ),
    );
  }

  Future<void> markCurrent(SessionItemStatus status) async {
    final current = state;
    if (current is! SessionShooting || current.busy) return;
    emit(
      current.copyWith(
        queue: SessionQueue.withStatus(current.queue, current.index, status),
        clearFlash: true,
      ),
    );
    await advance();
  }

  Future<void> skip() => markCurrent(SessionItemStatus.skipped);
  Future<void> markAbsent() => markCurrent(SessionItemStatus.absent);

  /// Toucher un élève de la file le rend courant — sauf s'il est déjà
  /// photographié.
  void select(int index) {
    final current = state;
    if (current is! SessionShooting || current.busy) return;
    if (current.queue[index].status == SessionItemStatus.photographed) return;
    emit(current.copyWith(index: index, clearFlash: true));
  }

  /// « Terminer » : la caméra s'éteint, le bilan s'affiche.
  Future<void> finish() async {
    final current = state;
    // Une photo en préparation se termine d'abord : elle serait sinon gardée
    // sans compter au bilan.
    if (current is! SessionShooting || current.busy) return;
    await opener?.release();
    if (!isClosed) {
      emit(SessionSummary(klass: current.klass, queue: current.queue));
    }
  }

  /// « Reprendre absents & passés » : ils redeviennent à photographier.
  Future<void> resume() async {
    final current = state;
    if (current is! SessionSummary) return;
    final queue = [
      for (final item in current.queue)
        item.status == SessionItemStatus.photographed
            ? item
            : item.withStatus(SessionItemStatus.todo),
    ];
    final first = queue.indexWhere((i) => i.status == SessionItemStatus.todo);
    if (first < 0) return;
    emit(SessionShooting(klass: current.klass, queue: queue, index: first));
    await openCamera();
  }

  @override
  Future<void> close() async {
    await opener?.release();
    return super.close();
  }
}
