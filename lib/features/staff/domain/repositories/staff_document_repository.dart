import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document_content.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_dossier_snapshot.dart';

/// Les pièces du dossier d'un agent — sous `hr.document.*`.
abstract class StaffDocumentRepository {
  /// Le référentiel des pièces et celles versées pour [staffMemberId].
  Future<Either<Failure, StaffDossierSnapshot>> dossierOf(String staffMemberId);

  /// Verse [document] sous le code [rawCode] : scellée sur le poste, puis mise
  /// en file d'envoi. « Remplacer » verse une nouvelle pièce.
  Future<Either<Failure, Unit>> addDocument(
    String staffMemberId,
    String rawCode,
    CapturedDocument document,
  );

  /// Les octets d'une pièce : la copie du poste, sinon demandés au serveur
  /// (en ligne seulement) et gardés chiffrés pour la fois suivante.
  Future<Either<Failure, StaffDocumentContent>> open(StaffDocument document);
}
