import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_refusal.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_validation.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/audience_selections.dart';

/// Maintenant, ou à l'heure choisie.
enum AnnouncementSendMode { now, scheduled }

/// Le geste en cours : il désactive la barre d'actions.
enum AnnouncementEditorBusy { saving, scheduling, sending, cancelling }

/// Ce qui a abouti : la page revient à la liste et le dit.
enum AnnouncementEditorOutcome { draftSaved, scheduled, sent, cancelled }

/// Ce que l'éditeur affiche, au-dessus des sections.
enum AnnouncementEditorNotice {
  /// Le serveur avait une version plus récente : relue, saisie conservée.
  reloaded,

  /// Parti ou annulé entre-temps : il ne se modifie plus.
  notEditable,
}

class AnnouncementEditorState extends Equatable {
  /// L'UUID de la tablette, posé à l'ouverture et gardé jusqu'au bout.
  final String id;

  /// La copie serveur, `null` tant que le brouillon n'est pas créé.
  final Announcement? announcement;
  final AnnouncementContent content;

  /// Les sélections de chaque mode de ciblage ; `content.audience` est celle
  /// du mode actif.
  final AudienceSelections selections;
  final AnnouncementSendMode sendMode;

  /// L'instant UTC choisi pour un envoi programmé.
  final DateTime scheduledAt;

  /// Ce qui manque pour programmer ou envoyer, recalculé à chaque frappe.
  final List<AnnouncementIssue> issues;

  /// Les manques ne s'affichent qu'après un premier essai d'envoi.
  final bool showErrors;

  /// Les champs que le serveur a refusés, jusqu'à la prochaine frappe.
  final Set<AnnouncementField> serverFields;
  final AnnouncementEditorBusy? busy;

  /// Un échec qui n'est pas un refus de champ : le bandeau d'échec.
  final Failure? failure;

  /// Le geste qui a échoué : le bandeau le nomme, « Réessayer » le rejoue.
  final AnnouncementEditorBusy? failedGesture;
  final AnnouncementRefusal? refusal;
  final AnnouncementEditorNotice? notice;
  final AnnouncementEditorOutcome? outcome;

  /// Sans le droit d'envoyer : le communiqué se lit, rien ne s'y écrit.
  final bool readOnly;

  const AnnouncementEditorState({
    required this.id,
    required this.content,
    required this.scheduledAt,
    required this.selections,
    this.announcement,
    this.sendMode = AnnouncementSendMode.now,
    this.issues = const [],
    this.showErrors = false,
    this.serverFields = const {},
    this.busy,
    this.failure,
    this.failedGesture,
    this.refusal,
    this.notice,
    this.outcome,
    this.readOnly = false,
  });

  bool get isNew => announcement == null;

  /// Un communiqué que l'on ne peut plus que consulter.
  bool get isLocked =>
      readOnly || notice == AnnouncementEditorNotice.notEditable;

  /// Les manques à montrer, champ par champ.
  bool hasIssueOn(AnnouncementField field) =>
      serverFields.contains(field) ||
      (showErrors && issues.any((issue) => issue.field == field));

  AnnouncementEditorState copyWith({
    Announcement? announcement,
    AnnouncementContent? content,
    AudienceSelections? selections,
    AnnouncementSendMode? sendMode,
    DateTime? scheduledAt,
    List<AnnouncementIssue>? issues,
    bool? showErrors,
    Set<AnnouncementField>? serverFields,
    AnnouncementEditorBusy? busy,
    Failure? failure,
    AnnouncementEditorBusy? failedGesture,
    AnnouncementRefusal? refusal,
    AnnouncementEditorNotice? notice,
    AnnouncementEditorOutcome? outcome,
  }) => AnnouncementEditorState(
    id: id,
    announcement: announcement ?? this.announcement,
    content: content ?? this.content,
    selections: selections ?? this.selections,
    sendMode: sendMode ?? this.sendMode,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    issues: issues ?? this.issues,
    showErrors: showErrors ?? this.showErrors,
    serverFields: serverFields ?? this.serverFields,
    // Le geste, l'échec et le refus valent pour un essai : remis à zéro par
    // défaut, à chaque nouvel état.
    busy: busy,
    failure: failure,
    failedGesture: failedGesture,
    refusal: refusal,
    notice: notice ?? this.notice,
    outcome: outcome,
    readOnly: readOnly,
  );

  @override
  List<Object?> get props => [
    id,
    announcement,
    content,
    selections,
    sendMode,
    scheduledAt,
    issues,
    showErrors,
    serverFields,
    busy,
    failure,
    failedGesture,
    refusal,
    notice,
    outcome,
    readOnly,
  ];
}
