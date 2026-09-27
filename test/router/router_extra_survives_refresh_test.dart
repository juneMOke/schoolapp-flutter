import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/router/router_extra_codec.dart';

class _Intent {
  final String name;
  const _Intent(this.name);
}

/// Régression du 27/09/2026 : au retour d'une correction de versement, la
/// fiche de facturation affichait « Contexte de détail indisponible ».
///
/// Un rafraîchissement du routeur (permissions rafraîchies par la
/// synchronisation) reconstruisait la pile depuis son état SÉRIALISÉ, où un
/// `extra` non JSON-isable devient `null`. Ce test rejoue la séquence : fiche
/// ouverte avec son contexte, page poussée puis refermée, rafraîchissement.
void main() {
  GoRouter routerWith(
    Listenable refresh, {
    Codec<Object?, Object?>? codec,
  }) => GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    extraCodec: codec,
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => const Text('home'),
        routes: [
          GoRoute(
            path: 'detail/:id',
            builder: (_, state) => Text(
              'detail ${(state.extra as _Intent?)?.name ?? 'SANS CONTEXTE'}',
            ),
            routes: [
              GoRoute(path: 'pay', builder: (_, _) => const Text('pay')),
            ],
          ),
        ],
      ),
    ],
  );

  Future<void> scenario(
    WidgetTester tester,
    GoRouter router,
    ValueNotifier<int> refresh,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/home/detail/1', extra: const _Intent('Gloredi'));
    await tester.pumpAndSettle();
    router.push('/home/detail/1/pay', extra: const _Intent('pay'));
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    refresh.value++;
    await tester.pumpAndSettle();
  }

  testWidgets('la fiche garde son contexte après un rafraîchissement', (
    tester,
  ) async {
    final refresh = ValueNotifier<int>(0);
    final router = routerWith(refresh, codec: InMemoryExtraCodec());

    await scenario(tester, router, refresh);

    expect(find.text('detail Gloredi'), findsOneWidget);
  });

  group('InMemoryExtraCodec', () {
    test('rend l objet d origine, identique', () {
      final codec = InMemoryExtraCodec();
      const extra = _Intent('x');

      expect(codec.decode(codec.encode(extra)), same(extra));
      expect(codec.decode(codec.encode(null)), isNull);
    });

    test('même objet, même identifiant : le registre ne grossit pas', () {
      final codec = InMemoryExtraCodec();
      const extra = _Intent('x');

      expect(codec.encode(extra), codec.encode(extra));
    });

    test('borné : les plus anciens sortent', () {
      final codec = InMemoryExtraCodec(capacity: 2);
      final first = codec.encode(const _Intent('a'));
      codec.encode(const _Intent('b'));
      codec.encode(const _Intent('c'));

      expect(codec.decode(first), isNull);
    });

    // Redémarrage à froid : état restauré, registre vide.
    test('un identifiant inconnu rend null, comme avant', () {
      expect(InMemoryExtraCodec().decode({'inMemoryExtra': 42}), isNull);
      expect(InMemoryExtraCodec().decode('texte'), isNull);
    });
  });
}
