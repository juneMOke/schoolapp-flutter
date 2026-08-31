import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';

/// Lecture de l'adresse d'un dossier en ses deux parties.
///
/// Le dossier porte le QUARTIER dans `neighborhood` — choisi dans le catalogue
/// géographique, obligatoire — et l'ADRESSE COMPLÉMENTAIRE (rue, avenue,
/// numéro) dans `address`, facultative : dans les quartiers d'où cette école
/// inscrit, rien n'est numéroté.
///
/// Avant la scission des deux champs, tout tenait dans `address` sous la forme
/// « Quartier, rue X », et ces dossiers-là sont toujours en base. C'est la
/// seule raison d'être de la découpe ci-dessous — et la raison pour laquelle
/// elle se lit à UN seul endroit : le formulaire et la validité de l'étape
/// l'ont déjà interprétée chacun de son côté, l'un rendant le complément
/// facultatif pendant que l'autre exigeait encore un `address` non vide.
class StudentAddressParts {
  final String neighborhood;
  final String additionalAddress;

  const StudentAddressParts({
    required this.neighborhood,
    required this.additionalAddress,
  });

  /// Dossier : `neighborhood` fait foi dès qu'il est renseigné ; `address`
  /// n'est redécoupé que pour les dossiers écrits avant la scission.
  factory StudentAddressParts.of(StudentDetail student) {
    final neighborhood = student.neighborhood.trim();
    if (neighborhood.isEmpty) {
      return StudentAddressParts.split(student.address);
    }

    final rawAddress = student.address.trim();
    if (rawAddress.isEmpty) {
      return StudentAddressParts(
        neighborhood: neighborhood,
        additionalAddress: '',
      );
    }

    // Dossier d'avant la scission dont le quartier a depuis été renseigné :
    // il est encore préfixé à l'adresse, on ne le compte pas deux fois.
    final prefixed = '$neighborhood,';
    if (rawAddress.startsWith(prefixed)) {
      return StudentAddressParts(
        neighborhood: neighborhood,
        additionalAddress: rawAddress.substring(prefixed.length).trim(),
      );
    }

    return StudentAddressParts(
      neighborhood: neighborhood,
      additionalAddress: rawAddress,
    );
  }

  /// Découpe « Quartier, rue X » d'un dossier d'avant la scission.
  factory StudentAddressParts.split(String rawAddress) {
    final trimmed = rawAddress.trim();
    if (trimmed.isEmpty) {
      return const StudentAddressParts(neighborhood: '', additionalAddress: '');
    }

    final separatorIndex = trimmed.indexOf(',');
    if (separatorIndex < 0) {
      return StudentAddressParts(neighborhood: trimmed, additionalAddress: '');
    }

    return StudentAddressParts(
      neighborhood: trimmed.substring(0, separatorIndex).trim(),
      additionalAddress: trimmed.substring(separatorIndex + 1).trim(),
    );
  }
}
