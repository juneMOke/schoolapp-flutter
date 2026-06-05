import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Carte d'erreur reutilisable avec anatomie unique: medaillon, titre,
/// message et action de recuperation.
enum EteeloErrorType { network, unauthorized, forbidden, server, unknown }

class EteeloErrorResult extends StatelessWidget {
  final EteeloErrorType type;
  final String title;
  final String message;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final String? incidentCodeLabel;
  final bool fullWidthCard;
  final double maxWidth;
  final double minHeight;
  final EdgeInsetsGeometry cardPadding;
  final String? semanticsLabel;
  final bool autofocusPrimaryAction;

  const EteeloErrorResult({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.primaryAction,
    this.secondaryAction,
    this.incidentCodeLabel,
    this.fullWidthCard = true,
    this.maxWidth = 460,
    this.minHeight = 380,
    this.cardPadding = const EdgeInsets.fromLTRB(32, 52, 32, 44),
    this.semanticsLabel,
    this.autofocusPrimaryAction = true,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryAction;
    final actions = <Widget?>[
      secondaryAction,
      if (primary != null)
        autofocusPrimaryAction
            ? Focus(autofocus: true, child: primary)
            : primary,
    ].whereType<Widget>().toList(growable: false);

    final tone = type.tone;
    final toneSoft = type.toneSoft;

    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticsLabel ?? title,
      child: SizedBox(
        width: double.infinity,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Center(
            child: _buildCard(tone: tone, toneSoft: toneSoft, actions: actions),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required Color tone,
    required Color toneSoft,
    required List<Widget> actions,
  }) {
    final content = Container(
      width: fullWidthCard ? double.infinity : null,
      padding: cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.shadowCard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ErrorMedallion(tone: tone, toneSoft: toneSoft, icon: type.icon),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (incidentCodeLabel != null &&
              incidentCodeLabel!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _IncidentCodeChip(label: incidentCodeLabel!),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: actions,
            ),
          ],
        ],
      ),
    );

    if (fullWidthCard) {
      return content;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: content,
    );
  }
}

class _ErrorMedallion extends StatelessWidget {
  final Color tone;
  final Color toneSoft;
  final IconData icon;

  const _ErrorMedallion({
    required this.tone,
    required this.toneSoft,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [toneSoft, AppColors.surfaceAlt],
                ),
                border: Border.all(
                  color: tone.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: Icon(icon, size: 38, color: tone),
            ),
          ),
          Positioned(
            top: -3,
            right: -3,
            child: ExcludeSemantics(
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tone,
                  border: Border.all(color: AppColors.surfaceRaised, width: 3),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: AppColors.surfaceRaised,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidentCodeChip extends StatelessWidget {
  final String label;

  const _IncidentCodeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

extension _EteeloErrorTypeX on EteeloErrorType {
  IconData get icon => switch (this) {
    EteeloErrorType.network => Icons.power_off_rounded,
    EteeloErrorType.unauthorized => Icons.lock_outline_rounded,
    EteeloErrorType.forbidden => Icons.gpp_bad_rounded,
    EteeloErrorType.server => Icons.dns_rounded,
    EteeloErrorType.unknown => Icons.warning_amber_rounded,
  };

  Color get tone => switch (this) {
    EteeloErrorType.network => AppColors.bleuArdoise,
    EteeloErrorType.unauthorized ||
    EteeloErrorType.forbidden => AppColors.warning,
    EteeloErrorType.server => AppColors.error,
    EteeloErrorType.unknown => AppColors.bleuArdoise,
  };

  Color get toneSoft => tone.withValues(alpha: 0.16);
}
