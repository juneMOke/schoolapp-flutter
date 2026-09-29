import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/geo/address_geo_catalog.dart';

/// Le référentiel réel (`assets/catalogs/address_geo_catalog.json`), lu comme
/// le lit l'application : c'est lui que partagent l'inscription, l'identité de
/// l'école et, demain, la fiche d'un agent.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AddressGeoCatalog catalog;

  setUpAll(() async => catalog = await AddressGeoCatalog.load());

  test('la cascade part de Kinshasa et de ses quatre districts', () {
    expect(catalog.cityOptions(), [AddressGeoCatalog.defaultCity]);
    expect(catalog.districtsForCity('Kinshasa'), [
      'Lukunga',
      'Funa',
      'Mont-Amba',
      'Tshangu',
    ]);
    expect(
      catalog.municipalitiesForDistrict('Kinshasa', 'Lukunga'),
      contains('Gombe'),
    );
  });

  test('un quartier s\'affiche avec son code postal et s\'enregistre sans', () {
    expect(
      catalog.neighborhoodsForMunicipality('Kinshasa', 'Tshangu', 'Masina'),
      contains('Télévision (1005190)'),
    );
    expect(
      catalog.neighborhoodNameFromDisplay(
        'Kinshasa',
        'Tshangu',
        'Masina',
        'Télévision (1005190)',
      ),
      'Télévision',
    );
    expect(
      catalog.neighborhoodDisplayFromName(
        'Kinshasa',
        'Tshangu',
        'Masina',
        'Télévision',
      ),
      'Télévision (1005190)',
    );
  });

  test('une valeur stockée sans accents ni casse retrouve son option', () {
    expect(catalog.resolveDistrict('Kinshasa', 'mont amba'), 'Mont-Amba');
    expect(
      catalog.resolveNeighborhoodName(
        'Kinshasa',
        'Mont-Amba',
        'Kisenso',
        'LIBERATION',
      ),
      'Libération',
    );
  });

  test('une valeur que le référentiel ne connaît plus reste proposée', () {
    expect(
      catalog.districtsForCity('Kinshasa', include: 'Ancien district').first,
      'Ancien district',
    );
  });

  test('le référentiel est chargé une seule fois', () async {
    expect(identical(await AddressGeoCatalog.load(), catalog), isTrue);
  });
}
