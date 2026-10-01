import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_row.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_avatar.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_contract_badge.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_dossier_meter.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_identity_lines.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les agents en tableau : Agent · Fonction · Contrat · Dossier · Synchro.
/// Une ligne entière ouvre l'agent. En-tête et zébrure suivent la grammaire
/// des listes (`ListingTones`) : la terre cuite appartient aux résultats.
class StaffAgentTable extends StatelessWidget {
  final List<StaffFileRow> rows;

  /// La colonne Dossier n'existe que pour un compte qui voit les pièces.
  final bool showDossier;
  final ValueChanged<StaffFileRow>? onOpen;

  const StaffAgentTable({
    super.key,
    required this.rows,
    required this.showDossier,
    this.onOpen,
  });

  static const double _fixedColumn = 150;
  static const double _chevronColumn = 32;

  /// Sous cette largeur, le tableau défile de côté plutôt que d'écraser ses
  /// colonnes souples à rien.
  static const double _minTableWidth = 760;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= _minTableWidth) return _table(context);
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: _minTableWidth, child: _table(context)),
      );
    },
  );

  Widget _table(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ClipRRect(
      borderRadius: AppRadius.brLg,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          border: Border.all(color: ListingTones.barreBord),
          borderRadius: AppRadius.brLg,
        ),
        child: Column(
          children: [
            _Line(
              background: DashboardTones.entete(ListingTones.zoneResultat),
              showDossier: showDossier,
              agent: _header(l10n.staffTableAgent),
              job: _header(l10n.staffTableJob),
              contract: _header(l10n.staffContractLabel),
              dossier: _header(l10n.staffTableDossier),
              sync: _header(l10n.staffTableSync),
            ),
            for (final (index, row) in rows.indexed)
              Material(
                color: index.isOdd
                    ? DashboardTones.zebrure(ListingTones.zoneResultat)
                    : AppColors.surfaceRaised,
                child: InkWell(
                  onTap: onOpen == null ? null : () => onOpen!(row),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppDimensions.staffTableRowMinHeight,
                    ),
                    child: _Line(
                      showDossier: showDossier,
                      agent: _AgentCell(row: row),
                      job: StaffRoleText(member: row.member),
                      contract: StaffContractBadge(kind: row.kind),
                      dossier: row.dossier == null
                          ? const SizedBox.shrink()
                          : StaffDossierMeter(dossier: row.dossier!),
                      sync: RecordSyncPill(state: row.sync),
                      trailing: onOpen == null
                          ? null
                          : const Icon(
                              Icons.chevron_right,
                              color: AppColors.textMutedAa,
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _header(String label) => Text(
    label.toUpperCase(),
    style: AppTypography.labelSmall.copyWith(
      color: ListingTones.inkEnteteTable,
      letterSpacing: 0.6,
    ),
  );
}

/// Une rangée de colonnes : deux souples (agent, fonction), trois fixes.
class _Line extends StatelessWidget {
  final Color? background;
  final bool showDossier;
  final Widget agent;
  final Widget job;
  final Widget contract;
  final Widget dossier;
  final Widget sync;
  final Widget? trailing;

  const _Line({
    required this.showDossier,
    required this.agent,
    required this.job,
    required this.contract,
    required this.dossier,
    required this.sync,
    this.background,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    Widget fixed(Widget child) => SizedBox(
      width: StaffAgentTable._fixedColumn,
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
    return Container(
      color: background,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(flex: 21, child: agent),
          const SizedBox(width: AppSpacing.md),
          Expanded(flex: 12, child: job),
          const SizedBox(width: AppSpacing.md),
          fixed(contract),
          if (showDossier) fixed(dossier),
          fixed(sync),
          SizedBox(width: StaffAgentTable._chevronColumn, child: trailing),
        ],
      ),
    );
  }
}

class _AgentCell extends StatelessWidget {
  final StaffFileRow row;

  const _AgentCell({required this.row});

  static const double _avatarSize = 38;

  @override
  Widget build(BuildContext context) {
    final member = row.member;
    final family = [
      member.lastName,
      member.middleName,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
    return Row(
      children: [
        StaffAvatar(member: member, sync: row.sync, size: _avatarSize),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                family,
                style: AppTypography.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                member.firstName,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              StaffNumberText(staffNumber: member.staffNumber),
            ],
          ),
        ),
      ],
    );
  }
}
