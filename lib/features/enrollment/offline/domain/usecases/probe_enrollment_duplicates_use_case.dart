import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_candidate.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_matcher.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_source.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_identity.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_identity_key.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/known_student_identity.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// « Cet enfant est-il déjà dans nos bases ? »
///
/// Confronte l'identité saisie à l'étape 1 d'une **Première inscription** au
/// corpus local (dossiers de l'année + cohorte N-1), et rend les élèves
/// retrouvés, du plus sûr au moins sûr.
///
/// Ce n'est pas une recherche : personne ne cherche. C'est une confrontation
/// déclenchée par la saisie, dont le seul livrable est un avertissement — elle
/// n'ouvre aucun dossier, **n'écrit rien**, et ne barre la route à personne.
///
/// **Le `Left` se traite comme une liste vide** par l'appelant : une sonde
/// d'aide qui tombe ne doit pas arrêter un guichet. Elle reste un `Left` ici
/// pour que l'échec soit visible en test plutôt que confondu avec « rien
/// trouvé » — les deux ne se disent pas pareil (cf. D6 : la popin ne parle que
/// quand elle trouve, elle n'affirme jamais l'absence).
class ProbeEnrollmentDuplicatesUseCase {
  final EnrollmentOfflineRepository _repository;

  const ProbeEnrollmentDuplicatesUseCase(this._repository);

  /// [typed] est la saisie du guichet ; [studentId] et [enrollmentId] ceux du
  /// brouillon en cours — **exclus du corpus**, sans quoi la sonde se
  /// trouverait elle-même.
  Future<Either<Failure, List<EnrollmentDuplicateCandidate>>> call({
    required EnrollmentIdentity typed,
    required String studentId,
    required String enrollmentId,
    String? academicYearId,
  }) async {
    final matcher = EnrollmentDuplicateMatcher(typed);
    // Saisie inexploitable (moins de deux noms) : rien à confronter, et surtout
    // pas de lecture à payer. L'étape Identité exige les trois noms, mais la
    // garde ne coûte rien et évite qu'une saisie dégradée rapproche la moitié
    // de l'école.
    if (!matcher.isUsable) {
      return const Right(<EnrollmentDuplicateCandidate>[]);
    }

    final corpus = await _repository.loadDuplicateProbeCorpus(
      studentId: studentId,
      enrollmentId: enrollmentId,
      academicYearId: academicYearId,
    );

    return corpus.map((known) => _retain(matcher, known));
  }

  /// Retient les élèves rapprochés, un par élève, classés.
  List<EnrollmentDuplicateCandidate> _retain(
    EnrollmentDuplicateMatcher matcher,
    List<KnownStudentIdentity> corpus,
  ) {
    // Déduplication PAR ÉLÈVE : le même enfant peut être à la fois dans un
    // dossier de l'année et dans la cohorte N-1 (une réinscription déjà faite).
    // Il ne se dit qu'une fois.
    final byStudent = <String, EnrollmentDuplicateCandidate>{};

    for (final known in corpus) {
      final level = matcher.match(known.identity);
      if (level == null) continue;

      final candidate = EnrollmentDuplicateCandidate.from(known, level);
      final kept = byStudent[known.studentId];
      if (kept == null || _outranks(candidate, kept)) {
        byStudent[known.studentId] = candidate;
      }
    }

    final candidates = byStudent.values.toList();
    candidates.sort(_byLevelThenName);
    return List<EnrollmentDuplicateCandidate>.unmodifiable(candidates);
  }

  /// [a] doit-il remplacer [b] pour le même élève ?
  ///
  /// Le **dossier de l'année prime sur la cohorte** N-1, quel que soit le
  /// niveau : c'est celui dont on peut parler au présent. À source égale, le
  /// rapprochement le plus fort gagne.
  bool _outranks(
    EnrollmentDuplicateCandidate a,
    EnrollmentDuplicateCandidate b,
  ) {
    if (a.source != b.source) {
      return a.source == EnrollmentDuplicateSource.currentYearDossier;
    }
    return a.level.index < b.level.index;
  }

  /// Le plus sûr d'abord — `EnrollmentDuplicateLevel` est déclaré dans cet
  /// ordre. À niveau égal, l'ordre alphabétique, sur les **clés** : deux
  /// écritures du même nom ne doivent pas se ranger à deux endroits.
  int _byLevelThenName(
    EnrollmentDuplicateCandidate a,
    EnrollmentDuplicateCandidate b,
  ) {
    final byLevel = a.level.index.compareTo(b.level.index);
    if (byLevel != 0) return byLevel;

    final byLastName = EnrollmentIdentityKey.of(
      a.identity.lastName,
    ).compareTo(EnrollmentIdentityKey.of(b.identity.lastName));
    if (byLastName != 0) return byLastName;

    return EnrollmentIdentityKey.of(
      a.identity.firstName,
    ).compareTo(EnrollmentIdentityKey.of(b.identity.firstName));
  }
}
