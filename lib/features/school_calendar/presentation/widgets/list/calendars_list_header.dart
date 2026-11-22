import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_page_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'en-tête de la liste (spec §4.6 H, maquette `CalList`) dans sa carte :
/// sur-titre, titre, sous-titre et « Nouveau calendrier ». Il reste affiché
/// pendant le chargement et l'erreur.
class CalendarsListHeader extends StatelessWidget {
  /// `null` : pas de bouton (pas le droit, hors ligne, liste vide — l'état
  /// vide porte alors l'action).
  final VoidCallback? onCreate;

  const CalendarsListHeader({super.key, this.onCreate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final create = onCreate;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg + AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.shadowCard,
      ),
      child: EteeloPageHeader(
        eyebrow: l10n.schoolCalendarEyebrow,
        title: l10n.schoolCalendarTitle,
        subtitle: l10n.schoolCalendarSubtitle,
        titleStyle: AppTypography.titleMedium.copyWith(
          color: AppColors.bleuProfond,
        ),
        actions: [
          if (create != null)
            PrimaryButton(
              label: l10n.schoolCalendarNew,
              icon: Icons.add_rounded,
              fullWidth: false,
              onPressed: create,
            ),
        ],
      ),
    );
  }
}
