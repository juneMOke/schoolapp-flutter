import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/owner_scoped_value.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_repository.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_filters.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/announcements_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/list/announcements_list_screen.dart';

import '../../communication_fixtures.dart';

class _MockRepository extends Mock implements AnnouncementRepository {}

void main() {
  late _MockRepository repository;

  setUp(() => repository = _MockRepository());

  Future<AnnouncementsCubit> pump(
    WidgetTester tester, {
    VoidCallback? onCreate,
  }) async {
    final cubit = AnnouncementsCubit(
      repository: repository,
      memory: OwnerScopedValue(const AnnouncementFilters(), owner: () => 'u'),
      now: () => DateTime.utc(2026, 10, 12, 9),
    );
    await tester.pumpWidget(
      communicationHost(
        BlocProvider.value(
          value: cubit,
          child: AnnouncementsListScreen(onOpen: (_) {}, onCreate: onCreate),
        ),
      ),
    );
    await cubit.load(academicYearId: 'y-1');
    await tester.pumpAndSettle();
    return cubit;
  }

  void answer(Either<Failure, List<Object>> Function() result) => when(
    () => repository.list(academicYearId: any(named: 'academicYearId')),
  ).thenAnswer((_) async => result().map((l) => l.cast()));

  testWidgets('groupes, méta et date de chaque ligne', (tester) async {
    answer(
      () => Right([
        announcement(
          id: 'p',
          title: 'Journée portes ouvertes',
          status: AnnouncementStatus.scheduled,
          category: AnnouncementCategory.event,
          scheduledAt: DateTime.utc(2026, 10, 13, 6),
        ),
        announcement(
          id: 's',
          title: 'Fermeture exceptionnelle',
          status: AnnouncementStatus.sent,
          category: AnnouncementCategory.urgent,
          sentAt: DateTime.utc(2026, 10, 12, 7),
          reachAtSend: reach,
        ),
      ]),
    );
    await pump(tester);
    expect(find.text('Programmés · 1'), findsOneWidget);
    expect(find.text('Envoyés · 1'), findsOneWidget);
    expect(find.text('Prévu demain · 07:00'), findsOneWidget);
    expect(find.text("Envoyé aujourd'hui · 08:00"), findsOneWidget);
    expect(
      find.text("Toute l'école · 113 messages sur 120 · WhatsApp"),
      findsOneWidget,
    );
  });

  testWidgets('filtrer jusqu\'au vide propose d\'effacer', (tester) async {
    answer(() => Right([announcement(status: AnnouncementStatus.draft)]));
    final cubit = await pump(tester);
    cubit.toggleCategory(AnnouncementCategory.urgent);
    await tester.pumpAndSettle();
    expect(find.text('Aucun communiqué ne correspond'), findsOneWidget);
    await tester.ensureVisible(find.text('Effacer les filtres'));
    await tester.tap(find.text('Effacer les filtres'));
    await tester.pumpAndSettle();
    expect(find.text('Brouillons · 1'), findsOneWidget);
  });

  testWidgets('aucun communiqué : créer, si le droit le permet', (
    tester,
  ) async {
    answer(() => const Right([]));
    var created = 0;
    await pump(tester, onCreate: () => created++);
    expect(find.text("Aucun communiqué pour l'instant"), findsOneWidget);
    await tester.ensureVisible(find.text('Nouveau communiqué').last);
    await tester.tap(find.text('Nouveau communiqué').last);
    expect(created, 1);
  });

  testWidgets('403 : contacter l\'administrateur, jamais « Réessayer »', (
    tester,
  ) async {
    answer(() => const Left(UnauthorizedFailure()));
    await pump(tester);
    expect(find.text('Accès refusé'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
    expect(find.text("Contacter l'administrateur"), findsOneWidget);
  });

  testWidgets('réseau : Réessayer relance la lecture', (tester) async {
    answer(() => const Left(NetworkFailure()));
    await pump(tester);
    await tester.ensureVisible(find.text('Réessayer'));
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    verify(() => repository.list(academicYearId: 'y-1')).called(2);
  });
}
