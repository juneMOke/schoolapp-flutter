import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_photo_source.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// La photo de [personId] si une [PersonPhotoScope] la fournit, sinon
/// [fallback] tel quel. Le point d'entrée de tout avatar qui peut porter une
/// photo d'élève : `null` (agent, parent, élève pas encore créé) garde le
/// repli, sans rien demander à personne.
class PersonPhotoOr extends StatelessWidget {
  final String? personId;
  final double size;
  final Widget fallback;

  const PersonPhotoOr({
    super.key,
    required this.personId,
    required this.size,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final id = personId;
    final source = id == null ? null : PersonPhotoScope.maybeOf(context);
    if (id == null || source == null) return fallback;
    return PersonPhotoAvatar(
      source: source,
      personId: id,
      size: size,
      fallback: fallback,
    );
  }
}

/// La photo d'une personne dans un disque de [size] dp, [fallback] (les
/// initiales) tant qu'il n'y en a pas.
///
/// - Photo connue mais pas encore lue : un disque squelette de même diamètre,
///   jamais de saut de mise en page.
/// - Photo illisible ou indisponible (hors ligne, sans copie) : [fallback].
/// - Les octets déjà en mémoire se dessinent au premier cadre, sans squelette.
class PersonPhotoAvatar extends StatefulWidget {
  final PersonPhotoSource source;
  final String personId;
  final double size;
  final Widget fallback;

  const PersonPhotoAvatar({
    super.key,
    required this.source,
    required this.personId,
    required this.size,
    required this.fallback,
  });

  @override
  State<PersonPhotoAvatar> createState() => _PersonPhotoAvatarState();
}

class _PersonPhotoAvatarState extends State<PersonPhotoAvatar> {
  String? _loadedKey;
  Future<Uint8List?>? _bytes;

  Future<Uint8List?> _bytesFor(String key) {
    if (_loadedKey != key || _bytes == null) {
      _loadedKey = key;
      _bytes = widget.source.photoBytesOf(
        widget.personId,
        diameter: widget.size,
      );
    }
    return _bytes!;
  }

  @override
  void didUpdateWidget(PersonPhotoAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.personId != widget.personId ||
        oldWidget.size != widget.size ||
        oldWidget.source != widget.source) {
      _loadedKey = null;
      _bytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: widget.source.photoKeyOf(widget.personId),
      builder: (context, key, _) {
        if (key == null) return widget.fallback;
        final ready = widget.source.peekPhotoBytes(
          widget.personId,
          diameter: widget.size,
        );
        if (ready != null) return _photo(ready);
        return FutureBuilder<Uint8List?>(
          future: _bytesFor(key),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return EteeloSkeletonBox(
                width: widget.size,
                height: widget.size,
                borderRadius: AppRadius.brPill,
              );
            }
            final bytes = snapshot.data;
            return bytes == null ? widget.fallback : _photo(bytes);
          },
        );
      },
    );
  }

  Widget _photo(Uint8List bytes) {
    final pixels = (widget.size * MediaQuery.devicePixelRatioOf(context))
        .ceil();
    return Container(
      width: widget.size,
      height: widget.size,
      foregroundDecoration: const BoxDecoration(
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.photoInnerRing),
        ),
      ),
      child: ClipOval(
        child: Image(
          image: ResizeImage(MemoryImage(bytes), width: pixels),
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => widget.fallback,
        ),
      ),
    );
  }
}
