import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_server_detail.dart';

void main() {
  group('EditiqueServerDetail', () {
    test('rend le message du serveur quand il y en a un', () {
      expect(
        EditiqueServerDetail.of(
          const NotFoundFailure('Aucune charge pour l élève'),
        ),
        'Aucune charge pour l élève',
      );
      expect(
        EditiqueServerDetail.of(const ValidationFailure('devises multiples')),
        'devises multiples',
      );
    });

    // Le message par défaut n'est pas une parole du serveur : c'est la constante
    // technique en anglais de `failures.dart`, que l'anatomie dit déjà mieux.
    test('rend null sur le message par défaut de la classe', () {
      expect(EditiqueServerDetail.of(const NotFoundFailure()), isNull);
      expect(EditiqueServerDetail.of(const ServerFailure()), isNull);
      expect(EditiqueServerDetail.of(const ValidationFailure()), isNull);
      expect(EditiqueServerDetail.of(const ConflictFailure()), isNull);
      expect(EditiqueServerDetail.of(const UnauthorizedFailure()), isNull);
      expect(
        EditiqueServerDetail.of(const InvalidCredentialsFailure()),
        isNull,
      );
    });

    // Sans réponse HTTP il n'y a pas de corps à décoder. La pré-garde de
    // connectivité du repository porte pourtant un message français très
    // convaincant : elle ne doit jamais ressortir comme un motif serveur.
    test('rend null sur un échec de transport, même messagé', () {
      expect(
        EditiqueServerDetail.of(
          const NetworkFailure(
            'Aucune connexion : le document ne peut pas être émis.',
          ),
        ),
        isNull,
      );
      expect(
        EditiqueServerDetail.of(
          const UncertainOutcomeFailure('délai de réception dépassé'),
        ),
        isNull,
      );
    });

    test('rend null sur un message vide ou blanc', () {
      expect(EditiqueServerDetail.of(const ServerFailure('')), isNull);
      expect(EditiqueServerDetail.of(const ServerFailure('   ')), isNull);
    });

    test('rogne les espaces autour du message', () {
      expect(
        EditiqueServerDetail.of(const ServerFailure('  poste en négatif  ')),
        'poste en négatif',
      );
    });

    // Un type hors du périmètre de l'éditique ne se voit pas attribuer de
    // détail : on ne sait pas si son message vient du serveur.
    test('rend null sur un type de Failure non couvert', () {
      expect(
        EditiqueServerDetail.of(const StorageFailure('disque plein')),
        isNull,
      );
    });
  });
}
