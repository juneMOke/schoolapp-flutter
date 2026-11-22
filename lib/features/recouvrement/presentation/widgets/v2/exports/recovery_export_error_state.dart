import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/states/recovery_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'échec d'un export du Recouvrement, dans la visionneuse : les refus
/// métier du serveur se nomment (plafond, élèves inconnus, lignes hors filtre,
/// liste vide, droit manquant) et ne proposent pas « Réessayer » — réessayer
/// produirait le même refus. Le reste suit l'anatomie partagée.
class RecoveryExportErrorState extends StatelessWidget {
  final Failure failure;
  final VoidCallback onRetry;

  const RecoveryExportErrorState({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final refusal = _refusal(failure, l10n);
    if (refusal != null) {
      return EteeloErrorResult(
        type: EteeloErrorType.unknown,
        title: l10n.recouvrementRelanceListFailed,
        message: refusal,
      );
    }
    if (EteeloErrorType.fromFailure(failure) == EteeloErrorType.forbidden) {
      return EteeloErrorResult(
        type: EteeloErrorType.forbidden,
        title: l10n.recoveryErrorForbiddenTitle,
        message: l10n.recouvrementRelanceListForbidden,
      );
    }
    return RecoveryResultsErrorState(
      failure: failure,
      onRetry: onRetry,
      nominative: true,
    );
  }

  static String? _refusal(Failure failure, AppLocalizations l10n) {
    if (failure is! ApiValidationFailure) return null;
    final details = failure.details ?? const <String, dynamic>{};
    int count(String key) => (details[key] as num?)?.toInt() ?? 0;
    return switch (failure.detailCode) {
      'REPORT_LINE_CAP' => l10n.recouvrementRelanceListTooLarge(
        count('lines'),
        count('cap'),
      ),
      'UNKNOWN_STUDENTS' => l10n.recouvrementRelanceListUnknownStudents(
        count('count'),
      ),
      'EMPTY_LIST' => l10n.recoveryExportEmpty,
      'LINE_OUTSIDE_FILTER' ||
      'INCONSISTENT_LINE' ||
      'AT_LEAST_UNAVAILABLE' => l10n.recouvrementRelanceListInconsistent,
      _ => null,
    };
  }
}
