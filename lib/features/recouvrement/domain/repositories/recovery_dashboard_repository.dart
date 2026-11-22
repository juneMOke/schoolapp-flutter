import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';

/// Le tableau de bord du Recouvrement v2 : **calculé par le serveur**, la
/// dernière photo datée hors ligne — pour la dernière question seulement.
abstract class RecoveryDashboardRepository {
  /// Les chiffres (B à F). [pendingWrites] : encaissements de la tablette pas
  /// encore remontés, renvoyés tels quels pour le bandeau.
  Future<Either<Failure, RecoveryDashboard>> dashboard(
    String academicYearId,
    RecoveryQuestion question, {
    int pendingWrites = 0,
  });

  /// Une page de la liste nominative (E) ou de la fiche de classe (O2).
  Future<Either<Failure, RecoveryStudentsPage>> students(
    String academicYearId,
    RecoveryStudentsQuery query, {
    int pendingWrites = 0,
  });

  /// L'export de la liste entière de l'onglet — **en ligne seulement**.
  Future<Either<Failure, RecoveryExportFile>> export(
    RecoveryStudentsQuery query,
    RecoveryExportFormat format, {
    int pendingWrites = 0,
  });

  /// La question de la dernière photo, pour rouvrir la page hors ligne sur
  /// ce que l'appareil sait montrer. `null` sans photo.
  Future<RecoveryQuestion?> lastCachedQuestion(String academicYearId);
}
