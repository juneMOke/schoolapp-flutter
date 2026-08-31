import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sales_history_period.dart';

void main() {
  /// Un mercredi, en fin de journée.
  final wednesday = DateTime(2026, 9, 2, 17, 42);

  test('« aujourd\'hui » part de MINUIT, pas de maintenant', () {
    // Une caisse du jour qui commencerait à l'heure d'ouverture de l'écran
    // perdrait tout ce que le guichet a encaissé avant de l'ouvrir.
    expect(SalesHistoryPeriod.day.startOf(wednesday), DateTime(2026, 9, 2));
  });

  test('« cette semaine » remonte au LUNDI, celui-ci compris', () {
    expect(SalesHistoryPeriod.week.startOf(wednesday), DateTime(2026, 8, 31));
  });

  test('un LUNDI, la semaine commence le jour même', () {
    // `weekday - monday` vaut alors 0 : le lundi ne remonte pas d'une semaine.
    final monday = DateTime(2026, 8, 31, 8);

    expect(SalesHistoryPeriod.week.startOf(monday), DateTime(2026, 8, 31));
  });

  test('un DIMANCHE appartient encore à la semaine qui s\'achève', () {
    // `weekday` vaut 7 : la semaine remonte au lundi qui précède, pas au
    // lendemain.
    final sunday = DateTime(2026, 9, 6, 20);

    expect(SalesHistoryPeriod.week.startOf(sunday), DateTime(2026, 8, 31));
  });

  test('« ce mois » et « cette année » sont CALENDAIRES', () {
    expect(SalesHistoryPeriod.month.startOf(wednesday), DateTime(2026, 9));
    expect(SalesHistoryPeriod.year.startOf(wednesday), DateTime(2026));
  });

  test('la borne est un PRÉFIXE de 19 caractères, sans suffixe', () {
    // ⚠️ `sold_at` mélange `...:00.000Z` (écriture locale) et `...:00Z` (delta
    // serveur). '.' est INFÉRIEUR à 'Z' : une borne suffixée exclurait
    // silencieusement l'un des deux formats à minuit pile.
    final bound = SalesHistoryPeriod.day.boundFor(wednesday);

    expect(bound, hasLength(19));
    expect(bound, isNot(contains('Z')));
    expect(bound, isNot(contains('.')));
    // Et elle est plus petite que les deux formes du même instant.
    expect(bound.compareTo('${bound}Z'), lessThan(0));
    expect(bound.compareTo('$bound.000Z'), lessThan(0));
  });

  test('la borne est convertie en UTC, comme sold_at', () {
    // « Aujourd'hui » est le jour du GUICHET, mais `sold_at` est en UTC :
    // comparer une heure locale à une colonne UTC décalerait la fenêtre du
    // décalage horaire — trois heures à Kinshasa perdues chaque soir.
    final localMidnight = DateTime(2026, 9, 2);
    final bound = SalesHistoryPeriod.day.boundFor(wednesday);

    expect(bound, localMidnight.toUtc().toIso8601String().substring(0, 19));
  });
}
