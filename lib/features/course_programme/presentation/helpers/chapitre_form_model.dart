import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_edit.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_objectif.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_ressource.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/ressource_draft.dart';

/// Une ligne d'objectif de la modale : son identité tient d'une édition à
/// l'autre, l'état « atteint » aussi.
class ObjectifLine {
  final String id;
  final bool atteint;
  final TextEditingController controller;

  ObjectifLine({required this.id, this.atteint = false, String texte = ''})
    : controller = TextEditingController(text: texte);
}

/// Pourquoi le titre est refusé.
enum TitreError { required, tooShort }

/// L'état de la modale d'un chapitre (spec §4) et ses règles, sans widget :
/// un seul champ obligatoire (le titre, 3 caractères au moins), des séances
/// entières positives, des objectifs vides ignorés, des stratégies sans
/// doublon. Les ressources retirées et jointes sont tenues à part : elles
/// partent à l'enregistrement.
class ChapitreFormModel {
  final String coursId;
  final Chapitre? base;
  final String Function() _newId;

  final TextEditingController titre;
  final TextEditingController resume;
  final TextEditingController seances;
  final TextEditingController strategyDraft = TextEditingController();
  final List<ObjectifLine> objectifs;
  final List<String> strategies;
  final List<ChapitreRessource> keptRessources;
  final List<RessourceDraft> addedRessources = [];
  ChapitreStatut statut;
  String? sousPeriodeId;

  ChapitreFormModel({
    required this.coursId,
    required this.base,
    required String Function() newId,
    String? defaultSousPeriodeId,
  }) : _newId = newId,
       titre = TextEditingController(text: base?.titre ?? ''),
       resume = TextEditingController(text: base?.resume ?? ''),
       seances = TextEditingController(
         text: '${base?.seances ?? Chapitre.defaultSeances}',
       ),
       objectifs = [
         for (final o in base?.objectifs ?? const <ChapitreObjectif>[])
           ObjectifLine(id: o.id, atteint: o.atteint, texte: o.texte),
       ],
       strategies = [...?base?.strategies],
       keptRessources = [...?base?.ressources],
       statut = base?.statut ?? ChapitreStatut.planifie,
       sousPeriodeId = base == null
           ? defaultSousPeriodeId
           : base.sousPeriodeId {
    if (objectifs.isEmpty) addObjectif();
  }

  bool get isNew => base == null;

  TitreError? get titreError {
    final value = titre.text.trim();
    if (value.isEmpty) return TitreError.required;
    if (value.length < Chapitre.minTitreLength) return TitreError.tooShort;
    return null;
  }

  int? get _seances {
    final text = seances.text.trim();
    if (text.isEmpty) return 0;
    final value = int.tryParse(text);
    return value == null || value < 0 ? null : value;
  }

  bool get seancesInvalid => _seances == null;

  int get ressourcesCount => keptRessources.length + addedRessources.length;

  void addObjectif() => objectifs.add(ObjectifLine(id: _newId()));

  void removeObjectif(ObjectifLine line) {
    if (objectifs.length <= 1) return;
    objectifs.remove(line);
    line.controller.dispose();
  }

  void toggleStrategy(String strategy) => strategies.contains(strategy)
      ? strategies.remove(strategy)
      : strategies.add(strategy);

  /// Ajoute la stratégie saisie librement, sans doublon ; vide le champ.
  void addCustomStrategy() {
    final value = strategyDraft.text.trim();
    if (value.isNotEmpty && !strategies.contains(value)) strategies.add(value);
    strategyDraft.clear();
  }

  void removeKeptRessource(ChapitreRessource ressource) =>
      keptRessources.remove(ressource);

  /// L'édition, ou `null` si une règle n'est pas tenue.
  ChapitreEdit? result() {
    final seancesValue = _seances;
    if (titreError != null || seancesValue == null) return null;
    final resumeText = resume.text.trim();
    final chapitre = Chapitre(
      id: base?.id ?? _newId(),
      coursId: coursId,
      ordre: base?.ordre ?? 0,
      titre: titre.text.trim(),
      resume: resumeText.isEmpty ? null : resumeText,
      statut: statut,
      seances: seancesValue,
      sousPeriodeId: sousPeriodeId,
      objectifs: [
        for (final line in objectifs)
          if (line.controller.text.trim().isNotEmpty)
            ChapitreObjectif(
              id: line.id,
              texte: line.controller.text.trim(),
              atteint: line.atteint,
            ),
      ],
      strategies: [...strategies],
      blocs: base?.blocs ?? const [],
    );
    final kept = {for (final r in keptRessources) r.id};
    return ChapitreEdit(
      chapitre: chapitre,
      isNew: isNew,
      addedRessources: [...addedRessources],
      removedRessourceIds: [
        for (final r in base?.ressources ?? const <ChapitreRessource>[])
          if (!kept.contains(r.id)) r.id,
      ],
    );
  }

  void dispose() {
    titre.dispose();
    resume.dispose();
    seances.dispose();
    strategyDraft.dispose();
    for (final line in objectifs) {
      line.controller.dispose();
    }
  }
}
