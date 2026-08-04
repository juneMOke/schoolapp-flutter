import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';

/// Modèle de la table `generated_documents` (partagé Inscription/Facturation).
class GeneratedDocumentLocalModel {
  final String id;
  final String docDomain;
  final String? enrollmentId;
  final String? paymentId;
  final String? studentId;
  final String docType;
  final String number;

  /// Numéro provisoire d'origine, CONSERVÉ après scellement (v19).
  /// Le scellement écrase `number` (`PROV-…` → `ETL-…`) : sans cette copie, le
  /// ticket papier détenu par un parent n'a plus aucun lien avec le reçu
  /// définitif — ce que RG-012-12 suppose pourtant possible.
  final String? provisionalNumber;

  final String status;
  final String? verificationToken;
  final int createdAt;

  const GeneratedDocumentLocalModel({
    required this.id,
    required this.docDomain,
    this.enrollmentId,
    this.paymentId,
    this.studentId,
    required this.docType,
    required this.number,
    this.provisionalNumber,
    this.status = 'PROVISIONAL',
    this.verificationToken,
    this.createdAt = 0,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'doc_domain': docDomain,
    'enrollment_id': enrollmentId,
    'payment_id': paymentId,
    'student_id': studentId,
    'doc_type': docType,
    'number': number,
    'provisional_number': provisionalNumber,
    'status': status,
    'verification_token': verificationToken,
    'created_at': createdAt,
  };

  factory GeneratedDocumentLocalModel.fromMap(Map<String, Object?> m) =>
      GeneratedDocumentLocalModel(
        id: m['id'] as String,
        docDomain: m['doc_domain'] as String,
        enrollmentId: m['enrollment_id'] as String?,
        paymentId: m['payment_id'] as String?,
        studentId: m['student_id'] as String?,
        docType: m['doc_type'] as String,
        number: m['number'] as String,
        provisionalNumber: m['provisional_number'] as String?,
        status: (m['status'] as String?) ?? 'PROVISIONAL',
        verificationToken: m['verification_token'] as String?,
        createdAt: (m['created_at'] as int?) ?? 0,
      );

  LocalGeneratedDocument toEntity() => LocalGeneratedDocument(
    id: id,
    docDomain: docDomain,
    enrollmentId: enrollmentId,
    paymentId: paymentId,
    studentId: studentId,
    docType: docType,
    number: number,
    provisionalNumber: provisionalNumber,
    status: status,
    verificationToken: verificationToken,
    createdAt: createdAt,
  );
}
