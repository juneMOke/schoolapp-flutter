import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';

/// La période consultée, **partagée** par le tableau de bord et le registre
/// (spec §2 : « basculer d'onglet compare, il ne recommence pas »).
///
/// Un porteur mémoire et non un BLoC : chaque écran garde son cubit en
/// `registerFactory` (règle n°2), et ce porteur n'a ni flux ni cycle de vie —
/// il se lit à la création d'un cubit et s'écrit à chaque pas. Enregistré en
/// `lazySingleton` pour la session de l'application.
///
/// **Scopé à son propriétaire** ([owner] : le compte et l'école) : au premier
/// accès sous un autre propriétaire, il repart de zéro. La période d'une
/// autre session n'a rien à faire ici, et aucune déconnexion n'a à y penser.
class ExpensePeriodMemory {
  final String? Function() _owner;
  String? _seenOwner;
  ExpensePeriod _period = ExpensePeriod.initial;

  /// Type à pré-sélectionner à la prochaine ouverture du registre — posé par
  /// un clic sur un poste du tableau de bord, **consommé une seule fois**.
  String? _pendingTypeFilter;

  ExpensePeriodMemory({String? Function()? owner}) : _owner = owner ?? _nobody {
    _seenOwner = _owner();
  }

  static String? _nobody() => null;

  ExpensePeriod get period {
    _followOwner();
    return _period;
  }

  set period(ExpensePeriod value) {
    _followOwner();
    _period = value;
  }

  void requestTypeFilter(String typeId) {
    _followOwner();
    _pendingTypeFilter = typeId;
  }

  /// Rend le type demandé et l'oublie : revenir au registre par le menu ne
  /// doit pas rejouer un filtre d'hier.
  String? takeTypeFilter() {
    _followOwner();
    final value = _pendingTypeFilter;
    _pendingTypeFilter = null;
    return value;
  }

  void _followOwner() {
    final owner = _owner();
    if (owner == _seenOwner) return;
    _seenOwner = owner;
    _period = ExpensePeriod.initial;
    _pendingTypeFilter = null;
  }
}
