import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/school_identity.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_repository.dart';
import 'package:school_app_flutter/features/configuration/presentation/cubit/school_identity_form_cubit.dart';

class _MockRepository extends Mock implements ProvisioningRepository {}

const _complete = SchoolIdentity(
  id: 'ecole-1',
  name: 'Complexe Scolaire Eteelo',
  country: 'RD Congo',
  city: 'Kinshasa',
  district: 'Lukunga',
  municipality: 'Gombe',
  address: '12, avenue de la Recette',
  phone: '+243810000001',
  email: 'direction@eteelo.cd',
);

void main() {
  late _MockRepository repository;

  setUpAll(() => registerFallbackValue(_complete));

  setUp(() {
    repository = _MockRepository();
    when(
      () => repository.loadSchoolIdentity(),
    ).thenAnswer((_) async => const Right(_complete));
    when(
      () => repository.saveSchoolIdentity(any()),
    ).thenAnswer((_) async => const Right(_complete));
  });

  SchoolIdentityFormCubit build() =>
      SchoolIdentityFormCubit(repository: repository);

  group('champs requis', () {
    test('les huit sont nommés un par un quand ils manquent', () {
      // « À compléter : Commune, E-mail » dit où aller ; « 2 champs
      // manquants » laisse chercher.
      const vide = SchoolIdentity(
        id: 'x',
        name: '',
        country: '',
        city: '',
        district: '',
        municipality: '',
        address: '',
        phone: '',
        email: '',
      );

      expect(vide.missingFields, hasLength(8));
      expect(vide.isComplete, isFalse);
    });

    test('un e-mail mal formé compte comme manquant', () {
      final bancal = _complete.copyWith(email: 'direction@eteelo');
      expect(bancal.missingFields, [SchoolIdentityField.email]);
    });

    test('un champ fait d\'espaces compte comme vide', () {
      final bancal = _complete.copyWith(address: '   ');
      expect(bancal.missingFields, [SchoolIdentityField.address]);
    });

    test('les huit renseignés : complet', () {
      expect(_complete.isComplete, isTrue);
      expect(_complete.missingFields, isEmpty);
    });
  });

  group('cascade géographique', () {
    blocTest<SchoolIdentityFormCubit, SchoolIdentityFormState>(
      'changer de district vide la commune',
      build: build,
      seed: () => const SchoolIdentityFormState(
        status: SchoolIdentityFormStatus.ready,
        identity: _complete,
        saved: _complete,
      ),
      act: (cubit) => cubit.selectDistrict('Tshangu'),
      verify: (cubit) {
        // La laisser en place produirait une adresse plausible et fausse —
        // « Gombe, Tshangu » — qui figurerait ensuite sur les attestations et
        // les reçus.
        expect(cubit.state.identity!.district, 'Tshangu');
        expect(cubit.state.identity!.municipality, isEmpty);
        expect(cubit.state.isComplete, isFalse);
      },
    );

    blocTest<SchoolIdentityFormCubit, SchoolIdentityFormState>(
      'rechoisir le même district ne vide rien',
      build: build,
      seed: () => const SchoolIdentityFormState(
        status: SchoolIdentityFormStatus.ready,
        identity: _complete,
        saved: _complete,
      ),
      act: (cubit) => cubit.selectDistrict('Lukunga'),
      verify: (cubit) => expect(cubit.state.identity!.municipality, 'Gombe'),
    );
  });

  group('enregistrement', () {
    blocTest<SchoolIdentityFormCubit, SchoolIdentityFormState>(
      'une saisie incomplète ne part pas au serveur',
      build: build,
      seed: () => SchoolIdentityFormState(
        status: SchoolIdentityFormStatus.ready,
        identity: _complete.copyWith(municipality: ''),
        saved: _complete,
      ),
      act: (cubit) => cubit.save(),
      verify: (_) => verifyNever(() => repository.saveSchoolIdentity(any())),
    );

    blocTest<SchoolIdentityFormCubit, SchoolIdentityFormState>(
      'on repart de ce que le serveur a relu, pas de ce qu\'on lui a envoyé',
      build: () {
        when(() => repository.saveSchoolIdentity(any())).thenAnswer(
          // Le serveur normalise : il rogne l'espace de trop.
          (_) async => Right(_complete.copyWith(name: 'Complexe Scolaire ET')),
        );
        return build();
      },
      seed: () => SchoolIdentityFormState(
        status: SchoolIdentityFormStatus.ready,
        identity: _complete.copyWith(name: 'Complexe Scolaire ET '),
        saved: _complete,
      ),
      act: (cubit) => cubit.save(),
      verify: (cubit) {
        // Lui seul sait ce qu'il a réellement retenu, et l'écart doit se voir
        // tout de suite plutôt qu'à la relecture suivante.
        expect(cubit.state.identity!.name, 'Complexe Scolaire ET');
        expect(cubit.state.isDirty, isFalse);
        expect(cubit.state.justSaved, isTrue);
      },
    );

    blocTest<SchoolIdentityFormCubit, SchoolIdentityFormState>(
      'un 403 ne fait pas passer l\'étape pour enregistrée',
      build: () {
        when(() => repository.saveSchoolIdentity(any())).thenAnswer(
          (_) async => const Left(UnauthorizedFailure('Access forbidden')),
        );
        return build();
      },
      seed: () => const SchoolIdentityFormState(
        status: SchoolIdentityFormStatus.ready,
        identity: _complete,
        saved: SchoolIdentity(
          id: 'ecole-1',
          name: 'ancien nom',
          country: 'RD Congo',
          city: 'Kinshasa',
          district: 'Lukunga',
          municipality: 'Gombe',
          address: '12, avenue de la Recette',
          phone: '+243810000001',
          email: 'direction@eteelo.cd',
        ),
      ),
      act: (cubit) => cubit.save(),
      verify: (cubit) {
        expect(cubit.state.status, SchoolIdentityFormStatus.failure);
        expect(cubit.state.justSaved, isFalse);
        // Toujours modifié : c'est ce qui garde « Continuer » fermé.
        expect(cubit.state.isDirty, isTrue);
      },
    );

    blocTest<SchoolIdentityFormCubit, SchoolIdentityFormState>(
      'éditer après un échec rouvre l\'étape',
      build: build,
      seed: () => const SchoolIdentityFormState(
        status: SchoolIdentityFormStatus.failure,
        identity: _complete,
        saved: _complete,
        failure: ServerFailure('panne'),
      ),
      act: (cubit) => cubit.edit(_complete.copyWith(name: 'Nouveau nom')),
      verify: (cubit) {
        // L'action de récupération repasse l'étape en nominal sans vider la
        // saisie.
        expect(cubit.state.status, SchoolIdentityFormStatus.ready);
        expect(cubit.state.failure, isNull);
        expect(cubit.state.identity!.name, 'Nouveau nom');
      },
    );
  });
}
