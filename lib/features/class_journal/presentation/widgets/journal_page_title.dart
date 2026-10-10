import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le titre de la page : plein cadre, la coquille ne pose pas de fil
/// d'Ariane au-dessus.
class JournalPageTitle extends StatelessWidget {
  const JournalPageTitle({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: Text(
      AppLocalizations.of(context)!.subMenuClassJournal,
      style: AppTypography.titleLarge.copyWith(color: AppColors.bleuArdoise),
    ),
  );
}
