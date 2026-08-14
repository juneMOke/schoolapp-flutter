import 'package:school_app_flutter/core/helpers/client_side_paginator.dart';
import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/local_enrollment_summary_mapper.dart';

/// Une page découpée côté client d'une liste locale de résumés.
class EnrollmentLocalPage {
  final List<EnrollmentSummary> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const EnrollmentLocalPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });
}

/// Raffinement (nom/surnom/DOB) + projection + pagination **côté client** des
/// lectures locales du listing Inscription.
///
/// Le DAO local n'offre que des filtres grossiers (`getEnrollments(status)` /
/// `searchByAcademicInfo(niveaux)`). On applique ici le reste des critères
/// saisis (parties de nom en « contient » insensible à la casse et aux accents,
/// DOB exacte) pour retrouver une sémantique de recherche fidèle à l'online,
/// puis on projette chaque `LocalEnrollmentListItem` sur le `EnrollmentSummary`
/// consommé par les widgets de résultats, et enfin on découpe la page demandée.
class EnrollmentLocalListProjector {
  const EnrollmentLocalListProjector._();

  static bool _contains(String? field, String? term) =>
      SearchNormalizationHelper.contains(field, term);

  /// Filtre client-side puis mappe en résumés (ordre du DAO préservé).
  static List<EnrollmentSummary> project(
    List<LocalEnrollmentListItem> items, {
    String? firstName,
    String? lastName,
    String? surname,
    String? dateOfBirth,
  }) {
    final dob = dateOfBirth?.trim() ?? '';
    return items
        .where((i) => _contains(i.firstName, firstName))
        .where((i) => _contains(i.lastName, lastName))
        .where((i) => _contains(i.surname, surname))
        .where((i) => dob.isEmpty || i.dateOfBirth == dob)
        .map(localItemToEnrollmentSummary)
        .toList(growable: false);
  }

  /// Superpose le **vivier N-1** et les **dossiers RE locaux** (année courante) :
  /// chaque candidat est remplacé par son dossier local de même `studentId` s'il
  /// existe (read-your-writes du parcours RE → jamais un candidat déjà réinscrit
  /// affiché comme frais). Puis raffine (nom/surnom/DOB) en préservant l'ordre du
  /// vivier. Les dossiers sans candidat correspondant (hors cohorte du niveau
  /// demandé) sont ignorés : la recherche reste bornée au vivier interrogé.
  static List<EnrollmentSummary> projectReenrollment({
    required List<ReenrollmentCandidate> candidates,
    required List<LocalEnrollmentListItem> localDossiers,
    String? firstName,
    String? lastName,
    String? surname,
    String? dateOfBirth,
  }) {
    final byStudent = <String, EnrollmentSummary>{};
    final order = <String>[];
    for (final c in candidates) {
      byStudent[c.studentId] = reenrollmentCandidateToEnrollmentSummary(c);
      order.add(c.studentId);
    }
    // `localDossiers` est trié par `updated_at` DESC (getEnrollments) : on ne
    // superpose que le PREMIER dossier rencontré par élève (le plus récent), et
    // seulement tant que l'entrée est encore le candidat brut (id vide) — jamais
    // écrasé par un dossier plus ancien du même élève.
    for (final d in localDossiers) {
      final current = byStudent[d.studentId];
      if (current != null && current.enrollmentId.isEmpty) {
        byStudent[d.studentId] = localItemToEnrollmentSummary(d);
      }
    }
    final dob = dateOfBirth?.trim() ?? '';
    return order
        .map((id) => byStudent[id]!)
        .where((s) => _contains(s.student.firstName, firstName))
        .where((s) => _contains(s.student.lastName, lastName))
        .where((s) => _contains(s.student.surname, surname))
        .where((s) => dob.isEmpty || s.student.dateOfBirth == dob)
        .toList(growable: false);
  }

  /// Superpose le **vivier de pré-inscription** et les **dossiers PRE locaux**
  /// (année courante) : chaque candidat est remplacé par son dossier local de
  /// même **id exact** s'il existe (contrairement à RE, dédup par `studentId` :
  /// ici `preEnrollmentId == enrollmentId` dès le seed, pas besoin de passer
  /// par l'élève). Puis raffine (nom/surnom/DOB) en préservant l'ordre du
  /// vivier. Les dossiers sans candidat correspondant sont ignorés.
  static List<EnrollmentSummary> projectPreEnrollment({
    required List<PreEnrollmentCandidate> candidates,
    required List<LocalEnrollmentListItem> localDossiers,
    String? firstName,
    String? lastName,
    String? surname,
    String? dateOfBirth,
  }) {
    final byId = <String, EnrollmentSummary>{};
    final order = <String>[];
    for (final c in candidates) {
      byId[c.id] = preEnrollmentCandidateToEnrollmentSummary(c);
      order.add(c.id);
    }
    // `localDossiers` est trié par `updated_at` DESC (getEnrollments) : on ne
    // superpose que le PREMIER dossier rencontré par id (le plus récent), et
    // seulement tant que l'entrée est encore le candidat brut (id vide) —
    // jamais écrasé par un dossier plus ancien.
    for (final d in localDossiers) {
      final current = byId[d.enrollmentId];
      if (current != null && current.enrollmentId.isEmpty) {
        byId[d.enrollmentId] = localItemToEnrollmentSummary(d);
      }
    }
    final dob = dateOfBirth?.trim() ?? '';
    return order
        .map((id) => byId[id]!)
        .where((s) => _contains(s.student.firstName, firstName))
        .where((s) => _contains(s.student.lastName, lastName))
        .where((s) => _contains(s.student.surname, surname))
        .where((s) => dob.isEmpty || s.student.dateOfBirth == dob)
        .toList(growable: false);
  }

  /// Découpe la page [page] (bornée) d'une liste déjà filtrée/projetée.
  ///
  /// Le bornage lui-même vit dans [ClientSidePaginator] : le Contrôle des frais
  /// pagine ses propres lignes de la même façon, et les deux pièges (liste vide
  /// → `clamp` invalide, taille nulle → division par zéro) ne doivent être
  /// résolus qu'une fois.
  static EnrollmentLocalPage paginate(
    List<EnrollmentSummary> all, {
    required int page,
    required int size,
  }) {
    final result = ClientSidePaginator.paginate(all, page: page, size: size);
    return EnrollmentLocalPage(
      content: result.content,
      page: result.page,
      size: result.size,
      totalElements: result.totalElements,
      totalPages: result.totalPages,
    );
  }
}
