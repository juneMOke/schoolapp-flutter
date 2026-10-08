import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_reason.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le libellé d'un motif de désactivation.
extension SuspensionReasonLabel on SuspensionReason {
  String label(AppLocalizations l10n) => switch (this) {
    SuspensionReason.medical => l10n.suspensionReasonMedical,
    SuspensionReason.family => l10n.suspensionReasonFamily,
    SuspensionReason.disciplinary => l10n.suspensionReasonDisciplinary,
    SuspensionReason.prolongedAbsence => l10n.suspensionReasonProlongedAbsence,
    SuspensionReason.other => l10n.suspensionReasonOther,
  };
}
