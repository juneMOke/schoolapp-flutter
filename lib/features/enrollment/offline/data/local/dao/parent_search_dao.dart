import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/database/phone_number_sql.dart';
import 'package:school_app_flutter/core/helpers/phone_number_format.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/enrollment_local_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';

/// Recherche locale de tuteurs déjà connus (popin "Rechercher un parent" de
/// l'étape Tuteurs) : lecture seule, 100% locale, jamais d'erreur métier.
class ParentSearchDao {
  final Database _db;

  const ParentSearchDao(this._db);

  /// Échappe les métacaractères LIKE (`%`/`_`) d'une saisie utilisateur pour
  /// qu'ils soient traités comme des caractères littéraux, pas des jokers
  /// SQL (ex. un nom de famille contenant "_" ne doit pas matcher "n'importe
  /// quel caractère").
  static String _escapeLike(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');

  /// Au moins un critère requis (nom/postnom/prénom et/ou téléphone), sinon
  /// liste vide sans requête SQL. Correspondance partielle (`LIKE`) sur
  /// chaque critère fourni, combinée en ET.
  Future<List<LocalParent>> search({
    String? firstName,
    String? lastName,
    String? surname,
    String? phoneNumber,
    int limit = 20,
  }) async {
    final clauses = <String>[];
    final args = <Object?>[];
    void addLike(String column, String? value) {
      final v = value?.trim() ?? '';
      if (v.isEmpty) return;
      clauses.add("$column LIKE ? ESCAPE '\\'");
      args.add('%${_escapeLike(v)}%');
    }

    addLike('first_name', firstName);
    addLike('last_name', lastName);
    addLike('surname', surname);
    // Le critère arrive en E.164 (`+2438169`) tandis que les fiches en base
    // peuvent porter des formats hérités (`0816939060`, `+243 81 693 90
    // 60`) : on cherche donc la partie NATIONALE dans les chiffres de la
    // colonne, sans quoi un tuteur enregistré autrement serait introuvable —
    // et l'utilisateur en recréerait un doublon.
    final nationalPhone = PhoneNumberFormat.nationalPartOf(
      phoneNumber?.trim() ?? '',
    );
    if (nationalPhone.isNotEmpty) {
      clauses.add(
        "${PhoneNumberSql.digitsOnly('phone_number')} LIKE ? ESCAPE '\\'",
      );
      args.add('%${_escapeLike(nationalPhone)}%');
    }
    if (clauses.isEmpty) return const <LocalParent>[];

    final rows = await _db.query(
      'parents',
      where: clauses.join(' AND '),
      whereArgs: args,
      orderBy: 'last_name, first_name',
      limit: limit,
    );
    return rows
        .map(
          (r) => ParentLocalModel.fromMap(
            r,
          ).toEntity(OfflineRelationshipType.other),
        )
        .toList(growable: false);
  }
}
