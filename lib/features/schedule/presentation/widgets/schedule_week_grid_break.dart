part of 'schedule_week_grid.dart';

/// Bande « récréation » : rayures dorées à 45° (spec §3) + libellé heure.
class _BreakBand extends StatelessWidget {
  final TimetableRow row;
  final AppLocalizations l10n;

  const _BreakBand({required this.row, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final label = row.timeSlot.label?.trim();
    final range =
        '${ScheduleTimeFormat.hourMinute(row.timeSlot.startTime)} – '
        '${ScheduleTimeFormat.hourMinute(row.timeSlot.endTime)}';
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: CustomPaint(
        painter: const _BreakStripePainter(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.free_breakfast_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  '$range · ${label ?? l10n.scheduleBreak}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.codeMuted.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rayures diagonales dorées à 45° (spec §3 : `--or-doux` 7 %).
class _BreakStripePainter extends CustomPainter {
  const _BreakStripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.orDoux.withValues(alpha: 0.07);
    const stripe = 6.0;
    const step = 12.0; // rayure 6 + creux 6
    for (double x = -size.height; x < size.width; x += step) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + size.height, 0)
        ..lineTo(x + size.height + stripe, 0)
        ..lineTo(x + stripe, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BreakStripePainter oldDelegate) => false;
}
