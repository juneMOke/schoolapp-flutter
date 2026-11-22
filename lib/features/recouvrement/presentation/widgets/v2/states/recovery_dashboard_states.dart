import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_dashboard_skeletons.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/formatters/local_date_time_format.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/states/recovery_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// « 05/09/2026 » — la date de situation (D12), à l'heure de l'école.
String recoveryDay(DateTime instant) =>
    formatLocalDay(SchoolTime.wallClock(instant));

/// « 14:05 », à l'heure de l'école.
String recoveryTime(DateTime instant) {
  final wall = SchoolTime.wallClock(instant);
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(wall.hour)}:${two(wall.minute)}';
}

/// Le bandeau « Hors ligne · chiffres du {date} à {heure}. Les exports
/// attendent le réseau. » — la page montre la dernière photo du serveur.
class RecoveryOfflineBanner extends StatelessWidget {
  final DateTime cachedAt;

  const RecoveryOfflineBanner({super.key, required this.cachedAt});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: EteeloNotice.warning(
        l10n.recoveryOfflineBanner(
          recoveryDay(cachedAt),
          recoveryTime(cachedAt),
        ),
      ),
    );
  }
}

/// Aucun frais facturé cette année (ou aucun élève inscrit) : le vide
/// structurel de la page, avec « Ouvrir la configuration ».
class RecoveryNoFeesState extends StatelessWidget {
  const RecoveryNoFeesState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloEmptyResult(
      label: l10n.recoveryEmptyTitle,
      description: l10n.recoveryEmptyDescription,
      medallionIcon: Icons.percent_rounded,
      accentColor: AppColors.accueilFeeControlAccent,
      primaryAction: EteeloButton.secondary(
        label: l10n.recoveryEmptyAction,
        icon: Icons.settings_outlined,
        onPressed: () => context.push(AppRoutesNames.configurationSettingsPath),
        fullWidth: false,
      ),
    );
  }
}

/// L'erreur de la page, en place sous la carte de périmètre.
class RecoveryResultsErrorBlock extends StatelessWidget {
  final Failure failure;
  final Future<void> Function() onRetry;

  const RecoveryResultsErrorBlock({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: RecoveryResultsErrorState(failure: failure, onRetry: onRetry),
  );
}

/// Le chargement : pavés, lignes-barres et liste fantômes (reduced-motion
/// respecté par les squelettes du socle).
class RecoveryDashboardSkeleton extends StatelessWidget {
  const RecoveryDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EteeloKpiBandSkeleton(count: 4),
        const SizedBox(height: AppSpacing.lg),
        const EteeloBarRowsSkeleton(rows: 4),
        const SizedBox(height: AppSpacing.lg),
        EteeloListSkeleton(
          rowCount: 6,
          semanticsLabel: l10n.recoveryDashboardTitle,
        ),
      ],
    );
  }
}
