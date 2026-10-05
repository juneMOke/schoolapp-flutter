import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/components/avatars/person_photo_source.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';

/// Une source dont le test règle la clé et rend les octets à la demande.
class _FakeSource implements PersonPhotoSource {
  final Map<String, ValueNotifier<String?>> keys = {};
  final Map<String, Uint8List> ready = {};
  Completer<Uint8List?>? pending;
  final List<double> askedDiameters = [];

  ValueNotifier<String?> keyOf(String id) =>
      keys.putIfAbsent(id, () => ValueNotifier<String?>(null));

  @override
  ValueListenable<String?> photoKeyOf(String personId) => keyOf(personId);

  @override
  Future<Uint8List?> photoBytesOf(String personId, {required double diameter}) {
    askedDiameters.add(diameter);
    return (pending ??= Completer<Uint8List?>()).future;
  }

  @override
  Uint8List? peekPhotoBytes(String personId, {required double diameter}) =>
      ready[personId];
}

// Un PNG 1×1 transparent.
final Uint8List _png = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  late _FakeSource source;

  setUp(() => source = _FakeSource());

  Future<void> pump(
    WidgetTester tester, {
    String? photoOf = 's-1',
    bool scoped = true,
  }) {
    final avatar = PersonAvatar(
      firstName: 'Daniel',
      lastName: 'Kabongo',
      personId: 's-1',
      size: 36,
      studentPhotoOf: photoOf,
    );
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: scoped
                ? PersonPhotoScope(source: source, child: avatar)
                : avatar,
          ),
        ),
      ),
    );
  }

  testWidgets('sans photo : les initiales', (tester) async {
    await pump(tester);
    expect(find.text('KD'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('sans demande de photo, la source n\'est pas consultée', (
    tester,
  ) async {
    source.keyOf('s-1').value = 'v1';
    await pump(tester, photoOf: null);
    expect(find.text('KD'), findsOneWidget);
    expect(source.askedDiameters, isEmpty);
  });

  testWidgets('sans portée de photo : les initiales', (tester) async {
    source.keyOf('s-1').value = 'v1';
    await pump(tester, scoped: false);
    expect(find.text('KD'), findsOneWidget);
  });

  testWidgets('photo en lecture : un squelette de même diamètre, puis la '
      'photo', (tester) async {
    source.keyOf('s-1').value = 'v1';
    await pump(tester);

    expect(find.byType(EteeloSkeletonBox), findsOneWidget);
    expect(tester.getSize(find.byType(EteeloSkeletonBox)), const Size(36, 36));
    expect(source.askedDiameters, [36]);

    source.pending!.complete(_png);
    await tester.pump();

    expect(find.byType(EteeloSkeletonBox), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('KD'), findsNothing);
  });

  testWidgets('photo indisponible (hors ligne) : les initiales', (
    tester,
  ) async {
    source.keyOf('s-1').value = 'v1';
    await pump(tester);
    source.pending!.complete(null);
    await tester.pump();
    expect(find.text('KD'), findsOneWidget);
  });

  testWidgets('octets déjà en mémoire : la photo au premier cadre', (
    tester,
  ) async {
    source.keyOf('s-1').value = 'v1';
    source.ready['s-1'] = _png;
    await pump(tester);
    expect(find.byType(EteeloSkeletonBox), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(source.askedDiameters, isEmpty);
  });

  testWidgets('photo retirée : retour aux initiales sans recharger', (
    tester,
  ) async {
    source.keyOf('s-1').value = 'v1';
    source.ready['s-1'] = _png;
    await pump(tester);

    source.keyOf('s-1').value = null;
    await tester.pump();

    expect(find.text('KD'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('la photo reste hors de l\'arbre sémantique, comme les '
      'initiales', (tester) async {
    source.keyOf('s-1').value = 'v1';
    source.ready['s-1'] = _png;
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(find.bySemanticsLabel(RegExp('.')), findsNothing);
    handle.dispose();
  });
}
