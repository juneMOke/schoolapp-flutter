import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/relance/fee_control_notify_content.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/relance/fee_control_notify_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import 'recouvrement_shots.dart';

// O4 · Relance des parents — captures hors CI.
const _recipients = [
  FeeControlNotifyRecipient(
    studentId: 's1',
    studentName: 'MOKE Junior',
    parentName: 'MOKE Albert',
    phoneNumber: '+243810000001',
  ),
  FeeControlNotifyRecipient(
    studentId: 's2',
    studentName: 'ILUNGA Grâce',
    parentName: 'ILUNGA KASONGO Marie-Thérèse',
    phoneNumber: '+243820000002',
  ),
  FeeControlNotifyRecipient(studentId: 's3', studentName: 'KABONGO Paul'),
];

void main() {
  setUpAll(loadRealFonts);

  for (final (w, h) in [(360.0, 740.0), (1280.0, 800.0)]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('notify $w ×$scale', (tester) async {
        await shoot(
          tester,
          'notify_${w.toInt()}_${scale == 1 ? '1' : '13'}',
          Size(w, h),
          textScale: scale,
          MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    FeeControlNotifyDialog.show(
                      context,
                      FeeControlNotifyDialog(
                        contextLabel: 'Scolarité · 6e A',
                        initialMessage:
                            'Cher parent, les frais Scolarité · 6e A ne sont pas soldés pour votre enfant. Merci de passer à la caisse de l\'école avant le 29/11/2026. La direction de CS La Colombe.',
                        recipients: _recipients,
                        onSend: (_) async {},
                      ),
                    );
                  });
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
