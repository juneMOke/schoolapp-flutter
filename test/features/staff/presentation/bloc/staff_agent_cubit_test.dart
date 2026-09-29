import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_draft_validator.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_member_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_agent_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_agent_state.dart';

import '../../staff_builders.dart';

class _MockSave extends Mock implements SaveStaffMemberUseCase {}

class _MockLoad extends Mock implements LoadStaffMemberUseCase {}

void main() {
  late _MockSave save;
  late _MockLoad load;

  setUpAll(() => registerFallbackValue(const StaffMemberDraft(id: 'x')));

  setUp(() {
    save = _MockSave();
    load = _MockLoad();
  });

  StaffAgentCubit creating([
    StaffMemberDraft draft = const StaffMemberDraft(id: 'new'),
  ]) => StaffAgentCubit(
    save: save,
    load: load,
    others: const [],
    today: '2026-09-29',
    draft: draft,
  );

  test('création : aucune erreur au premier regard', () {
    final cubit = creating();

    expect(cubit.state.mode, StaffAgentMode.create);
    expect(cubit.state.visibleErrors, isEmpty);
  });

  test(
    'Suivant sur une étape fautive : on reste, et ses erreurs paraissent',
    () {
      final cubit = creating()..next();

      expect(cubit.state.step, 0);
      expect(cubit.state.visibleErrors.keys.every((f) => f.step == 0), isTrue);
      expect(cubit.state.visibleErrorSteps, {0});
    },
  );

  test('on n atteint une étape qu après avoir validé la précédente', () {
    final cubit = creating(completeDraft())..goTo(2);
    expect(cubit.state.step, 0);

    cubit
      ..next()
      ..next()
      ..goTo(0)
      ..goTo(2);
    expect(cubit.state.step, 2);
    expect(cubit.state.reached, 2);
  });

  test(
    'enregistrer une fiche fautive saute à la première étape en erreur',
    () async {
      final draft = completeDraft().copyWith(district: '');
      final cubit = creating(draft)
        ..next()
        ..next()
        ..next();

      expect(await cubit.save(), isFalse);
      expect(cubit.state.step, 1);
      expect(cubit.state.visibleErrors.keys, [StaffField.district]);
      verifyNever(() => save(any()));
    },
  );

  test('enregistrer une fiche juste bascule en consultation', () async {
    when(() => save(any())).thenAnswer((_) async => const Right(unit));
    when(() => load(any())).thenAnswer(
      (_) async => Right(
        member(
          'new',
          lastName: 'Kalala',
          staffNumber: null,
          syncState: StaffSyncState.pending,
        ),
      ),
    );
    final cubit = creating(completeDraft());

    expect(await cubit.save(), isTrue);
    expect(cubit.state.mode, StaffAgentMode.view);
    expect(cubit.state.justSaved, isTrue);
    expect(cubit.state.member?.syncState, StaffSyncState.pending);
  });

  test('un échec d écriture reste en saisie, sans rien perdre', () async {
    when(
      () => save(any()),
    ).thenAnswer((_) async => const Left(StorageFailure()));
    final cubit = creating(completeDraft());

    expect(await cubit.save(), isFalse);
    expect(cubit.state.mode, StaffAgentMode.create);
    expect(cubit.state.failure, isA<StorageFailure>());
    expect(cubit.state.draft, completeDraft());
  });

  test(
    'consultation : lecture seule ; Modifier puis Annuler rend la fiche',
    () {
      final existing = member('m-1', firstName: 'Jean');
      final cubit = StaffAgentCubit(
        save: save,
        load: load,
        others: const [],
        today: '2026-09-29',
        draft: StaffMemberDraft.of(existing),
        member: existing,
      );

      cubit.updateDraft((d) => d.copyWith(firstName: 'Ignoré'));
      expect(cubit.state.draft.firstName, 'Jean');

      cubit
        ..startEdit()
        ..updateDraft((d) => d.copyWith(firstName: 'Paul'));
      expect(cubit.hasChanges, isTrue);
      expect(cubit.state.step, 0);

      cubit.cancelEdit();
      expect(cubit.state.mode, StaffAgentMode.view);
      expect(cubit.state.draft.firstName, 'Jean');
    },
  );
}
