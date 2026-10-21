import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/provisional_sales.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/dashboard/boutique_dashboard_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « 2 tickets provisoires en attente de synchronisation » — affiché
/// **seulement** s'il y en a sur la fenêtre.
///
/// Ambre, sans action : ce n'est pas une erreur. L'argent est encaissé, et il
/// est déjà compté dans les chiffres en dessous.
class BoutiqueProvisionalNotice extends StatelessWidget {
  final ProvisionalSales provisional;

  const BoutiqueProvisionalNotice({super.key, required this.provisional});

  @override
  Widget build(BuildContext context) {
    if (provisional.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final amounts = BoutiqueDashboardLabels.moneyInline(
      provisional.amounts.entries,
    );
    return EteeloNotice.tinted(
      icon: Icons.cloud_off_outlined,
      ink: AppColors.warningInk,
      background: AppColors.boutiqueUnresolvedSurface,
      border: AppColors.warning,
      message:
          '${l10n.boutiqueDashboardProvisionalTitle(provisional.saleCount)} — '
          '${l10n.boutiqueDashboardProvisionalMessage(amounts)}',
    );
  }
}
