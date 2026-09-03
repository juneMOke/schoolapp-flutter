import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/core/helpers/sorted_nested_options_helper.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/fee_control/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FeeControlPageHelpers {
  const FeeControlPageHelpers._();

  /// Options « cycle - niveau » du contexte académique, triées et dédupliquées.
  ///
  /// Produit directement des [SearchLevelOption] : le formulaire du Contrôle
  /// des frais compose les briques de `core/components/search`, il n'a donc pas
  /// besoin d'un type d'option propre à la feature.
  static List<SearchLevelOption> buildAcademicOptions(
    List<SchoolLevelGroupBundle> bundles,
  ) {
    final seen = <String>{};
    final sortedOptions = SortedNestedOptionsHelper.buildFlat(
      outers: bundles,
      outerOrder: (bundle) => bundle.group.displayOrder,
      inners: (bundle) => bundle.levels,
      innerOrder: (level) => level.displayOrder,
      mapItem: (bundle, level) => SearchLevelOption(
        schoolLevelGroupId: bundle.group.id,
        schoolLevelId: level.id,
        label: '${bundle.group.name} - ${level.name}',
      ),
    );

    return sortedOptions
        .where((option) => seen.add(option.key))
        .toList(growable: false);
  }

  /// Libellé du filtre de statut. Hors « Tous », il emprunte **les libellés de
  /// statut de créance du détail Facturation** (`studentChargeStatus*`) : le même
  /// état ne doit pas s'appeler « Soldé » ici et « Payé » sur la fiche de
  /// l'élève, sinon les deux écrans semblent parler de deux choses.
  static String paymentFilterLabel(
    FeeControlPaymentFilter filter,
    AppLocalizations l10n,
  ) {
    final status = filter.targetStatus;
    if (status == null) return l10n.feeControlPaymentStatusAll;
    return status.localizedLabel(l10n);
  }
}
