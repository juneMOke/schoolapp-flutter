import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/app_bars/module_top_bar.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/content_max_width.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/boutique_bloc.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_line_tile.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le panier, en **page dédiée**, sur tablette et téléphone.
///
/// Empilé sous le catalogue, il obligeait à faire défiler tout un catalogue
/// pour atteindre le total. Sur grand écran, la caisse le montre en colonne à
/// côté du catalogue (cf. `BoutiqueCartView`) et cette page ne s'ouvre pas.
///
/// **Le bloc est celui du catalogue**, passé par valeur : un second bloc
/// composerait un second panier, et la vente encaissée ne serait pas celle
/// qu'on a vue à l'écran.
class BoutiqueCartPage extends StatelessWidget {
  final String academicYearId;
  final List<BoutiqueLevelOption> levels;

  const BoutiqueCartPage({
    super.key,
    required this.academicYearId,
    required this.levels,
  });

  /// Ouvre la page. Rend quand elle se referme.
  static Future<void> push(
    BuildContext context, {
    required BoutiqueBloc bloc,
    required String academicYearId,
    required List<BoutiqueLevelOption> levels,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => BlocProvider<BoutiqueBloc>.value(
        value: bloc,
        child: BoutiqueCartPage(academicYearId: academicYearId, levels: levels),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPageBackground(
      appBar: ModuleTopBar(
        eyebrow: l10n.boutiqueCartPageEyebrow,
        title: l10n.boutiqueCartTitle,
        onBack: () => Navigator.of(context).maybePop(),
        backTooltip: l10n.boutiqueBackToCatalog,
      ),
      child: ContentMaxWidth(
        // Largeur de lecture d'un formulaire : étalés sur 1180, les champs du
        // payeur faisaient 550 dp chacun.
        maxWidth: AppDimensions.facturationContentMaxWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingXL),
          child: BoutiqueCartView(
            academicYearId: academicYearId,
            levels: levels,
          ),
        ),
      ),
    );
  }
}
