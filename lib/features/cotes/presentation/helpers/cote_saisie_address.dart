import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/navigation/location_query.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/list/cote_student_query.dart';

/// L'adresse de la Saisie des notes :
/// `?classe=…&portee=…&cible=…&eleve=…&recherche=…&filtre=…`. Un F5 retrouve
/// la classe, la portée, l'élève, et la liste telle qu'on l'avait filtrée.
abstract final class CoteSaisieAddress {
  static const classe = 'classe';
  static const portee = 'portee';
  static const cible = 'cible';
  static const eleve = 'eleve';
  static const recherche = 'recherche';
  static const filtre = 'filtre';

  /// Tout retirer : plus de classe ouverte.
  static const Map<String, String?> cleared = {
    classe: null,
    portee: null,
    cible: null,
    eleve: null,
    recherche: null,
    filtre: null,
  };

  static CoteScope? scopeOf(GoRouter router) {
    final value = LocationQuery.read(router, portee);
    final match = CotePortee.values.where((p) => p.name == value).firstOrNull;
    if (match == null) return null;
    return CoteScope(portee: match, cibleId: LocationQuery.read(router, cible));
  }

  /// La recherche et le filtre de l'adresse ; un filtre inconnu vaut « tous ».
  static CoteStudentQuery queryOf(GoRouter? router) {
    if (router == null) return CoteStudentQuery();
    final value = LocationQuery.read(router, filtre);
    return CoteStudentQuery(
      text: LocationQuery.read(router, recherche) ?? '',
      filter:
          CoteStudentFilter.values.where((f) => f.name == value).firstOrNull ??
          CoteStudentFilter.all,
    );
  }

  /// « Tous » et la recherche vide ne s'écrivent pas : l'adresse reste courte.
  static Map<String, String?> ofQuery(CoteStudentQuery query) => {
    recherche: query.text.isEmpty ? null : query.text,
    filtre: query.filter == CoteStudentFilter.all ? null : query.filter.name,
  };
}
