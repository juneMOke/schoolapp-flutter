import 'package:school_app_flutter/features/configuration/data/models/provisioning_instant.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';

/// L'année académique proposée d'après la date du jour.
///
/// **La bascule tombe au 1er juillet.** Avant, on prépare l'année qui commence
/// en septembre de l'année civile en cours ; à partir de juillet, celle de la
/// rentrée qui vient. Une école qui se paramètre en août prépare donc la rentrée
/// de septembre, et non celle qui vient de s'achever.
///
/// Calcul pur, isolé de l'écran : c'est la seule façon de l'éprouver sur les
/// quatre dates qui comptent — de part et d'autre de la bascule, et de part et
/// d'autre du changement d'année civile.
class AcademicYearProposal {
  const AcademicYearProposal._();

  /// Mois à partir duquel on prépare la rentrée suivante.
  static const int switchMonth = DateTime.july;

  /// Jour de rentrée proposé.
  static const int startMonth = DateTime.september;
  static const int startDay = 1;

  /// Fin d'année proposée.
  static const int endMonth = DateTime.june;
  static const int endDay = 30;

  /// Année de début de l'exercice à préparer, d'après [today].
  static int startYearFor(DateTime today) =>
      today.month >= switchMonth ? today.year : today.year - 1;

  /// Libellé de l'année (`2026-2027`).
  static String labelFor(DateTime today) {
    final start = startYearFor(today);
    return '$start-${start + 1}';
  }

  /// La proposition complète, dates comprises.
  ///
  /// Les deux dates sont des **instants UTC** : le contrat l'impose, et les
  /// lire autrement décalerait le jour affiché d'un fuseau à l'autre.
  static AcademicYearInput forDate(DateTime today) {
    final start = startYearFor(today);
    return AcademicYearInput(
      name: '$start-${start + 1}',
      startDate: ProvisioningInstant.startOfDayUtc(
        DateTime.utc(start, startMonth, startDay),
      ),
      endDate: ProvisioningInstant.startOfDayUtc(
        DateTime.utc(start + 1, endMonth, endDay),
      ),
    );
  }

  /// L'année saisie est-elle encore celle qu'on aurait proposée ?
  ///
  /// Sert la pastille d'origine : « Proposée automatiquement » tant que rien n'a
  /// bougé, « Modifiée » ensuite, avec le lien pour rétablir.
  static bool isPristine(AcademicYearInput input, DateTime today) =>
      input == forDate(today);

  /// Durée indicative, en mois, entre les deux dates.
  ///
  /// Approximation assumée (30,44 jours par mois) : le chiffre est là pour
  /// qu'un écart grossier saute aux yeux — « ≈ 2 mois » sur une année scolaire —
  /// pas pour être exact.
  static int monthsBetween(DateTime start, DateTime end) {
    final days = end.difference(start).inDays;
    if (days <= 0) return 0;
    return (days / 30.44).round();
  }
}
