import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/communication/data/online/announcement_api.dart';
import 'package:school_app_flutter/features/communication/data/online/announcement_audience_api.dart';
import 'package:school_app_flutter/features/communication/data/online/announcement_template_api.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';

import '../../communication_fixtures.dart';

void main() {
  const extras = {'requiresAuth': true};

  test(
    'la liste : l\'année en paramètre, l\'authentification en extra',
    () async {
      final adapter = RecordingAdapter([announcementJson()]);
      final list = await AnnouncementApi(
        dioWith(adapter),
        extras,
      ).list(academicYearId: 'y-1');
      expect(list.single.id, 'a-1');
      expect(adapter.last.path, '/api/v1/announcements');
      expect(adapter.last.queryParameters, {'academicYearId': 'y-1'});
      expect(adapter.last.extra['requiresAuth'], isTrue);
    },
  );

  test('créer : l\'id de la tablette part avec le contenu', () async {
    final adapter = RecordingAdapter(announcementJson(id: 'uuid-1'));
    await AnnouncementApi(dioWith(adapter), extras).create(
      id: 'uuid-1',
      academicYearId: 'y-1',
      content: const AnnouncementContent(title: 'T', body: 'B'),
    );
    expect(adapter.last.method, 'POST');
    final data = adapter.last.data as Map;
    expect(data['id'], 'uuid-1');
    expect(data['academicYearId'], 'y-1');
    expect(data['title'], 'T');
  });

  test('modifier : PUT avec la version vue', () async {
    final adapter = RecordingAdapter(announcementJson());
    await AnnouncementApi(
      dioWith(adapter),
      extras,
    ).update('a/1', const AnnouncementContent(title: 'T'), version: 4);
    expect(adapter.last.method, 'PUT');
    expect(adapter.last.path, '/api/v1/announcements/a%2F1');
    expect((adapter.last.data as Map)['version'], 4);
  });

  test('programmer : le moment part en UTC avec la version', () async {
    final adapter = RecordingAdapter(announcementJson(status: 'SCHEDULED'));
    final result = await AnnouncementApi(dioWith(adapter), extras).gesture(
      'a-1',
      AnnouncementGesture.schedule,
      version: 2,
      scheduledAt: DateTime.utc(2026, 10, 13, 6, 30),
    );
    expect(adapter.last.path, '/api/v1/announcements/a-1/schedule');
    expect(adapter.last.data, {
      'version': 2,
      'scheduledAt': '2026-10-13T06:30:00.000Z',
    });
    expect(result.version, 3);
  });

  test('envoyer : la version seule', () async {
    final adapter = RecordingAdapter(announcementJson(status: 'SENT'));
    await AnnouncementApi(
      dioWith(adapter),
      extras,
    ).gesture('a-1', AnnouncementGesture.send, version: 5);
    expect(adapter.last.path, '/api/v1/announcements/a-1/send');
    expect(adapter.last.data, {'version': 5});
  });

  test('réponse illisible : FormatException', () async {
    final adapter = RecordingAdapter({'id': 'x'});
    expect(
      AnnouncementApi(dioWith(adapter), extras).get('x'),
      throwsFormatException,
    );
  });

  test('portée : l\'audience dans le corps', () async {
    final adapter = RecordingAdapter({
      'students': 2,
      'guardians': 2,
      'messages': 3,
      'reachableMessages': 3,
      'guardiansWithoutPhone': 0,
      'studentsUnreachable': 0,
      'whatsappEnabled': true,
    });
    final reach = await AnnouncementAudienceApi(
      dioWith(adapter),
      extras,
    ).reach(const LevelsAudience(['l-1']));
    expect(reach.messages, 3);
    expect(adapter.last.path, '/api/v1/announcements/reach');
    expect(adapter.last.data, {
      'audience': {
        'mode': 'LEVELS',
        'levelIds': ['l-1'],
      },
    });
  });

  test('recherche d\'élèves : la saisie rognée en q', () async {
    final adapter = RecordingAdapter([
      {
        'id': 's-1',
        'firstName': 'Grâce',
        'lastName': 'KABONGO',
        'surname': 'Mbuyi',
        'classroomName': '6e A',
        'levelName': '6e',
      },
      {
        'id': 's-3',
        'firstName': 'Paul',
        'lastName': 'ILUNGA',
        'surname': 'Kasa',
        'classroomName': null,
        'levelName': '5e',
      },
      {'id': 's-2'},
    ]);
    final found = await AnnouncementAudienceApi(
      dioWith(adapter),
      extras,
    ).searchStudents(' kab ');
    expect(found.map((s) => s.displayName), [
      'KABONGO Mbuyi Grâce',
      'ILUNGA Kasa Paul',
    ]);
    // Sans classe, le niveau.
    expect(found.map((s) => s.classroomLabel), ['6e A', '5e']);
    expect(adapter.last.queryParameters, {'q': 'kab'});
  });

  test('modèles : créer sans id, supprimer par DELETE', () async {
    final adapter = RecordingAdapter({
      'id': 't-1',
      'category': 'INFO',
      'title': 'T',
      'body': 'B',
    });
    final api = AnnouncementTemplateApi(dioWith(adapter), extras);
    await api.create(
      category: AnnouncementCategory.info,
      title: 'T',
      body: 'B',
    );
    expect(adapter.last.data, {'category': 'INFO', 'title': 'T', 'body': 'B'});
    adapter.body = null;
    adapter.status = 204;
    await api.delete('t-1');
    expect(adapter.last.method, 'DELETE');
    expect(adapter.last.path, '/api/v1/announcement-templates/t-1');
  });
}
