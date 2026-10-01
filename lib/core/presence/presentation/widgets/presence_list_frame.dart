import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_row.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le registre en liste : un en-tête de colonnes puis les lignes. Sous
/// 900 dp, la liste défile horizontalement plutôt que d'écraser ses colonnes.
class PresenceListFrame extends StatelessWidget {
  /// L'en-tête de la colonne « personne » (« Agent », « Élève »).
  final String personColumn;

  /// L'en-tête de la colonne des heures (« Arrivée · départ ») ; par défaut
  /// « Arrivée ».
  final String? timesColumn;

  /// `null` : pas de colonne des heures prestées.
  final String? hoursColumn;
  final List<Widget> rows;

  const PresenceListFrame({
    super.key,
    required this.personColumn,
    required this.rows,
    this.timesColumn,
    this.hoursColumn,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width =
          constraints.maxWidth < AppDimensions.presenceMarkListMinWidth
          ? AppDimensions.presenceMarkListMinWidth
          : constraints.maxWidth;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              _Header(
                person: personColumn,
                times: timesColumn,
                hours: hoursColumn,
              ),
              for (final row in rows) ...[
                const SizedBox(height: AppSpacing.sm),
                row,
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _Header extends StatelessWidget {
  final String person;
  final String? times;
  final String? hours;

  const _Header({required this.person, this.times, this.hours});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hours = this.hours;
    Widget cell(String text) => Text(
      text.toUpperCase(),
      overflow: TextOverflow.ellipsis,
      style: AppTypography.labelSmall.copyWith(color: AppColors.textMutedAa),
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brSm,
      ),
      child: PresenceRowLayout(
        person: cell(person),
        status: cell(l10n.presenceMarkColStatus),
        times: cell(times ?? l10n.presenceMarkArrival),
        hours: hours == null ? null : cell(hours),
        late: cell(l10n.presenceMarkColLate),
        action: const SizedBox.shrink(),
      ),
    );
  }
}
