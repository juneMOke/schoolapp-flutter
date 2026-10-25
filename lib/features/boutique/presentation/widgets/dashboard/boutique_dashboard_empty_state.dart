import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/entities/dashboard_period.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/dashboard/boutique_dashboard_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Aucune vente sur 3 jours » — remplace tout sous l'en-tête, la période
/// restant accessible. Sur l'année, il n'y a plus rien à élargir : le message
/// dit alors que les ventes viendront.
class BoutiqueDashboardEmptyState extends StatelessWidget {
  final DashboardPeriod period;
  final DashboardWindow window;
  final VoidCallback onOpenTill;

  const BoutiqueDashboardEmptyState({
    super.key,
    required this.period,
    required this.window,
    required this.onOpenTill,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloEmptyResult(
      label: BoutiqueDashboardLabels.emptyTitle(window, period, l10n),
      description: period == DashboardPeriod.year
          ? l10n.boutiqueDashboardEmptyFirst
          : l10n.boutiqueDashboardEmptyWiden,
      medallionIcon: Icons.shopping_bag_outlined,
      fullWidthCard: true,
      primaryAction: EteeloButton.primary(
        label: l10n.boutiqueDashboardOpenTill,
        icon: Icons.storefront_outlined,
        onPressed: onOpenTill,
        fullWidth: false,
      ),
    );
  }
}
