import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_dao.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';

/// Les pièces d'un élève dont **cette tablette** détient une copie scellée.
///
/// C'est la seule source qui dit ce qui est consultable hors ligne. La nuance
/// est essentielle : le barème du catalogue dit ce qu'une pièce **autorise**
/// (« restitution offline ✅ »), pas ce qui est **déjà là**. Promettre
/// « Consulter » sur un type plutôt que sur un fait produirait un bouton qui
/// échoue une fois sur deux.
///
/// Distincte de la trace locale de `generated_documents`, qui n'enregistre que
/// ce que cette tablette a elle-même produit et n'a jamais d'octets à servir.
///
/// Ne remonte jamais d'erreur : une lecture qui échoue rend une liste vide, et
/// la ligne retombe sur « Émettre » — ce qui ne coûte rien sur une pièce
/// idempotente.
class ListCachedDocumentsUseCase {
  final EditiqueCacheDao _dao;
  final CurrentUserContext _currentUser;

  const ListCachedDocumentsUseCase(this._dao, this._currentUser);

  Future<List<EditiqueCacheEntry>> call({
    required String studentId,
    String? academicYearId,
  }) async {
    final schoolId = _currentUser.schoolId;
    // La portée de lecture est l'école : sans elle, on ne lit rien plutôt que
    // de lire tout.
    if (schoolId == null || schoolId.isEmpty) return const [];
    if (studentId.trim().isEmpty) return const [];

    try {
      final indexed = await _dao.listForStudent(
        schoolId: schoolId,
        studentId: studentId,
        academicYearId: academicYearId,
      );
      // **Détenues seulement.** L'index décrit deux choses depuis le delta de
      // synchronisation : les pièces dont la tablette a les octets, et celles
      // dont elle sait seulement qu'elles existent. Rendre les secondes ferait
      // allumer « Consulter » sur une pièce absente — un bouton qui échoue à
      // tous les coups hors ligne, c'est-à-dire précisément là où il est censé
      // servir.
      return indexed.where((entry) => entry.hasBytes).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
