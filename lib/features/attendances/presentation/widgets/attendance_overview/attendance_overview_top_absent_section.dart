import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/top_absent_class.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/attendance_overview_format.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Section « Top 5 des classes les plus absentes » du tableau de bord.
///
/// Classement des 5 classes au plus fort taux d'absence. Chaque ligne associe
/// un badge de rang, le nom et le niveau de la classe, une barre proportionnelle
/// (relative au taux maximal du classement) et le taux d'absence. Le rang 1 est
/// mis en avant (badge rouge desature + chiffre rouge). Lecture seule.
class AttendanceOverviewTopAbsentSection extends StatelessWidget {
  final List<TopAbsentClass> classes;

  const AttendanceOverviewTopAbsentSection({super.key, required this.classes});

  // Largeur fixe de la colonne identite (nom + niveau de la classe).
  static const double _identityWidth = 120.0;
  // Largeur minimale de la valeur de taux en fin de ligne.
  static const double _valueMinWidth = 48.0;
  // Rayon des elements arrondis : badge de rang et barre (pilule).
  static const double _badgeRadius = 7.0;
  static const double _barRadius = 999.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AttendanceOverviewCard(
      title: l10n.attendanceOverviewTopAbsentTitle,
      hint: l10n.attendanceOverviewTopAbsentHint,
      child: _buildChild(context, l10n),
    );
  }

  Widget _buildChild(BuildContext context, AppLocalizations l10n) {
    final top = classes.take(5).toList();
    if (top.isEmpty) {
      return _Placeholder(l10n: l10n);
    }

    // Taux d'absence maximal du classement : echelle des barres proportionnelles.
    // Garde a 0 pour eviter une division par zero si tous les taux sont nuls.
    var maxRate = 0.0;
    for (final c in top) {
      if (c.absenceRate > maxRate) maxRate = c.absenceRate;
    }

    // Resume textuel pour l'accessibilite (l'info ne repose pas sur la couleur).
    final a11ySummary = <String>[
      for (var i = 0; i < top.length; i++)
        '${i + 1}. ${top[i].className} (${top[i].level}) : '
            '${l10n.attendanceOverviewRateValue(AttendanceOverviewFormat.rate(top[i].absenceRate, context))}',
    ].join(', ');

    return Semantics(
      label: '${l10n.attendanceOverviewTopAbsentTitle}. $a11ySummary',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < top.length; i++) ...[
              if (i > 0) const SizedBox(height: AppDimensions.spacingS),
              _TopAbsentRow(rank: i + 1, item: top[i], maxRate: maxRate),
            ],
          ],
        ),
      ),
    );
  }
}

/// Une ligne du classement : badge de rang, identite, barre et taux.
class _TopAbsentRow extends StatelessWidget {
  final int rank;
  final TopAbsentClass item;
  final double maxRate;

  const _TopAbsentRow({
    required this.rank,
    required this.item,
    required this.maxRate,
  });

  @override
  Widget build(BuildContext context) {
    // Largeur relative de la barre (rapport au pic du classement), bornee [0;1].
    final widthFactor = maxRate <= 0
        ? 0.0
        : (item.absenceRate / maxRate).clamp(0.0, 1.0);

    return Row(
      children: [
        _RankBadge(rank: rank),
        const SizedBox(width: AppDimensions.spacingM),
        SizedBox(
          width: AttendanceOverviewTopAbsentSection._identityWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.className,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                item.level,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              AttendanceOverviewTopAbsentSection._barRadius,
            ),
            child: Container(
              height: AppDimensions.attendanceOverviewTopBarHeight,
              color: AppColors.surfaceAlt,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: widthFactor,
                child: Container(color: AppColors.error),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AttendanceOverviewTopAbsentSection._valueMinWidth,
          ),
          child: Text(
            AppLocalizations.of(context)!.attendanceOverviewRateValue(
              AttendanceOverviewFormat.rate(item.absenceRate, context),
            ),
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.error,
              fontFeatures: AppTextStyles.tabularFigures,
            ),
          ),
        ),
      ],
    );
  }
}

/// Badge de rang carre arrondi : rang 1 mis en avant (fond/texte rouge),
/// rangs 2 a 5 neutres (fond bordure, texte secondaire).
class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final isLeader = rank == 1;
    return Container(
      width: AppDimensions.attendanceOverviewRankBadgeSize,
      height: AppDimensions.attendanceOverviewRankBadgeSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isLeader
            ? AppColors.presenceStateUnjustifiedSoft
            : AppColors.border,
        borderRadius: BorderRadius.circular(
          AttendanceOverviewTopAbsentSection._badgeRadius,
        ),
      ),
      child: Text(
        '$rank',
        style: AppTextStyles.badge.copyWith(
          color: isLeader ? AppColors.error : AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          fontFeatures: AppTextStyles.tabularFigures,
        ),
      ),
    );
  }
}

/// Placeholder discret affiche lorsqu'aucune classe n'est disponible.
class _Placeholder extends StatelessWidget {
  final AppLocalizations l10n;

  const _Placeholder({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
      child: Text(
        l10n.attendanceOverviewEmptyDescription,
        style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}
