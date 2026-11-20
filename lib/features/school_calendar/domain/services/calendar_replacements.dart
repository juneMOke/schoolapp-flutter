import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';

/// Les remplacements d'éléments nationaux par l'école (contrat du
/// 2026-11-20), la même règle que `daysBetween` côté serveur, tenue par les
/// vecteurs partagés `calendar/days-between-vectors.json`.
///
/// Sur la liste **entière** (cadre et école), avant tout filtre de portée ou
/// de dates :
/// - un élément dont l'id est le `replaces` d'un autre est écarté ;
/// - un élément dont `replaces` ne nomme aucun id de la liste est écarté
///   (orphelin : l'élément national a quitté le cadre).
///
/// Un remplacement gardé hérite du rythme et des rangs de période de
/// l'élément national qu'il remplace : l'événement de l'école ne les porte pas.
///
/// La règle s'applique **une fois**, sur la liste brute : sur une liste déjà
/// résolue, chaque remplacement gardé serait vu orphelin.
class CalendarReplacements {
  const CalendarReplacements._();

  /// [inert] : les ids d'éléments montrés sans effet de remplacement (un
  /// événement refusé par le serveur ne masque pas l'élément national, et
  /// reste à l'écran, marqué).
  static List<CalendarElement> resolve(
    List<CalendarElement> elements, {
    Set<String> inert = const {},
  }) {
    final byId = {for (final e in elements) e.id: e};
    final replaced = {
      for (final e in elements)
        if (!inert.contains(e.id)) ?e.replaces,
    };
    final kept = <CalendarElement>[];
    for (final e in elements) {
      if (replaced.contains(e.id)) continue;
      final target = e.replaces;
      if (target == null || inert.contains(e.id)) {
        kept.add(e);
        continue;
      }
      // Un remplacement prend le rythme et les rangs de l'élément national
      // (une période déplacée reste « P2 · 1er semestre ») ; sans lui, il est
      // orphelin et s'écarte.
      final national = byId[target];
      if (national != null) kept.add(e.inheritingPeriodOf(national));
    }
    return kept;
  }

  /// Les remplacements dont l'élément national n'est plus remplaçable, ou n'a
  /// plus leur nature ou leur portée (cadre corrigé), sont **orphelins** :
  /// l'élément reprend sa place. Le serveur fait de même avant `daysBetween`
  /// (contrat du 2026-11-20) ; les vecteurs n'en portent pas la trace.
  static List<CalendarElement> withStaleOrphaned(
    List<CalendarElement> elements,
  ) {
    final nationals = {
      for (final e in elements)
        if (e.isNational) e.id: e,
    };
    return [
      for (final e in elements)
        switch (e.replaces) {
          final target? when !_fits(e, nationals[target]) => e.withReplaces(
            '$orphanPrefix$target',
          ),
          _ => e,
        },
    ];
  }

  /// Le marqueur d'une cible écartée : aucun id de la liste ne le porte.
  static const String orphanPrefix = 'orphan:';

  static bool _fits(CalendarElement replacement, CalendarElement? national) =>
      national == null ||
      (national.replaceable &&
          national.nature == replacement.nature &&
          national.scope == replacement.scope);

  /// La lecture des écrans : [withStaleOrphaned], puis [resolve].
  static List<CalendarElement> resolveForDisplay(
    List<CalendarElement> elements, {
    Set<String> inert = const {},
  }) => resolve(withStaleOrphaned(elements), inert: inert);
}
