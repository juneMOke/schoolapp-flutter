import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_refusal.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_state.dart';

/// Ce que l'éditeur devient après un échec de geste — sans appel, sans état :
/// le cubit relit le serveur quand il le faut, ces fonctions décident.
abstract final class EditorRefusals {
  /// Le refus impose-t-il de relire le communiqué avant de conclure ?
  static bool needsReload(Failure failure) =>
      switch (AnnouncementRefusal.of(failure)) {
        AnnouncementRefusal.stale || AnnouncementRefusal.notEditable => true,
        _ => false,
      };

  /// Un refus de champ va sous le champ ; le reste, au bandeau.
  static AnnouncementEditorState refused(
    AnnouncementEditorState state,
    Failure failure,
    AnnouncementEditorBusy gesture,
  ) {
    final fields = AnnouncementRefusal.fieldsOf(failure);
    return state.copyWith(
      showErrors: true,
      serverFields: fields,
      failure: fields.isEmpty ? failure : null,
      failedGesture: fields.isEmpty ? gesture : null,
      refusal: AnnouncementRefusal.of(failure),
    );
  }

  /// Après relecture ([fresh], `null` si elle a échoué aussi).
  ///
  /// Un geste dont la réponse s'est perdue a pu aboutir : rejoué, il est
  /// refusé alors que le serveur est déjà là où l'on voulait aller. On le
  /// constate sur l'état relu, plutôt que de verrouiller à tort.
  static AnnouncementEditorState afterReload(
    AnnouncementEditorState state,
    Failure failure,
    AnnouncementEditorBusy gesture,
    Announcement? fresh,
  ) {
    final refusal = AnnouncementRefusal.of(failure);
    if (fresh == null) {
      return state.copyWith(
        failure: failure,
        failedGesture: gesture,
        refusal: refusal,
      );
    }
    final reached = _reached(state, gesture, fresh);
    if (reached != null) {
      return state.copyWith(announcement: fresh, outcome: reached);
    }
    final gone =
        fresh.status == AnnouncementStatus.sent ||
        fresh.status == AnnouncementStatus.cancelled;
    return state.copyWith(
      announcement: fresh,
      notice: gone
          ? AnnouncementEditorNotice.notEditable
          : AnnouncementEditorNotice.reloaded,
      refusal: refusal,
    );
  }

  static AnnouncementEditorOutcome? _reached(
    AnnouncementEditorState state,
    AnnouncementEditorBusy gesture,
    Announcement fresh,
  ) => switch (gesture) {
    AnnouncementEditorBusy.sending
        when fresh.status == AnnouncementStatus.sent =>
      AnnouncementEditorOutcome.sent,
    AnnouncementEditorBusy.scheduling
        when fresh.status == AnnouncementStatus.scheduled &&
            fresh.scheduledAt?.toUtc() == state.scheduledAt.toUtc() &&
            fresh.content.sameAs(state.content) =>
      AnnouncementEditorOutcome.scheduled,
    AnnouncementEditorBusy.cancelling
        when fresh.status == AnnouncementStatus.cancelled =>
      AnnouncementEditorOutcome.cancelled,
    AnnouncementEditorBusy.saving
        when fresh.status == AnnouncementStatus.draft &&
            fresh.content.sameAs(state.content) =>
      AnnouncementEditorOutcome.draftSaved,
    _ => null,
  };
}
