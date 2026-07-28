import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/search_or_separator.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';

/// Dispose deux groupes de recherche bi-mode (« par élève » / « par cycle-
/// niveau ») séparés par un « OU » : côte à côte au-delà de
/// [AppBreakpoints.formMediumMin], empilés en-deçà. Partagé par tous les
/// formulaires de recherche bi-mode (Réinscription, Facturation, Première
/// inscription) — une seule source de vérité pour ce point de rupture.
///
/// Pas d'IntrinsicHeight : les groupes contiennent un LayoutBuilder (champs
/// nom), incompatible avec le calcul des dimensions intrinsèques.
class SearchTwoGroupsLayout extends StatelessWidget {
  final Widget studentGroup;
  final Widget classGroup;
  final String orSeparatorLabel;

  const SearchTwoGroupsLayout({
    super.key,
    required this.studentGroup,
    required this.classGroup,
    required this.orSeparatorLabel,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.formMediumMin;
        final orSeparator = SearchOrSeparator(
          label: orSeparatorLabel,
          vertical: !isWide,
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 3, child: studentGroup),
              orSeparator,
              Expanded(flex: 2, child: classGroup),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [studentGroup, orSeparator, classGroup],
        );
      },
    );
  }
}
