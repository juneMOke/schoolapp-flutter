import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/configuration/data/models/school_identity_model.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/school_identity.dart';

const _identity = SchoolIdentity(
  id: 'A',
  name: 'EP Kimbanguiste',
  country: 'RDC',
  city: 'Kinshasa',
  district: 'Lukunga',
  municipality: 'Gombe',
  address: '12, avenue du Commerce',
  phone: '+243 000 000 000',
  email: 'ecole@x.cd',
);

/// Le nombre d'exemplaires par ticket sur le fil de `PUT /schools/{id}`.
void main() {
  test('le choix de l école part dans le corps du PUT', () {
    final json = SchoolIdentityModel.fromEntity(
      _identity.copyWith(ticketCopies: 2),
    ).toJson();

    expect(json['ticketCopies'], 2);
  });

  /// Absent ou `null`, le serveur CONSERVE la valeur déjà enregistrée : une
  /// école qui n'a rien choisi ne risque donc pas d'effacer quoi que ce soit.
  test('rien de choisi : `null`, que le serveur lit comme « conserver »', () {
    final json = SchoolIdentityModel.fromEntity(_identity).toJson();

    expect(json.containsKey('ticketCopies'), isTrue);
    expect(json['ticketCopies'], isNull);
  });

  test('la lecture rend le réglage à l écran', () {
    final entity = SchoolIdentityModel.fromJson({
      ...SchoolIdentityModel.fromEntity(_identity).toJson(),
      'id': 'A',
      'ticketCopies': 3,
    }).toEntity(fallbackId: 'A');

    expect(entity.ticketCopies, 3);
  });
}
