import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_day_banner_parts.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_agent_situation.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/staff_pay_profile.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/agent/payroll_agent_hero_tiles.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_avatar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau de la fiche : l'agent entre ses deux flèches (précédent,
/// suivant dans l'ordre du livre), son versement habituel, puis les quatre
/// chiffres qu'on vient chercher — ce que l'école lui doit, ses prêts, ce
/// qu'il a perçu dans l'année, son net prévu.
class PayrollAgentHero extends StatelessWidget {
  final StaffMember? member;
  final String staffMemberId;
  final StaffContractKind? contractKind;
  final StaffPayProfile? profile;
  final PayrollAgentSituation situation;

  /// Rang dans le livre d'entrée, à partir de 0 ; `count` 0 : hors du livre.
  final int index;
  final int count;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  /// `null` : le compte ne modifie pas le profil de paie.
  final VoidCallback? onEditProfile;

  const PayrollAgentHero({
    super.key,
    required this.member,
    required this.staffMemberId,
    required this.contractKind,
    required this.profile,
    required this.situation,
    required this.index,
    required this.count,
    required this.onPrevious,
    required this.onNext,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const onBanner = AppColors.payrollAgentOnBanner;
    final muted = AppTypography.bodySmall.copyWith(
      color: AppColors.payrollAgentOnBannerMuted,
    );
    final member = this.member;
    final meta = [
      ?member?.jobTitle,
      StaffLabels.contract(l10n, contractKind),
      ?member?.staffNumber,
    ].where((part) => part.trim().isNotEmpty).join(' · ');
    final position = count > 0
        ? Text(
            l10n.payrollPayslipPosition(index + 1, count),
            style: AppTypography.labelLarge.copyWith(color: onBanner),
          )
        : null;
    // Sur un téléphone, l'avatar cède sa place au nom, et la position passe
    // sous lui : les deux flèches gardent leurs 48 dp.
    Widget identity(bool compact) => Row(
      children: [
        PresenceBannerButton(
          icon: Icons.chevron_left,
          tooltip: l10n.payrollAgentPrevious,
          onPressed: onPrevious,
        ),
        const SizedBox(width: AppSpacing.md),
        if (member != null && !compact) ...[
          StaffAvatar(
            member: member,
            sync: member.syncState,
            size: AppDimensions.payrollAgentAvatar,
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.payrollAgentEyebrow.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.orDoux,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                member?.fullName ?? staffMemberId,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleLarge.copyWith(color: onBanner),
              ),
              if (meta.isNotEmpty) Text(meta, style: muted),
              _UsualPayout(profile: profile, onEdit: onEditProfile),
              if (compact) ?position,
            ],
          ),
        ),
        if (!compact && position != null) ...[
          const SizedBox(width: AppSpacing.md),
          position,
        ],
        const SizedBox(width: AppSpacing.sm),
        PresenceBannerButton(
          icon: Icons.chevron_right,
          tooltip: l10n.payrollAgentNext,
          onPressed: onNext,
        ),
      ],
    );
    return ClipRRect(
      borderRadius: AppRadius.brCard,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.payrollAgentBannerStart,
              AppColors.payrollAgentBannerMid,
              AppColors.payrollAgentBannerEnd,
            ],
          ),
        ),
        child: Stack(
          children: [
            const KubaPatternLayer(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) => identity(
                      constraints.maxWidth < AppBreakpoints.dataTableCardsMax,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PayrollAgentHeroTiles(situation: situation),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// « Versement habituel · M-Pesa · 0812 345 678 » ; le crayon ouvre le
/// profil de paie.
class _UsualPayout extends StatelessWidget {
  final StaffPayProfile? profile;
  final VoidCallback? onEdit;

  const _UsualPayout({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = this.profile;
    final detail = switch (profile?.preferredMode) {
      PayoutMode.mobileMoney => [
        if (profile?.operator case final op?) PayrollLabels.operator(l10n, op),
        ?profile?.payoutPhone,
      ].join(' · '),
      PayoutMode.bank => [
        ?profile?.bankName,
        ?profile?.bankAccount,
      ].join(' · '),
      _ => '',
    };
    final text = Text(
      l10n.payrollAgentUsualPayout(
        detail.isEmpty ? l10n.payrollAgentPayoutCash : detail,
      ),
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.payrollAgentOnBanner,
      ),
    );
    final onEdit = this.onEdit;
    if (onEdit == null) return text;
    return Row(
      children: [
        Flexible(child: text),
        IconButton(
          tooltip: l10n.payrollAgentEditProfile,
          onPressed: onEdit,
          color: AppColors.payrollAgentOnBanner,
          icon: const Icon(Icons.edit_outlined, size: AppSpacing.lg),
        ),
      ],
    );
  }
}
