import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_declaration_row.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_local_model.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_delta_dto.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_gesture_policy.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_transitions.dart';

/// DEP-16 — le modèle de la dépense déclarée (DEPENSES_PLAN partie III).
void main() {
  group('lecture tolérante (F36)', () {
    test('un mode absent ou inconnu se lit « autorisation »', () {
      expect(ExpenseMode.fromWire(null), ExpenseMode.authorization);
      expect(ExpenseMode.fromWire('SOMETHING'), ExpenseMode.authorization);
      expect(ExpenseMode.fromWire(' declaration '), ExpenseMode.declaration);
    });

    test('le visa est nul hors déclaration, « à viser » si illisible', () {
      expect(
        ExpenseVisaStatus.fromWire('VISAED', mode: ExpenseMode.authorization),
        isNull,
      );
      expect(
        ExpenseVisaStatus.fromWire('???', mode: ExpenseMode.declaration),
        ExpenseVisaStatus.pending,
      );
      expect(
        ExpenseVisaStatus.fromWire('flagged', mode: ExpenseMode.declaration),
        ExpenseVisaStatus.flagged,
      );
    });

    test('les trois actes neufs se lisent', () {
      expect(ExpenseAct.fromWire('DECLARATION'), ExpenseAct.declaration);
      expect(ExpenseAct.fromWire('VISA'), ExpenseAct.visa);
      expect(ExpenseAct.fromWire('FLAG'), ExpenseAct.flag);
    });
  });

  group('transitions par mode (F43)', () {
    test('une déclaration ne mène qu’à son annulation, terminale', () {
      const mode = ExpenseMode.declaration;
      expect(
        ExpenseTransitions.isAllowedIn(
          mode,
          ExpenseStatus.paid,
          ExpenseStatus.retracted,
        ),
        isTrue,
      );
      expect(
        ExpenseTransitions.isAllowedIn(
          mode,
          ExpenseStatus.paid,
          ExpenseStatus.pending,
        ),
        isFalse,
        reason: 'une déclaration ne revient jamais en attente',
      );
      expect(
        ExpenseTransitions.isAllowedIn(
          mode,
          ExpenseStatus.retracted,
          ExpenseStatus.pending,
        ),
        isFalse,
        reason: 'annulée, elle ne se renvoie pas',
      );
      expect(ExpenseTransitions.canCancelDeclaration(ExpenseStatus.paid), true);
      expect(
        ExpenseTransitions.canCancelDeclaration(ExpenseStatus.retracted),
        false,
      );
    });

    test('la table de l’autorisation ne bouge pas', () {
      expect(
        ExpenseTransitions.tableFor(ExpenseMode.authorization),
        same(ExpenseTransitions.allowed),
      );
      expect(
        ExpenseTransitions.reopenTarget(ExpenseMode.authorization),
        ExpenseStatus.pending,
      );
      expect(
        ExpenseTransitions.reopenTarget(ExpenseMode.declaration),
        ExpenseStatus.retracted,
      );
    });
  });

  group('gestes offerts sur une déclaration', () {
    Expense declared(ExpenseStatus status) => Expense(
      id: 'e-1',
      typeId: 't-1',
      title: 'Carburant',
      amountInCents: 4500,
      currency: 'USD',
      status: status,
      expenseDate: DateTime(2026, 11, 25),
      recordedById: 'u-moi',
      clientUpdatedAt: DateTime.utc(2026, 11, 25),
      mode: ExpenseMode.declaration,
      visaStatus: ExpenseVisaStatus.pending,
    );

    test('payée : commenter, annuler, viser, signaler — rien du circuit', () {
      expect(
        ExpenseGesturePolicy.offeredOn(
          declared(ExpenseStatus.paid),
          accountId: 'u-moi',
        ).toSet(),
        {
          ExpenseGesture.comment,
          ExpenseGesture.reopen,
          ExpenseGesture.visa,
          ExpenseGesture.flag,
        },
      );
    });

    test('annulée : seulement commenter', () {
      final expense = declared(ExpenseStatus.retracted);
      expect(expense.isCancelledDeclaration, isTrue);
      expect(
        ExpenseGesturePolicy.offeredOn(expense, accountId: 'u-moi'),
        [ExpenseGesture.comment],
        reason: 'ni renvoi, ni annulation d’une annulation',
      );
    });
  });

  group('le delta', () {
    Map<String, Object?> wire([Map<String, Object?> extra = const {}]) => {
      'id': 'e-1',
      'typeId': 't-1',
      'title': 'Carburant',
      'amountInCents': 4500,
      'currency': 'USD',
      'status': 'PAID',
      'expenseDate': '2026-11-25',
      'clientUpdatedAt': '2026-11-25T09:14:00Z',
      ...extra,
    };

    test('un serveur d’avant la v3 donne une demande d’autorisation', () {
      final dto = ExpenseDeltaDto.tryParse(wire())!;
      expect(dto.declaration.mode, 'AUTHORIZATION');
      expect(dto.declaration.visaStatus, isNull);
      expect(dto.declaration.afterClosure, isFalse);
    });

    test('une déclaration descend entière', () {
      final dto = ExpenseDeltaDto.tryParse(
        wire({
          'mode': 'DECLARATION',
          'visaStatus': 'FLAGGED',
          'visaById': 'u-prom',
          'visaByName': 'Le promoteur',
          'visaAt': '2026-11-26T07:40:00Z',
          'flagReason': 'Montant supérieur au devis',
          'paidAt': '2026-11-25T09:12:00Z',
          'cashDay': '2026-11-26',
          'afterClosure': true,
          'voucher': {
            'id': 'e-1',
            'contentType': 'IMAGE/JPEG',
            'sizeBytes': 301234,
            'uploadedAt': '2026-11-25T09:15:00Z',
          },
        }),
      )!;
      final row = dto.declaration;
      expect(row.mode, 'DECLARATION');
      expect(row.visaStatus, 'FLAGGED');
      expect(row.flagReason, 'Montant supérieur au devis');
      expect(row.disbursedAt, '2026-11-25T09:12:00.000Z');
      expect(row.cashDay, '2026-11-26');
      expect(row.afterClosure, isTrue);
      expect(row.voucherContentType, 'image/jpeg');
      expect(row.voucherSizeBytes, 301234);
    });

    test('un motif sur une déclaration visée est ignoré', () {
      final dto = ExpenseDeltaDto.tryParse(
        wire({
          'mode': 'DECLARATION',
          'visaStatus': 'VISAED',
          'flagReason': 'ancien motif',
        }),
      )!;
      expect(dto.declaration.flagReason, isNull);
    });

    test('un visa mal formé n’écarte pas la dépense', () {
      final dto = ExpenseDeltaDto.tryParse(
        wire({
          'mode': 'DECLARATION',
          'visaAt': 42,
          'voucher': 'pas un objet',
          'afterClosure': 'oui',
        }),
      );
      expect(dto, isNotNull);
      expect(dto!.declaration.visaAt, isNull);
      expect(dto.declaration.voucherId, isNull);
      expect(dto.declaration.afterClosure, isFalse);
    });
  });

  test('la ligne locale rend la déclaration à l’entité', () {
    const row = ExpenseDeclarationRow(
      mode: 'DECLARATION',
      visaStatus: 'VISAED',
      visaById: 'u-prom',
      visaAt: '2026-11-26T07:40:00.000Z',
      disbursedAt: '2026-11-25T09:12:00.000Z',
      cashDay: '2026-11-25',
      voucherId: 'e-1',
      voucherContentType: 'application/pdf',
      voucherSizeBytes: 1200,
    );
    final map = const ExpenseLocalModel(
      id: 'e-1',
      schoolId: 'school-A',
      typeId: 't-1',
      title: 'Carburant',
      amountInCents: 4500,
      currency: 'USD',
      status: 'PAID',
      expenseDate: '2026-11-25',
      clientUpdatedAt: '2026-11-25T09:14:00.000Z',
      syncStatus: 'SYNCED',
      declaration: row,
    ).toMap();

    final entity = ExpenseLocalModel.fromMap(map).toEntity()!;

    expect(entity.isDeclaration, isTrue);
    expect(entity.visaStatus, ExpenseVisaStatus.visaed);
    expect(entity.disbursedAt, DateTime.utc(2026, 11, 25, 9, 12));
    expect(entity.cashDay, DateTime(2026, 11, 25));
    expect(entity.voucher?.isPdf, isTrue);
  });
}
