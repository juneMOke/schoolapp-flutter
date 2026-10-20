import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/navigation/location_query.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';

/// L'élève dont la fiche est ouverte à côté de la liste (vue scindée), tenu
/// d'accord avec l'adresse : `?eleve=…&annee=…`.
///
/// Sur le web, c'est le parcours par défaut d'un poste de bureau : F5 rouvre
/// la même fiche, Précédent revient à l'élève d'avant, l'adresse se partage.
/// L'identité (nom, niveau) ne voyage pas dans l'adresse : choisie dans la
/// liste, elle est gardée ; lue dans l'adresse seule, la fiche la relit en
/// base locale.
///
/// Sans routeur (tests d'un écran isolé), la sélection reste en mémoire.
class FacturationSplitSelection extends ChangeNotifier {
  static const studentParam = 'eleve';
  static const yearParam = 'annee';

  final GoRouter? _router;
  FacturationDetailIntent? _selected;

  FacturationSplitSelection(this._router) {
    _router?.routerDelegate.addListener(_followLocation);
    _followLocation();
  }

  FacturationDetailIntent? get selected => _selected;

  /// Ouvre la fiche de [intent] à côté de la liste.
  void select(FacturationDetailIntent intent) {
    _set(intent);
    _writeLocation(intent);
  }

  /// Referme la fiche.
  void clear() {
    _set(null);
    _writeLocation(null);
  }

  void _set(FacturationDetailIntent? intent) {
    if (intent == _selected) return;
    _selected = intent;
    notifyListeners();
  }

  /// L'adresse a changé (Précédent, Suivant, F5) : la fiche la suit.
  void _followLocation() {
    final router = _router;
    if (router == null) return;
    final studentId = LocationQuery.read(router, studentParam) ?? '';
    final yearId = LocationQuery.read(router, yearParam) ?? '';
    if (studentId.isEmpty || yearId.isEmpty) {
      _set(null);
      return;
    }
    final current = _selected;
    if (current?.studentId == studentId && current?.academicYearId == yearId) {
      return;
    }
    _set(
      FacturationDetailIntent.invalid(
        studentId: studentId,
        academicYearId: yearId,
      ),
    );
  }

  void _writeLocation(FacturationDetailIntent? intent) {
    final router = _router;
    if (router == null) return;
    LocationQuery.write(router, {
      studentParam: intent?.studentId,
      yearParam: intent?.academicYearId,
    });
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_followLocation);
    super.dispose();
  }
}
