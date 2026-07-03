import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/periode_scolaire.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/periodes_scolaires_bloc.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/periodes_scolaires_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Barre découpage + pilules de période (spec §2), sous la carte de recherche.
///
/// Le découpage (Trimestres / Semestres) est **dérivé** du `periodType` du cycle
/// sélectionné (une classe est rattachée à un seul découpage) : rendu en
/// indicateur en lecture seule, pas en bascule. Les pilules listent les grandes
/// périodes de l'année (triées par `ordre`). Pilotée par [PeriodesScolairesBloc].
class ResultatsPeriodeBar extends StatelessWidget {
  final Decoupage cycleDecoupage;
  final String? selectedPeriodeId;
  final ValueChanged<PeriodeScolaire> onSelect;
  final VoidCallback onRetry;

  const ResultatsPeriodeBar({
    super.key,
    required this.cycleDecoupage,
    required this.selectedPeriodeId,
    required this.onSelect,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<PeriodesScolairesBloc, PeriodesScolairesState>(
      builder: (context, state) {
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            _DecoupageIndicator(decoupage: cycleDecoupage),
            _body(context, l10n, state),
          ],
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    PeriodesScolairesState state,
  ) {
    switch (state.status) {
      case PeriodesScolairesStatus.initial:
      case PeriodesScolairesStatus.loading:
        return const _PillsSkeleton();
      case PeriodesScolairesStatus.failure:
        return _InlineNotice(
          label: l10n.resultatsPeriodsError,
          onRetry: onRetry,
        );
      case PeriodesScolairesStatus.empty:
        return _InlineNotice(label: l10n.resultatsPeriodsEmpty);
      case PeriodesScolairesStatus.success:
        final periodes = [...state.periodes]
          ..sort((a, b) => a.ordre.compareTo(b.ordre));
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final periode in periodes)
              _PeriodePill(
                label: _pillLabel(l10n, periode),
                selected: periode.id == selectedPeriodeId,
                onTap: () => onSelect(periode),
              ),
          ],
        );
    }
  }

  /// Le libellé serveur (« Semestre 1 »…) prêt à l'emploi, sinon composé
  /// T{n}/S{n} depuis le découpage (repli si le backend ne l'a pas fourni).
  String _pillLabel(AppLocalizations l10n, PeriodeScolaire periode) {
    final libelle = periode.libelle;
    if (libelle != null && libelle.trim().isNotEmpty) {
      return libelle.trim();
    }
    final effective = periode.decoupage == Decoupage.unknown
        ? cycleDecoupage
        : periode.decoupage;
    return switch (effective) {
      Decoupage.trimestre => l10n.resultatsPeriodShortTrimestre(periode.ordre),
      Decoupage.semestre => l10n.resultatsPeriodShortSemestre(periode.ordre),
      Decoupage.unknown => l10n.resultatsPeriodShortGeneric(periode.ordre),
    };
  }
}

class _DecoupageIndicator extends StatelessWidget {
  final Decoupage decoupage;

  const _DecoupageIndicator({required this.decoupage});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = switch (decoupage) {
      Decoupage.trimestre => l10n.resultatsDecoupageTrimestres,
      Decoupage.semestre => l10n.resultatsDecoupageSemestres,
      Decoupage.unknown => l10n.resultatsDecoupagePeriodes,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_view_month_outlined,
            size: 15,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.brPill,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: selected ? AppColors.bleuArdoise : AppColors.surface,
              borderRadius: AppRadius.brPill,
              border: Border.all(
                color: selected ? AppColors.bleuArdoise : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: selected
                    ? AppColors.textOnDark
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillsSkeleton extends StatelessWidget {
  const _PillsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: AppSpacing.sm,
      children: [
        EteeloSkeletonBox(
          width: 84,
          height: 34,
          borderRadius: AppRadius.brPill,
        ),
        EteeloSkeletonBox(
          width: 84,
          height: 34,
          borderRadius: AppRadius.brPill,
        ),
        EteeloSkeletonBox(
          width: 84,
          height: 34,
          borderRadius: AppRadius.brPill,
        ),
      ],
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final String label;
  final VoidCallback? onRetry;

  const _InlineNotice({required this.label, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        if (onRetry != null) ...[
          const SizedBox(width: AppSpacing.xs),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(l10n.resultatsErrorRetry),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.bleuArdoise,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ],
    );
  }
}
