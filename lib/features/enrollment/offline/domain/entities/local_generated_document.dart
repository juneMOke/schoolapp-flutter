import 'package:equatable/equatable.dart';

/// Document généré (attestation AI, reçu RC…), provisoire ou définitif.
class LocalGeneratedDocument extends Equatable {
  final String id;
  final String docDomain; // ENROLLMENT | PAYMENT
  final String? enrollmentId;
  final String? paymentId;
  final String? studentId;
  final String docType; // AI | RC | NP
  final String number; // PROV-… | ETL-…

  /// Numéro provisoire d'origine, conservé après scellement — seul lien entre
  /// un ticket papier déjà remis et le reçu définitif.
  final String? provisionalNumber;

  final String status; // PROVISIONAL | DEFINITIVE
  final String? verificationToken;

  /// Epoch ms d'écriture de la ligne — ordonne les pièces d'un même dossier.
  final int createdAt;

  const LocalGeneratedDocument({
    required this.id,
    required this.docDomain,
    this.enrollmentId,
    this.paymentId,
    this.studentId,
    required this.docType,
    required this.number,
    this.provisionalNumber,
    required this.status,
    this.verificationToken,
    this.createdAt = 0,
  });

  /// Vrai **uniquement** sur le statut définitif, scellé par un ACK serveur.
  ///
  /// C'est le seul prédicat que la présentation doit consulter pour décider
  /// qu'un numéro **fait foi**. Le test inverse (`!isProvisional`) serait un
  /// piège : `status` est une chaîne libre, et tout statut futur ou inconnu y
  /// répondrait « vrai » alors que `number` vaut toujours `PROV-…` — la
  /// tablette présenterait un numéro provisoire comme une référence officielle.
  bool get isDefinitive => status == 'DEFINITIVE';

  /// Vrai **uniquement** sur le statut provisoire. Volontairement disjoint de
  /// [isDefinitive] : un statut inconnu n'est ni l'un ni l'autre, et c'est le
  /// comportement voulu (aucune des deux affirmations ne peut être faite).
  bool get isProvisional => status == 'PROVISIONAL';

  @override
  List<Object?> get props => [
    id,
    docDomain,
    enrollmentId,
    paymentId,
    studentId,
    docType,
    number,
    provisionalNumber,
    status,
    verificationToken,
    createdAt,
  ];
}
