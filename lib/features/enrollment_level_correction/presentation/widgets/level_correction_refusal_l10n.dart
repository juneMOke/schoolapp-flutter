import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_refusal.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Phrase du guichet pour un refus de correction de niveau.
///
/// Le code rangé sur la ligne (`sync_error_code`) est lu tel quel : un code
/// inconnu — serveur plus récent, ou statut HTTP faute de code — retombe sur
/// la phrase générique, jamais sur le code brut.
extension LevelCorrectionRefusalL10n on AppLocalizations {
  String levelCorrectionRefusalMessage(
    String? storedCode,
  ) => switch (LevelCorrectionRefusal.fromWire(storedCode)) {
    LevelCorrectionRefusal.enrollmentNotConfirmed =>
      levelCorrectionRefusedEnrollmentNotConfirmed,
    LevelCorrectionRefusal.staleLevel => levelCorrectionRefusedStaleLevel,
    LevelCorrectionRefusal.invalidTargetLevel =>
      levelCorrectionRefusedInvalidTargetLevel,
    LevelCorrectionRefusal.noTariffForLevel => levelCorrectionRefusedNoTariff,
    LevelCorrectionRefusal.hasPayments => levelCorrectionRefusedHasPayments,
    LevelCorrectionRefusal.hasGrades => levelCorrectionRefusedHasGrades,
    LevelCorrectionRefusal.targetClassroomRequired =>
      levelCorrectionRefusedTargetClassroomRequired,
    LevelCorrectionRefusal.levelMismatch => levelCorrectionRefusedLevelMismatch,
    null => levelCorrectionRefusedGeneric,
  };
}
