import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultat_focus_args.dart';
import 'package:school_app_flutter/features/resultats/presentation/pages/resultat_focus_page.dart';
import 'package:school_app_flutter/features/resultats/presentation/pages/resultats_page.dart';

/// Coordinateur in-shell (spec §Anatomie) : bascule vue classe ↔ vue focus.
///
/// Utilise un [IndexedStack] (plutôt que l'`AnimatedSwitcher` des modules frères)
/// afin de **garder la page de recherche vivante** : au retour du focus, la
/// sélection (cycle/classe/période) et les résultats sont préservés. La vue focus
/// n'est construite que lorsqu'un élève est ouvert ; son `ResultatFocusBloc` est
/// alors créé, puis fermé au retour.
class ResultatsCoordinatorPage extends StatefulWidget {
  const ResultatsCoordinatorPage({super.key});

  @override
  State<ResultatsCoordinatorPage> createState() =>
      _ResultatsCoordinatorPageState();
}

class _ResultatsCoordinatorPageState extends State<ResultatsCoordinatorPage> {
  ResultatFocusArgs? _openFocus;

  void _openFocusView(ResultatFocusArgs args) =>
      setState(() => _openFocus = args);

  void _backToClasse() => setState(() => _openFocus = null);

  @override
  Widget build(BuildContext context) {
    final openFocus = _openFocus;
    return IndexedStack(
      sizing: StackFit.expand,
      index: openFocus == null ? 0 : 1,
      children: [
        ResultatsPage(onOpenFocus: _openFocusView),
        if (openFocus == null)
          const SizedBox.shrink()
        else
          ResultatFocusPage(
            key: ValueKey<String>('resultat-focus-${openFocus.studentId}'),
            args: openFocus,
            onBack: _backToClasse,
          ),
      ],
    );
  }
}
