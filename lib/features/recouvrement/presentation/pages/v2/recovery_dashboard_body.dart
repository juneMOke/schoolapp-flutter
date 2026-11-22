import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_page_header.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_catalog_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_dashboard_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/v2/recovery_dashboard_address.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/v2/recovery_dashboard_blocks.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/perimeter/recovery_dashboard_perimeter.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/states/recovery_dashboard_states.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le corps du tableau de bord : l'en-tête (toujours visible), le bandeau hors
/// ligne, la carte de périmètre (A, toujours à l'écran), puis l'état de la
/// zone de résultats — fantômes, vide, erreur en place, ou les blocs B à G.
class RecoveryDashboardBody extends StatelessWidget {
  final String academicYearId;
  final String yearName;
  final List<SchoolLevelGroupBundle> groups;
  final RecoveryDashboardAddress? address;
  final ValueChanged<RecoveryDashboardAddress> onAddressChanged;
  final ValueChanged<int> onPageChanged;
  final Future<void> Function() onRetry;

  const RecoveryDashboardBody({
    super.key,
    required this.academicYearId,
    required this.yearName,
    required this.groups,
    required this.address,
    required this.onAddressChanged,
    required this.onPageChanged,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catalog = context.watch<RecoveryCatalogCubit>().state;
    final titles = context.watch<FeeSectionTitlesCubit>().state;
    return BlocBuilder<RecoveryDashboardCubit, RecoveryDashboardState>(
      builder: (context, state) {
        final dashboard = state.dashboard;
        final address = this.address;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EteeloPageHeader(
              eyebrow: l10n.recouvrementControlEyebrow(yearName),
              title: l10n.recoveryDashboardTitle,
              subtitle: dashboard == null
                  ? l10n.recoveryDashboardSubtitleNoDate
                  : l10n.recoveryDashboardSubtitle(
                      recoveryDay(dashboard.situationAt),
                    ),
            ),
            if (dashboard?.cachedAt != null)
              RecoveryOfflineBanner(cachedAt: dashboard!.cachedAt!),
            const SizedBox(height: AppSpacing.lg),
            if (catalog.status == RecoveryLoadStatus.success &&
                catalog.natures.isEmpty)
              const RecoveryNoFeesState()
            else ...[
              RecoveryDashboardPerimeter(
                natures: catalog.natures,
                feeCodes: address?.feeCodes ?? const [],
                titles: titles,
                groups: groups,
                classrooms: catalog.classrooms,
                scope: address?.scope ?? RecoveryScopeKind.school,
                scopeId: address?.scopeId,
                studentCount: dashboard?.studentCount,
                enabled: address != null,
                onFeesChanged: (fees) {
                  if (address == null || fees.isEmpty) return;
                  onAddressChanged(address.copyWith(feeCodes: fees));
                },
                onScopeChanged: (scope, id) {
                  if (address == null) return;
                  onAddressChanged(address.copyWith(scope: scope, scopeId: id));
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _results(context, state, dashboard, address),
            ],
          ],
        );
      },
    );
  }

  Widget _results(
    BuildContext context,
    RecoveryDashboardState state,
    RecoveryDashboard? dashboard,
    RecoveryDashboardAddress? address,
  ) {
    final failure = state.failure;
    // Erreur en place, sous la carte de périmètre ; une relecture ratée sur
    // une page déjà remplie garde les chiffres et ne dit que l'échec.
    if (failure != null && dashboard == null) {
      return RecoveryResultsErrorBlock(failure: failure, onRetry: onRetry);
    }
    if (dashboard == null || address == null) {
      return const RecoveryDashboardSkeleton();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (failure != null)
          RecoveryResultsErrorBlock(failure: failure, onRetry: onRetry),
        RecoveryDashboardBlocks(
          academicYearId: academicYearId,
          dashboard: dashboard,
          address: address,
          onAddressChanged: onAddressChanged,
          onPageChanged: onPageChanged,
          onRetryList: onRetry,
        ),
      ],
    );
  }
}
