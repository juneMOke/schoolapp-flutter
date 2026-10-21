import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart' as tokens;
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Date de la vente », en tête du panier.
///
/// Aujourd'hui par défaut ; le guichet peut remonter jusqu'à l'ouverture de
/// l'année scolaire — un cahier de caisse rattrapé le lendemain, une coupure de
/// courant. Jamais l'avenir.
///
/// Rendre le jour d'aujourd'hui rend `null`, et non la date du jour : un panier
/// laissé ouvert passé minuit serait sinon antidaté sans que personne ne l'ait
/// choisi.
class BoutiqueSaleDateSection extends StatelessWidget {
  /// Le jour choisi, `null` = aujourd'hui.
  final DateTime? saleDate;

  /// L'ouverture de l'année scolaire active ; `null` si le référentiel ne la
  /// donne pas — on ouvre alors un an en arrière.
  final DateTime? academicYearStart;

  final ValueChanged<DateTime?> onChanged;

  /// Horloge injectable, pour les tests.
  final DateTime Function() now;

  const BoutiqueSaleDateSection({
    super.key,
    required this.saleDate,
    required this.academicYearStart,
    required this.onChanged,
    this.now = DateTime.now,
  });

  static DateTime _dayOf(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Borne basse : l'ouverture de l'année, lue en jour brut. Une rentrée
  /// postérieure à aujourd'hui (référentiel en avance) fermerait le sélecteur
  /// sur une plage vide, et `showDatePicker` lève.
  static DateTime firstSelectableDay(DateTime? yearStart, DateTime today) {
    if (yearStart == null) {
      return DateTime(today.year - 1, today.month, today.day);
    }
    final start = _dayOf(yearStart);
    return start.isAfter(today) ? today : start;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final today = _dayOf(now());
    final chosen = saleDate;
    final isBackdated = chosen != null && chosen.isBefore(today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EteeloDateInput(
          label: l10n.boutiqueSaleDateLabel,
          value: chosen ?? today,
          firstDate: firstSelectableDay(academicYearStart, today),
          lastDate: today,
          helpText: l10n.boutiqueSaleDateLabel,
          onChanged: (picked) {
            if (picked == null) return;
            final day = _dayOf(picked);
            onChanged(day == today ? null : day);
          },
        ),
        if (isBackdated) ...[
          const SizedBox(height: AppDimensions.spacingS),
          _BackdatedNote(text: l10n.boutiqueSaleDateBackdated),
        ],
      ],
    );
  }
}

/// La note ambre d'une vente antidatée. Pas une erreur : rien n'est bloqué,
/// c'est le rappel que le ticket portera ce jour-là.
class _BackdatedNote extends StatelessWidget {
  final String text;

  const _BackdatedNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              text,
              // L'encre ambre et non l'ambre de fond : #D68910 ne s'écrit pas
              // lisiblement sur un fond clair.
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens.AppColors.warningInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
