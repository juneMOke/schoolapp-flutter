import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_adjustment.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/register_adjustments_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_failure_text.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'historique déplié d'une caisse : chaque ajustement avec son écart signé,
/// son numéro, son motif, sa date et son auteur — le plus récent en tête.
///
/// Un échec reste **dans la liste** : la carte et le reste de l'écran restent
/// utilisables.
class RegisterAdjustmentsList extends StatelessWidget {
  final TreasuryCurrency currency;

  const RegisterAdjustmentsList({super.key, required this.currency});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<RegisterAdjustmentsCubit, RegisterAdjustmentsState>(
      builder: (context, state) {
        final failure = state.failure;
        return switch (state.status) {
          RegisterAdjustmentsStatus.loading => EteeloListSkeleton(
            rowCount: 2,
            pillCount: 0,
            showAvatar: false,
            semanticsLabel: l10n.treasuryAdjustmentsLoading,
          ),
          RegisterAdjustmentsStatus.failure => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.treasuryAdjustmentsLoadFailed(
                  failure == null ? '' : l10n.treasuryFailureReason(failure),
                ),
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
              EteeloButton.ghost(
                label: l10n.treasuryRetry,
                icon: Icons.refresh,
                onPressed: context.read<RegisterAdjustmentsCubit>().load,
                fullWidth: false,
              ),
            ],
          ),
          _ when state.items.isEmpty => Text(
            l10n.treasuryAdjustmentsEmpty,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          _ => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final adjustment in state.items)
                _AdjustmentRow(adjustment: adjustment, currency: currency),
            ],
          ),
        };
      },
    );
  }
}

class _AdjustmentRow extends StatelessWidget {
  final CashAdjustment adjustment;
  final TreasuryCurrency currency;

  const _AdjustmentRow({required this.adjustment, required this.currency});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final up = adjustment.deltaInCents > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                up ? Icons.trending_up : Icons.trending_down,
                size: AppSpacing.lg,
                color: up ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                TreasuryFormat.signedMoney(adjustment.deltaInCents, currency),
                softWrap: false,
                style: AppTextStyles.moneyTabular.copyWith(
                  fontWeight: FontWeight.w600,
                  color: up ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Le numéro s'élide, jamais le montant.
              Expanded(
                child: Text(
                  adjustment.number,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.codeMuted,
                ),
              ),
            ],
          ),
          Text(adjustment.reason, style: AppTypography.bodySmall),
          Text(
            l10n.treasuryAdjustmentLine(
              adjustment.cashDay,
              TreasuryFormat.time(adjustment.adjustedAt),
              adjustment.createdByName,
            ),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
