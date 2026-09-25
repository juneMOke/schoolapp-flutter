import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/printing/ticket_copies.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/resolve_ticket_copies_use_case.dart';
import 'package:school_app_flutter/features/school/domain/entities/school.dart';
import 'package:school_app_flutter/features/school/domain/entities/school_logo.dart';
import 'package:school_app_flutter/features/school/domain/repositories/school_repository.dart';

class _FakeSchools implements SchoolRepository {
  Either<Failure, School?> result = const Right(null);

  @override
  Future<Either<Failure, School?>> loadCurrentSchool() async => result;

  @override
  Future<Either<Failure, SchoolLogo?>> loadCurrentSchoolLogo() async =>
      const Right(null);
}

School _school(int? copies) =>
    School(id: 'A', name: 'EP Kimbanguiste', ticketCopies: copies);

void main() {
  late _FakeSchools schools;
  late ResolveTicketCopiesUseCase resolve;

  setUp(() {
    schools = _FakeSchools();
    resolve = ResolveTicketCopiesUseCase(schools);
  });

  test('le réglage de l école décide', () async {
    schools.result = Right(_school(3));

    expect(await resolve(), 3);
  });

  test('une école sans réglage : un exemplaire, comme avant', () async {
    schools.result = Right(_school(null));

    expect(await resolve(), TicketCopies.fallback);
  });

  /// Le cache local peut être plus vieux que les règles : la borne se
  /// réapplique ici, une valeur aberrante ne vide pas le rouleau.
  test('une valeur hors bornes est ramenée dans les bornes', () async {
    schools.result = Right(_school(40));
    expect(await resolve(), TicketCopies.max);

    schools.result = Right(_school(0));
    expect(await resolve(), TicketCopies.min);
  });

  /// Identité indisponible ou autre école sur la tablette : rien de
  /// bloquant, le ticket sort quand même.
  test('aucune identité : un exemplaire', () async {
    schools.result = const Right(null);

    expect(await resolve(), TicketCopies.fallback);
  });

  test('une lecture en panne ne bloque jamais le ticket', () async {
    schools.result = const Left(StorageFailure('illisible'));

    expect(await resolve(), TicketCopies.fallback);
  });
}
