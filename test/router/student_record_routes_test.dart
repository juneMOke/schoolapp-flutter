import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';
import 'package:school_app_flutter/router/student_record_routes.dart';

void main() {
  group('encaissement rouvert par son adresse', () {
    test('avec ses créances, il s’ouvre', () {
      const intent = FacturationCreatePaymentIntent.invalid(
        studentId: 's1',
        academicYearId: 'y1',
      );
      expect(
        StudentRecordRoutes.createPaymentRedirect(
          extra: intent,
          studentId: 's1',
          academicYearId: 'y1',
        ),
        isNull,
      );
    });

    test('sans elles (onglet rechargé), retour à la fiche', () {
      expect(
        StudentRecordRoutes.createPaymentRedirect(
          extra: null,
          studentId: 's1',
          academicYearId: 'y1',
        ),
        AppRoutesNames.facturationDetailPath(
          studentId: 's1',
          academicYearId: 'y1',
        ),
      );
    });
  });
}
