import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

class FacturationPaymentDetailIntent extends Equatable {
  final String paymentId;
  final String studentId;
  final String academicYearId;
  final String firstName;
  final String lastName;
  final String surname;
  final String levelName;
  final String levelGroupName;
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;

  /// Numéro E.164 du payeur (v28). `null` est un état NORMAL : les versements
  /// antérieurs au palier n'en portent pas, et un versement scellé avant que le
  /// contrat de synchro ne le descende non plus.
  final String? payerPhoneNumber;

  /// Ce qui a été encaissé, **par devise**. Un passage au guichet peut solder
  /// une créance en dollars et une en francs : c'est un acte, donc un versement
  /// et un reçu — mais pas un montant unique.
  final MoneyBag amounts;
  final DateTime paidAt;

  /// Encaissement pas encore remonté au serveur.
  ///
  /// Le serveur honore l'uuid client au push, donc [paymentId] devient un
  /// identifiant serveur valide dès la synchro — mais **avant**, il lui est
  /// inconnu et toute demande de reçu répondrait 404. C'est la garde du bouton
  /// de téléchargement.
  ///
  /// Défaut `false` : un paiement reconstruit depuis l'URL (deep-link à froid)
  /// vient forcément du serveur, donc il est synchronisé.
  final bool isPendingSync;

  /// Qui a encaissé, déjà composé. `null` quand rien n'a été stampé — et c'est
  /// un état **normal et durable**, pas un chargement : seul le poste qui
  /// encaisse écrit ce nom, aucun contrat de synchronisation ne le transporte.
  /// Un versement pris au guichet d'à côté n'en portera donc jamais, tant que
  /// `PaymentDelta`/`PaymentDto` ne l'auront pas descendu.
  final String? cashierFullName;

  const FacturationPaymentDetailIntent({
    required this.paymentId,
    required this.studentId,
    required this.academicYearId,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.levelName,
    required this.levelGroupName,
    required this.payerFirstName,
    required this.payerLastName,
    this.payerMiddleName,
    this.payerPhoneNumber,
    this.amounts = MoneyBag.empty,
    required this.paidAt,
    this.isPendingSync = false,
    this.cashierFullName,
  });

  FacturationPaymentDetailIntent.invalid({
    required String paymentId,
    required String studentId,
    required String academicYearId,
  }) : this(
         paymentId: paymentId,
         studentId: studentId,
         academicYearId: academicYearId,
         firstName: '',
         lastName: '',
         surname: '',
         levelName: '',
         levelGroupName: '',
         payerFirstName: '',
         payerLastName: '',
         payerMiddleName: '',
         amounts: MoneyBag.empty,
         paidAt: DateTime.fromMillisecondsSinceEpoch(0),
       );

  /// Sait-on **de qui** est cet argent, et de **quelle** ligne ?
  ///
  /// Identité + identifiant de la ligne, jamais la classe : voir la docstring de
  /// `FacturationDetailIntent.hasStudentIdentity`. Une fiche ouverte depuis une
  /// recherche **par identité** n'a pas de classe à transmettre — le résumé
  /// d'élève n'en porte pas — et l'exiger ici referait, dans cette modale, la
  /// panne que la fiche vient de perdre : « contexte indisponible » par-dessus
  /// une ligne parfaitement identifiée.
  bool get hasDisplayContext =>
      paymentId.trim().isNotEmpty &&
      firstName.trim().isNotEmpty &&
      lastName.trim().isNotEmpty;

  FacturationPaymentDetailIntent withRouteParams({
    required String paymentId,
    required String studentId,
    required String academicYearId,
  }) => FacturationPaymentDetailIntent(
    paymentId: paymentId,
    studentId: studentId,
    academicYearId: academicYearId,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    levelName: levelName,
    levelGroupName: levelGroupName,
    payerFirstName: payerFirstName,
    payerLastName: payerLastName,
    payerMiddleName: payerMiddleName,
    payerPhoneNumber: payerPhoneNumber,
    amounts: amounts,
    paidAt: paidAt,
    isPendingSync: isPendingSync,
    // Reconduit : un rechargement de route ne doit pas vider une ligne que
    // l'écran affichait l'instant d'avant.
    cashierFullName: cashierFullName,
  );

  static FacturationPaymentDetailIntent fromRouteContext({
    required String paymentId,
    required String studentId,
    required String academicYearId,
    Object? extra,
  }) {
    if (extra is FacturationPaymentDetailIntent) {
      return extra.withRouteParams(
        paymentId: paymentId,
        studentId: studentId,
        academicYearId: academicYearId,
      );
    }

    return FacturationPaymentDetailIntent.invalid(
      paymentId: paymentId,
      studentId: studentId,
      academicYearId: academicYearId,
    );
  }

  @override
  List<Object?> get props => [
    paymentId,
    studentId,
    academicYearId,
    firstName,
    lastName,
    surname,
    levelName,
    levelGroupName,
    payerFirstName,
    payerLastName,
    payerMiddleName,
    payerPhoneNumber,
    amounts,
    paidAt,
    isPendingSync,
    cashierFullName,
  ];
}
