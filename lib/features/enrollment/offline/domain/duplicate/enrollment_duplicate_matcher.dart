import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_level.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_identity.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_identity_key.dart';

/// Rapproche l'identité **saisie au guichet** d'élèves déjà connus, et dit avec
/// quelle force. Fonction pure : ni base, ni contexte, ni traduction.
///
/// La saisie est normalisée **une seule fois**, à la construction : le
/// rapprochement balaie ensuite tout le corpus local (dossiers de l'année +
/// cohorte N-1) sans refaire ce travail à chaque ligne.
///
/// Le SQL ne peut pas porter ce filtre : `LOWER()` SQLite ne plie pas les
/// accents, et ici un faux négatif n'est pas une gêne — c'est le doublon
/// manqué, donc l'échec de la sonde.
class EnrollmentDuplicateMatcher {
  /// Les trois clés de la saisie, **en position**.
  final _IdentityKeys _keys;

  /// Les mêmes, réduites aux non vides — le multi-ensemble dans lequel les noms
  /// d'un candidat doivent tous se retrouver.
  final List<String> _pool;

  /// Date de naissance saisie, ramenée en date-only. `null` si elle ne se lit
  /// pas : on ne confirmera alors aucune date.
  final String? _dateOfBirth;

  const EnrollmentDuplicateMatcher._(this._keys, this._pool, this._dateOfBirth);

  factory EnrollmentDuplicateMatcher(EnrollmentIdentity typed) {
    final keys = _IdentityKeys.of(typed);
    return EnrollmentDuplicateMatcher._(
      keys,
      keys.nonEmpty,
      dateOnlyOrNull(typed.dateOfBirth),
    );
  }

  /// Vrai si la saisie porte de quoi rapprocher, c'est-à-dire **au moins deux**
  /// noms non vides.
  ///
  /// Garde défensive : l'étape Identité exige les trois, mais une saisie
  /// dégradée qui arriverait ici avec un seul nom rapprocherait la moitié de
  /// l'école. Faux dans ce cas, et [match] ne rend plus rien.
  bool get isUsable => _pool.length >= 2;

  /// Force du rapprochement avec [candidate], ou `null` si les noms ne se
  /// correspondent pas du tout.
  ///
  /// |                          | même date | date différente |
  /// |--------------------------|-----------|-----------------|
  /// | noms exacts              | certain   | possible        |
  /// | noms à l'ordre près      | probable  | possible        |
  /// | ni l'un ni l'autre       | —         | —               |
  ///
  /// Les trois niveaux sont exclusifs : un élève ne remonte qu'une fois, au
  /// plus fort qu'il atteint.
  EnrollmentDuplicateLevel? match(EnrollmentIdentity candidate) {
    if (!isUsable) return null;

    final keys = _IdentityKeys.of(candidate);
    final sameDateOfBirth = _sameDateOfBirth(candidate.dateOfBirth);

    // Un candidat exact est nécessairement inclus (la saisie porte au moins
    // deux noms non vides, donc lui aussi) : le test d'inclusion est inutile.
    if (keys == _keys) {
      return sameDateOfBirth
          ? EnrollmentDuplicateLevel.certain
          : EnrollmentDuplicateLevel.possible;
    }

    if (!_isIncluded(keys)) return null;

    return sameDateOfBirth
        ? EnrollmentDuplicateLevel.probable
        : EnrollmentDuplicateLevel.possible;
  }

  /// Tous les noms non vides de [keys] se retrouvent-ils dans la saisie,
  /// **multiplicités comprises** et sans égard à l'ordre ?
  ///
  /// L'inclusion — et non l'égalité — est ce qui laisse passer le dossier
  /// ancien dépourvu de post-nom, dont les deux noms se retrouvent tels quels
  /// dans une saisie qui en porte trois.
  ///
  /// Deux noms minimum côté candidat : à un seul, tous les « Mukendi » de
  /// l'école remonteraient sur une saisie qui contient ce nom.
  bool _isIncluded(_IdentityKeys keys) {
    final candidateKeys = keys.nonEmpty;
    if (candidateKeys.length < 2) return false;

    final pool = List<String>.of(_pool);
    for (final key in candidateKeys) {
      // `remove` retire UNE occurrence : deux noms identiques côté candidat
      // exigent deux noms identiques côté saisie.
      if (!pool.remove(key)) return false;
    }
    return true;
  }

  bool _sameDateOfBirth(String raw) {
    final typed = _dateOfBirth;
    if (typed == null) return false;
    final candidate = dateOnlyOrNull(raw);
    return candidate != null && candidate == typed;
  }

  /// [raw] ramenée à une date-only ISO comparable, ou `null` si elle est
  /// absente ou illisible.
  ///
  /// Passer par un `DateTime` plutôt que comparer les chaînes brutes : la même
  /// date descend du serveur avec une partie horaire (`2015-03-04T00:00:00Z`)
  /// là où le brouillon local l'écrit nue (`2015-03-04`). Deux chaînes
  /// différentes, une seule date.
  ///
  /// **Une date qu'on ne sait pas lire ne confirme rien** — elle ne vaut pas
  /// égalité entre deux illisibles. Le rapprochement retombe sur `possible`,
  /// qui est exactement ce qu'on sait alors.
  static String? dateOnlyOrNull(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    try {
      return DateOnlyJsonHelper.toJson(DateOnlyJsonHelper.fromJson(trimmed));
    } catch (_) {
      return null;
    }
  }
}

/// Les trois noms d'une identité, réduits à leur clé de rapprochement.
class _IdentityKeys {
  final String lastName;
  final String firstName;
  final String surname;

  const _IdentityKeys({
    required this.lastName,
    required this.firstName,
    required this.surname,
  });

  factory _IdentityKeys.of(EnrollmentIdentity identity) => _IdentityKeys(
    lastName: EnrollmentIdentityKey.of(identity.lastName),
    firstName: EnrollmentIdentityKey.of(identity.firstName),
    surname: EnrollmentIdentityKey.of(identity.surname),
  );

  List<String> get nonEmpty => <String>[
    lastName,
    firstName,
    surname,
  ].where((key) => key.isNotEmpty).toList(growable: false);

  @override
  bool operator ==(Object other) =>
      other is _IdentityKeys &&
      other.lastName == lastName &&
      other.firstName == firstName &&
      other.surname == surname;

  @override
  int get hashCode => Object.hash(lastName, firstName, surname);
}
