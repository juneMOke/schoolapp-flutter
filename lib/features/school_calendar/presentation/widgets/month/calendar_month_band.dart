import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_dashed_border.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/school_calendar_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_nature_style.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/month_layout.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/month/calendar_dashed_bar.dart';

/// Une bande d'élément sur une semaine du mois (CAL-R4, maquette `CalBand`) :
/// un élément national prend un fond doux de sa teinte, un liseré à gauche
/// et un cadenas ; un élément de l'école, un fond blanc au contour en tirets.
/// Un élément « à vérifier » porte un point ambre. En compact, un trait de
/// 6 dp sans texte, plein ou en tirets — estompé pour une période.
class CalendarMonthBand extends StatelessWidget {
  final MonthBand band;
  final bool compact;
  final bool pending;
  final VoidCallback? onTap;

  const CalendarMonthBand({
    super.key,
    required this.band,
    required this.compact,
    required this.pending,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final element = band.element;
    final tone = element.nature.tone;
    final national = element.isNational;
    if (compact) {
      final radius = _radius(AppDimensions.calendarBandCompactHeight / 2);
      final trait = national
          ? DecoratedBox(
              decoration: BoxDecoration(color: tone.tone, borderRadius: radius),
            )
          : ClipRRect(
              borderRadius: radius,
              child: CalendarDashedBar(color: tone.tone),
            );
      return ExcludeSemantics(
        child: Opacity(
          opacity: element.nature == CalendarNature.period
              ? AppDimensions.calendarCompactPeriodOpacity
              : 1,
          child: SizedBox.expand(child: trait),
        ),
      );
    }
    final radius = _radius(AppDimensions.calendarBandRadius);
    final head = !band.continuesBefore;
    final label = Row(
      children: [
        if (national && head) ...[
          Opacity(
            opacity: AppDimensions.calendarBandLockOpacity,
            child: Icon(
              SchoolCalendarTones.nationalIcon,
              size: AppDimensions.calendarNatureTagIcon,
              color: tone.ink,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        if (element.toVerify && head) ...[
          Container(
            width: AppDimensions.calendarVerifyDot,
            height: AppDimensions.calendarVerifyDot,
            decoration: const BoxDecoration(
              color: AppColors.calendarVerifyDot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        if (pending) ...[
          Icon(
            Icons.cloud_upload_outlined,
            size: AppDimensions.calendarNatureTagIcon,
            color: tone.ink,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Expanded(
          child: Text(
            element.title,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.calendarBand.copyWith(color: tone.ink),
          ),
        ),
      ],
    );
    final padded = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.calendarBandPaddingH,
      ),
      child: label,
    );
    final Widget body = national
        ? ClipRRect(
            borderRadius: radius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(
                      AppColors.surfaceRaised,
                      tone.tone,
                      AppDimensions.calendarBandNationalMix,
                    )!,
                    tone.soft,
                  ],
                ),
                borderRadius: radius,
                border: Border.all(
                  color: tone.tone.withValues(
                    alpha: AppDimensions.calendarBandBorderOpacity,
                  ),
                ),
              ),
              // Le liseré gauche se pose par-dessus : un bord de couleur
              // différente ne se dessine pas avec un rayon.
              child: Stack(
                children: [
                  Positioned.fill(child: padded),
                  if (head)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: AppDimensions.calendarBandAccent,
                      child: ColoredBox(color: tone.tone),
                    ),
                ],
              ),
            ),
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: radius,
            ),
            child: CustomPaint(
              foregroundPainter: DashedRRectPainter(
                color: tone.tone,
                borderRadius: radius,
                strokeWidth: AppDimensions.calendarBandInternalStroke,
                dash: AppDimensions.calendarBandDash,
                gap: AppDimensions.calendarBandDashGap,
              ),
              child: padded,
            ),
          );
    // Un raccourci de pointeur, pas une cible : la case du jour, dessous,
    // porte le geste accessible (I6 : un seul élément ouvre son détail,
    // plusieurs filtrent la liste).
    final tap = onTap;
    return ExcludeSemantics(
      child: Tooltip(
        message: element.title,
        child: tap == null
            ? body
            : MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(onTap: tap, child: body),
              ),
      ),
    );
  }

  BorderRadius _radius(double r) => BorderRadius.horizontal(
    left: band.continuesBefore ? Radius.zero : Radius.circular(r),
    right: band.continuesAfter ? Radius.zero : Radius.circular(r),
  );
}
