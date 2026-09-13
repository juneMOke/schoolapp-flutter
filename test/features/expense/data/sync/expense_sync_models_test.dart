import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_models.dart';

void main() {
  group('remontée : le round-trip de l’outbox EST le chemin du push', () {
    const request = ExpenseSyncRequestDto(
      expense: ExpenseInputDto(
        id: 'e-1',
        typeId: 't-elec',
        title: 'Facture SNEL — août',
        description: 'Compteur bloc B',
        amountInCents: 38500000,
        currency: 'CDF',
        status: 'PAID',
        paidOn: '2026-09-03',
        expenseDate: '2026-09-03',
        supplier: 'SNEL',
        fundingSource: 'MOBILE_MONEY',
        clientUpdatedAt: '2026-09-03T09:12:40.123Z',
      ),
      authorId: 'u-1',
    );

    test('forme du fil : l’auteur à la racine, tous les champs du contrat', () {
      final wire = jsonDecode(jsonEncode(request.toJson())) as Map;
      expect(wire['authorId'], 'u-1');
      expect(wire['expense'], {
        'id': 'e-1',
        'typeId': 't-elec',
        'title': 'Facture SNEL — août',
        'description': 'Compteur bloc B',
        'amountInCents': 38500000,
        'currency': 'CDF',
        'status': 'PAID',
        'paidOn': '2026-09-03',
        'expenseDate': '2026-09-03',
        'supplier': 'SNEL',
        'fundingSource': 'MOBILE_MONEY',
        'clientUpdatedAt': '2026-09-03T09:12:40.123Z',
      });
    });

    test('relu depuis le texte rangé, rien ne se perd', () {
      final text = jsonEncode(request.toJson());
      final back = ExpenseSyncRequestDto.fromJson(
        jsonDecode(text) as Map<String, dynamic>,
      );
      expect(jsonEncode(back.toJson()), text);
    });

    test('sans uid connu, la clé d’auteur est omise', () {
      final wire = ExpenseSyncRequestDto(expense: request.expense).toJson();
      expect(wire.containsKey('authorId'), isFalse);
    });
  });

  test('retrait : l’identifiant va dans le chemin, pas dans le corps', () {
    const payload = ExpenseWithdrawalPayload(
      expenseId: 'e-1',
      deleted: true,
      changedAt: '2026-09-04T10:00:00.000Z',
      authorId: 'u-1',
    );
    expect(payload.toWireJson(), {
      'deleted': true,
      'changedAt': '2026-09-04T10:00:00.000Z',
      'authorId': 'u-1',
    });
    final back = ExpenseWithdrawalPayload.fromJson(
      jsonDecode(jsonEncode(payload.toJson())) as Map<String, dynamic>,
    );
    expect(back.expenseId, 'e-1');
    expect(back.deleted, isTrue);
  });

  group('descente', () {
    Map<String, dynamic> delta([Map<String, dynamic> patch = const {}]) => {
      'id': 'e-1',
      'expenseNumber': 'DEP-0412',
      'typeId': 't-elec',
      'title': 'Facture SNEL',
      'description': null,
      'amountInCents': 38500000,
      'currency': 'cdf',
      'status': 'paid',
      'paidOn': '2026-09-03',
      'expenseDate': '2026-09-03',
      'supplier': null,
      'fundingSource': 'CASH',
      'recordedById': 'u-9',
      'recordedByName': 'Moke Junior',
      'clientUpdatedAt': '2026-09-03T09:12:40Z',
      'deletedAt': null,
      'version': 3,
      'serverUpdatedAt': '2026-09-03T09:14:02Z',
      ...patch,
    };

    test('un delta complet se lit, devise et statut normalisés', () {
      final dto = ExpenseDeltaDto.tryParse(delta())!;
      expect(dto.expenseNumber, 'DEP-0412');
      expect(dto.currency, 'CDF');
      expect(dto.status, 'PAID');
      expect(dto.recordedByName, 'Moke Junior');
      expect(dto.version, 3);
      // Instant normalisé : comparable à la colonne locale.
      expect(dto.clientUpdatedAt, '2026-09-03T09:12:40.000Z');
    });

    test('une devise inconnue est gardée, jamais rejetée', () {
      expect(
        ExpenseDeltaDto.tryParse(delta({'currency': 'XAF'}))!.currency,
        'XAF',
      );
    });

    test(
      'une ligne fautive est écartée, les autres passent (anti poison-page)',
      () {
        final page = ExpensePageDto.fromJson({
          'items': [
            delta(),
            delta({'id': 'e-2', 'expenseDate': 'pas une date'}),
            delta({'id': 'e-3', 'amountInCents': null}),
            delta({'id': 'e-4'}),
          ],
          'hasMore': false,
          'nextWatermark': 'w-1',
          'serverTime': '2026-09-13T08:00:00Z',
        });
        expect(page.items.map((d) => d.id), ['e-1', 'e-4']);
        expect(page.skipped, 2);
        expect(page.page.cursorToPersist, 'w-1');
      },
    );

    test(
      'accusé : SUPERSEDED lu, accusé sans dépense lisible ⇒ FormatException',
      () {
        final ack = ExpenseSyncResponseDto.fromJson({
          'expense': delta(),
          'lwwOutcome': 'SUPERSEDED',
        });
        expect(ack.isSuperseded, isTrue);
        expect(
          () => ExpenseSyncResponseDto.fromJson({'expense': null}),
          throwsFormatException,
        );
      },
    );
  });
}
