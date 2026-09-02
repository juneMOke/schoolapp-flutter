import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_dao_support.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/parent_local_model.dart';

/// Le rapprochement d'un tuteur **sans numéro** — miroir du `GuardianMatcher`
/// serveur (V117).
///
/// Le téléphone est la clé naturelle du tuteur : il prouve que le tuteur d'un
/// dossier et celui d'un autre sont la même personne. Facultatif depuis la V117,
/// il laisse sans clé le tuteur qui n'en a pas, et c'est cette règle qui en fait
/// office — même nom complet, même dossier d'élève, pas de numéro de part et
/// d'autre.
///
/// Ce qu'elle rend possible : un rejeu idempotent. Ce qu'elle refuse : traverser
/// les dossiers. Deux homonymes sans numéro dans deux familles ne sont
/// rapprochés par rien, et c'est exactement ce que le téléphone prouvait.
ParentLocalModel _parent({
  String id = 'par-neuf',
  String firstName = 'Willy',
  String lastName = 'Ndombo',
  String? surname,
  String? phoneNumber,
}) => ParentLocalModel(
  id: id,
  firstName: firstName,
  lastName: lastName,
  surname: surname,
  phoneNumber: phoneNumber,
  updatedAt: 1,
);

StudentGuardianSnapshot _guardian({
  String id = 'par-existant',
  String firstName = 'Willy',
  String lastName = 'Ndombo',
  String? surname,
  String? phoneNumber,
}) => StudentGuardianSnapshot(
  id: id,
  firstName: firstName,
  lastName: lastName,
  surname: surname,
  phoneNumber: phoneNumber,
);

void main() {
  group('findGuardianWithoutPhone', () {
    test('même nom, même dossier, aucun numéro : c\'est le même tuteur', () {
      expect(
        findGuardianWithoutPhone([_guardian()], _parent()),
        'par-existant',
      );
    });

    test('aucun tuteur au dossier : rien à rapprocher', () {
      expect(findGuardianWithoutPhone(const [], _parent()), isNull);
    });

    /// La règle ne s'applique QU'aux tuteurs sans numéro, des deux côtés. Un
    /// tuteur qui en a un garde sa clé, et c'est elle qui décide — pas son nom.
    test('un homonyme QUI A un numéro n\'est jamais rapproché par le nom', () {
      final guardians = [_guardian(phoneNumber: '+243810220145')];
      expect(findGuardianWithoutPhone(guardians, _parent()), isNull);
    });

    test('nom différent : aucun rapprochement', () {
      final guardians = [_guardian(lastName: 'Kabongo')];
      expect(findGuardianWithoutPhone(guardians, _parent()), isNull);
    });

    /// Le post-nom compte, et « absent » vaut « vide » — sans quoi un tuteur
    /// créé sans post-nom ne se reconnaîtrait pas dans le même tuteur re-saisi
    /// avec un post-nom vide.
    test('post-nom absent et post-nom vide sont la même chose', () {
      expect(
        findGuardianWithoutPhone([
          _guardian(surname: null),
        ], _parent(surname: '')),
        'par-existant',
      );
      expect(
        findGuardianWithoutPhone([
          _guardian(surname: '   '),
        ], _parent(surname: null)),
        'par-existant',
      );
    });

    test('un post-nom RENSEIGNÉ différent sépare deux tuteurs', () {
      expect(
        findGuardianWithoutPhone([
          _guardian(surname: 'Lelo'),
        ], _parent(surname: 'Mwepu')),
        isNull,
      );
    });

    /// Aux espaces et à la casse près, et rien de plus. Ni phonétique, ni
    /// distance d'édition : un rapprochement approximatif fusionnerait deux
    /// personnes réelles sur une ressemblance, et c'est irréversible.
    test('la casse et les espaces de bord ne séparent pas', () {
      expect(
        findGuardianWithoutPhone([
          _guardian(firstName: '  WILLY ', lastName: 'ndombo'),
        ], _parent(firstName: 'Willy', lastName: 'Ndombo')),
        'par-existant',
      );
    });

    test('une ressemblance n\'est PAS un rapprochement', () {
      expect(
        findGuardianWithoutPhone([
          _guardian(lastName: 'Ndombo'),
        ], _parent(lastName: 'Ndombu')),
        isNull,
      );
    });

    test('le premier tuteur qui correspond gagne, les autres sont ignorés', () {
      final guardians = [_guardian(id: 'par-a'), _guardian(id: 'par-b')];
      expect(findGuardianWithoutPhone(guardians, _parent()), 'par-a');
    });
  });
}
