import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce qui est entré dans le tiroir — **trois cartes, et aucun taux**.
///
/// La bande du recouvrement en porte quatre : encaissé, attendu, reste dû,
/// taux. Ici rien n'est dû et rien n'est attendu ; tout est déjà encaissé. Y
/// glisser un taux ferait chercher un ratio là où le caissier compte des
/// billets.
///
/// Le **total** d'abord, puis ses deux moitiés — frais scolaires et ventes
/// boutique. La part boutique est le seul chiffre réellement neuf de l'écran,
/// et la raison d'être de l'onglet : un uniforme payé comptant est de l'argent
/// reçu au même guichet, dans le même tiroir, le même jour.
///
/// Une ligne par devise dans chaque carte, **dans l'ordre du serveur** — le
/// même que celui des sections qui suivent, parce que tout descend de la même
/// liste. Elles ne s'additionnent pas : leur total n'existe pas, il demanderait
/// un taux de change qui bouge alors qu'aucun argent n'a bougé.
class FinanceTillKpiBand extends StatelessWidget {
  final List<TillCurrencyBlock> blocks;

  const FinanceTillKpiBand({super.key, required this.blocks})
    : assert(
        blocks.length > 0,
        'FinanceTillKpiBand : aucun bloc à afficher. Trois cartes vides ne '
        'disent pas « aucun mouvement » — la vue rend son état vide avant.',
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      container: true,
      label: l10n.financeTillKpiBandA11yLabel,
      child: EteeloKpiBand(
        cards: [
          EteeloKpiCardData(
            label: l10n.financeTillKpiTotal,
            valueLines: _money((summary) => summary.total),
            accent: AppColors.feeStatusPaid,
            accentSoft: AppColors.feeStatusPaidSoft,
            icon: Icons.point_of_sale_rounded,
          ),
          EteeloKpiCardData(
            label: l10n.financeTillKpiFees,
            valueLines: _money((summary) => summary.fees),
            percent: _soleShare((summary) => summary.fees),
            accent: AppColors.bleuArdoise,
            accentSoft: AppColors.billingHelpSurface,
            icon: Icons.school_rounded,
          ),
          EteeloKpiCardData(
            label: l10n.financeTillKpiBoutique,
            valueLines: _money((summary) => summary.boutique),
            percent: _soleShare((summary) => summary.boutique),
            accent: AppColors.terreCuite,
            accentSoft: AppColors.terreCuiteSoft,
            icon: Icons.storefront_rounded,
          ),
        ],
      ),
    );
  }

  /// Un montant par devise, dans l'ordre des blocs — et rien d'autre.
  List<String> _money(int Function(TillSummary summary) pick) => [
    for (final block in blocks)
      MoneyFormat.format(Money.parse(pick(block.summary), block.currency)),
  ];

  /// La part de la moitié dans le total, en pastille.
  ///
  /// `null` — et la pastille disparaît — dans deux cas :
  ///
  /// - **deux devises** : la carte n'a qu'une pastille, et un pourcentage
  ///   unique posé sur deux montants désignerait l'un des deux sans le dire ;
  /// - **tiroir vide** : sans total, il n'y a pas de part dont on soit une
  ///   fraction. « 0 % » se lirait comme un résultat quand il veut dire qu'il
  ///   n'y a rien à rapporter.
  int? _soleShare(int Function(TillSummary summary) pick) {
    if (blocks.length != 1) return null;
    final summary = blocks.single.summary;
    if (summary.total <= 0) return null;
    return ((pick(summary) * 100) / summary.total).round();
  }
}
