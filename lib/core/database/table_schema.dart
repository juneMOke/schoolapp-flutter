/// Contribution de schéma d'un module au socle offline : le DDL de création
/// d'une table + ses index. Le migrateur ([openOfflineDatabase]) agrège toutes
/// les contributions à la création de la base (onCreate).
///
/// Chaque branche offline ajoute ses tables à `buildOfflineSchema()`
/// (cf. offline_schema.dart) : point d'extension purement additif.
class TableSchema {
  /// Nom logique de la table (diagnostic / dédup).
  final String name;

  /// `CREATE TABLE …` complet (sans le point-virgule final).
  final String createTableSql;

  /// `CREATE INDEX …` associés (exécutés après la création de la table).
  final List<String> createIndexSql;

  const TableSchema({
    required this.name,
    required this.createTableSql,
    this.createIndexSql = const [],
  });
}
