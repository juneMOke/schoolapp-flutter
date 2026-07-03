import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/moyenne_eleve.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Mode de tri du relevé (spec §6).
enum _ReleveSort { ranking, alpha }

/// Ouvre le relevé par élève d'un bucket (spec §6) — modale centrée, pleine
/// largeur sur écran étroit.
Future<void> showCoursReleveModal(
  BuildContext context, {
  required String brancheNom,
  required String classroomName,
  required String label,
  required BucketVm bucket,
}) {
  final size = MediaQuery.sizeOf(context);
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.bleuProfond.withValues(alpha: 0.5),
    builder: (_) => Dialog(
      backgroundColor: AppColors.surfaceRaised,
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width <= 390 ? AppSpacing.md : AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: size.height * 0.88,
        ),
        child: _ReleveContent(
          brancheNom: brancheNom,
          classroomName: classroomName,
          label: label,
          bucket: bucket,
        ),
      ),
    ),
  );
}

class _ReleveContent extends StatefulWidget {
  final String brancheNom;
  final String classroomName;
  final String label;
  final BucketVm bucket;

  const _ReleveContent({
    required this.brancheNom,
    required this.classroomName,
    required this.label,
    required this.bucket,
  });

  @override
  State<_ReleveContent> createState() => _ReleveContentState();
}

class _ReleveContentState extends State<_ReleveContent> {
  _ReleveSort _sort = _ReleveSort.ranking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bucket = widget.bucket;
    final entries = _entries();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          eyebrow: '${widget.brancheNom} · ${widget.classroomName}',
          title: l10n.courseDetailReleveTitle(widget.label),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KpiRow(bucket: bucket),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedTabFilter<_ReleveSort>(
                        expand: true,
                        selected: _sort,
                        onSelected: (s) => setState(() => _sort = s),
                        options: [
                          SegmentedTabOption(
                            label: l10n.courseDetailSortRanking,
                            value: _ReleveSort.ranking,
                          ),
                          SegmentedTabOption(
                            label: l10n.courseDetailSortAlpha,
                            value: _ReleveSort.alpha,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      l10n.myCoursesStudentCount(bucket.moyennesEleves.length),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (entries.isEmpty)
                  _Empty(label: l10n.courseDetailReleveEmpty)
                else
                  _ReleveList(
                    entries: entries,
                    showRank: _sort == _ReleveSort.ranking,
                  ),
                const SizedBox(height: AppSpacing.md),
                _MethodNote(text: l10n.courseDetailReleveMethod),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<_ReleveEntry> _entries() {
    final eleves = List<MoyenneEleve>.of(widget.bucket.moyennesEleves);
    if (_sort == _ReleveSort.alpha) {
      eleves.sort((a, b) {
        final byLast = a.lastName.toLowerCase().compareTo(
          b.lastName.toLowerCase(),
        );
        if (byLast != 0) return byLast;
        return a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
      });
      return [for (final e in eleves) _ReleveEntry(eleve: e, rank: null)];
    }

    // Classement : moyenne décroissante, non notés en dernier. Rang avec ex æquo
    // (rang = 1 + nombre d'élèves à moyenne strictement supérieure).
    eleves.sort((a, b) {
      final am = a.moyenne;
      final bm = b.moyenne;
      if (am == null && bm == null) return 0;
      if (am == null) return 1;
      if (bm == null) return -1;
      return bm.compareTo(am);
    });
    return [
      for (final e in eleves)
        _ReleveEntry(
          eleve: e,
          rank: e.moyenne == null
              ? null
              : 1 +
                    eleves
                        .where(
                          (o) => o.moyenne != null && o.moyenne! > e.moyenne!,
                        )
                        .length,
        ),
    ];
  }
}

class _ReleveEntry {
  final MoyenneEleve eleve;
  final int? rank;

  const _ReleveEntry({required this.eleve, required this.rank});
}

class _Header extends StatelessWidget {
  final String eyebrow;
  final String title;

  const _Header({required this.eyebrow, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.orDoux,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textOnDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: AppColors.textOnDark),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final BucketVm bucket;

  const _KpiRow({required this.bucket});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final moyenne = bucket.moyenneClasse;
    final above50 = bucket.nombreElevesNotes > 0
        ? '${bucket.nombreEleves50} / ${bucket.nombreElevesNotes}'
        : '—';
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _KpiTile(
          label: l10n.courseDetailReleveKpiAverage,
          value: moyenne == null ? '—' : formatPercent(moyenne),
          valueColor: moyenne == null
              ? AppColors.textPrimary
              : scoreTone(moyenne).color,
        ),
        _KpiTile(
          label: l10n.courseDetailReleveKpiAbove50,
          value: above50,
          valueColor: AppColors.textPrimary,
        ),
        _KpiTile(
          label: l10n.courseDetailReleveKpiEvals,
          value: '${bucket.evalCount}',
          valueColor: AppColors.textPrimary,
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReleveList extends StatelessWidget {
  final List<_ReleveEntry> entries;
  final bool showRank;

  const _ReleveList({required this.entries, required this.showRank});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            _ReleveRow(entry: entries[i], isFirst: i == 0, showRank: showRank),
        ],
      ),
    );
  }
}

class _ReleveRow extends StatelessWidget {
  final _ReleveEntry entry;
  final bool isFirst;
  final bool showRank;

  const _ReleveRow({
    required this.entry,
    required this.isFirst,
    required this.showRank,
  });

  @override
  Widget build(BuildContext context) {
    final eleve = entry.eleve;
    final primary = [
      eleve.lastName,
      eleve.middleName ?? '',
    ].where((s) => s.trim().isNotEmpty).join(' ');
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: isFirst
              ? BorderSide.none
              : const BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (showRank) ...[
            SizedBox(
              width: 24,
              child: Text(
                entry.rank == null
                    ? '–'
                    : entry.rank!.toString().padLeft(2, '0'),
                textAlign: TextAlign.right,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          StudentAvatar(
            firstName: eleve.firstName,
            lastName: eleve.lastName,
            studentId: eleve.studentId,
            size: 30,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primary.isEmpty ? eleve.firstName : primary,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  eleve.firstName,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _ScorePill(moyenne: eleve.moyenne),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final double? moyenne;

  const _ScorePill({required this.moyenne});

  @override
  Widget build(BuildContext context) {
    if (moyenne == null) {
      return Text(
        '—',
        style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted),
      );
    }
    final tone = scoreTone(moyenne!);
    return Container(
      constraints: const BoxConstraints(minWidth: 50),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: tone.color.withValues(alpha: 0.25)),
      ),
      child: Text(
        formatPercent(moyenne!),
        style: AppTypography.labelSmall.copyWith(
          color: tone.color,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _MethodNote extends StatelessWidget {
  final String text;

  const _MethodNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 15,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final String label;

  const _Empty({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}
