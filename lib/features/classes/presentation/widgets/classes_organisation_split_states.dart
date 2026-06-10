import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_common_widgets.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Squelette de chargement de la vue répartie : conserve la grille en affichant
/// 3 cartes fantômes (en-tête + barre + lignes). Marqué « occupé » pour les
/// lecteurs d'écran ; le shimmer respecte reduced-motion.
class ClassesOrganisationClassroomsSkeleton extends StatelessWidget {
  const ClassesOrganisationClassroomsSkeleton({super.key});

  static const int _ghostCount = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n.classesOrganisationLoadingTitle,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= AppBreakpoints.classesGridThreeColMin
                ? 3
                : width >= AppBreakpoints.classesGridTwoColMin
                ? 2
                : 1;
            const gap = AppDimensions.spacingM;
            final cardWidth = columns <= 1
                ? width
                : (width - (columns - 1) * gap) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < _ghostCount; i++)
                  SizedBox(width: cardWidth, child: const _GhostCard()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GhostCard extends StatelessWidget {
  const _GhostCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _ShimmerBox(height: 44, shape: BoxShape.circle),
              SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(height: 14),
                    SizedBox(height: AppDimensions.spacingXS),
                    _ShimmerBox(height: 10, width: 80),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          const _ShimmerBox(height: 7),
          const SizedBox(height: AppDimensions.spacingM),
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: AppDimensions.spacingS),
            const _ShimmerBox(height: 44),
          ],
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  final BoxShape shape;

  const _ShimmerBox({
    required this.height,
    this.width,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.skeletonPulse,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      return _box(AppColors.border);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final color =
            Color.lerp(
              AppColors.border,
              AppColors.surfaceRaised,
              _controller.value,
            ) ??
            AppColors.border;
        return _box(color);
      },
    );
  }

  Widget _box(Color color) => Container(
    width: widget.shape == BoxShape.circle ? widget.height : widget.width,
    height: widget.height,
    decoration: BoxDecoration(
      color: color,
      shape: widget.shape,
      borderRadius: widget.shape == BoxShape.rectangle ? AppRadius.brSm : null,
    ),
  );
}

/// État vide de la vue répartie : médaillon pointillé + invitation à inscrire.
class ClassesOrganisationSplitEmptyState extends StatelessWidget {
  const ClassesOrganisationSplitEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ClassesOrganisationDashedContainer(
      backgroundColor: AppColors.surfaceRaised,
      borderColor: AppColors.borderStrong.withValues(alpha: 0.4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DashedCircleMedallion(icon: Icons.group_add_outlined),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            l10n.classesOrganisationEmptyTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            l10n.classesOrganisationEmptyInvite,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DashedCircleMedallion extends StatelessWidget {
  final IconData icon;

  const _DashedCircleMedallion({required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: CustomPaint(
        painter: _DashedCirclePainter(
          color: AppColors.bleuArdoise.withValues(alpha: 0.5),
        ),
        child: Center(
          child: Icon(icon, size: 26, color: AppColors.bleuArdoise),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()..addOval((Offset.zero & size).deflate(0.7));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + 6).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// État d'erreur de la vue répartie : anatomie ErrorState partagée + Réessayer.
class ClassesOrganisationSplitErrorState extends StatelessWidget {
  final ClassroomErrorType errorType;
  final String message;
  final VoidCallback onRetry;

  const ClassesOrganisationSplitErrorState({
    required this.errorType,
    required this.message,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EteeloErrorResult(
      type: _mapErrorType(errorType),
      title: l10n.classesOrganisationOverviewErrorTitle,
      message: message,
      primaryAction: FilledButton.icon(
        onPressed: onRetry,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.bleuArdoise,
          foregroundColor: AppColors.blancCasse,
          minimumSize: const Size(0, AppDimensions.minTouchTarget),
          shape: const StadiumBorder(),
        ),
        icon: const Icon(Icons.refresh_rounded),
        label: Text(l10n.classesDistributionRetry),
      ),
    );
  }

  EteeloErrorType _mapErrorType(ClassroomErrorType type) => switch (type) {
    ClassroomErrorType.network => EteeloErrorType.network,
    ClassroomErrorType.unauthorized ||
    ClassroomErrorType.auth ||
    ClassroomErrorType.invalidCredentials => EteeloErrorType.unauthorized,
    ClassroomErrorType.server ||
    ClassroomErrorType.storage => EteeloErrorType.server,
    _ => EteeloErrorType.unknown,
  };
}
