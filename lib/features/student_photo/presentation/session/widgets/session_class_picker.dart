import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_class_tile.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le choix de la classe : une tuile par classe (élèves sans photo, taux de
/// couverture), le filtre « uniquement sans photo » coché par défaut, et
/// « Commencer ».
class SessionClassPicker extends StatelessWidget {
  final SessionSetup state;
  final ValueChanged<String> onSelect;
  final ValueChanged<bool> onOnlyMissing;
  final VoidCallback onStart;

  const SessionClassPicker({
    super.key,
    required this.state,
    required this.onSelect,
    required this.onOnlyMissing,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = state.selected;
    final emptyQueue = selected != null && state.startCount == 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: AppDimensions.photoSessionClassMedallion,
                height: AppDimensions.photoSessionClassMedallion,
                decoration: const BoxDecoration(
                  color: AppColors.bleuArdoiseSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: AppColors.bleuArdoise,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                l10n.photoSessionChooseClass,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns =
                  (constraints.maxWidth /
                          (AppDimensions.photoSessionTileMin + AppSpacing.md))
                      .floor()
                      .clamp(1, 6);
              final width =
                  (constraints.maxWidth - (columns - 1) * AppSpacing.md) /
                  columns;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final summary in state.classes)
                    SizedBox(
                      width: width,
                      child: SessionClassTile(
                        summary: summary,
                        selected: summary.klass.id == state.selectedId,
                        onTap: () => onSelect(summary.klass.id),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          InkWell(
            onTap: () => onOnlyMissing(!state.onlyMissing),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppDimensions.photoFilterRow,
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: state.onlyMissing,
                    onChanged: (value) => onOnlyMissing(value ?? true),
                  ),
                  Expanded(child: Text(l10n.photoSessionOnlyMissing)),
                ],
              ),
            ),
          ),
          if (emptyQueue) ...[
            const SizedBox(height: AppSpacing.md),
            EteeloEmptyResult(
              label: l10n.photoSessionAllDoneTitle,
              description: l10n.photoSessionAllDoneMessage,
              medallionIcon: Icons.verified_rounded,
              accentColor: AppColors.photoDone,
              minHeight: 0,
              cardPadding: const EdgeInsets.all(AppSpacing.xl),
              primaryAction: EteeloButton.secondary(
                label: l10n.photoSessionIncludeAll,
                fullWidth: false,
                onPressed: () => onOnlyMissing(false),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: EteeloButton.primary(
              label: selected == null
                  ? l10n.photoSessionPickClass
                  : l10n.photoSessionStart(state.startCount),
              icon: Icons.photo_camera_outlined,
              fullWidth: false,
              onPressed: state.startCount == 0 ? null : onStart,
            ),
          ),
        ],
      ),
    );
  }
}
