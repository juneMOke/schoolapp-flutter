import 'package:equatable/equatable.dart';

/// Une version `MAJEUR.MINEUR.CORRECTIF`, la seule forme que le back accepte
/// pour une version de bureau (ni pré-version, ni « +build »).
///
/// [tryParse] tolère le « +N » que `PackageInfo` peut accoler sur certaines
/// plateformes : le numéro de build ne départage jamais deux versions.
class AppVersion extends Equatable implements Comparable<AppVersion> {
  final int major;
  final int minor;
  final int patch;

  const AppVersion(this.major, this.minor, this.patch);

  static final RegExp _strict = RegExp(
    r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$',
  );

  /// La version stricte de [raw], ou `null`.
  static AppVersion? tryParseStrict(String? raw) {
    final match = _strict.firstMatch(raw?.trim() ?? '');
    if (match == null) return null;
    return AppVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  /// Comme [tryParseStrict], après avoir retiré un éventuel « +build ».
  static AppVersion? tryParse(String? raw) {
    final value = raw?.trim() ?? '';
    final plus = value.indexOf('+');
    return tryParseStrict(plus < 0 ? value : value.substring(0, plus));
  }

  bool operator <(AppVersion other) => compareTo(other) < 0;
  bool operator >(AppVersion other) => compareTo(other) > 0;

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  String toString() => '$major.$minor.$patch';

  @override
  List<Object?> get props => [major, minor, patch];
}
