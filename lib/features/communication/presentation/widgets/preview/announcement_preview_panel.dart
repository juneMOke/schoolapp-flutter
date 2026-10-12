import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/preview/phone_frame.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/preview/reading_page_preview.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/preview/whatsapp_preview.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

enum PreviewSurface { whatsapp, readingPage }

/// L'aperçu parent, en temps réel, pour une famille d'exemple : le message
/// WhatsApp, ou la page de lecture qu'il ouvre.
class AnnouncementPreviewPanel extends StatefulWidget {
  final AnnouncementContent content;
  final String? schoolName;

  /// WhatsApp décoché, ou pas encore activé pour l'école : le message ne
  /// partirait pas, l'aperçu se voile.
  final bool channelOff;

  const AnnouncementPreviewPanel({
    super.key,
    required this.content,
    this.schoolName,
    this.channelOff = false,
  });

  @override
  State<AnnouncementPreviewPanel> createState() =>
      _AnnouncementPreviewPanelState();
}

class _AnnouncementPreviewPanelState extends State<AnnouncementPreviewPanel> {
  var _surface = PreviewSurface.whatsapp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final whatsapp = _surface == PreviewSurface.whatsapp;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.communicationPreviewTitle,
          style: AppTypography.titleSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedTabFilter<PreviewSurface>(
          expand: true,
          semanticsLabel: l10n.communicationPreviewTitle,
          options: [
            SegmentedTabOption(
              label: l10n.communicationChannelWhatsapp,
              value: PreviewSurface.whatsapp,
            ),
            SegmentedTabOption(
              label: l10n.communicationPreviewReadingPage,
              value: PreviewSurface.readingPage,
            ),
          ],
          selected: _surface,
          onSelected: (surface) => setState(() => _surface = surface),
        ),
        const SizedBox(height: AppSpacing.md),
        PhoneFrame(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (whatsapp)
                WhatsappPreview(
                  content: widget.content,
                  schoolName: widget.schoolName,
                )
              else
                ReadingPagePreview(
                  content: widget.content,
                  schoolName: widget.schoolName,
                ),
              if (widget.channelOff) const _Veil(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.communicationPreviewSampleNote,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _Veil extends StatelessWidget {
  const _Veil();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.surface.withValues(alpha: 0.85),
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadius.brPill,
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          AppLocalizations.of(context)!.communicationPreviewChannelOff,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    ),
  );
}
