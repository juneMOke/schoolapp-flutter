import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les libellés qui dépendent du découpage de la classe.
abstract final class CoteLabels {
  /// « S1 » ou « T1 ».
  static String groupShort(
    AppLocalizations l10n,
    Decoupage decoupage,
    int ordre,
  ) => decoupage == Decoupage.trimestre
      ? l10n.coteGroupShortTrimester(ordre)
      : l10n.coteGroupShortSemester(ordre);

  /// Le groupe de la première colonne : « S1 », jamais son numéro de période.
  static String firstGroupShort(
    AppLocalizations l10n,
    CoteClasse classe,
    List<CoteColumn> columns,
  ) {
    if (columns.isEmpty) return '';
    final periodeId = columns.first.periodeId;
    final group = classe.periodes.where((p) => p.id == periodeId).firstOrNull;
    return group == null ? '' : groupShort(l10n, classe.decoupage, group.ordre);
  }

  static String _periodeLibelle(CoteClasse classe, String periodeId) => classe
      .periodes
      .firstWhere((p) => p.id == periodeId, orElse: () => classe.periodes.first)
      .libelle;

  /// L'en-tête de colonne : « P3 », « Exam. », « Tot. S1 ».
  static String columnShort(
    AppLocalizations l10n,
    Decoupage decoupage,
    CoteColumn column,
  ) => switch (column.kind) {
    CoteColumnKind.periode => l10n.coteColumnPeriod(column.numero),
    CoteColumnKind.examen => l10n.coteColumnExam,
    CoteColumnKind.totalGroupe => l10n.coteColumnTotalOf(
      groupShort(l10n, decoupage, column.numero),
    ),
  };

  /// La puce d'une cible : « P3 », « Examen S1 ».
  static String columnChip(
    AppLocalizations l10n,
    Decoupage decoupage,
    CoteColumn column,
  ) => column.isExamen
      ? l10n.coteColumnExamOf(groupShort(l10n, decoupage, column.numero))
      : columnShort(l10n, decoupage, column);

  /// L'info-bulle et le lecteur d'écran : « 2e période », « Examen · Semestre 1 ».
  static String columnLong(
    AppLocalizations l10n,
    CoteClasse classe,
    CoteColumn column,
  ) => switch (column.kind) {
    CoteColumnKind.periode => l10n.coteColumnPeriodLong(column.numero),
    CoteColumnKind.examen => l10n.coteColumnExamLong(
      _periodeLibelle(classe, column.periodeId),
    ),
    CoteColumnKind.totalGroupe => l10n.coteColumnTotalLong(
      _periodeLibelle(classe, column.periodeId),
    ),
  };

  /// La portée en clair, pour les sous-titres.
  static String scope(
    AppLocalizations l10n,
    CoteClasse classe,
    CoteScope scope,
    List<CoteColumn> columns,
  ) => switch (scope.portee) {
    CotePortee.annee =>
      classe.decoupage == Decoupage.trimestre
          ? l10n.cotePorteeLesTrimestres
          : l10n.cotePorteeLesSemestres,
    CotePortee.groupe => _periodeLibelle(classe, scope.cibleId ?? ''),
    CotePortee.colonne =>
      columns.isEmpty ? '' : columnLong(l10n, classe, columns.first),
  };

  static String rejection(AppLocalizations l10n, String? reason) =>
      switch (reason) {
        'PERIODE_CLOSE' => l10n.coteRejectedClosed,
        'OUT_OF_RANGE' => l10n.coteRejectedRange,
        'NO_EXAM' => l10n.coteRejectedNoExam,
        'STUDENT_NOT_IN_CLASS' => l10n.coteRejectedStudent,
        'UNKNOWN_COLUMN' => l10n.coteRejectedColumn,
        _ => l10n.coteRejectedOther,
      };
}
