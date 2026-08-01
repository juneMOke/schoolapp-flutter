import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_cubit.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_state.dart';
import 'package:school_app_flutter/core/components/status/outbox_retry_policy.dart';
import 'package:school_app_flutter/core/components/status/sync_error_tile.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre la feuille de reprise des écritures en échec.
///
/// À la fermeture, rafraîchit la pastille globale : un requeue réussi doit faire
/// retomber « Conflit » sans attendre un autre événement.
Future<void> showSyncErrorsSheet(BuildContext context) async {
  final syncStatusCubit = context.read<SyncStatusCubit>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: AppRadius.card),
    ),
    builder: (_) => BlocProvider<OutboxErrorsCubit>(
      create: (_) => getIt<OutboxErrorsCubit>()..load(),
      child: const _SyncErrorsSheet(),
    ),
  );
  await syncStatusCubit.refresh();
}

class _SyncErrorsSheet extends StatelessWidget {
  const _SyncErrorsSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.syncErrorsTitle,
                    style: AppTypography.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: l10n.syncErrorsClose,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.syncErrorsSubtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Expanded(child: _SyncErrorsBody()),
          ],
        ),
      ),
    );
  }
}

class _SyncErrorsBody extends StatelessWidget {
  const _SyncErrorsBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<OutboxErrorsCubit, OutboxErrorsState>(
      builder: (context, state) {
        if (state.status == OutboxErrorsStatus.loading) {
          return const EteeloListSkeleton(rowCount: 3, showAvatar: false);
        }
        if (state.status == OutboxErrorsStatus.failure) {
          return EteeloErrorResult(
            // Lecture d'une base locale : ni réseau, ni droits — `unknown` est
            // le seul type honnête ici, et il ne propose pas de « Réessayer »
            // trompeur sur une base indisponible.
            type: EteeloErrorType.unknown,
            title: l10n.syncErrorsLoadFailedTitle,
            message: l10n.syncErrorsLoadFailedMessage,
          );
        }
        if (state.isEmpty) {
          return EteeloEmptyResult(
            label: l10n.syncErrorsEmptyLabel,
            description: l10n.syncErrorsEmptyDescription,
            medallionIcon: Icons.cloud_done_outlined,
          );
        }
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: state.entries.length,
                itemBuilder: (context, index) {
                  final entry = state.entries[index];
                  return SyncErrorTile(
                    entry: entry,
                    busy: state.busy,
                    onRetry: () =>
                        context.read<OutboxErrorsCubit>().retry(entry.id),
                  );
                },
              ),
            ),
            // « Tout réessayer » n'apparaît que s'il y a effectivement quelque
            // chose à rejouer : sinon le bouton est actif et sans aucun effet.
            if (state.entries.any(
              (e) => canRequeueFrozenPayload(e.aggregateType),
            )) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.busy
                      ? null
                      : () => context.read<OutboxErrorsCubit>().retryAll(),
                  child: Text(l10n.syncErrorsRetryAll),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
