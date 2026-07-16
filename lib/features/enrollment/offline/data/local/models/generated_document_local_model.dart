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
    status: status,
    verificationToken: verificationToken,
  );
}
