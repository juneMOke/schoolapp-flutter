import 'package:equatable/equatable.dart';

/// Document généré (attestation AI, reçu RC…), provisoire ou définitif.
class LocalGeneratedDocument extends Equatable {
  final String id;
  final String docDomain; // ENROLLMENT | PAYMENT
  final String? enrollmentId;
  final String? paymentId;
  final String? studentId;
  final String docType; // AI | RC | NP
  final String number; // PROV-… | ETL-…
  final String status; // PROVISIONAL | DEFINITIVE
  final String? verificationToken;

  const LocalGeneratedDocument({
    required this.id,
    required this.docDomain,
    this.enrollmentId,
    this.paymentId,
    this.studentId,
    required this.docType,
    required this.number,
    required this.status,
    this.verificationToken,
  });

  bool get isProvisional => status == 'PROVISIONAL';

  @override
  List<Object?> get props => [
    id,
    docDomain,
    enrollmentId,
    paymentId,
    studentId,
    docType,
    number,
    status,
    verificationToken,
  ];
}
