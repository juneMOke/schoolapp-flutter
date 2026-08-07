import 'package:equatable/equatable.dart';

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
  final int amountInCents;
  final String currency;
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
    required this.amountInCents,
    required this.currency,
    required this.paidAt,
    this.isPendingSync = false,
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
         amountInCents: 0,
         currency: '',
         paidAt: DateTime.fromMillisecondsSinceEpoch(0),
       );

  bool get hasDisplayContext =>
      paymentId.trim().isNotEmpty &&
      firstName.trim().isNotEmpty &&
      lastName.trim().isNotEmpty &&
      levelName.trim().isNotEmpty &&
      levelGroupName.trim().isNotEmpty;

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
    amountInCents: amountInCents,
    currency: currency,
    paidAt: paidAt,
    isPendingSync: isPendingSync,
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
    amountInCents,
    currency,
    paidAt,
    isPendingSync,
  ];
}
