import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_candidate.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_source.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_identity.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Met en mots les élèves retrouvés par la sonde de doublon.
///
/// Séparé de la popin pour se tester sans widget : ce sont ces phrases-là que
/// le guichet lit pour trancher, pas la boîte qui les entoure.
class EnrollmentDuplicateLines {
  const EnrollmentDuplicateLines._();

  /// Combien d'élèves sont **nommés** avant que le reste ne soit compté.
  ///
  /// Trois, parce qu'au-delà la popin cesse d'être un avertissement et devient
  /// une liste à dépouiller — or elle ne sait pas ouvrir un dossier, et n'a donc
  /// rien à offrir à quelqu'un qui voudrait la parcourir.
  static const int maxNamed = 3;

  /// Les [maxNamed] premiers, dans l'ordre déjà décidé par la sonde (du
  /// rapprochement le plus sûr au moins sûr).
  static List<EnrollmentDuplicateCandidate> named(
    List<EnrollmentDuplicateCandidate> candidates,
  ) => candidates.take(maxNamed).toList(growable: false);

  /// Ceux qui restent, et qu'on se contente de compter. `0` = tous nommés.
  static int othersCount(List<EnrollmentDuplicateCandidate> candidates) {
    final rest = candidates.length - maxNamed;
    return rest > 0 ? rest : 0;
  }

  /// « MUKENDI Kabeya Jean · né(e) le 04/03/2015 ».
  ///
  /// La date **est** l'information utile : c'est en la lisant que le guichet
  /// voit si l'enfant retrouvé est bien celui qu'il saisit. **Absente**, la
  /// mention tombe entièrement — « né(e) le » suivi de rien ferait chercher une
  /// donnée qui n'existe pas. **Illisible**, elle se dit quand même, brute :
  /// une date qu'on ne sait pas mettre en forme reste une date qu'on sait
  /// comparer à l'œil, et la taire priverait le guichet du seul champ qui
  /// sépare deux homonymes.
  static String identityOf(
    EnrollmentDuplicateCandidate candidate,
    AppLocalizations l10n,
  ) {
    final name = displayName(candidate.identity);
    final date = displayDate(candidate.identity.dateOfBirth);
    if (date.isEmpty) return name;
    return l10n.enrollmentDuplicateIdentityLine(name, date);
  }

  /// Nom, post-nom, prénom — dans cet ordre, et **tels qu'ils sont stockés**.
  /// Les vides s'escamotent : un dossier ancien sans post-nom ne doit pas
  /// laisser un double espace au milieu de son nom.
  static String displayName(EnrollmentIdentity identity) => [
    identity.lastName.trim(),
    identity.surname.trim(),
    identity.firstName.trim(),
  ].where((part) => part.isNotEmpty).join(' ');

  /// D'où vient l'élève — et ce que ça implique. Un candidat de l'an dernier
  /// n'annonce pas « doublon » mais « ce dossier relève de la Réinscription ».
  static String sourceOf(
    EnrollmentDuplicateSource source,
    AppLocalizations l10n,
  ) => switch (source) {
    EnrollmentDuplicateSource.currentYearDossier =>
      l10n.enrollmentDuplicateSourceCurrentYear,
    EnrollmentDuplicateSource.previousYearCohort =>
      l10n.enrollmentDuplicateSourcePreviousYear,
  };

  /// Date ISO stockée → `JJ/MM/AAAA`.
  ///
  /// Chaîne vide **uniquement** si la date est absente. Illisible, elle est
  /// rendue **telle quelle** plutôt qu'escamotée : c'est le champ qui sépare
  /// deux homonymes, et le guichet la lit très bien sans notre mise en forme.
  /// (À ne pas confondre avec `EnrollmentDuplicateMatcher.dateOnlyOrNull`, qui
  /// rend `null` sur l'illisible — *comparer* deux dates qu'on ne sait pas lire
  /// n'a pas de sens, les *montrer* si.)
  ///
  /// Passer par un `DateTime` plutôt que découper la chaîne sur les tirets : la
  /// même date descend du serveur avec une partie horaire
  /// (`2015-03-04T00:00:00.000Z`) là où le brouillon local l'écrit nue. Un
  /// `split('-')` naïf afficherait `04T00:00:00.000Z/03/2015`.
  static String displayDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    try {
      final date = DateOnlyJsonHelper.fromJson(trimmed);
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year.toString().padLeft(4, '0')}';
    } catch (_) {
      return trimmed;
    }
  }
}
