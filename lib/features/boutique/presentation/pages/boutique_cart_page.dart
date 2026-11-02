import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/app_bars/module_top_bar.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
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
  final DateTime? academicYearStart;

  /// Ce que la coquille prend à la fenêtre autour de la caisse (barre
  /// latérale), mesuré à l'ouverture : la page couvre toute la fenêtre, la
  /// caisse non. Sert à juger, au passage en paysage, si la caisse montre
  /// désormais le panier en colonne.
  final double chromeWidth;

  const BoutiqueCartPage({
    super.key,
    required this.academicYearId,
    required this.levels,
    this.academicYearStart,
    this.chromeWidth = 0,
  });

  /// Ouvre la page. Rend quand elle se referme.
  static Future<void> push(
    BuildContext context, {
    required BoutiqueBloc bloc,
    required String academicYearId,
    required List<BoutiqueLevelOption> levels,
    DateTime? academicYearStart,
    double chromeWidth = 0,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => BlocProvider<BoutiqueBloc>.value(
        value: bloc,
        child: BoutiqueCartPage(
          academicYearId: academicYearId,
          levels: levels,
          academicYearStart: academicYearStart,
          chromeWidth: chromeWidth,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _ClosesBesideCatalog(
      chromeWidth: chromeWidth,
      child: AppPageBackground(
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
              academicYearStart: academicYearStart,
            ),
          ),
        ),
      ),
    );
  }
}

/// Referme la page quand la caisse dessous montrerait le panier en colonne
/// (`AppBreakpoints.boutiqueSideCartMin`, paysage, fenêtre agrandie) : sinon
/// le panier s'affiche deux fois, en page puis en colonne au retour. Jamais
/// pendant un encaissement, ni sous une modale ou le reçu.
class _ClosesBesideCatalog extends StatefulWidget {
  final double chromeWidth;
  final Widget child;

  const _ClosesBesideCatalog({required this.chromeWidth, required this.child});

  @override
  State<_ClosesBesideCatalog> createState() => _ClosesBesideCatalogState();
}

class _ClosesBesideCatalogState extends State<_ClosesBesideCatalog> {
  bool _closing = false;

  void _closeIfBeside() {
    if (!mounted || _closing) return;
    final route = ModalRoute.of(context);
    final state = context.read<BoutiqueBloc>().state;
    if (route == null ||
        !route.isCurrent ||
        state.isCollecting ||
        state.recordedSale != null) {
      return;
    }
    _closing = true;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final catalog = constraints.maxWidth - widget.chromeWidth;
      if (catalog >= AppBreakpoints.boutiqueSideCartMin) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _closeIfBeside());
      }
      return widget.child;
    },
  );
}
