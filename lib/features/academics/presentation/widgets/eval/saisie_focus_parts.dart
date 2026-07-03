part of 'saisie_focus.dart';

/// Fil de progression (spec §9) : un carré par élève, coloré par statut,
/// cliquable ; le courant porte un bord bleu profond.
class _ProgressThread extends StatelessWidget {
  final SaisieDraftController draft;
  final int current;
  final ValueChanged<int> onTap;

  const _ProgressThread({
    required this.draft,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var i = 0; i < draft.order.length; i++)
          _ThreadSquare(
            statut: draft.statutFor(draft.order[i]),
            isCurrent: i == current,
            onTap: () => onTap(i),
          ),
      ],
    );
  }
}

class _ThreadSquare extends StatelessWidget {
  final StatutNote statut;
  final bool isCurrent;
  final VoidCallback onTap;

  const _ThreadSquare({
    required this.statut,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fill = statut == StatutNote.enAttente
        ? AppColors.surfaceAlt
        : noteStatutVisual(statut).color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isCurrent ? AppColors.bleuProfond : AppColors.border,
            width: isCurrent ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final NoteEleve student;
  final int position;
  final int total;

  const _Identity({
    required this.student,
    required this.position,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = [
      student.lastName,
      student.middleName ?? '',
    ].where((s) => s.trim().isNotEmpty).join(' ');
    return Row(
      children: [
        StudentAvatar(
          firstName: student.firstName,
          lastName: student.lastName,
          studentId: student.studentId,
          size: 40,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                primary.isEmpty ? student.firstName : primary,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                student.firstName,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Text(
          l10n.evalFocusPosition(position, total),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _BigNote extends StatelessWidget {
  final SaisieDraftController draft;
  final String id;

  const _BigNote({required this.draft, required this.id});

  @override
  Widget build(BuildContext context) {
    final absence = draft.absenceOf(id);
    final raw = draft.rawOf(id);
    final hasError = draft.hasErrorFor(id);
    final max = formatPoints(draft.maxPoints);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: hasError ? AppColors.academicsScoreFail : AppColors.border,
          width: hasError ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: absence != null
          ? Text(
              '—',
              style: AppTypography.displayMedium.copyWith(
                color: AppColors.textMuted,
              ),
            )
          : Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: raw.isEmpty ? '–' : raw,
                    style: AppTypography.displayMedium.copyWith(
                      color: hasError
                          ? AppColors.academicsScoreFail
                          : AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: '  / $max',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AbsencePlaceholder extends StatelessWidget {
  final StatutNote statut;

  const _AbsencePlaceholder({required this.statut});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visual = noteStatutVisual(statut);
    return Container(
      height: 148,
      alignment: Alignment.center,
      child: NotationPill(
        color: visual.color,
        soft: visual.soft,
        icon: visual.icon,
        label: noteStatutLabel(l10n, statut),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final int index;
  final int total;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _NavRow({
    required this.index,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLast = index >= total - 1;
    return Row(
      children: [
        Expanded(
          flex: 10,
          child: EteeloButton.secondary(
            label: l10n.evalFocusPrevious,
            icon: Icons.chevron_left_rounded,
            size: EteeloButtonSize.regular,
            onPressed: index > 0 ? onPrev : null,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 14,
          child: EteeloButton.primary(
            label: isLast ? l10n.evalFocusLast : l10n.evalFocusNext,
            icon: isLast ? null : Icons.chevron_right_rounded,
            size: EteeloButtonSize.regular,
            onPressed: isLast ? null : onNext,
          ),
        ),
      ],
    );
  }
}
