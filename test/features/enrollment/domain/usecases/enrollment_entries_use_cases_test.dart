import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/paginated_response.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_stats_repository.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_entries_report_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_entries_use_case.dart';

class _MockRepository extends Mock implements EnrollmentStatsRepository {}

/// La table et son PDF ne lisent **pas** dans le même ordre, et chacun demande
/// le sien explicitement : l'écran suit l'ordre du guichet, le registre
/// imprimé se range par nom — on ne cherche pas sur le papier ce qu'on
/// regarde à l'écran.
void main() {
  late _MockRepository repository;

  setUpAll(() {
    registerFallbackValue(const EnrollmentStatsWindow.year());
    registerFallbackValue(EnrollmentEntriesOrder.oldestFirst);
  });

  setUp(() => repository = _MockRepository());

  test('la table et le registre demandent CHACUN leur ordre', () async {
    when(
      () => repository.getEntries(
        window: any(named: 'window'),
        page: any(named: 'page'),
        size: any(named: 'size'),
        order: any(named: 'order'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        PaginatedResponse<DayEnrollmentEntry>(
          content: <DayEnrollmentEntry>[],
          totalElements: 0,
          totalPages: 0,
          page: 3,
          size: 8,
        ),
      ),
    );
    when(
      () => repository.getEntriesReport(
        window: any(named: 'window'),
        order: any(named: 'order'),
      ),
    ).thenAnswer((_) async => const Left(NetworkFailure('coupure')));

    await GetEnrollmentEntriesUseCase(repository)(
      window: const EnrollmentStatsWindow.month(),
      page: 3,
    );
    await GetEnrollmentEntriesReportUseCase(repository)(
      window: const EnrollmentStatsWindow.month(),
    );

    final listOrder = verify(
      () => repository.getEntries(
        window: const EnrollmentStatsWindow.month(),
        page: 3,
        size: GetEnrollmentEntriesUseCase.pageSize,
        order: captureAny(named: 'order'),
      ),
    ).captured.single;
    final reportOrder = verify(
      () => repository.getEntriesReport(
        window: const EnrollmentStatsWindow.month(),
        order: captureAny(named: 'order'),
      ),
    ).captured.single;

    expect(listOrder, EnrollmentEntriesOrder.dashboard);
    expect(reportOrder, EnrollmentEntriesOrder.document);
  });

  test('la table suit le guichet, le registre imprimé se range par nom', () {
    // Les deux ne répondent pas à la même question : l'écran montre ce qui
    // vient d'arriver, le papier sert à retrouver quelqu'un — et c'est le tri
    // par nom qui fait paraître l'index par initiale.
    expect(
      EnrollmentEntriesOrder.dashboard,
      EnrollmentEntriesOrder.oldestFirst,
    );
    expect(EnrollmentEntriesOrder.dashboard.apiValue, 'oldest');

    expect(EnrollmentEntriesOrder.document, EnrollmentEntriesOrder.byName);
    // La valeur de fil, épinglée : c'est le seul mot que le serveur accepte
    // pour l'alphabet, et il refuse tout le reste en 400.
    expect(EnrollmentEntriesOrder.document.apiValue, 'name');
  });
}
