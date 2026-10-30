import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// La disposition de la page « Encaisser un paiement ».
///
/// Sur tablette, une colonne : la correction (s'il y en a une), le payeur, la
/// date, les créances, le motif. Sur grand écran, deux : les créances — le
/// travail du guichet — à gauche, le payeur et la date à droite, à hauteur
/// d'œil ; le total et le bouton restent dans la barre du bas.
class FacturationCreatePaymentLayout extends StatelessWidget {
  /// Origine et élève d'une correction, au-dessus de tout le reste.
  final List<Widget> header;
  final Widget payer;

  /// Le jour d'origine d'une correction ; `null` pour un encaissement, daté
  /// du jour de sa saisie.
  final Widget? date;
  final Widget charges;

  /// Motif d'une correction, sous les créances.
  final Widget? footer;

  const FacturationCreatePaymentLayout({
    super.key,
    this.header = const [],
    required this.payer,
    this.date,
    required this.charges,
    this.footer,
  });

  /// Deux colonnes dans cette fenêtre ? La page plein écran (hors coquille)
  /// la mesure ; la barre d'encaissement prend la même largeur qu'elle.
  static bool twoColumnsFor(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppBreakpoints.paymentTwoColumnMin;

  /// Plafond du contenu et de la barre d'encaissement.
  static double maxWidthFor(BuildContext context) => twoColumnsFor(context)
      ? AppDimensions.paymentTwoColumnMaxWidth
      : AppDimensions.facturationContentMaxWidth;

  static const _gap = SizedBox(
    height: AppDimensions.detailSectionSpacing,
    width: AppDimensions.detailSectionSpacing,
  );

  /// Un bloc et tous ses champs, à la place [order] du parcours clavier.
  static Widget _ordered(double order, Widget child) => FocusTraversalOrder(
    order: NumericFocusOrder(order),
    child: FocusTraversalGroup(child: child),
  );

  @override
  Widget build(BuildContext context) {
    final footer = this.footer;
    final date = this.date;
    if (!twoColumnsFor(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final card in header) ...[card, _gap],
          payer,
          _gap,
          if (date != null) ...[date, _gap],
          charges,
          if (footer != null) ...[_gap, footer],
        ],
      );
    }
    // Au clavier, l'ordre du guichet reste celui de la tablette : la
    // correction, puis le payeur et la date, puis les créances — et non un
    // va-et-vient entre les colonnes par bandes horizontales.
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final card in header) ...[_ordered(0, card), _gap],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ordered(
                  2,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      charges,
                      if (footer != null) ...[_gap, footer],
                    ],
                  ),
                ),
              ),
              _gap,
              SizedBox(
                width: AppDimensions.paymentSideColumnWidth,
                child: _ordered(
                  1,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      payer,
                      if (date != null) ...[_gap, date],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
