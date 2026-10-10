import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';

enum JournalEntryStatus { loading, editing, saving, saved, cleared }

/// La modale d'une séance : le chapitre choisi, les sept champs, et la
/// micro-machine d'édition (chargement → saisie → enregistrement).
class JournalEntryState extends Equatable {
  final JournalEntryStatus status;
  final List<Chapitre> chapters;

  /// `null` : hors programme.
  final String? chapitreId;
  final JournalFields fields;

  /// Augmente quand les champs changent sans la frappe (ouverture,
  /// préremplissage) : les champs de saisie s'y resynchronisent.
  final int revision;

  /// Les erreurs des champs requis ne s'affichent qu'après une tentative.
  final bool showErrors;

  /// Le nombre d'enregistrements refusés : chacun ramène le focus sur le
  /// premier champ requis vide.
  final int refusals;

  /// Le chapitre a changé sur une saisie déjà commencée : rien n'a été
  /// écrasé, « Reprendre du chapitre » le propose.
  final bool canApplyChapter;

  /// L'écriture locale a échoué : la modale reste ouverte, saisie conservée.
  final Failure? failure;

  const JournalEntryState({
    this.status = JournalEntryStatus.loading,
    this.chapters = const [],
    this.chapitreId,
    this.fields = JournalFields.empty,
    this.revision = 0,
    this.showErrors = false,
    this.refusals = 0,
    this.canApplyChapter = false,
    this.failure,
  });

  bool get isBusy =>
      status == JournalEntryStatus.loading ||
      status == JournalEntryStatus.saving;

  JournalEntryState copyWith({
    JournalEntryStatus? status,
    List<Chapitre>? chapters,
    String? Function()? chapitreId,
    JournalFields? fields,
    int? revision,
    bool? showErrors,
    int? refusals,
    bool? canApplyChapter,
    Failure? Function()? failure,
  }) => JournalEntryState(
    status: status ?? this.status,
    chapters: chapters ?? this.chapters,
    chapitreId: chapitreId == null ? this.chapitreId : chapitreId(),
    fields: fields ?? this.fields,
    revision: revision ?? this.revision,
    showErrors: showErrors ?? this.showErrors,
    refusals: refusals ?? this.refusals,
    canApplyChapter: canApplyChapter ?? this.canApplyChapter,
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [
    status,
    chapters,
    chapitreId,
    fields,
    revision,
    showErrors,
    refusals,
    canApplyChapter,
    failure,
  ];
}
