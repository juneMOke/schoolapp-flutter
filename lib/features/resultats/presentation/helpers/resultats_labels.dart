import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/periode_scolaire.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Libellés et formats localisés du module résultats (centralisés pour garder
/// une cohérence entre la carte de recherche, la table, la synthèse et le focus).

/// Libellé court d'une grande période : « T1 » / « S1 » (spec table & pilules).
String resultatsPeriodShort(AppLocalizations l10n, PeriodeScolaire periode) =>
    switch (periode.decoupage) {
      Decoupage.trimestre => l10n.resultatsPeriodShortTrimestre(periode.ordre),
      Decoupage.semestre => l10n.resultatsPeriodShortSemestre(periode.ordre),
      Decoupage.unknown => l10n.resultatsPeriodShortGeneric(periode.ordre),
    };

/// Libellé long d'une grande période : le libellé serveur s'il existe, sinon
/// « Trimestre 1 » / « Semestre 1 » (spec pilules & synthèse).
String resultatsPeriodLong(AppLocalizations l10n, PeriodeScolaire periode) {
  final libelle = periode.libelle;
  if (libelle != null && libelle.trim().isNotEmpty) {
    return libelle.trim();
  }
  return switch (periode.decoupage) {
    Decoupage.trimestre => l10n.resultatsPeriodLongTrimestre(periode.ordre),
    Decoupage.semestre => l10n.resultatsPeriodLongSemestre(periode.ordre),
    Decoupage.unknown => l10n.resultatsPeriodLongGeneric(periode.ordre),
  };
}

/// Libellé d'une colonne sous-période de la table (« P1 », « P2 »…).
String resultatsSubPeriodColumn(AppLocalizations l10n, int ordre) =>
    l10n.resultatsSubPeriodColumn(ordre);

/// Genre localisé au singulier (« Garçon » / « Fille » / « Autre »).
String resultatsGenderLabel(
  AppLocalizations l10n,
  ClassroomMemberGender? genre,
) => switch (genre) {
  ClassroomMemberGender.male => l10n.resultatsGenderMale,
  ClassroomMemberGender.female => l10n.resultatsGenderFemale,
  ClassroomMemberGender.other => l10n.resultatsGenderOther,
  null => '',
};

/// « Prénom Nom » (table, liste de recherche).
String resultatsShortName(String prenom, String nom) =>
    [prenom, nom].where((p) => p.trim().isNotEmpty).join(' ');

/// « Prénom Nom Postnom » (en-tête focus).
String resultatsFullName(String prenom, String nom, String? postnom) =>
    [prenom, nom, postnom].where((p) => (p ?? '').trim().isNotEmpty).join(' ');

/// Pourcentage entier localisé (« 68 % ») ou tiret si `null`.
String resultatsPercent(AppLocalizations l10n, double? pourcentage) =>
    pourcentage == null
    ? l10n.resultatsDash
    : l10n.resultatsPercentValue(pourcentage.round());

/// Score `note / max` formaté (entier si rond, sinon 1 décimale).
String resultatsNoteOverMax(AppLocalizations l10n, double obtenu, double max) =>
    l10n.resultatsNoteOverMax(formatScore(obtenu), formatScore(max));

/// « place / total » (cellule Place de la synthèse focus).
String resultatsPlace(AppLocalizations l10n, int? place, int total) =>
    place == null ? l10n.resultatsDash : l10n.resultatsPlaceValue(place, total);

/// Delta de progression signé (« +6 pts » / « −3 pts »).
String resultatsDelta(AppLocalizations l10n, double? deltaPts) {
  if (deltaPts == null) {
    return l10n.resultatsDash;
  }
  final rounded = deltaPts.round();
  final sign = rounded > 0
      ? '+'
      : rounded < 0
      ? '−'
      : '';
  return l10n.resultatsDeltaPts('$sign${rounded.abs()}');
}

/// Formate un score : entier si valeur ronde, sinon une décimale.
String formatScore(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}
