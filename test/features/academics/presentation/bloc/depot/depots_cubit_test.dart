import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/attachments/attachment_availability.dart';
import 'package:school_app_flutter/core/attachments/attachment_ref.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/resource_sync_signals.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/academics/domain/entities/depot/copie_rendue.dart';
import 'package:school_app_flutter/features/academics/domain/entities/depot/depot_copie.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/depot/depot_copie_use_cases.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/depot/depots_cubit.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/depot/depots_state.dart';

class _Load extends Mock implements LoadCopiesRenduesUseCase {}

class _Open extends Mock implements OpenDepotFichierUseCase {}

class _Engine extends Mock implements SyncEngine {}

class _Availability extends Mock implements AttachmentAvailabilityTracker {}

void main() {
  DepotFichier page(String id) => DepotFichier(
    id: id,
    ordre: 1,
    ref: AttachmentRef(
      name: '$id.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 1,
      sha256: id,
    ),
  );

  final eleve = CopieRendue(
    studentId: 's1',
    firstName: 'Ali',
    lastName: 'Kanda',
    depot: DepotCopie(
      id: 'd1',
      studentId: 's1',
      fichiers: [page('p1'), page('p2')],
    ),
  );

  late _Load load;
  late _Open open;
  late _Availability availability;

  DepotsCubit build() {
    final engine = _Engine();
    when(() => engine.addFlushCompleteListener(any())).thenReturn(() {});
    return DepotsCubit(
      load: load,
      open: open,
      availability: availability,
      signals: ResourceSyncSignals(
        bus: PullCompletionBus(),
        engine: engine,
        watched: const {'academics_evaluations'},
        pull: () async {},
      ),
    );
  }

  setUpAll(() {
    registerFallbackValue(page('fallback'));
    registerFallbackValue(page('fallback').ref);
  });

  setUp(() {
    load = _Load();
    open = _Open();
    availability = _Availability();
    when(() => availability.watch(any())).thenReturn(() {});
    when(
      () => availability.snapshot(any()),
    ).thenAnswer((_) async => const AttachmentAvailability(online: false));
    when(() => availability.isCached(any())).thenAnswer((_) async => true);
    when(
      () => load('e1'),
    ).thenAnswer((_) async => Right(CopiesRendues([eleve])));
  });

  test('hors ligne, une copie jamais ouverte est grisée', () async {
    final cubit = build();
    await cubit.start('e1');

    expect(cubit.state.load, DepotsLoad.ready);
    expect(cubit.state.canOpen(eleve), isFalse);
    await cubit.close();
  });

  test('les pages viennent dans l ordre, puis restent ouvrables', () async {
    when(() => open('e1', any())).thenAnswer((_) async => Right(Uint8List(1)));
    final cubit = build();
    await cubit.start('e1');

    final pages = (await cubit.pages(eleve)).getOrElse(() => const []);

    expect(pages.map((p) => p.ref.name), ['p1.jpg', 'p2.jpg']);
    expect(cubit.state.canOpen(eleve), isTrue);
    await cubit.close();
  });

  test('une page qui manque arrête tout', () async {
    when(
      () => open('e1', page('p1')),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    final cubit = build();
    await cubit.start('e1');

    final result = await cubit.pages(eleve);

    expect(result, const Left<Failure, Object>(NetworkFailure()));
    verifyNever(() => open('e1', page('p2')));
    await cubit.close();
  });
}
