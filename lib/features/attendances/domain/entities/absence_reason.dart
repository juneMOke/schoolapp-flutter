import 'package:school_app_flutter/l10n/app_localizations.dart';

enum AbsenceReason {
  sickness,
  familyEmergency,
  personal,
  unknown,
  vacation,
  underGraduateLeave,
  marriageLeave,
  parentalLeave,
  workLeave,
  unjustified,
  other,
}

extension AbsenceReasonX on AbsenceReason {
  static AbsenceReason? fromApiValue(String? value) {
    if (value == null) return null;
    return switch (value.toUpperCase()) {
      'SICKNESS' => AbsenceReason.sickness,
      'FAMILY_EMERGENCY' => AbsenceReason.familyEmergency,
      'PERSONAL' => AbsenceReason.personal,
      'UNKNOWN' => AbsenceReason.unknown,
      'VACATION' => AbsenceReason.vacation,
      'UNDER_GRADUATE_LEAVE' => AbsenceReason.underGraduateLeave,
      'MARRIAGE_LEAVE' => AbsenceReason.marriageLeave,
      'PARENTAL_LEAVE' => AbsenceReason.parentalLeave,
      'WORK_LEAVE' => AbsenceReason.workLeave,
      'UNJUSTIFIED' => AbsenceReason.unjustified,
      'OTHER' => AbsenceReason.other,
      // Parsing défensif (invariant #9) : un motif ENRICHI côté back mais inconnu
      // de cette tablette retombe sur `OTHER`, jamais une exception. Distinct de
      // `UNKNOWN` (valeur cataloguée = motif inconnu à la saisie). Sans ça,
      // ajouter un motif ferait tomber les tablettes non redéployées.
      _ => AbsenceReason.other,
    };
  }

  String toApiValue() => switch (this) {
    AbsenceReason.sickness => 'SICKNESS',
    AbsenceReason.familyEmergency => 'FAMILY_EMERGENCY',
    AbsenceReason.personal => 'PERSONAL',
    AbsenceReason.unknown => 'UNKNOWN',
    AbsenceReason.vacation => 'VACATION',
    AbsenceReason.underGraduateLeave => 'UNDER_GRADUATE_LEAVE',
    AbsenceReason.marriageLeave => 'MARRIAGE_LEAVE',
    AbsenceReason.parentalLeave => 'PARENTAL_LEAVE',
    AbsenceReason.workLeave => 'WORK_LEAVE',
    AbsenceReason.unjustified => 'UNJUSTIFIED',
    AbsenceReason.other => 'OTHER',
  };

  /// Libelle localise du motif (reutilise les cles `absenceReason*`).
  String getDisplayName(AppLocalizations l10n) => switch (this) {
    AbsenceReason.sickness => l10n.absenceReasonSickness,
    AbsenceReason.familyEmergency => l10n.absenceReasonFamilyEmergency,
    AbsenceReason.personal => l10n.absenceReasonPersonal,
    AbsenceReason.unknown => l10n.absenceReasonUnknown,
    AbsenceReason.vacation => l10n.absenceReasonVacation,
    AbsenceReason.underGraduateLeave => l10n.absenceReasonUnderGraduateLeave,
    AbsenceReason.marriageLeave => l10n.absenceReasonMarriageLeave,
    AbsenceReason.parentalLeave => l10n.absenceReasonParentalLeave,
    AbsenceReason.workLeave => l10n.absenceReasonWorkLeave,
    AbsenceReason.unjustified => l10n.absenceReasonUnjustified,
    AbsenceReason.other => l10n.absenceReasonOther,
  };
}

/// Le verdict d'une absence : injustifiée, ou justifiée.
///
/// `unknown` = motif non connu au moment de la saisie (transitoire) ;
/// `unjustified` = verdict rendu après coup, aucune justification produite ;
/// **motif absent** (`null`) = injustifiée aussi. Tout autre motif renseigné
/// justifie l'absence.
///
/// ## Pourquoi la fonction prend un `AbsenceReason?`
///
/// C'est le cœur du défaut qu'elle corrige. La règle vivait sur un getter
/// d'extension, qui ne pouvait pas être appelé sur un motif absent : chaque
/// appelant devait donc décider lui-même du sort de `null`, et les quatre l'ont
/// décidé différemment — deux le rangeaient du côté justifié, un du côté
/// injustifié, un l'excluait des deux. Une signature qui refuse `null` ne
/// centralise rien : elle délègue la moitié de la question.
///
/// ## L'accord avec le serveur n'est pas décoratif
///
/// La synthèse d'un élève se calcule **en local** et les KPIs du tableau de bord
/// viennent du **serveur** : les deux doivent rendre le même chiffre sur la même
/// période, sinon le produit se contredit d'un écran à l'autre. Le miroir de
/// cette fonction côté back est `AbsenceReason.isUnjustified` (dépôt
/// `eteelo-backend`) ; les deux ne bougent qu'ensemble.
///
/// ⚠️ L'écran d'appel est la seule exception, et elle est délibérée : il
/// **interdit** d'enregistrer une absence sans motif, donc « sans motif » y est
/// un état de saisie en cours, jamais un verdict. Il écarte `null` avant
/// d'appeler cette fonction et le compte à part.
bool isUnjustifiedAbsence(AbsenceReason? reason) =>
    reason == null ||
    reason == AbsenceReason.unjustified ||
    reason == AbsenceReason.unknown;

/// Les motifs proposés **à la saisie**, dans l'ordre d'affichage.
///
/// ## Catalogue de transport ≠ liste de saisie
///
/// [AbsenceReason] est le catalogue du contrat : onze valeurs, que le parc lit
/// et écrit déjà, et dont aucune n'est retirée — supprimer une valeur ferait
/// tomber sur le repli défensif des données parfaitement valides. Ce que l'UI
/// propose est autre chose, et c'est cette liste-ci.
///
/// ## Ce qui en sort, et pourquoi
///
/// Cinq valeurs sont des congés de **salarié** — vacances, congé d'études, de
/// mariage, parental, professionnel. Elles n'ont pas de sens pour un élève, et
/// l'écran les offrait parce qu'il rendait `AbsenceReason.values` brut.
///
/// `unjustified` en sort aussi, mais pour la raison inverse : ce n'est pas un
/// motif, c'est un **verdict**. Des lignes le portent déjà, il reste donc au
/// catalogue et s'affiche normalement — il n'est simplement plus écrit à neuf.
///
/// ## Ce qui y reste, et qui porte le verdict
///
/// `unknown` **reste proposé**, et c'est lui qui vaut « pas justifiée » (cf.
/// [isUnjustifiedAbsence]). Sans lui, plus aucune valeur du côté injustifié ne
/// serait atteignable — l'appel interdisant déjà d'enregistrer sans motif — et
/// le taux d'absences injustifiées tendrait vers zéro : un indicateur qui
/// affiche encore un chiffre tout en ne mesurant plus rien.
///
/// ⚠️ Son libellé dit « Non justifiée », pas « Inconnu ». La valeur technique
/// parle d'ignorance, l'écran doit parler du verdict : un enseignant qui croit
/// noter qu'il ne sait pas ne saurait pas qu'il tranche, et le KPI se lirait sur
/// un haussement d'épaules.
///
/// Le verdict se corrige après coup **sans écran neuf** : on rouvre l'appel du
/// jour concerné (le sélecteur de date couvre deux ans en arrière) et on pose le
/// vrai motif.
const List<AbsenceReason> kSelectableAbsenceReasons = [
  AbsenceReason.sickness,
  AbsenceReason.familyEmergency,
  AbsenceReason.personal,
  AbsenceReason.other,
  AbsenceReason.unknown,
];
