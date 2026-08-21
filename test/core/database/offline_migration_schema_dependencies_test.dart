import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';

/// Filet contre la panne de démarrage la plus coûteuse du migrateur.
///
/// ## Le défaut qu'il attrape
///
/// Onze étapes de migration vont chercher la définition d'une table dans le
/// schéma COURANT (`schema.firstWhere((t) => t.name == …)`). `firstWhere` lève
/// un `StateError` quand rien ne correspond — donc le jour où une table est
/// retirée de `buildOfflineSchema()`, toute base assez ancienne pour traverser
/// l'étape qui la nommait **cesse de monter en version**. L'app ne démarre plus,
/// sur la tablette d'un agent, pour une table dont plus personne ne se sert.
///
/// C'est arrivé : le retrait de `ref_cours_notation` (palier v27) a cassé
/// l'étape v9, qui l'y lisait. Le correctif — inliner le DDL dans l'étape — est
/// la bonne réponse, mais rien ne l'imposait au suivant.
///
/// ## Pourquoi cette forme
///
/// Le filet évident — « rejouer toutes les montées de 1 à 27 sur une base nue »
/// — ne tient pas : l'étape v3 fait `ALTER TABLE enrollments ADD COLUMN
/// source_ref`, et sur une base bâtie avec le schéma d'AUJOURD'HUI la colonne
/// existe déjà, donc l'ALTER lèverait. C'est correct en production (une vraie
/// base v2 n'a pas la colonne) et intestable à l'identique. Une migration
/// s'applique à des formes historiques qu'on ne sait pas reconstituer à la
/// demande.
///
/// On vise donc la dépendance elle-même, qui est vérifiable sans jouer quoi que
/// ce soit : chaque nom que le migrateur va chercher dans le schéma doit s'y
/// trouver.
void main() {
  /// Tables lues via `schema.firstWhere` dans `app_database.dart`, avec l'étape
  /// qui les nomme. Liste tenue à la main — elle DOIT être complétée à chaque
  /// nouvelle étape qui lit le schéma vivant.
  ///
  /// ⚠️ Si un retrait de table fait échouer ce test, la correction n'est PAS de
  /// retirer la ligne d'ici : c'est d'inliner le DDL dans l'étape concernée,
  /// comme le fait la v9. Une étape de migration décrit le passé ; la faire
  /// suivre le schéma vivant, c'est la faire mentir au premier changement.
  const lookedUpByMigrations = <String, String>{
    'attendance_sessions': 'v4 — modèle session-agrégat (Présence)',
    'classroom_transfers': 'v5 — transfert de classe offline',
    'disciplinary_case_comments': 'v6 — agrégat cas + commentaires',
    'auth_local_user': 'v7 — session offline (ADR-010)',
    'auth_local_session': 'v7 — session offline (ADR-010)',
    'ref_time_slots': 'v8 — Notes/Cours',
    'ref_recurring_sessions': 'v8, v18 — Notes/Cours + scope enseignant',
    'ref_cours': 'v8, v18 — Notes/Cours + scope enseignant',
    'evaluation': 'v8 — Notes/Cours',
    'note_evaluation': 'v8 — Notes/Cours',
    'ref_branche': 'v12, v18 — bundle grades-referential',
    'ref_ligne_bareme': 'v12, v18 — bundle grades-referential',
    'ref_chapitre': 'v12, v18 — bundle grades-referential',
    'ref_periode': 'v12, v18 — bundle grades-referential',
    'ref_sous_periode': 'v12, v18 — bundle grades-referential',
    'ref_school': 'v14 — identité du tenant',
    'payment_anomalies': 'v20 — anomalies de paiement',
    'editique_cache_entries': 'v21/v22 — cache de pièces scellées',
  };

  test(
    'toute table lue par une étape de migration existe encore au schéma',
    () {
      final present = buildOfflineSchema().map((t) => t.name).toSet();
      for (final entry in lookedUpByMigrations.entries) {
        expect(
          present,
          contains(entry.key),
          reason:
              'La table `${entry.key}` a quitté buildOfflineSchema(), mais '
              "l'étape « ${entry.value} » la cherche encore par "
              'schema.firstWhere : toute base assez ancienne pour traverser '
              'cette étape lèvera un StateError et ne démarrera plus. '
              'Inlinez son DDL dans l’étape (cf. la v9 pour '
              '`ref_cours_notation`) au lieu de retirer cette ligne.',
        );
      }
    },
  );

  test('`ref_cours_notation` est bien sortie du schéma (palier v27)', () {
    // Le pendant du test ci-dessus : la table retirée ne doit PAS revenir, et
    // elle ne figure volontairement pas dans `lookedUpByMigrations` — l'étape
    // v9 porte désormais son DDL en dur.
    expect(
      buildOfflineSchema().map((t) => t.name),
      isNot(contains('ref_cours_notation')),
    );
  });

  test('aucun doublon de nom de table dans le schéma', () {
    // `firstWhere` prend la PREMIÈRE correspondance : deux contributions
    // portant le même nom feraient créer l'une et migrer l'autre, en silence.
    final names = buildOfflineSchema().map((t) => t.name).toList();
    expect(names.toSet(), hasLength(names.length));
  });
}
