import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';

/// Ce qu'un module rattaché aux cours retire de la tablette quand un cours
/// n'est plus au professeur.
typedef CoursEvictor = Future<void> Function(String coursId);

/// Le retrait d'un cours réaffecté (403 `COURS_NOT_OWNED`), **en un seul
/// endroit** : sa référence, ses évaluations et notes, ce que les modules
/// rattachés y ont enregistré ([register]), et les curseurs de tous les flux
/// scopés cours.
///
/// Les curseurs partent tous, pas seulement celui du flux qui a reçu le 403 :
/// le cours disparaît de `ref_cours` ici, aucun autre flux ne le reverra donc
/// dans son itération — un curseur laissé derrière ferait reprendre une
/// réaffectation en retour au lieu de rebootstraper (perte silencieuse).
class CoursEviction {
  final AcademicsRefLocalDataSource _refLocal;
  final AcademicsLocalDataSource _local;
  final SyncMetaDao _syncMetaDao;
  final Set<String> _cursorPrefixes;
  final List<CoursEvictor> _evictors = [];

  CoursEviction({
    required AcademicsRefLocalDataSource refLocalDataSource,
    required AcademicsLocalDataSource localDataSource,
    required SyncMetaDao syncMetaDao,
    required Set<String> cursorPrefixes,
  }) : _refLocal = refLocalDataSource,
       _local = localDataSource,
       _syncMetaDao = syncMetaDao,
       _cursorPrefixes = {...cursorPrefixes};

  /// Un module rattaché aux cours : son flux scopé ([cursorPrefix]) et ce
  /// qu'il retire ([evict]).
  void register({required String cursorPrefix, required CoursEvictor evict}) {
    _cursorPrefixes.add(cursorPrefix);
    _evictors.add(evict);
  }

  Future<void> evict(String coursId) async {
    for (final evict in _evictors) {
      await evict(coursId);
    }
    await _refLocal.evictCours(coursId);
    await _local.evictCoursData(coursId);
    for (final prefix in _cursorPrefixes) {
      await _syncMetaDao.deleteCursor('$prefix:$coursId');
      await _syncMetaDao.deleteCursor('${prefix}_bootstrap:$coursId');
    }
  }
}
