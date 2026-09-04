import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_candidate.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_matcher.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_identity.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_identity_key.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/probe_enrollment_duplicates_use_case.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/enrollment_duplicate_dialog.dart';

/// La sonde de doublon **du côté du parcours** : décide s'il y a lieu de
/// confronter, confronte, montre, et retient ce que le guichet a assumé.
///
/// Vit aussi longtemps que le wizard (créé par `EnrollmentStepperScope`), parce
/// que sa mémoire est celle d'une session de saisie : ce qu'on vient d'assumer
/// ne doit pas être redemandé au prochain aller-retour d'étape.
class EnrollmentDuplicateGuard {
  /// Comment atteindre la sonde — **pas** la sonde elle-même.
  ///
  /// Le wizard se monte dans des parcours qui ne la solliciteront jamais
  /// (consultation, réédition, réinscription). Résoudre au montage ferait payer
  /// à tous ces parcours une dépendance qu'un seul utilise, et surtout : cela
  /// couplerait **le montage du wizard au conteneur global**, là où les écrans
  /// d'inscription se montent aujourd'hui par injection explicite. Six suites de
  /// test le font, délibérément, sans `getIt`.
  ///
  /// La résolution a donc lieu au premier usage réel — c'est-à-dire une fois
  /// [appliesTo] franchi. Un enregistrement manquant lève toujours, bruyamment,
  /// mais sur le seul chemin qui en avait besoin ; et `enrollment_duplicate_
  /// wiring_test.dart` continue de prouver que cet enregistrement existe.
  final ProbeEnrollmentDuplicatesUseCase Function() _resolveProbe;

  /// Mémorisée : une session de saisie ne résout qu'une fois.
  ProbeEnrollmentDuplicatesUseCase? _probe;

  /// Signatures d'identité pour lesquelles le guichet a explicitement répondu
  /// « Continuer quand même ».
  ///
  /// **On retient l'acquiescement, pas l'exposition.** « Corriger la saisie »
  /// n'y entre pas : celui qui repart corriger, puis ressort sans avoir rien
  /// changé, se retrouve devant le même avertissement — ce qui est juste, rien
  /// n'a changé. Il en sort d'un tap sur « Continuer quand même », et c'est
  /// justement ce tap-là qui vaut décision.
  final Set<String> _acknowledged = <String>{};

  /// Sonde déjà en main — le cas des tests, qui la pilotent.
  EnrollmentDuplicateGuard(ProbeEnrollmentDuplicatesUseCase probe)
    : _resolveProbe = (() => probe),
      _probe = probe;

  /// Sonde **à aller chercher**, et seulement si le parcours la réclame : le
  /// cas du wizard, monté bien plus souvent qu'il n'interroge.
  EnrollmentDuplicateGuard.lazy(this._resolveProbe);

  /// Le guichet peut-il quitter l'étape Identité ?
  ///
  /// `true` dans tous les cas sauf un : la sonde a trouvé, et il a choisi de
  /// retourner corriger. **Un échec de lecture rend `true`** — une sonde d'aide
  /// qui tombe ne doit pas arrêter un guichet, et elle n'a rien à dire.
  Future<bool> allowContinue({
    required BuildContext context,
    required EnrollmentDetail detail,
    required EnrollmentDetailPolicy detailPolicy,
  }) async {
    if (!appliesTo(detailPolicy)) return true;

    final typed = identityOf(detail);
    if (isAcknowledged(typed)) return true;

    final result = await (_probe ??= _resolveProbe())(
      typed: typed,
      studentId: detail.studentDetail.id,
      enrollmentId: detail.enrollmentDetail.id,
      academicYearId: _nonEmptyOrNull(detail.enrollmentDetail.academicYearId),
    );

    // Le `Left` se lit comme « rien à dire » : c'est le contrat du usecase, et
    // c'est la seule lecture qui ne transforme pas une panne locale en blocage.
    final candidates = result.fold(
      (_) => const <EnrollmentDuplicateCandidate>[],
      (found) => found,
    );
    if (candidates.isEmpty) return true;
    if (!context.mounted) return false;

    final passed = await EnrollmentDuplicateDialog.show(
      context,
      candidates: candidates,
    );
    if (passed) _acknowledged.add(_signatureOf(typed));
    return passed;
  }

  /// La sonde ne tourne qu'en **Première inscription** (D1) et sur une étape
  /// **modifiable**.
  ///
  /// En Réinscription et en Pré-inscription, l'élève vient d'un vivier : son
  /// `student_id` est canonique, il n'y a pas de doublon à craindre — et le
  /// candidat dont le dossier est en cours serait sa propre alerte.
  /// En consultation, il n'y a rien à corriger : avertir n'offrirait aucune
  /// suite.
  bool appliesTo(EnrollmentDetailPolicy detailPolicy) =>
      detailPolicy.draftEnrollmentType == 'NEW_ENROLLMENT' &&
      detailPolicy.isStepEditable(EnrollmentWizardStep.personalInfo);

  /// L'identité telle qu'elle vient d'être enregistrée à l'étape 1.
  static EnrollmentIdentity identityOf(EnrollmentDetail detail) =>
      EnrollmentIdentity(
        lastName: detail.studentDetail.lastName,
        firstName: detail.studentDetail.firstName,
        surname: detail.studentDetail.surname,
        dateOfBirth: detail.studentDetail.dateOfBirth,
      );

  bool isAcknowledged(EnrollmentIdentity typed) =>
      _acknowledged.contains(_signatureOf(typed));

  /// Signature **normalisée** : deux écritures du même nom sont la même
  /// identité. Sans ça, corriger « Mukendi » en « MUKENDI » relancerait un
  /// avertissement que le guichet vient d'écarter.
  static String _signatureOf(EnrollmentIdentity identity) => [
    EnrollmentIdentityKey.of(identity.lastName),
    EnrollmentIdentityKey.of(identity.firstName),
    EnrollmentIdentityKey.of(identity.surname),
    EnrollmentDuplicateMatcher.dateOnlyOrNull(identity.dateOfBirth) ?? '',
  ].join('|');

  static String? _nonEmptyOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
