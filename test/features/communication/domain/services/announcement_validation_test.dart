import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_validation.dart';

void main() {
  const complete = AnnouncementContent(title: 'T', body: 'B');

  test('brouillon : un titre OU un message suffit', () {
    expect(
      AnnouncementValidation.canSaveDraft(const AnnouncementContent()),
      isFalse,
    );
    expect(
      AnnouncementValidation.canSaveDraft(
        const AnnouncementContent(body: ' x '),
      ),
      isTrue,
    );
  });

  test('complet : rien ne manque', () {
    expect(AnnouncementValidation.issuesOf(complete), isEmpty);
  });

  test('vide, sans canal, sans classe : chaque manque est nommé', () {
    expect(
      AnnouncementValidation.issuesOf(
        const AnnouncementContent(
          audience: ClassroomsAudience([]),
          channels: [],
        ),
      ),
      [
        AnnouncementIssue.titleMissing,
        AnnouncementIssue.bodyMissing,
        AnnouncementIssue.audienceEmpty,
        AnnouncementIssue.noChannel,
      ],
    );
  });

  test('{montant} hors des retards de paiement', () {
    final content = complete.copyWith(body: 'Reste {montant}');
    expect(AnnouncementValidation.issuesOf(content), [
      AnnouncementIssue.amountOutsideOverdue,
    ]);
    expect(
      AnnouncementValidation.issuesOf(
        content.copyWith(audience: const OverdueAudience()),
      ),
      isEmpty,
    );
  });

  test('{montant} au titre : refusé même en retards de paiement', () {
    final content = complete.copyWith(
      title: 'Reste {montant}',
      audience: const OverdueAudience(),
    );
    expect(AnnouncementValidation.issuesOf(content), [
      AnnouncementIssue.amountInTitle,
    ]);
    expect(AnnouncementValidation.amountMisplaced(content), isFalse);
  });

  test('variable inconnue, au titre comme au message', () {
    expect(
      AnnouncementValidation.issuesOf(complete.copyWith(title: 'Le {jour}')),
      [AnnouncementIssue.unknownVariable],
    );
  });

  test('programmer : strictement dans le futur', () {
    final now = DateTime.utc(2026, 10, 12, 10);
    expect(
      AnnouncementValidation.issuesOf(complete, scheduledAt: now, now: now),
      [AnnouncementIssue.scheduleNotFuture],
    );
    expect(
      AnnouncementValidation.issuesOf(
        complete,
        scheduledAt: now.add(const Duration(minutes: 1)),
        now: now,
      ),
      isEmpty,
    );
  });
}
