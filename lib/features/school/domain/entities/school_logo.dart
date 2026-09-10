import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Le sceau de l'établissement dans sa variante d'écran — PNG 256×256 en
/// palette avec alpha, tel que le serveur l'a servi et que `school_logo_cache`
/// le range.
///
/// Les octets ne sont ni redimensionnés ni recomposés au passage : ce qui est
/// détenu est ce qui a été vérifié contre son empreinte au tirage, et une forme
/// dérivée ne serait plus comparable à elle.
class SchoolLogo extends Equatable {
  /// Empreinte `sha256` des [bytes] détenus.
  final String sha256;

  /// Les octets du PNG, tels quels.
  final Uint8List bytes;

  const SchoolLogo({required this.sha256, required this.bytes});

  /// ⚠️ **L'empreinte SEULE fait l'identité, jamais les octets.**
  ///
  /// Elle décrit exactement ces octets-là — c'est déjà sur elle que le tirage
  /// conditionnel se construit — et se compare en 64 caractères.
  ///
  /// Les octets n'ajouteraient rien au verdict : Equatable compare une liste
  /// élément par élément, deux copies du même PNG resteraient égales. Ils le
  /// paieraient en revanche d'un parcours du PNG entier à chaque comparaison
  /// d'état — et il y en a une par cycle de pull fructueux.
  @override
  List<Object?> get props => [sha256];
}
