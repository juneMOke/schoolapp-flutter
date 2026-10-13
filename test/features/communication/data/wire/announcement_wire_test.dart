import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/communication/data/wire/announcement_wire.dart';
import 'package:school_app_flutter/features/communication/data/wire/audience_wire.dart';
import 'package:school_app_flutter/features/communication/data/wire/reach_wire.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_channel.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/domain/entities/audience_student.dart';

import '../../communication_fixtures.dart';

void main() {
  group('communiqué lu', () {
    test('tous les champs, sauts de ligne du message gardés', () {
      final parsed = AnnouncementWire.fromJson(
        announcementJson(
          status: 'SENT',
          category: 'URGENT',
          sentAt: '2026-10-08T17:20:00+00:00',
          reachAtSend: {
            'students': 104,
            'guardians': 95,
            'messages': 120,
            'reachableMessages': 113,
            'guardiansWithoutPhone': 6,
            'studentsUnreachable': 4,
          },
        ),
      )!;
      expect(parsed.id, 'a-1');
      expect(parsed.status, AnnouncementStatus.sent);
      expect(parsed.content.category, AnnouncementCategory.urgent);
      expect(parsed.content.body, 'Chers parents de {eleve},\nréunion samedi.');
      expect(parsed.content.channels, [AnnouncementChannel.whatsapp]);
      expect(parsed.sentAt, DateTime.utc(2026, 10, 8, 17, 20));
      expect(parsed.referenceDate, DateTime.utc(2026, 10, 8, 17, 20));
      expect(parsed.reachAtSend!.unreachableMessages, 7);
      expect(parsed.reachAtSend!.whatsappEnabled, isNull);
      expect(parsed.version, 3);
    });

    test('statut inconnu, audience illisible ou sans id : ligne écartée', () {
      final list = AnnouncementWire.listFromJson([
        announcementJson(id: 'ok'),
        announcementJson(id: 'x', status: 'ARCHIVED'),
        announcementJson(id: 'y', audience: {'mode': 'PLANET'}),
        {...announcementJson(), 'id': null},
        'pas un objet',
      ]);
      expect(list.map((a) => a.id), ['ok']);
    });

    test('catégorie inconnue : Information', () {
      final parsed = AnnouncementWire.fromJson(
        announcementJson(category: 'GOSSIP'),
      )!;
      expect(parsed.content.category, AnnouncementCategory.info);
    });
  });

  group('audience', () {
    final cases = <AnnouncementAudience>[
      const SchoolAudience(),
      const LevelsAudience(['l-1', 'l-2']),
      const ClassroomsAudience(['c-1']),
      const StudentsAudience.ids(['s-1']),
      const OverdueAudience(),
      const OverdueAudience(
        feeCode: 'TUITION',
        tariffCode: 'T1',
        overdueDays: 30,
      ),
    ];
    for (final audience in cases) {
      test('${audience.mode.wire} fait l\'aller-retour', () {
        expect(AudienceWire.fromJson(AudienceWire.toJson(audience)), audience);
      });
    }

    test('retards : les deux codes et le seuil partent, null compris', () {
      expect(AudienceWire.toJson(const OverdueAudience()), {
        'mode': 'OVERDUE',
        'feeCode': null,
        'tariffCode': null,
        'overdueDays': 0,
      });
    });

    test('une tranche sans nature est lue comme « tous les frais »', () {
      final parsed = AudienceWire.fromJson({
        'mode': 'OVERDUE',
        'tariffCode': 'T1',
      });
      expect(parsed, const OverdueAudience());
    });

    test('élèves : les noms rendus avec l\'audience sont gardés', () {
      final parsed =
          AudienceWire.fromJson({
                'mode': 'STUDENTS',
                'studentIds': ['s-1'],
                'students': [
                  {
                    'id': 's-1',
                    'lastName': 'KABONGO',
                    'surname': 'Mbuyi',
                    'firstName': 'Grâce',
                    'classroomName': '6e A',
                  },
                ],
              })
              as StudentsAudience;
      expect(parsed.studentIds, ['s-1']);
      expect(
        parsed.studentOf('s-1'),
        const AudienceStudent(
          id: 's-1',
          lastName: 'KABONGO',
          middleName: 'Mbuyi',
          firstName: 'Grâce',
          classroomLabel: '6e A',
        ),
      );
      expect(parsed.studentOf('s-1')!.displayName, 'KABONGO Mbuyi Grâce');
    });
  });

  test('contenu envoyé : bords rognés, canaux et audience', () {
    final json = AnnouncementWire.contentToJson(
      const AnnouncementContent(
        category: AnnouncementCategory.event,
        title: '  Portes ouvertes ',
        body: 'Bonjour\n',
        audience: ClassroomsAudience(['c-1']),
      ),
    );
    expect(json, {
      'category': 'EVENT',
      'title': 'Portes ouvertes',
      'body': 'Bonjour',
      'audience': {
        'mode': 'CLASSROOMS',
        'classroomIds': ['c-1'],
      },
      'channels': ['WHATSAPP'],
    });
  });

  test('portée illisible : null plutôt que zéro', () {
    expect(ReachWire.fromJson({'students': 3}), isNull);
    expect(
      ReachWire.fromJson({
        'messages': 2,
        'reachableMessages': 1,
        'whatsappEnabled': false,
      })!.whatsappEnabled,
      isFalse,
    );
  });

  test('modèles : sans id, écarté', () {
    final list = AnnouncementWire.templatesFromJson([
      {
        'id': 't-1',
        'category': 'ADMINISTRATIVE',
        'title': 'Rappel',
        'body': 'x',
      },
      {'title': 'orphelin'},
    ]);
    expect(list.single.category, AnnouncementCategory.administrative);
  });
}
