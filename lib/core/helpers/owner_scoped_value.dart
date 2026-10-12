/// Une valeur de session **scopée à son propriétaire** (le compte et l'école) :
/// au premier accès sous un autre propriétaire, elle repart de [initial].
///
/// Un porteur mémoire et non un BLoC : les écrans gardent leurs cubits en
/// `registerFactory`, et ce porteur, enregistré en `lazySingleton`, se lit à
/// la création d'un cubit et s'écrit à chaque geste. La valeur d'une autre
/// session n'a rien à faire ici, et aucune déconnexion n'a à y penser.
class OwnerScopedValue<T> {
  final T initial;
  final String? Function() _owner;
  String? _seenOwner;
  late T _value = initial;

  OwnerScopedValue(this.initial, {required String? Function() owner})
    : _owner = owner {
    _seenOwner = _owner();
  }

  T get value {
    _followOwner();
    return _value;
  }

  set value(T next) {
    _followOwner();
    _value = next;
  }

  void _followOwner() {
    final owner = _owner();
    if (owner == _seenOwner) return;
    _seenOwner = owner;
    _value = initial;
  }
}
