import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le nom d'une classe tel que la page l'écrit : la rubrique « Non affectés »
/// (`classroomId == null`) prend le libellé traduit, jamais celui du serveur
/// — qui arrive en français, quelle que soit la langue de l'écran.
String recoveryClassName(
  String? classroomId,
  String classroomName,
  AppLocalizations l10n,
) => classroomId == null ? l10n.recouvrementUnassigned : classroomName;

extension RecoveryClassFeeRowName on RecoveryClassFeeRow {
  String displayName(AppLocalizations l10n) =>
      recoveryClassName(classroomId, classroomName, l10n);
}

extension RecoverySimulationRowName on RecoverySimulationRow {
  String displayName(AppLocalizations l10n) =>
      recoveryClassName(classroomId, classroomName, l10n);
}
