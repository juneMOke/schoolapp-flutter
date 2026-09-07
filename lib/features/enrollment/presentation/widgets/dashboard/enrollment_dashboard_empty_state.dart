import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Aucune inscription » — et surtout : **sur quelle fenêtre**.
///
/// Le titre nomme la fenêtre cherchée. Sans elle, l'utilisateur qui a laissé
/// l'onglet sur « Aujourd'hui » lit « aucune inscription » et comprend que son
/// école est vide, alors que trois cents dossiers l'attendent sous l'onglet
/// « Année ».
///
/// ## Deux vides, deux messages
///
/// Quand la fenêtre couvre déjà tout ce qu'il y a à couvrir, proposer de
/// l'élargir est une impasse : il n'y a rien de plus large. L'écran le dit et
/// n'offre qu'une issue — enregistrer une inscription. Sinon, il propose
/// d'élargir **puis** d'enregistrer, dans cet ordre : élargir coûte un clic et
/// répond souvent, enregistrer engage une saisie.
class EnrollmentDashboardEmptyState extends StatelessWidget {
  /// Libellé de la fenêtre courante, tel qu'il est écrit sur son onglet.
  final String windowLabel;

  /// Vrai quand la fenêtre courante est déjà la plus large disponible.
  ///
  /// Passé par l'appelant plutôt que déduit ici : c'est une propriété de la
  /// fenêtre, et la fenêtre est affaire du bloc.
  final bool isWidestWindow;

  /// Élargit la fenêtre à l'année entière. Ignoré quand [isWidestWindow].
  final VoidCallback? onSeeWholeYear;

  /// Ouvre l'écran de première inscription.
  final VoidCallback? onOpenFirstRegistration;

  const EnrollmentDashboardEmptyState({
    super.key,
    required this.windowLabel,
    required this.isWidestWindow,
    this.onSeeWholeYear,
    this.onOpenFirstRegistration,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final openFirstRegistration = onOpenFirstRegistration == null
        ? null
        : EteeloButton.primary(
            label: l10n.enrollmentDashboardEmptyOpenFirstRegistration,
            icon: Icons.person_add_rounded,
            onPressed: onOpenFirstRegistration,
            fullWidth: false,
          );

    final seeWholeYear = onSeeWholeYear == null
        ? null
        : EteeloButton.secondary(
            label: l10n.enrollmentDashboardEmptySeeWholeYear,
            icon: Icons.calendar_month_rounded,
            onPressed: onSeeWholeYear,
            fullWidth: false,
          );

    return EteeloEmptyResult(
      label: l10n.enrollmentDashboardEmptyTitle(windowLabel),
      description: isWidestWindow
          ? l10n.enrollmentDashboardEmptyWidestMessage
          : l10n.enrollmentDashboardEmptyNarrowMessage,
      medallionIcon: Icons.how_to_reg_outlined,
      accentColor: AppColors.bleuArdoise,
      // Sur la fenêtre la plus large, « élargir » n'existe pas : l'action
      // primaire devient la seule, et c'est celle qui mène quelque part.
      primaryAction: isWidestWindow ? openFirstRegistration : seeWholeYear,
      secondaryAction: isWidestWindow ? null : openFirstRegistration,
      fullWidthCard: true,
    );
  }
}
