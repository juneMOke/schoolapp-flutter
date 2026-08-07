/// Statut de chargement générique des lectures Inscription
/// (listes / détail / preview).
///
/// Extrait de `enrollment_bloc.dart` pour être partagé sans dépendre du BLoC :
/// consommé par le bloc online (détail/preview), le bloc de listing LOCAL
/// (offline) et des modules tiers (classes, finance) qui réutilisent les
/// widgets de résultats Inscription.
enum EnrollmentLoadStatus { initial, loading, success, failure }
