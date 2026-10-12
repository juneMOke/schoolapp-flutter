import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/audience_student.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_channel.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_refusal.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_validation.dart';
import 'package:school_app_flutter/features/communication/domain/usecases/announcement_writer.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_state.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/audience_selections.dart';

/// L'éditeur d'un communiqué : nouveau, brouillon, programmé ou échec.
///
/// Il ne juge que ce que la tablette sait juger (champs vides, variables,
/// moment passé) ; le reste, c'est le serveur qui le dit, et l'éditeur le
/// range sous le champ qu'il désigne ou dans le bandeau.
class AnnouncementEditorCubit extends Cubit<AnnouncementEditorState> {
  final AnnouncementWriter _writer;
  final DateTime Function() _now;
  final String? _academicYearId;

  AnnouncementEditorCubit._(
    super.initial, {
    required AnnouncementWriter writer,
    required DateTime Function() now,
    String? academicYearId,
  }) : _writer = writer,
       _now = now,
       _academicYearId = academicYearId;

  /// Un communiqué neuf, vide ou pré-rempli ([seed] : un modèle, un double).
  factory AnnouncementEditorCubit.create({
    required String id,
    required AnnouncementWriter writer,
    AnnouncementContent seed = const AnnouncementContent(),
    String? academicYearId,
    DateTime Function() now = DateTime.now,
  }) => AnnouncementEditorCubit._(
    _initial(id: id, content: seed, now: now()),
    writer: writer,
    now: now,
    academicYearId: academicYearId,
  );

  /// Un communiqué existant, rouvert.
  factory AnnouncementEditorCubit.edit({
    required Announcement announcement,
    required AnnouncementWriter writer,
    bool readOnly = false,
    DateTime Function() now = DateTime.now,
  }) => AnnouncementEditorCubit._(
    _initial(
      id: announcement.id,
      content: announcement.content,
      now: now(),
      announcement: announcement,
      readOnly: readOnly,
    ),
    writer: writer,
    now: now,
    academicYearId: announcement.academicYearId,
  );

  static AnnouncementEditorState _initial({
    required String id,
    required AnnouncementContent content,
    required DateTime now,
    Announcement? announcement,
    bool readOnly = false,
  }) {
    final scheduled = announcement?.status == AnnouncementStatus.scheduled
        ? announcement?.scheduledAt
        : null;
    return AnnouncementEditorState(
      id: id,
      announcement: announcement,
      content: content,
      selections: AudienceSelections.of(content.audience),
      sendMode: scheduled == null
          ? AnnouncementSendMode.now
          : AnnouncementSendMode.scheduled,
      scheduledAt: scheduled ?? defaultScheduleFor(now),
      issues: AnnouncementValidation.issuesOf(content),
      readOnly: readOnly,
    );
  }

  /// Le lendemain, 07:30 à l'heure de l'école.
  static DateTime defaultScheduleFor(DateTime now) => SchoolTime.instantAt(
    day: SchoolTime.today(now).add(const Duration(days: 1)),
    hour: 7,
    minute: 30,
  );

  // ── Saisie ──

  void setCategory(AnnouncementCategory category) =>
      _edit(state.content.copyWith(category: category));

  void setTitle(String title) => _edit(state.content.copyWith(title: title));

  void setBody(String body) => _edit(state.content.copyWith(body: body));

  void setAudienceMode(AudienceMode mode) =>
      _select(state.selections.withMode(mode));

  void toggleLevel(String id) => _select(state.selections.toggleLevel(id));

  void toggleClassroom(String id) =>
      _select(state.selections.toggleClassroom(id));

  void toggleClassrooms(List<String> ids) =>
      _select(state.selections.toggleClassrooms(ids));

  void addStudent(AudienceStudent student) =>
      _select(state.selections.addStudent(student));

  void removeStudent(String id) => _select(state.selections.removeStudent(id));

  void setOverdueFee(String? feeCode, {String? tariffCode}) =>
      _select(state.selections.withFee(feeCode, tariffCode: tariffCode));

  void setOverdueDays(int days) =>
      _select(state.selections.withOverdueDays(days));

  void _select(AudienceSelections selections) => _emitEdited(
    state.copyWith(
      selections: selections,
      content: state.content.copyWith(audience: selections.audience),
    ),
  );

  void toggleChannel(AnnouncementChannel channel) {
    final channels = state.content.channels;
    _edit(
      state.content.copyWith(
        channels: channels.contains(channel)
            ? [
                for (final c in channels)
                  if (c != channel) c,
              ]
            : [...channels, channel],
      ),
    );
  }

  void setSendMode(AnnouncementSendMode mode) =>
      _emitEdited(state.copyWith(sendMode: mode));

  void setScheduledAt(DateTime instant) =>
      _emitEdited(state.copyWith(scheduledAt: instant.toUtc()));

  void _edit(AnnouncementContent content) =>
      _emitEdited(state.copyWith(content: content));

  /// Une frappe efface ce que le serveur avait refusé : son verdict valait
  /// pour l'ancien texte.
  void _emitEdited(AnnouncementEditorState next) =>
      emit(next.copyWith(issues: _issuesOf(next), serverFields: const {}));

  List<AnnouncementIssue> _issuesOf(AnnouncementEditorState s) =>
      AnnouncementValidation.issuesOf(
        s.content,
        scheduledAt: s.sendMode == AnnouncementSendMode.scheduled
            ? s.scheduledAt
            : null,
        now: _now(),
      );

  // ── Gestes ──

  /// Un brouillon s'enregistre dès qu'il a un titre ou un message.
  Future<void> saveDraft() async {
    if (!AnnouncementValidation.canSaveDraft(state.content)) {
      emit(state.copyWith(showErrors: true));
      return;
    }
    await _run(
      AnnouncementEditorBusy.saving,
      AnnouncementEditorOutcome.draftSaved,
      () => _writer.saveDraft(
        id: state.id,
        content: state.content,
        current: state.announcement,
        academicYearId: _academicYearId,
        onStep: _track,
      ),
    );
  }

  /// Vrai si le communiqué peut partir (ou être programmé) tel quel ; sinon
  /// les manques s'affichent sous leurs champs.
  bool validateForSubmit() {
    final issues = _issuesOf(state);
    emit(state.copyWith(issues: issues, showErrors: true));
    return issues.isEmpty;
  }

  /// Envoie maintenant ou programme, selon le mode choisi.
  Future<void> submit() async {
    if (!validateForSubmit()) return;
    if (state.sendMode == AnnouncementSendMode.scheduled) {
      final at = state.scheduledAt;
      await _run(
        AnnouncementEditorBusy.scheduling,
        AnnouncementEditorOutcome.scheduled,
        () => _writer.schedule(
          id: state.id,
          content: state.content,
          scheduledAt: at,
          current: state.announcement,
          academicYearId: _academicYearId,
          onStep: _track,
        ),
      );
      return;
    }
    await _run(
      AnnouncementEditorBusy.sending,
      AnnouncementEditorOutcome.sent,
      () => _writer.send(
        id: state.id,
        content: state.content,
        current: state.announcement,
        academicYearId: _academicYearId,
        onStep: _track,
      ),
    );
  }

  /// Rejoue le geste qui a échoué. Sans danger : l'id vient de la tablette et
  /// un envoi rejoué sur un communiqué parti ne renvoie rien aux familles.
  Future<void> retry() => switch (state.failedGesture) {
    AnnouncementEditorBusy.saving => saveDraft(),
    AnnouncementEditorBusy.scheduling ||
    AnnouncementEditorBusy.sending => submit(),
    AnnouncementEditorBusy.cancelling => cancel(),
    null => Future.value(),
  };

  /// Supprime un brouillon, ou annule un envoi programmé.
  Future<void> cancel() async {
    final current = state.announcement;
    if (current == null) return;
    await _run(
      AnnouncementEditorBusy.cancelling,
      AnnouncementEditorOutcome.cancelled,
      () => _writer.cancel(current),
    );
  }

  /// Une étape intermédiaire a réussi : la copie serveur avance, le geste
  /// continue.
  void _track(Announcement announcement) {
    if (isClosed) return;
    emit(state.copyWith(announcement: announcement, busy: state.busy));
  }

  Future<void> _run(
    AnnouncementEditorBusy busy,
    AnnouncementEditorOutcome outcome,
    Future<Either<Failure, Announcement>> Function() call,
  ) async {
    if (state.busy != null || state.isLocked) return;
    emit(state.copyWith(busy: busy));
    final result = await call();
    if (isClosed) return;
    await result.fold(
      (failure) => _refused(failure, busy),
      (announcement) async =>
          emit(state.copyWith(announcement: announcement, outcome: outcome)),
    );
  }

  /// Un refus de champ va sous le champ ; une version périmée ou un
  /// communiqué déjà parti fait relire l'état serveur, saisie conservée.
  Future<void> _refused(Failure failure, AnnouncementEditorBusy gesture) async {
    final refusal = AnnouncementRefusal.of(failure);
    if (refusal == AnnouncementRefusal.stale ||
        refusal == AnnouncementRefusal.notEditable) {
      final fresh = await _writer.reload(state.id);
      if (isClosed) return;
      final announcement = fresh.fold((_) => null, (value) => value);
      final locked =
          refusal == AnnouncementRefusal.notEditable ||
          (announcement != null && !announcement.status.canSend);
      emit(
        state.copyWith(
          announcement: announcement,
          notice: locked
              ? AnnouncementEditorNotice.notEditable
              : AnnouncementEditorNotice.reloaded,
          refusal: refusal,
        ),
      );
      return;
    }
    final fields = AnnouncementRefusal.fieldsOf(failure);
    emit(
      state.copyWith(
        showErrors: true,
        serverFields: fields,
        // Un refus nommé sur un champ se lit sous le champ : le bandeau reste
        // aux échecs qui ne désignent rien à corriger dans la saisie.
        failure: fields.isEmpty ? failure : null,
        failedGesture: fields.isEmpty ? gesture : null,
        refusal: refusal,
      ),
    );
  }
}
