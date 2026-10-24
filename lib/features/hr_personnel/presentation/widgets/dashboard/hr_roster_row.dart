import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_sync_avatar.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_member_row.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/helpers/hr_personnel_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_contract_badge.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_dossier_meter.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une ligne de « Qui sont-ils » : l'agent et sa fonction à gauche ; à
/// droite, sa catégorie, son contrat, depuis quand il est là, son dossier et
/// où en est sa fiche sur cette tablette. Toute la ligne ouvre sa fiche.
///
/// Sous [AppDimensions.hrRosterTwoLinesMaxWidth], le bloc de droite passe sous
/// le nom, toujours aligné à droite.
class HrRosterRow extends StatelessWidget {
  final HrStaffMemberRow row;

  /// L'état de la fiche **sur cette tablette** : le serveur la connaît, mais
  /// une modification peut ne pas lui être encore parvenue.
  final RecordSyncState sync;
  final VoidCallback onOpen;

  const HrRosterRow({
    super.key,
    required this.row,
    required this.sync,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final job = row.jobTitle;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppDimensions.hrRosterRowMinHeight,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final identity = Row(
                children: [
                  PersonSyncAvatar(
                    firstName: row.firstName ?? '',
                    lastName: row.lastName,
                    personId: row.id,
                    sync: sync,
                    size: AppDimensions.hrRosterAvatarSize,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (job != null)
                          Text(
                            job,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
              final facts = _Facts(row: row, sync: sync);
              if (constraints.maxWidth <
                  AppDimensions.hrRosterTwoLinesMaxWidth) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    identity,
                    const SizedBox(height: AppSpacing.sm),
                    Align(alignment: Alignment.centerRight, child: facts),
                  ],
                );
              }
              // Le bloc de droite est borné : sans `Flexible`, le `Wrap`
              // recevrait une largeur infinie, ne passerait jamais à la ligne
              // et déborderait entre 600 et ~860 dp.
              return Row(
                children: [
                  Expanded(flex: 4, child: identity),
                  const SizedBox(width: AppSpacing.md),
                  Flexible(
                    flex: 5,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: facts,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  final HrStaffMemberRow row;
  final RecordSyncState sync;

  const _Facts({required this.row, required this.sync});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final since = HrPersonnelLabels.monthYear(row.entryDate);
    final dossier = row.dossier;
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        Text(
          HrPersonnelLabels.category(l10n, row.category),
          style: AppTypography.labelMedium.copyWith(
            color: HrPersonnelLabels.categoryInk(row.category),
          ),
        ),
        StaffContractBadge(kind: row.contractKind),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppDimensions.hrRosterSeniorityMinWidth,
          ),
          child: Text.rich(
            TextSpan(
              children: [
                if (since != null) TextSpan(text: l10n.hrRosterSince(since)),
                TextSpan(
                  text: HrPersonnelLabels.seniorityOf(l10n, row.seniorityYears),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (dossier != null && dossier.required > 0)
          Tooltip(
            message: l10n.hrRosterDossierTooltip(
              dossier.provided,
              dossier.required,
            ),
            child: StaffDossierMeter.counts(
              done: dossier.provided,
              total: dossier.required,
            ),
          ),
        Semantics(
          label: RecordSyncPill.label(l10n, sync),
          child: RecordSyncDot(state: sync, size: AppDimensions.hrSyncDotSize),
        ),
      ],
    );
  }
}
