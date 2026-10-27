import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_row_view.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_person_heading.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les personnes encore « à pointer », avant de valider la journée : une
/// ligne par personne, avec la tête de ligne du registre (avatar, nom,
/// fonction ou classe) — on y reconnaît d'un coup d'œil qui manque.
/// « Voir dans le registre » y ramène, filtré sur elles.
class PresenceUnmarkedList extends StatelessWidget {
  final List<PresenceRowView> people;

  /// `null` : pas de retour au registre proposé.
  final VoidCallback? onReview;

  const PresenceUnmarkedList({super.key, required this.people, this.onReview});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onReview = this.onReview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.presenceMarkUnmarkedListTitle(people.length),
          style: AppTypography.titleSmall.copyWith(
            color: AppColors.presenceMarkLateInk,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (final (i, person) in people.indexed) ...[
                if (i > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: PresencePersonHeading(row: person),
                ),
              ],
            ],
          ),
        ),
        if (onReview != null)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: EteeloButton.ghost(
              label: l10n.presenceMarkReviewUnmarked,
              icon: Icons.filter_list,
              onPressed: onReview,
              fullWidth: false,
            ),
          ),
      ],
    );
  }
}
