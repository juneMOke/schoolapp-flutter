import 'package:sqflite_common/sqlite_api.dart';

/// La base de l'APPAREIL (`device.db`) : ce qui appartient au poste et non à
/// une école (MULTI_ECOLE_PLAN.md, option C).
///
/// Deux choses y vivent, chacune pour une raison qui ne se déduit pas :
///
///  - **les comptes vus sur la tablette et leur session locale** — le login
///    hors ligne les lit AVANT de savoir quelle école ouvrir ;
///  - **l'index du cache éditique et ses curseurs** — son magasin d'octets est
///    un répertoire unique, sous une clé unique, dont le balayage des orphelins
///    compare le disque à l'index ENTIER. Un index par école y verrait les
///    pièces des autres écoles comme des orphelins, et les effacerait.
///
/// Un type à part plutôt qu'un second `Database` nommé : `getIt<Database>()`
/// reste, sans ambiguïté, la base de l'école.
class DeviceDatabase {
  final Database db;

  const DeviceDatabase(this.db);
}
