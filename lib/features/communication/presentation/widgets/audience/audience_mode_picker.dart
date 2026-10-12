import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_labels.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/choice_tile.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un seul mode de ciblage à la fois.
class AudienceModePicker extends StatelessWidget {
  final AudienceMode value;
  final ValueChanged<AudienceMode>? onChanged;

  const AudienceModePicker({super.key, required this.value, this.onChanged});

  static IconData iconOf(AudienceMode mode) => switch (mode) {
    AudienceMode.school => Icons.apartment_outlined,
    AudienceMode.levels => Icons.layers_outlined,
    AudienceMode.classrooms => Icons.meeting_room_outlined,
    AudienceMode.students => Icons.person_search_outlined,
    AudienceMode.overdue => Icons.payments_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const tone = (
      ink: AppColors.bleuArdoise,
      soft: AppColors.bleuArdoiseSoft,
      icon: Icons.circle,
    );
    return Semantics(
      container: true,
      label: l10n.communicationAudienceModeLabel,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final mode in AudienceMode.values)
            ChoiceTile(
              label: l10n.audienceModeLabel(mode),
              icon: iconOf(mode),
              tone: tone,
              selected: mode == value,
              minHeight: AppDimensions.communicationChoiceMinHeight,
              onTap: onChanged == null ? null : () => onChanged!(mode),
            ),
        ],
      ),
    );
  }
}
