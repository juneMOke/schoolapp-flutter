import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';

/// Les noms sous lesquels les octets d'une photo sont scellés.
///
/// - la copie d'affichage, par taille : **une par élève**, remplacée quand la
///   photo change (la ligne dit de quelle empreinte elle est la copie) ;
/// - les octets d'un geste en attente : **un par geste**, nommés par leur
///   empreinte. Un nouveau geste n'écrase donc jamais les octets que l'envoi
///   en vol est en train de relire.
abstract final class StudentPhotoBlobIds {
  static String cached(String studentId, StudentPhotoSize size) =>
      'c${size.pixels}_$studentId';

  /// 16 caractères d'empreinte suffisent à distinguer deux prises d'un même
  /// élève, et tiennent dans les 64 caractères d'un nom de fichier sûr.
  static String pending(String studentId, String sha256) =>
      'p${sha256.substring(0, 16)}_$studentId';
}
