import 'package:equatable/equatable.dart';

/// Nature d'une diffusion de la copie.
enum CopieKind {
  print('PRINT'),
  share('SHARE');

  const CopieKind(this.apiValue);

  final String apiValue;

  static CopieKind? fromApiValue(String? value) {
    for (final kind in values) {
      if (kind.apiValue == value?.toUpperCase()) return kind;
    }
    return null;
  }
}

/// Canal d'un partage. La tablette ne produit que [systeme] : la feuille de
/// partage du système ne dit pas quelle appli a été choisie. Les autres
/// valeurs peuvent descendre du serveur (spec web).
enum CopieCanal {
  systeme('SYSTEME'),
  whatsapp('WHATSAPP'),
  email('EMAIL'),
  lien('LIEN');

  const CopieCanal(this.apiValue);

  final String apiValue;

  static CopieCanal? fromApiValue(String? value) {
    for (final canal in values) {
      if (canal.apiValue == value?.toUpperCase()) return canal;
    }
    return null;
  }
}

/// Une impression ou un partage de la copie, journalisé (append-only).
class CopieDiffusion extends Equatable {
  final String id;
  final CopieKind kind;

  /// `null` pour une impression ; requis pour un partage.
  final CopieCanal? canal;

  /// La copie diffusée était un corrigé (option « Réponses » cochée).
  final bool corrige;
  final DateTime occurredAt;

  const CopieDiffusion({
    required this.id,
    required this.kind,
    this.canal,
    required this.corrige,
    required this.occurredAt,
  });

  @override
  List<Object?> get props => [id, kind, canal, corrige, occurredAt];
}
