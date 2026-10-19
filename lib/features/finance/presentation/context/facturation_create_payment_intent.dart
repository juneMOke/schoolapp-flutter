import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_payment_correction_context.dart';

class FacturationCreatePaymentIntent extends Equatable {
  final String studentId;
  final String academicYearId;
  final String firstName;
  final String lastName;
  final String surname;
  final String levelName;
  final String levelGroupName;
  final List<StudentCharge> studentCharges;

  /// Présent quand la page sert à CORRIGER un versement : elle annule
  /// l'origine et encaisse son remplaçant en un seul geste.
  final FacturationPaymentCorrectionContext? correction;

  /// Appelé dès que l'encaissement (ou la correction) est écrit, avant que la
  /// page ne se referme : la fiche relit ses listes.
  ///
  /// Pas le résultat de `push` : un rafraîchissement du routeur (droits
  /// relus par la synchronisation) recrée la route empilée avec une nouvelle
  /// attente, et l'ancienne ne se dénoue jamais (go_router #128122) — la
  /// fiche garderait des soldes périmés et rouvrirait un encaissement dessus.
  /// L'intention, elle, survit au rafraîchissement (`InMemoryExtraCodec`).
  ///
  /// Hors de l'égalité : c'est un canal de retour, pas une donnée.
  final VoidCallback? onWritten;

  const FacturationCreatePaymentIntent({
    required this.studentId,
    required this.academicYearId,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.levelName,
    required this.levelGroupName,
    required this.studentCharges,
    this.correction,
    this.onWritten,
  });

  const FacturationCreatePaymentIntent.invalid({
    required String studentId,
    required String academicYearId,
  }) : this(
         studentId: studentId,
         academicYearId: academicYearId,
         firstName: '',
         lastName: '',
         surname: '',
         levelName: '',
         levelGroupName: '',
         studentCharges: const [],
       );

  /// Sait-on **de qui** est cet argent ?
  ///
  /// L'identité seule, jamais la classe : voir la docstring de
  /// `FacturationDetailIntent.hasStudentIdentity`. Un encaissement ouvert
  /// depuis une fiche trouvée **par identité** n'a pas de classe à transmettre,
  /// et la classe ne figure sur aucune pièce émise — elle n'alimente que le
  /// sur-titre de l'écran.
  bool get hasDisplayContext =>
      firstName.trim().isNotEmpty && lastName.trim().isNotEmpty;

  List<StudentCharge> get unpaidCharges => studentCharges
      .where((c) => c.status != StudentChargeStatus.paid)
      .toList();

  FacturationCreatePaymentIntent withRouteParams({
    required String studentId,
    required String academicYearId,
  }) => FacturationCreatePaymentIntent(
    studentId: studentId,
    academicYearId: academicYearId,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    levelName: levelName,
    levelGroupName: levelGroupName,
    studentCharges: studentCharges,
    correction: correction,
    onWritten: onWritten,
  );

  static FacturationCreatePaymentIntent fromRouteContext({
    required String studentId,
    required String academicYearId,
    Object? extra,
  }) {
    if (extra is FacturationCreatePaymentIntent) {
      return extra.withRouteParams(
        studentId: studentId,
        academicYearId: academicYearId,
      );
    }
    return FacturationCreatePaymentIntent.invalid(
      studentId: studentId,
      academicYearId: academicYearId,
    );
  }

  @override
  List<Object?> get props => [
    studentId,
    academicYearId,
    firstName,
    lastName,
    surname,
    levelName,
    levelGroupName,
    studentCharges,
    correction,
  ];
}
