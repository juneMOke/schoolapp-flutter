import 'package:school_app_flutter/core/capture/camera/camera_viewfinder_gateway.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_state.dart';

/// Ce qu'une ouverture de caméra a donné : un flux, ou la raison de son
/// absence.
sealed class CameraOpening {
  const CameraOpening();
}

class CameraOpened extends CameraOpening {
  final CameraSession session;
  final bool canSwitch;

  const CameraOpened(this.session, {required this.canSwitch});
}

class CameraUnavailable extends CameraOpening {
  final CameraBlockReason reason;

  const CameraUnavailable(this.reason);
}

/// Une ouverture plus récente a pris la place de celle-ci (double appui sur
/// la bascule, reprise d'arrière-plan) : son flux est déjà refermé, il n'y a
/// rien à montrer.
class CameraSuperseded extends CameraOpening {
  const CameraSuperseded();
}

/// Ouvre, bascule et referme la caméra pour un écran de prise de vue — la
/// modale comme la séance. Une seule caméra ouverte à la fois : en ouvrir une
/// referme la précédente.
class CameraOpener {
  final CameraViewfinderGateway _gateway;
  final bool _isTouch;

  CameraOpener(this._gateway, {required bool isTouch}) : _isTouch = isTouch;

  List<CameraLens> _lenses = const [];
  CameraSession? _session;

  /// Le numéro de la dernière ouverture demandée : une ouverture dépassée
  /// referme ce qu'elle a obtenu, sinon un contrôleur resterait allumé sans
  /// que personne ne le tienne.
  int _generation = 0;

  CameraSession? get session => _session;

  /// Ouvre [lens], ou la caméra préférée (arrière sur tablette, avant sur
  /// poste).
  Future<CameraOpening> open([CameraLens? lens]) async {
    final generation = ++_generation;
    await close();
    try {
      if (_lenses.isEmpty) _lenses = await _gateway.lenses();
      final chosen = lens ?? _gateway.preferredLens(_lenses, isTouch: _isTouch);
      if (chosen == null) {
        return const CameraUnavailable(CameraBlockReason.none);
      }
      final session = await _gateway.open(chosen);
      if (generation != _generation) {
        await session.close();
        return const CameraSuperseded();
      }
      _session = session;
      return CameraOpened(session, canSwitch: _lenses.length > 1);
    } on CameraAccessDeniedException {
      return const CameraUnavailable(CameraBlockReason.denied);
    } catch (_) {
      return const CameraUnavailable(CameraBlockReason.none);
    }
  }

  /// Passe à la caméra suivante (avant ↔ arrière).
  Future<CameraOpening> switchNext() async {
    final current = _session?.lens;
    if (current == null || _lenses.length < 2) return open();
    final index = _lenses.indexOf(current);
    return open(_lenses[(index + 1) % _lenses.length]);
  }

  /// Referme le flux, et rend caduque toute ouverture encore en vol.
  Future<void> release() async {
    _generation++;
    await close();
  }

  Future<void> close() async {
    final session = _session;
    _session = null;
    if (session != null) await session.close();
  }
}
