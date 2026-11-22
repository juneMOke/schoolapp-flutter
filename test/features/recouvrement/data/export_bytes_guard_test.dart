import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/recouvrement/data/export_bytes_guard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';

Uint8List _b(String s) => Uint8List.fromList(s.codeUnits);

void main() {
  const pdf = RecoveryExportFormat.pdf;
  const xlsx = RecoveryExportFormat.xlsx;
  const xlsxType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  test('un vrai PDF et un vrai classeur passent', () {
    ExportBytesGuard.check(_b('%PDF-1.7 …'), 'application/pdf', pdf);
    ExportBytesGuard.check(_b('PK\x03\x04…'), xlsxType, xlsx);
  });

  test('un 200 en HTML (portail captif) est refusé', () {
    expect(
      () => ExportBytesGuard.check(_b('<html>'), 'text/html', pdf),
      throwsFormatException,
    );
  });

  test('des octets qui ne commencent pas par la signature sont refusés', () {
    expect(
      () => ExportBytesGuard.check(_b('oops'), 'application/pdf', pdf),
      throwsFormatException,
    );
    expect(
      () => ExportBytesGuard.check(_b('%PDF'), xlsxType, xlsx),
      throwsFormatException,
    );
  });

  test('un corps vide est refusé', () {
    expect(
      () => ExportBytesGuard.check(Uint8List(0), 'application/pdf', pdf),
      throwsFormatException,
    );
  });
}
