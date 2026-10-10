import 'package:school_app_flutter/features/class_journal/domain/entities/journal_day_sources.dart';
import 'package:school_app_flutter/features/course_programme/domain/repositories/programme_repository.dart';

/// Les chapitres de cours, tels qu'une étiquette les montre : leur numéro est
/// leur rang dans le programme du cours. Un programme illisible n'en donne
/// aucun — la séance se lit sans étiquette.
///
/// Les programmes se lisent en parallèle. Avec [remember], chacun n'est lu
/// qu'une fois : c'est la lecture en ligne de la direction, qu'une navigation
/// jour par jour referait sinon à chaque page.
class JournalChapterRefs {
  final ProgrammeRepository _programme;
  final bool remember;
  final Map<String, Map<String, JournalChapterRef>> _known = {};

  JournalChapterRefs(this._programme, {this.remember = false});

  /// Les chapitres des cours [coursIds], par id de chapitre. Seule une
  /// lecture réussie est retenue : une panne passagère se relit à la page
  /// suivante.
  Future<Map<String, JournalChapterRef>> of(Set<String> coursIds) async {
    final missing = coursIds.where((c) => !_known.containsKey(c)).toList();
    final read = await Future.wait(missing.map(_read));
    final refs = <String, JournalChapterRef>{
      for (final c in coursIds) ...?_known[c],
    };
    for (var i = 0; i < missing.length; i++) {
      final chapters = read[i];
      if (chapters == null) continue;
      refs.addAll(chapters);
      if (remember) _known[missing[i]] = chapters;
    }
    return refs;
  }

  Future<Map<String, JournalChapterRef>?> _read(String coursId) async =>
      (await _programme.loadProgramme(coursId)).fold((_) => null, (p) {
        final rows = p.chapitres;
        return {
          for (var i = 0; i < rows.length; i++)
            rows[i].chapitre.id: JournalChapterRef(
              number: i + 1,
              title: rows[i].chapitre.titre,
            ),
        };
      });
}
