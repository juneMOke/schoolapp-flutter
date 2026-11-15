import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/report_signatory.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/report_signatories_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/signatories/signatory_tile.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/states/treasury_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Trésorerie ▸ Configuration ▸ Signataires des rapports : les blocs imprimés
/// au pied des rapports, dans l'ordre. [onEdit] vaut `null` hors promoteur.
class ReportSignatoriesSection extends StatelessWidget {
  final VoidCallback? onEdit;

  const ReportSignatoriesSection({super.key, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ReportSignatoriesCubit, ReportSignatoriesState>(
      builder: (context, state) {
        final data = state.signatories;
        final edit = state.status == ReportSignatoriesStatus.ready
            ? onEdit
            : null;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.brLg,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppDimensions.treasurySectionIntroMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.treasurySignatoriesTitle,
                          style: AppTypography.titleMedium,
                        ),
                        Text(
                          l10n.treasurySignatoriesSubtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (edit != null)
                    EteeloButton.secondary(
                      label: l10n.treasurySignatoriesEdit,
                      icon: Icons.edit_outlined,
                      onPressed: edit,
                      fullWidth: false,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              switch (state.status) {
                ReportSignatoriesStatus.loading => EteeloListSkeleton(
                  rowCount: 1,
                  pillCount: 0,
                  showAvatar: false,
                  semanticsLabel: l10n.treasurySignatoriesLoading,
                ),
                ReportSignatoriesStatus.failure => TreasuryResultsErrorState(
                  failure: state.failure ?? const ServerFailure(),
                  onRetry: context.read<ReportSignatoriesCubit>().load,
                ),
                ReportSignatoriesStatus.ready => _content(context, data!),
              },
              if (onEdit == null &&
                  state.status == ReportSignatoriesStatus.ready) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.treasurySignatoriesReadOnly,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, ReportSignatories data) {
    final printed = data.printed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EteeloGridView(
          itemCount: printed.length,
          padding: EdgeInsets.zero,
          minItemWidth: AppDimensions.treasurySignatoryTileMinWidth,
          spacing: AppSpacing.md,
          itemBuilder: (context, index) =>
              SignatoryTile(signatory: printed[index]),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          signatoriesProvenance(context, data),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// D'où vient la liste : les blocs par défaut, ou qui l'a modifiée et quand.
String signatoriesProvenance(BuildContext context, ReportSignatories data) {
  final l10n = AppLocalizations.of(context)!;
  final at = data.updatedAt;
  if (data.defaults || at == null) return l10n.treasurySignatoriesDefaults;
  final when = l10n.treasuryDateAtTime(
    MaterialLocalizations.of(
      context,
    ).formatMediumDate(SchoolTime.wallClock(at)),
    TreasuryFormat.time(at),
  );
  final name = data.updatedByName;
  return name == null || name.trim().isEmpty
      ? l10n.treasurySignatoriesUpdatedAt(when)
      : l10n.treasurySignatoriesUpdatedBy(when, name);
}
