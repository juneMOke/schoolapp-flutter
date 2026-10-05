import 'package:equatable/equatable.dart';

/// Les deux tailles servies par le serveur : la vignette des listes et la
/// photo des en-têtes.
enum StudentPhotoSize {
  /// 96 px — avatars de 48 dp et moins.
  thumb(96),

  /// 512 px — en-têtes, recadrage, séance photo.
  full(512);

  const StudentPhotoSize(this.pixels);

  final int pixels;

  /// La taille à charger pour un avatar de [diameter] dp : la vignette suffit
  /// jusqu'à 48 dp, au-delà elle se verrait floue.
  static StudentPhotoSize forDiameter(double diameter) =>
      diameter <= 48 ? thumb : full;
}

/// Ce qu'on sait de la photo d'un élève à un instant donné.
///
/// [version] change chaque fois que la photo à montrer change : c'est la clé
/// des copies en mémoire, et ce qui fait se reconstruire un avatar. `null`
/// quand l'élève n'a pas de photo (ou qu'un retrait est en attente).
class StudentPhotoRef extends Equatable {
  final String studentId;
  final String? version;

  /// Un geste local (prise ou retrait) n'est pas encore accusé.
  final bool isPending;

  /// Le dernier geste a été refusé par le serveur ; la photo montrée reste
  /// celle du serveur.
  final String? rejection;

  const StudentPhotoRef({
    required this.studentId,
    this.version,
    this.isPending = false,
    this.rejection,
  });

  bool get hasPhoto => version != null;

  @override
  List<Object?> get props => [studentId, version, isPending, rejection];
}
