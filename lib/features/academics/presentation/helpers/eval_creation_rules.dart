import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/sous_periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';

/// Règles de la modale de création (spec §2-§5) sur une cible donnée : la
/// période et la sous-période choisies, le type, la date.
///
/// Pur et sans état : le formulaire le reconstruit à chaque saisie.
class EvalCreationRules {
  final CoursNotationDetail detail;
  final TypeEvaluation type;
  final String? periodeId;
  final String? sousPeriodeId;
  final DateTime? date;

  const EvalCreationRules({
    required this.detail,
    required this.type,
    required this.periodeId,
    required this.sousPeriodeId,
    required this.date,
  });

  List<PeriodeNotation> get periodes => detail.periodes;

  bool get isExamen => type == TypeEvaluation.examen;

  PeriodeNotation? get periode {
    for (final p in periodes) {
      if (p.periodeScolaireId == periodeId) return p;
    }
    return null;
  }

  SousPeriodeNotation? get sousPeriode {
    for (final sp in periode?.sousPeriodes ?? const <SousPeriodeNotation>[]) {
      if (sp.sousPeriodeId == sousPeriodeId) return sp;
    }
    return null;
  }

  /// La première période encore OUVERTE (repli sur la première), pour ne pas
  /// ouvrir le formulaire sur une cible verrouillée quand un choix valide
  /// existe.
  static PeriodeNotation? defaultPeriode(List<PeriodeNotation> periodes) {
    if (periodes.isEmpty) return null;
    return periodes.firstWhere(
      (p) => p.statut != StatutPeriode.cloturee,
      orElse: () => periodes.first,
    );
  }

  /// Id de la première sous-période OUVERTE de [periode] (repli sur la
  /// première ; `null` si aucune).
  static String? defaultSousPeriodeId(PeriodeNotation periode) {
    final sps = periode.sousPeriodes;
    if (sps.isEmpty) return null;
    return sps
        .firstWhere(
          (s) => s.statut != StatutPeriode.cloturee,
          orElse: () => sps.first,
        )
        .sousPeriodeId;
  }

  bool get isPeriodeClosed => periode?.statut == StatutPeriode.cloturee;

  bool get isSousPeriodeClosed => sousPeriode?.statut == StatutPeriode.cloturee;

  /// Cible verrouillée : on n'ajoute pas d'évaluation à une période clôturée.
  /// Examen → la période scolaire ; journalière → la sous-période (ou son
  /// parent clôturé, par sécurité).
  bool get isTargetClosed =>
      isExamen ? isPeriodeClosed : isPeriodeClosed || isSousPeriodeClosed;

  /// Plafond EXAMEN de la période (`maxExamenParPeriodeScolaire`, bundle) —
  /// un seul créneau examen par période, donc « atteint » dès qu'un examen
  /// existe. Plafond `null` (bundle pas encore pullé) → pas de blocage local,
  /// le backstop serveur reste le dernier rempart.
  bool get _examenPlafondReached {
    final maxExamen = detail.plafonds?.maxExamenParPeriodeScolaire;
    if (maxExamen == null) return false;
    final existing = periode?.examen != null ? 1 : 0;
    return existing >= maxExamen;
  }

  /// Plafond journalier (`maxJournalierParSousPeriode`, bundle) — évaluations
  /// journalières déjà présentes dans la sous-période, à la date choisie.
  bool get _journalierPlafondReached {
    final maxJournalier = detail.plafonds?.maxJournalierParSousPeriode;
    final day = date;
    final sp = sousPeriode;
    if (maxJournalier == null || day == null || sp == null) return false;
    final target = DateTime.utc(day.year, day.month, day.day);
    var count = 0;
    for (final groupe in sp.evaluationsParType) {
      for (final ev in groupe.evaluations) {
        if (DateTime.utc(ev.date.year, ev.date.month, ev.date.day) == target) {
          count++;
        }
      }
    }
    return count >= maxJournalier;
  }

  bool get isPlafondReached =>
      isExamen ? _examenPlafondReached : _journalierPlafondReached;

  /// Type EXAMEN grisé si la branche n'a pas d'examen
  /// (`maxExamenParPeriodeScolaire` `null`, bundle) — jamais traité comme 0 ;
  /// plafonds pas encore en cache → pas de grisage.
  Set<TypeEvaluation> get disabledTypes {
    final plafonds = detail.plafonds;
    if (plafonds == null || plafonds.maxExamenParPeriodeScolaire != null) {
      return const {};
    }
    return const {TypeEvaluation.examen};
  }

  /// Rattachement présent pour le type choisi.
  bool get hasTarget => isExamen
      ? periodeId != null && periodeId!.isNotEmpty
      : sousPeriodeId != null && sousPeriodeId!.isNotEmpty;

  /// La cible accepte une évaluation de ce type.
  bool get isTargetOpen =>
      !isTargetClosed && !isPlafondReached && !disabledTypes.contains(type);
}
