import 'package:school_app_flutter/features/academics/domain/entities/notation/intitule_colonne.dart';

/// `{libelle, libelleCourt}` d'un objet du fil : `null` s'ils manquent (serveur
/// plus ancien) ou sont vides.
IntituleColonne? intituleColonneFromJson(Object? json) {
  if (json is! Map) return null;
  return IntituleColonne.of(
    _string(json['libelle']),
    _string(json['libelleCourt']),
  );
}

/// L'examen d'une période sous la clé [key] : champ absent ⇒ inconnu, `null` ⇒
/// absent, objet ⇒ nommé (inconnu s'il n'a aucun nom lisible).
ColonneExamen colonneExamenFromJson(Map<String, dynamic> json, String key) {
  if (!json.containsKey(key)) return const ColonneExamen.inconnue();
  final raw = json[key];
  if (raw == null) return const ColonneExamen.absente();
  final intitule = intituleColonneFromJson(raw);
  return intitule == null
      ? const ColonneExamen.inconnue()
      : ColonneExamen.nommee(intitule);
}

String? _string(Object? value) => value is String ? value : null;
