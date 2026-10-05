import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:school_app_flutter/core/components/avatars/person_photo_source.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';
import 'package:school_app_flutter/features/student_photo/domain/usecases/student_photo_use_cases.dart';

/// La photo de chaque élève, telle que l'interface la montre — la
/// [PersonPhotoSource] des avatars.
///
/// Tient en mémoire l'index de l'école (une ligne par élève photographié) et
/// les octets récemment montrés, sous la version de la photo : tant qu'elle ne
/// change pas, le même tableau est rendu et le cache d'images de Flutter le
/// sert sans le décoder. Relit l'index à chaque changement annoncé, et ne
/// prévient que les avatars dont la photo a changé.
///
/// Un service de longue vie, pas un BLoC : il n'a pas d'écran, il sert tous
/// les écrans.
class StudentPhotoRegistry implements PersonPhotoSource {
  final LoadStudentPhotoIndexUseCase _loadIndex;
  final ReadStudentPhotoUseCase _read;

  StudentPhotoRegistry({
    required LoadStudentPhotoIndexUseCase loadIndex,
    required ReadStudentPhotoUseCase read,
  }) : _loadIndex = loadIndex,
       _read = read;

  /// Plafond des octets gardés en mémoire (≈ 300 vignettes et 60 photos).
  static const int maxCachedBytes = 8 * 1024 * 1024;

  Map<String, StudentPhotoRef> _refs = const {};
  final Map<String, ValueNotifier<StudentPhotoRef?>> _watched = {};
  final Map<String, _KeyListenable> _keys = {};
  final LinkedHashMap<String, Uint8List> _bytes = LinkedHashMap();
  final Map<String, Future<Uint8List?>> _inFlight = {};
  int _cachedBytes = 0;
  StreamSubscription<Set<String>>? _changes;
  Future<void>? _loading;
  bool _refreshing = false;
  bool _stale = false;

  /// Charge l'index et s'abonne aux changements. Idempotent.
  Future<void> start() {
    _changes ??= _loadIndex.changes.listen((_) => unawaited(_coalesce()));
    return _loading ??= refresh();
  }

  /// Une relecture à la fois : les annonces reçues pendant qu'elle court en
  /// demandent UNE de plus, pas une chacune.
  Future<void> _coalesce() async {
    if (_refreshing) {
      _stale = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _stale = false;
        await refresh();
      } while (_stale);
    } finally {
      _refreshing = false;
    }
  }

  /// Relit l'index et prévient les avatars dont la photo a changé.
  Future<void> refresh() async {
    final result = await _loadIndex();
    result.fold((_) {}, (refs) {
      _refs = refs;
      for (final entry in _watched.entries) {
        entry.value.value = refs[entry.key];
      }
    });
  }

  StudentPhotoRef? refOf(String studentId) => _refs[studentId];

  /// L'état de la photo de [studentId], au fil de l'eau — pour les écrans qui
  /// montrent aussi l'attente ou le refus d'un geste.
  ValueListenable<StudentPhotoRef?> watch(String studentId) {
    unawaited(start());
    return _watched.putIfAbsent(
      studentId,
      () => ValueNotifier<StudentPhotoRef?>(_refs[studentId]),
    );
  }

  @override
  ValueListenable<String?> photoKeyOf(String personId) =>
      _keys.putIfAbsent(personId, () => _KeyListenable(watch(personId)));

  @override
  Uint8List? peekPhotoBytes(String personId, {required double diameter}) {
    final key = _cacheKey(personId, diameter);
    if (key == null) return null;
    final bytes = _bytes.remove(key);
    if (bytes != null) _bytes[key] = bytes;
    return bytes;
  }

  @override
  Future<Uint8List?> photoBytesOf(
    String personId, {
    required double diameter,
  }) async {
    final ref = _refs[personId];
    final key = _cacheKey(personId, diameter);
    if (ref == null || key == null) return null;
    final ready = peekPhotoBytes(personId, diameter: diameter);
    if (ready != null) return ready;
    // Le rappel ne doit RIEN rendre : `remove` rendrait ce futur même, et
    // `whenComplete` l'attendrait — il s'attendrait lui-même, pour toujours.
    return _inFlight[key] ??= _load(ref, key, diameter).whenComplete(() {
      _inFlight.remove(key);
    });
  }

  Future<Uint8List?> _load(
    StudentPhotoRef ref,
    String key,
    double diameter,
  ) async {
    final wanted = StudentPhotoSize.forDiameter(diameter);
    final result = await _read(ref, wanted);
    final photo = result.fold((_) => null, (photo) => photo);
    if (photo == null) return null;
    // Rangés sous la taille REÇUE : une vignette servie faute de mieux (hors
    // ligne) ne doit pas passer pour la grande photo une fois le réseau
    // revenu.
    if (photo.size == wanted) _remember(key, photo.bytes);
    return photo.bytes;
  }

  /// La grande photo (512 px) de [studentId], **elle seule** : ce qu'un
  /// recadrage peut reprendre sans perdre en finesse. `null` si elle n'est ni
  /// sur le poste ni téléchargeable.
  Future<Uint8List?> fullPhotoOf(String studentId) async {
    final ref = _refs[studentId];
    if (ref == null || !ref.hasPhoto) return null;
    final result = await _read(ref, StudentPhotoSize.full, exact: true);
    return result.fold((_) => null, (photo) => photo?.bytes);
  }

  String? _cacheKey(String personId, double diameter) {
    final version = _refs[personId]?.version;
    if (version == null) return null;
    return '$personId|$version|${StudentPhotoSize.forDiameter(diameter).name}';
  }

  void _remember(String key, Uint8List bytes) {
    final previous = _bytes.remove(key);
    if (previous != null) _cachedBytes -= previous.length;
    _bytes[key] = bytes;
    _cachedBytes += bytes.length;
    while (_cachedBytes > maxCachedBytes && _bytes.length > 1) {
      final oldest = _bytes.keys.first;
      _cachedBytes -= _bytes.remove(oldest)!.length;
    }
  }

  Future<void> dispose() async {
    await _changes?.cancel();
    for (final notifier in _watched.values) {
      notifier.dispose();
    }
  }
}

/// La clé de photo d'un élève, tirée de son état : elle ne change qu'avec la
/// version, et c'est elle que les avatars écoutent.
class _KeyListenable extends ValueListenable<String?> {
  final ValueListenable<StudentPhotoRef?> _ref;

  _KeyListenable(this._ref);

  @override
  String? get value => _ref.value?.version;

  @override
  void addListener(VoidCallback listener) => _ref.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _ref.removeListener(listener);
}
